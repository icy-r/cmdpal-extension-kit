using System;
using System.Collections.Generic;
using System.Linq;
using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace __Name__;

/// <summary>
/// The flyout (and Command Palette page): rows grouped in sections, with tags and a details pane.
///
/// RaiseItemsChanged() reloads the list and moves the selection back to the first row. So this page
/// keeps its ListItem objects, updates them in place on every poll, and raises ItemsChanged only when
/// the set or order of rows changes.
/// </summary>
internal sealed partial class StatusPage : ListPage
{
    private readonly Dictionary<string, ListItem> _rows = [];
    private readonly object _gate = new();
    private string _layout = string.Empty;

    public StatusPage()
    {
        Id = "__Id__.page"; // every command shown in the Dock needs a non-empty Id
        Name = "Open";
        Title = "__DisplayName__";
        Icon = StatusIcons.Ok;
        ShowDetails = true; // details pane on the right
        PlaceholderText = "Filter…";
        StatusSource.Changed += OnChanged;
    }

    public override IListItem[] GetItems()
    {
        lock (_gate)
        {
            var rows = Build(StatusSource.Current);
            _layout = Layout(rows);
            return rows.Select(r => (IListItem)r.Item).ToArray();
        }
    }

    private void OnChanged(StatusSnapshot s)
    {
        lock (_gate)
        {
            var layout = Layout(Build(s)); // Build updates existing rows in place
            if (layout == _layout)
            {
                return;
            }

            _layout = layout;
        }

        RaiseItemsChanged();
    }

    private static string Layout(List<(string Key, ListItem Item)> rows) =>
        string.Join("|", rows.Select(r => r.Key + "@" + r.Item.Section));

    private List<(string Key, ListItem Item)> Build(StatusSnapshot s) =>
    [
        Row("time", "System", s.Time.ToString("HH:mm:ss"), s.Time.ToString("D"),
            [new Tag(s.Time.ToString("ddd"))],
            $"Local time on **{s.Machine}**.\n\nTime zone: {TimeZoneInfo.Local.DisplayName}"),
        Row("uptime", "System", $"Up {StatusView.Span(s.Uptime)}", "Since the last restart",
            [Colored("uptime", 0x3B, 0x82, 0xF6)],
            $"Last restart: **{s.Time - s.Uptime:g}**"),
        Row("processes", s.IsBusy ? "Needs attention" : "System", $"{s.Processes} processes", "Running now",
            [s.IsBusy ? Colored("busy", 0xE0, 0x7B, 0x00) : Colored("ok", 0x16, 0xA3, 0x4A)],
            "Replace this sample with your own data in `StatusSource.cs`."),
    ];

    private (string Key, ListItem Item) Row(string key, string section, string title, string subtitle, ITag[] tags, string markdown)
    {
        if (!_rows.TryGetValue(key, out var item))
        {
            item = new ListItem(new CopyTextCommand(title) { Name = "Copy" });
            _rows[key] = item;
        }

        item.Title = title;
        item.Subtitle = subtitle;
        item.Section = section;
        item.Tags = tags;

        // A new Details object re-renders the details pane, so assign one only when the text changed.
        if (item.Details is not Details d || d.Title != title || d.Body != markdown)
        {
            item.Details = new Details { Title = title, Body = markdown };
        }

        return (key, item);
    }

    private static Tag Colored(string text, byte r, byte g, byte b) =>
        new(text) { Foreground = ColorHelpers.FromRgb(255, 255, 255), Background = ColorHelpers.FromRgb(r, g, b) };
}
