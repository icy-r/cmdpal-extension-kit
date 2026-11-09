using Microsoft.CommandPalette.Extensions;
using Microsoft.CommandPalette.Extensions.Toolkit;

namespace __Name__;

public sealed partial class __Name__CommandsProvider : CommandProvider
{
    // The Dock needs a provider Id and a band Id. add-to-dock.ps1 pins BandId.
    public const string ProviderId = "__Id__";
    public const string BandId = "__Id__.band";

    private readonly StatusBand _band = new();
    private readonly ICommandItem[] _commands;

    public __Name__CommandsProvider()
    {
        Id = ProviderId;
        DisplayName = "__DisplayName__";
        Icon = StatusIcons.Ok;
        _commands =
        [
            // Also searchable in the Command Palette itself.
            new CommandItem(new StatusPage()) { Title = "__DisplayName__", Subtitle = "Open the status list" },
        ];
        StatusSource.Start();
    }

    public override ICommandItem[] TopLevelCommands() => _commands;

    public override ICommandItem[]? GetDockBands() => [_band];
}
