using System;
using System.Threading;
using Microsoft.CommandPalette.Extensions;
using Shmuelie.WinRTServer;
using Shmuelie.WinRTServer.CsWinRT;

namespace __Name__;

public static class Program
{
    [MTAThread]
    public static void Main(string[] args)
    {
        if (args.Length > 0 && args[0] == "-RegisterProcessAsComServer")
        {
            // Normal start: Command Palette launches the exe with this argument (see Package.appxmanifest).
            global::Shmuelie.WinRTServer.ComServer server = new();
            ManualResetEvent disposed = new(false);
            __Name__Extension instance = new(disposed);
            server.RegisterClass<__Name__Extension, IExtension>(() => instance);
            server.Start();
            disposed.WaitOne();
            server.Stop();
            server.UnsafeDispose();
        }
        else if (args.Length > 0 && args[0] == "--dump")
        {
            // Diagnostics without Command Palette: print what the band would show.
            // WinExe: run as  .\__Name__.exe --dump | Out-String
            var s = StatusSource.Read();
            Console.WriteLine($"Title:   {StatusView.Title(s)}");
            Console.WriteLine($"Tooltip:\n{StatusView.Hover(s)}");
        }
        else
        {
            Console.WriteLine("Not launched by Command Palette. Use --dump.");
        }
    }
}
