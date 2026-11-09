using System;
using System.Runtime.InteropServices;
using System.Threading;
using Microsoft.CommandPalette.Extensions;

namespace __Name__;

// The COM class Command Palette creates. The GUID must match the two ClassId values in
// Package.appxmanifest, and must be unique to this extension.
[Guid("__Guid__")]
public sealed partial class __Name__Extension : IExtension, IDisposable
{
    private readonly ManualResetEvent _disposed;
    private readonly __Name__CommandsProvider _provider = new();

    public __Name__Extension(ManualResetEvent disposed) => _disposed = disposed;

    public object? GetProvider(ProviderType providerType) => providerType switch
    {
        ProviderType.Commands => _provider,
        _ => null,
    };

    public void Dispose() => _disposed.Set();
}
