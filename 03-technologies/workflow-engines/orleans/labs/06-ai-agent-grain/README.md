# Lab 06: AI Agent Grain — Stateful Agents with Durable Memory

📖 **What you'll learn**: How to model AI agents as Orleans grains. Each agent has memory-backed state, can execute tools through grain methods, and can communicate with other agents using grain-to-grain calls.

## AI Concepts Mapped to Orleans

| AI Concept | Orleans Mapping |
|---|---|
| Agent identity | Grain ID |
| Durable memory | Persistent grain state |
| Tool execution | Grain method calls |
| Conversation history | State list |
| Agent-to-agent | Grain-to-grain calls |

## Architecture

```text
User ──▶ AgentGrain ──▶ (durable state + tool calls)
```

Each agent is just a grain with its own ID. Orleans gives every agent isolated state, single-threaded request processing, and easy agent-to-agent messaging.

## What This Lab Simulates

This lab **simulates LLM responses**. There is no API key, model host, or external service required.

The grain code is written against Orleans persistent state APIs, so the same agent logic can later be connected to a real durable provider such as PostgreSQL, Redis, or Azure Storage.

## How to Run

```bash
dotnet run
```

## Suggested Experiments

1. Change an agent personality and compare its replies.
2. Teach an agent a few facts using messages with the word `remember`.
3. Create more agent IDs and have them ask each other questions.
4. Swap the storage provider to a durable backend and observe how the same grain code stays unchanged.

## What You Learned

- An Orleans grain is a natural fit for an AI agent.
- Agent memory maps well to persistent grain state.
- Tool execution can be modeled as normal grain methods.
- Agent-to-agent collaboration is just a grain-to-grain call.
