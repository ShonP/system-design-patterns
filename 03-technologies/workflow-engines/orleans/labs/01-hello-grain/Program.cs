using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Orleans;
using Orleans.Hosting;
using System;
using System.Threading.Tasks;

namespace HelloGrain;

public static class Program
{
    public static async Task Main(string[] args)
    {
        Console.WriteLine("=== Lab 01: Hello Grain ===\n");

        // Build and start an Orleans silo (the server that hosts grains)
        var builder = Host.CreateApplicationBuilder(args);

        builder.Host.UseOrleans(silo =>
        {
            // UseLocalhostClustering: single-node development mode
            // No external dependencies needed — everything runs in-process
            silo.UseLocalhostClustering();
        });

        using var host = builder.Build();
        await host.StartAsync();

        Console.WriteLine("✅ Orleans silo started!\n");

        // Get a reference to the grain factory (used to call grains)
        var grainFactory = host.Services.GetRequiredService<IGrainFactory>();

        // --- Exercise 1: Call a grain ---
        // GetGrain<IHelloGrain>("hello-1") gets a REFERENCE to the grain.
        // It does NOT create it — Orleans activates it on the first call.
        var grain = grainFactory.GetGrain<IHelloGrain>("hello-1");

        var response = await grain.SayHello("World");
        Console.WriteLine($"  Response: {response}");

        // --- Exercise 2: Same ID = same grain ---
        // Calling the same grain ID again goes to the SAME activation.
        var response2 = await grain.SayHello("Orleans");
        Console.WriteLine($"  Response: {response2}");

        var count = await grain.GetCallCount();
        Console.WriteLine($"  Call count: {count} (should be 2)\n");

        // --- Exercise 3: Different ID = different grain ---
        var grain2 = grainFactory.GetGrain<IHelloGrain>("hello-2");
        var response3 = await grain2.SayHello("Developer");
        Console.WriteLine($"  Response: {response3}");

        var count2 = await grain2.GetCallCount();
        Console.WriteLine($"  Call count: {count2} (should be 1)\n");

        Console.WriteLine("🎓 Key takeaways:");
        Console.WriteLine("   - Grains are referenced by ID, not created manually");
        Console.WriteLine("   - Same ID = same grain activation");
        Console.WriteLine("   - Different ID = different grain activation");
        Console.WriteLine("   - Each grain processes one request at a time\n");

        await host.StopAsync();
    }
}
