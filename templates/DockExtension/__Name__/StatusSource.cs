using System;
using System.Diagnostics;
using System.IO;
using System.Threading;

namespace __Name__;

/// <summary>One reading of the data the band shows. Replace the fields with your own data.</summary>
internal sealed record StatusSnapshot(DateTime Time, TimeSpan Uptime, int Processes, string Machine)
{
    public bool IsBusy => Processes > 400;
}

/// <summary>
/// YOUR DATA GOES HERE. Polls on a timer and raises <see cref="Changed"/> with a new snapshot.
/// The sample reads the clock, the system uptime and the process count. Replace <see cref="Read"/>
/// with a call to your API, a file, a CLI tool, and so on. Keep each poll short: it runs on a
/// thread-pool thread, and the Dock updates on every change.
/// </summary>
internal static class StatusSource
{
    private static readonly TimeSpan Interval = TimeSpan.FromSeconds(15);
    private static Timer? _timer;

    public static event Action<StatusSnapshot>? Changed;

    public static StatusSnapshot Current { get; private set; } = Read();

    public static void Start() => _timer ??= new Timer(_ => Poll(), null, TimeSpan.Zero, Interval);

    public static StatusSnapshot Read()
    {
        var processes = Process.GetProcesses();
        var count = processes.Length;
        foreach (var p in processes)
        {
            p.Dispose();
        }

        return new StatusSnapshot(DateTime.Now, TimeSpan.FromMilliseconds(Environment.TickCount64), count, Environment.MachineName);
    }

    private static void Poll()
    {
        try
        {
            Current = Read();
            Changed?.Invoke(Current);
        }
        catch (Exception ex)
        {
            Log.Write($"Poll failed: {ex}");
        }
    }
}

/// <summary>Extensions have no console. Write to %USERPROFILE%\.__namelower__\log.txt instead.</summary>
internal static class Log
{
    private static readonly string LogPath = Init();
    private static readonly object Gate = new();

    public static void Write(string message)
    {
        try
        {
            lock (Gate)
            {
                File.AppendAllText(LogPath, $"{DateTime.Now:HH:mm:ss.fff} {message}{Environment.NewLine}");
            }
        }
        catch
        {
        }
    }

    private static string Init()
    {
        var dir = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.UserProfile), ".__namelower__");
        Directory.CreateDirectory(dir);
        return Path.Combine(dir, "log.txt");
    }
}
