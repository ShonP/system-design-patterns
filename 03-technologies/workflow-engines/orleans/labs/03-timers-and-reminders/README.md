# Lab 03: Timers & Reminders — Scheduled Work in Grains

📖 **What you'll learn**

- How to use in-memory timers for high-frequency work inside a grain
- How to use Orleans reminders for scheduled work that can outlive a grain activation
- Why timers and reminders solve different scheduling problems

## Timer vs Reminder

| Feature | Timer | Reminder |
|---|---|---|
| Durability | In-memory only | Durable concept in Orleans |
| Frequency | Great for seconds or sub-minute work | Better for lower-frequency scheduled tasks |
| Survives grain deactivation | No | Yes |
| Survives silo restart | No | Yes with a durable reminder store |
| Best use case | Fast polling, heartbeats, short-lived background loops | Scheduled follow-up work, recurring jobs, wake-up signals |

> This lab uses `UseInMemoryReminderService()` so you can run everything locally with zero extra setup. In production, reminders are usually backed by durable storage.

## Architecture

```text
┌──────────────┐
│   Program    │
│ dotnet run   │
└──────┬───────┘
       │ grain call
       ▼
┌──────────────────────────────┐
│         MonitorGrain         │
│                              │
│  StartTimer()                │
│  ScheduleReminder()          │
│                              │
│  ┌────────────────────────┐  │
│  │ Grain Timer            │  │
│  │ due: 2s, every 3s      │  │
│  │ fast, in-memory only   │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ Orleans Reminder       │  │
│  │ due: 10s, every 1 min  │  │
│  │ scheduled wake-up      │  │
│  └────────────────────────┘  │
└──────────────────────────────┘
```

## Files in this lab

- `IMonitorGrain.cs` — grain contract
- `MonitorGrain.cs` — timer and reminder implementation
- `Program.cs` — local Orleans silo + demo runner

## How to run

```bash
cd 03-technologies/workflow-engines/orleans/labs/03-timers-and-reminders
dotnet run
```

## What to expect

- The grain activates when the program first calls it
- The timer starts after 2 seconds and ticks every 3 seconds
- The reminder is scheduled to fire after 10 seconds
- After 12 seconds, the program prints both counters

## Key takeaway

Use a **timer** when you want fast, in-memory recurring work tied to the current activation.
Use a **reminder** when you want Orleans to remember that scheduled work should happen again later.