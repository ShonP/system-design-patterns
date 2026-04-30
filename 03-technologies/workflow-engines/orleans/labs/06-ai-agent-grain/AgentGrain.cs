using Orleans;
using Orleans.Runtime;

namespace AiAgentGrain;

/// <summary>
/// AI agent as an Orleans grain.
/// Each agent has its own memory-backed state and can collaborate with other agents.
/// This lab simulates LLM responses so it runs without external dependencies.
/// </summary>
public sealed class AgentGrain(
    [PersistentState("memory", "Default")]
    IPersistentState<AgentState> memory,
    IGrainFactory grainFactory)
    : Grain, IAgentGrain
{
    public async Task<AgentReply> Chat(string userMessage)
    {
        var agentId = this.GetPrimaryKeyString();

        memory.State.ConversationHistory.Add($"User: {userMessage}");
        memory.State.TotalInteractions++;

        var response = SimulateResponse(userMessage, agentId);

        if (userMessage.Contains("remember", StringComparison.OrdinalIgnoreCase))
        {
            var fact = userMessage.Replace("remember", "", StringComparison.OrdinalIgnoreCase).Trim();
            if (!string.IsNullOrWhiteSpace(fact))
            {
                memory.State.LearnedFacts.Add(fact);
            }
        }

        memory.State.ConversationHistory.Add($"Agent: {response}");
        await memory.WriteStateAsync();

        return new AgentReply
        {
            Text = response,
            AgentId = agentId,
            InteractionNumber = memory.State.TotalInteractions
        };
    }

    public Task<AgentState> GetMemory() => Task.FromResult(memory.State);

    public async Task SetPersonality(string personality)
    {
        memory.State.Personality = string.IsNullOrWhiteSpace(personality) ? "helpful" : personality;
        await memory.WriteStateAsync();
    }

    public async Task<AgentReply> AskOtherAgent(string otherAgentId, string question)
    {
        var otherAgent = grainFactory.GetGrain<IAgentGrain>(otherAgentId);
        var reply = await otherAgent.Chat($"[From agent {this.GetPrimaryKeyString()}] {question}");

        memory.State.ConversationHistory.Add(
            $"Asked agent '{otherAgentId}': {question} → Got: {reply.Text}");
        await memory.WriteStateAsync();

        return reply;
    }

    private string SimulateResponse(string input, string agentId)
    {
        var personality = memory.State.Personality;
        var factCount = memory.State.LearnedFacts.Count;

        return input.ToLowerInvariant() switch
        {
            var s when s.Contains("hello") =>
                $"[{personality}] Hi! I'm agent '{agentId}'. I know {factCount} facts.",
            var s when s.Contains("facts") =>
                $"[{personality}] I know: {string.Join(", ", memory.State.LearnedFacts)}",
            var s when s.Contains("history") =>
                $"[{personality}] We've had {memory.State.TotalInteractions} interactions.",
            _ =>
                $"[{personality}] I processed: '{input}' (interaction #{memory.State.TotalInteractions})"
        };
    }
}
