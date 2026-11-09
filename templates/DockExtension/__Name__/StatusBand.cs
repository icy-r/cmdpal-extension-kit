using System;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace __Name__;

internal static class StatusIcons
{
    // SVG files in Assets\ keep their colors and stay sharp at every Dock size.
    public static readonly IconInfo Ok = IconHelpers.FromRelativePath("Assets\\status-ok.svg");
    public static readonly IconInfo Busy = IconHelpers.FromRelativePath("Assets\\status-busy.svg");

    // A Segoe Fluent Icons glyph: drawn in the theme's text color.
    public static readonly IconInfo Copy = new("");
}

/// <summary>Text for the band, its tooltip, and the flyout. Keep formatting in one place.</summary>
internal static class StatusView
{
    public static string Title(StatusSnapshot s) => s.Time.ToString("HH:mm");

    // The Dock tooltip is Title + "\n" + Subtitle, so a multi-line subtitle is the hover preview.
    // Plain text only: no Markdown, no colors. Emoji work.
    public static string Hover(StatusSnapshot s) =>
        $"{s.Time:dddd, d MMMM}\n" +
        $"{(s.IsBusy ? "🟠" : "🟢")} {s.Processes} processes\n" +
        $"⏱ up {Span(s.Uptime)} on {s.Machine}\n" +
        "Click: open details";

    public static string Span(TimeSpan t) =>
        t.TotalHours < 1 ? $"{(int)t.TotalMinutes}m" : t.TotalDays < 1 ? $"{(int)t.TotalHours}h {t.Minutes}m" : $"{(int)t.TotalDays}d {t.Hours}h";
}

/// <summary>
/// The Dock band: a strip of buttons (here just one). Update the existing ListItem's properties in
/// place; assign <see cref="WrappedDockItem.Items"/> again only when buttons come or go, because
/// that rebuilds every button (flicker, and an open tooltip closes).
/// </summary>
internal sealed partial class StatusBand : WrappedDockItem
{
    private readonly ListItem _item;

    public StatusBand()
        : base([], __Name__CommandsProvider.BandId, "__DisplayName__")
    {
        Icon = StatusIcons.Ok;

        // The item's command decides what a click does: a ListPage opens a flyout.
        _item = new ListItem(new StatusPage())
        {
            // Right-click menu.
            MoreCommands = [new CommandContextItem(new CopyTextCommand(Environment.MachineName) { Name = "Copy machine name", Icon = StatusIcons.Copy })],
        };
        Update(StatusSource.Current);
        Items = [_item];
        StatusSource.Changed += Update;
    }

    private void Update(StatusSnapshot s)
    {
        _item.Title = StatusView.Title(s);
        _item.Subtitle = StatusView.Hover(s);
        _item.Icon = s.IsBusy ? StatusIcons.Busy : StatusIcons.Ok;
    }
}
