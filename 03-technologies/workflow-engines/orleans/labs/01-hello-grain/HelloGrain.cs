using Orleans;
using System;
using System.Threading;
using System.Threading.Tasks;

namespace HelloGrain;

/// <summary>
/// Grain implementation — the actual logic.
/// Each grain processes one request at a time (no concurrent access).
/// The _callCount field lives in memory — it resets when the grain deactivates.
/// </summary>
public sealed class HelloGrain : Grain, IHelloGrain
{
    private int _callCount;

    public override Task OnActivateAsync(CancellationToken ct)
    {
        Console.WriteLine($"  [Grain] Activated: {this.GetPrimaryKeyString()}");
        return base.OnActivateAsync(ct);
    }

    public Task<string> SayHello(string name)
    {
        _callCount++;
        var grainId = this.GetPrimaryKeyString();
        return Task.FromResult($"Hello, {name}! I am grain '{grainId}'. Call #{_callCount}");
    }

    public Task<int> GetCallCount() => Task.FromResult(_callCount);
}
