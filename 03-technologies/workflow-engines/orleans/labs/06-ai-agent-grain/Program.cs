using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Orleans;

namespace AiAgentGrain;

public static class Program
{
    public static async Task Main(string[] args)
    {
        Console.WriteLine("=== Lab 06: AI Agent Grain ===\n");

        var builder = Host.CreateApplicationBuilder(args);

        builder.UseOrleans(silo =>
        {
            silo.UseLocalhostClustering();
            silo.AddMemoryGrainStorage("Default");
        });

        using var host = builder.Build();
        await host.StartAsync();

        Console.WriteLine("✅ Orleans silo started!\n");

        var grainFactory = host.Services.GetRequiredService<IGrainFactory>();

        var agent = grainFactory.GetGrain<IAgentGrain>("assistant-1");
        await agent.SetPersonality("friendly");

        var r1 = await agent.Chat("Hello, who are you?");
        Console.WriteLine($"  Agent: {r1.Text}");

        var r2 = await agent.Chat("Please remember that the sky is blue");
        Console.WriteLine($"  Agent: {r2.Text}");

        var r3 = await agent.Chat("What facts do you know?");
        Console.WriteLine($"  Agent: {r3.Text}");

        Console.WriteLine("\n  Creating a second agent...");
        var agent2 = grainFactory.GetGrain<IAgentGrain>("researcher-1");
        await agent2.SetPersonality("analytical");

        var crossReply = await agent.AskOtherAgent("researcher-1", "Hello, what do you do?");
        Console.WriteLine($"  researcher-1 replied: {crossReply.Text}");

        Console.WriteLine("\n  Agent memory:");
        var mem = await agent.GetMemory();
        Console.WriteLine($"    Interactions: {mem.TotalInteractions}");
        Console.WriteLine($"    Facts: {string.Join(", ", mem.LearnedFacts)}");
        Console.WriteLine($"    History ({mem.ConversationHistory.Count} messages):");
        foreach (var msg in mem.ConversationHistory.TakeLast(4))
        {
            Console.WriteLine($"      {msg}");
        }

        Console.WriteLine("\n🎓 Key takeaways:");
        Console.WriteLine("   - Each AI agent is a grain with its own state");
        Console.WriteLine("   - Conversation history is stored through Orleans state APIs");
        Console.WriteLine("   - Agents communicate via grain-to-grain calls");
        Console.WriteLine("   - In production, inject an LLM client instead of SimulateResponse\n");

        await host.StopAsync();
    }
}
