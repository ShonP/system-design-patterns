using Orleans;

namespace AiAgentGrain;

[GenerateSerializer]
public sealed class AgentReply
{
    [Id(0)] public string Text { get; set; } = "";
    [Id(1)] public string AgentId { get; set; } = "";
    [Id(2)] public int InteractionNumber { get; set; }
}

public interface IAgentGrain : IGrainWithStringKey
{
    Task<AgentReply> Chat(string userMessage);
    Task<AgentState> GetMemory();
    Task SetPersonality(string personality);
    Task<AgentReply> AskOtherAgent(string otherAgentId, string question);
}
