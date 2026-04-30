# Lab 01: Hello Grain — Your First Virtual Actor

📖 **What you'll learn**: The fundamentals of Orleans — grain interfaces, grain implementations, silo hosting, and calling grains from a client.

## What is a Grain?

A **grain** is the fundamental building block in Orleans. Think of it as an object that:
- Has a **stable identity** (like a primary key)
- Processes **one request at a time** (no concurrency bugs)
- Is **activated on demand** (you don't create it — Orleans does)
- Is **location transparent** (it can run on any server)

## Architecture

```
Client (Program.cs) ──▶ Orleans Silo ──▶ HelloGrain
     "Call grain        "I'll find/       "Hello, World!
      hello-1"           activate it"     I am grain hello-1"
```

## How to Run

```bash
dotnet run
```

## Key Concepts

- **IGrainWithStringKey**: Grain identity is a string (could also be int, Guid, etc.)
- **Grain**: Base class for all grain implementations
- **UseLocalhostClustering()**: Single-node development mode
- **GetGrain<T>(id)**: Get a reference to a grain by type and ID — does NOT create it, just gets a reference

## What You Learned

1. Grains have **interfaces** (the contract) and **implementations** (the logic)
2. Silos are the **runtime** that hosts grain activations
3. Grains are **always addressable** by ID — you never "new" them up
4. Calling the same grain ID twice goes to the **same activation**
