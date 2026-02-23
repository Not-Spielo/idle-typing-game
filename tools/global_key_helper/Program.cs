using System.Net.Sockets;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.Json;

namespace GlobalKeyHelper;

internal static class Program
{
    private const int WH_KEYBOARD_LL = 13;
    private const int WM_KEYDOWN = 0x0100;
    private const int WM_SYSKEYDOWN = 0x0104;

    private static readonly HookProc HookDelegate = HookCallback;
    private static readonly object SendLock = new();

    private static IntPtr hookHandle = IntPtr.Zero;
    private static string host = "127.0.0.1";
    private static int port = 37193;

    private static TcpClient? client;
    private static StreamWriter? writer;
    private static DateTime lastReconnectAttemptUtc = DateTime.MinValue;

    private sealed record KeyMessage(string @char);

    private static int Main(string[] args)
    {
        ParseArgs(args);
        EnsureConnected();

        AppDomain.CurrentDomain.ProcessExit += (_, _) => Cleanup();
        Console.CancelKeyPress += (_, eventArgs) =>
        {
            eventArgs.Cancel = true;
            Cleanup();
            Environment.Exit(0);
        };

        hookHandle = SetWindowsHookEx(WH_KEYBOARD_LL, HookDelegate, GetModuleHandle(null), 0);
        if (hookHandle == IntPtr.Zero)
        {
            return 1;
        }

        while (GetMessage(out MSG msg, IntPtr.Zero, 0, 0) > 0)
        {
            TranslateMessage(ref msg);
            DispatchMessage(ref msg);
        }

        Cleanup();
        return 0;
    }

    private static void ParseArgs(string[] args)
    {
        for (int i = 0; i < args.Length; i++)
        {
            if (string.Equals(args[i], "--host", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
            {
                host = args[++i];
            }
            else if (string.Equals(args[i], "--port", StringComparison.OrdinalIgnoreCase) && i + 1 < args.Length)
            {
                if (int.TryParse(args[++i], out int parsedPort) && parsedPort > 0 && parsedPort <= 65535)
                {
                    port = parsedPort;
                }
            }
        }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0)
        {
            int msg = wParam.ToInt32();
            if (msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN)
            {
                KBDLLHOOKSTRUCT keyData = Marshal.PtrToStructure<KBDLLHOOKSTRUCT>(lParam);
                string? keyText = TryTranslateKey((uint)keyData.vkCode, (uint)keyData.scanCode);
                if (!string.IsNullOrEmpty(keyText))
                {
                    SendKey(keyText);
                }
            }
        }

        return CallNextHookEx(hookHandle, nCode, wParam, lParam);
    }

    private static string? TryTranslateKey(uint virtualKeyCode, uint scanCode)
    {
        byte[] keyboardState = new byte[256];
        if (!GetKeyboardState(keyboardState))
        {
            return null;
        }

        IntPtr keyboardLayout = GetKeyboardLayout(0);
        StringBuilder buffer = new(8);
        int result = ToUnicodeEx(virtualKeyCode, scanCode, keyboardState, buffer, buffer.Capacity, 0, keyboardLayout);
        if (result <= 0)
        {
            return null;
        }

        string translated = buffer.ToString();
        if (translated.Length == 0)
        {
            return null;
        }

        char c = translated[0];
        if (char.IsControl(c))
        {
            return null;
        }

        return c.ToString();
    }

    private static void SendKey(string key)
    {
        lock (SendLock)
        {
            EnsureConnected();
            if (writer is null)
            {
                return;
            }

            try
            {
                string payload = JsonSerializer.Serialize(new KeyMessage(key));
                writer.WriteLine(payload);
            }
            catch
            {
                DisposeClient();
            }
        }
    }

    private static void EnsureConnected()
    {
        if (writer is not null)
        {
            return;
        }

        DateTime now = DateTime.UtcNow;
        if ((now - lastReconnectAttemptUtc).TotalMilliseconds < 750)
        {
            return;
        }

        lastReconnectAttemptUtc = now;

        try
        {
            TcpClient tcpClient = new();
            tcpClient.NoDelay = true;
            tcpClient.Connect(host, port);
            client = tcpClient;
            writer = new StreamWriter(client.GetStream(), new UTF8Encoding(false))
            {
                AutoFlush = true
            };
        }
        catch
        {
            DisposeClient();
        }
    }

    private static void Cleanup()
    {
        if (hookHandle != IntPtr.Zero)
        {
            UnhookWindowsHookEx(hookHandle);
            hookHandle = IntPtr.Zero;
        }

        DisposeClient();
    }

    private static void DisposeClient()
    {
        try
        {
            writer?.Dispose();
        }
        catch
        {
        }

        try
        {
            client?.Dispose();
        }
        catch
        {
        }

        writer = null;
        client = null;
    }

    private delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    private struct KBDLLHOOKSTRUCT
    {
        public uint vkCode;
        public uint scanCode;
        public uint flags;
        public uint time;
        public nuint dwExtraInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct MSG
    {
        public IntPtr hwnd;
        public uint message;
        public nuint wParam;
        public nint lParam;
        public uint time;
        public POINT pt;
    }

    [StructLayout(LayoutKind.Sequential)]
    private struct POINT
    {
        public int x;
        public int y;
    }

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, HookProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", SetLastError = true)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    private static extern IntPtr GetModuleHandle(string? lpModuleName);

    [DllImport("user32.dll")]
    private static extern sbyte GetMessage(out MSG lpMsg, IntPtr hWnd, uint wMsgFilterMin, uint wMsgFilterMax);

    [DllImport("user32.dll")]
    private static extern bool TranslateMessage([In] ref MSG lpMsg);

    [DllImport("user32.dll")]
    private static extern IntPtr DispatchMessage([In] ref MSG lpmsg);

    [DllImport("user32.dll")]
    private static extern bool GetKeyboardState(byte[] lpKeyState);

    [DllImport("user32.dll")]
    private static extern IntPtr GetKeyboardLayout(uint idThread);

    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    private static extern int ToUnicodeEx(uint wVirtKey, uint wScanCode, byte[] lpKeyState, [Out, MarshalAs(UnmanagedType.LPWStr)] StringBuilder pwszBuff, int cchBuff, uint wFlags, IntPtr dwhkl);
}
