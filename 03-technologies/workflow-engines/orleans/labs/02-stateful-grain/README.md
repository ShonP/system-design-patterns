# Lab 02: Stateful Grain — Persistent State

📖 **What you'll learn**: How to persist grain state so it survives silo restarts. You'll use Orleans' `[PersistentState]` attribute with an in-memory provider (easily swappable to PostgreSQL, Redis, or Azure Storage).

## The Problem

In Lab 01, the HelloGrain's call count was stored in a plain field. When the grain deactivated or the silo restarted, that data was lost.

For real applications, you need **durable state** — a counter that remembers its value, a shopping cart that persists items, an IoT device that keeps its last reading.

## Architecture

```
Client ──▶ CounterGrain ──▶ IPersistentState<CounterState>
                                       │
                               ┌───────▼───────┐
                               │ Storage Provider│
                               │ (Memory / SQL / │
                               │  Redis / Azure) │
                               └────────────────┘
```

## How to Run

```bash
dotnet run
```

## Key Concepts

- **[GenerateSerializer]**: Orleans source-generates serializers for your state classes
- **[Id(n)]**: Tags each field for serialization — append new IDs for schema evolution
- **[PersistentState("name", "provider")]**: Injects persistent state into the grain
- **WriteStateAsync()**: Explicitly save state to the storage provider
- **ClearStateAsync()**: Delete the persisted state

## Switching Providers

Replace `AddMemoryGrainStorage` with a real provider:

```csharp
// PostgreSQL (requires Docker Compose)
silo.AddAdoNetGrainStorage("Default", options =>
{
    options.Invariant = "Npgsql";
    options.ConnectionString = "Host=localhost;Database=orleans;Username=orleans;Password=orleans_dev";
});
```

## What You Learned

1. State classes use **[GenerateSerializer]** and **[Id(n)]** for serialization
2. **IPersistentState<T>** is injected via constructor with **[PersistentState]**
3. State is read automatically on activation, written explicitly with **WriteStateAsync()**
4. Providers are **pluggable** — swap memory for PostgreSQL/Redis without changing grain code
