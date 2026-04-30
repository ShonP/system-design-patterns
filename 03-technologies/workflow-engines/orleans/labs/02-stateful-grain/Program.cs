using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Orleans;
using Orleans.Hosting;
using System;
using System.Threading.Tasks;

namespace StatefulGrain;

public static class Program
{
    public static async Task Main(string[] args)
    {
        Console.WriteLine("=== Lab 02: Stateful Grain ===\n");

        var builder = Host.CreateApplicationBuilder(args);

        builder.Host.UseOrleans(silo =>
        {
            silo.UseLocalhostClustering();

            // AddMemoryGrainStorage: stores state in memory (not durable)
            // For production, swap with AddAdoNetGrainStorage, AddRedisGrainStorage, etc.
            silo.AddMemoryGrainStorage("Default");
        });

        using var host = builder.Build();
        await host.StartAsync();

        Console.WriteLine("✅ Orleans silo started!\n");

        var grainFactory = host.Services.GetRequiredService<IGrainFactory>();
        var counter = grainFactory.GetGrain<ICounterGrain>("my-counter");

        // --- Exercise 1: Increment the counter ---
        Console.WriteLine("Adding values to the counter:");
        var v1 = await counter.Add(5);
        Console.WriteLine($"  Add(5) → {v1}");

        var v2 = await counter.Add(3);
        Console.WriteLine($"  Add(3) → {v2}");

        var v3 = await counter.Add(10);
        Console.WriteLine($"  Add(10) → {v3}");

        // --- Exercise 2: Read the full state ---
        var state = await counter.GetFullState();
        Console.WriteLine($"\n  Full state:");
        Console.WriteLine($"    Value: {state.Value}");
        Console.WriteLine($"    Operations: {state.TotalOperations}");
        Console.WriteLine($"    Last modified: {state.LastModified:HH:mm:ss}");

        // --- Exercise 3: Reset ---
        Console.WriteLine("\n  Resetting counter...");
        await counter.Reset();
        var afterReset = await counter.Get();
        Console.WriteLine($"  Value after reset: {afterReset} (should be 0)\n");

        Console.WriteLine("🎓 Key takeaways:");
        Console.WriteLine("   - [PersistentState] injects durable state into grains");
        Console.WriteLine("   - WriteStateAsync() saves state explicitly");
        Console.WriteLine("   - ClearStateAsync() deletes persisted state");
        Console.WriteLine("   - Swap providers without changing grain code\n");

        await host.StopAsync();
    }
}
