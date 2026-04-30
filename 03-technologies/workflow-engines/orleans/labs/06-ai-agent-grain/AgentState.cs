using Orleans;

namespace AiAgentGrain;

/// <summary>
/// Durable-style memory for an AI agent.
/// Persists conversation history and learned facts when paired with a persistent provider.
/// </summary>
[GenerateSerializer]
public sealed class AgentState
{
    [Id(0)]
    public List<string> ConversationHistory { get; set; } = [];

    [Id(1)]
    public List<string> LearnedFacts { get; set; } = [];

    [Id(2)]
    public int TotalInteractions { get; set; }

    [Id(3)]
    public string Personality { get; set; } = "helpful";
}
