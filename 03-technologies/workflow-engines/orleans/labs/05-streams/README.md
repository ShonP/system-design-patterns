# Lab 05: Streams — Pub/Sub Messaging Between Grains

📖 **What you'll learn**

- How to configure an Orleans stream provider
- How one grain can publish events into a stream
- How another grain can subscribe and react to those events
- Why streams help decouple producers from consumers

## Architecture

```text
┌────────────────┐      publish SensorEvent       ┌──────────────────────┐
│ ProducerGrain  │ ─────────────────────────────▶ │  Stream: sensor-data │
│   sensor-1     │                                │  provider: events    │
└────────────────┘                                └──────────┬───────────┘
                                                            │ deliver event
                                                            ▼
                                                   ┌────────────────┐
                                                   │ ConsumerGrain  │
                                                   │   dashboard    │
                                                   └────────────────┘
```

## Flow

1. The silo starts with the in-memory stream provider named `events`
2. `ConsumerGrain` subscribes to the `sensor-data` stream for `sensor-1`
3. `ProducerGrain` publishes 5 `SensorEvent` messages
4. Orleans routes the events to the subscribed consumer
5. The consumer counts how many events it received

## How to run

```bash
cd 03-technologies/workflow-engines/orleans/labs/05-streams
dotnet run
```

## Files in this lab

- `IProducerGrain.cs` / `ProducerGrain.cs` — event producer
- `IConsumerGrain.cs` / `ConsumerGrain.cs` — stream subscriber and observer
- `Program.cs` — silo setup and demo runner

## Key takeaway

Streams let grains communicate through pub/sub instead of direct request/reply calls. That makes it easier to add new consumers without changing the producer.