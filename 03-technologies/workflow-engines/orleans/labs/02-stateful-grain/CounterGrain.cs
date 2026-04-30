using Orleans;
using Orleans.Runtime;
using System;
using System.Threading.Tasks;

namespace StatefulGrain;

/// <summary>
/// A grain with durable state.
/// The [PersistentState] attribute injects an IPersistentState wrapper.
/// "counter" is the state name (used as storage key).
/// "Default" is the storage provider name (configured in Program.cs).
/// </summary>
public sealed class CounterGrain(
    [PersistentState("counter", "Default")]
    IPersistentState<CounterState> state)
    : Grain, ICounterGrain
{
    public async Task<int> Add(int amount)
    {
        state.State.Value += amount;
        state.State.TotalOperations++;
        state.State.LastModified = DateTime.UtcNow;

        // Explicitly write state to the storage provider
        await state.WriteStateAsync();

        return state.State.Value;
    }

    public Task<int> Get() => Task.FromResult(state.State.Value);

    public async Task Reset()
    {
        // ClearStateAsync removes the state from storage
        await state.ClearStateAsync();
    }

    public Task<CounterState> GetFullState() => Task.FromResult(state.State);
}
