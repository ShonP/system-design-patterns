# Lab 04: Grain Communication — Building Processing Pipelines

📖 **What you'll learn**

- How one grain can call another grain
- How to model a simple processing pipeline with request/reply calls
- How to add compensation logic when a later step fails

## Architecture

```text
┌──────────────┐
│  Program.cs  │
└──────┬───────┘
       │ PlaceOrder(...)
       ▼
┌──────────────────┐
│    OrderGrain    │
│ orchestration    │
└──────┬───────────┘
       │ Reserve(product, qty)
       ▼
┌──────────────────┐
│  InventoryGrain  │
│ stock check      │
└──────┬───────────┘
       │ Charge(orderId, total)
       ▼
┌──────────────────┐
│   PaymentGrain   │
│ payment step     │
└──────────────────┘

Failure path:
OrderGrain -> InventoryGrain reserve succeeds -> PaymentGrain charge fails
           -> OrderGrain calls InventoryGrain.Release(...) to compensate
```

## How the pipeline works

1. `OrderGrain` receives the order request
2. It asks `InventoryGrain` to reserve stock
3. If stock exists, it asks `PaymentGrain` to charge the customer
4. If payment fails, it releases the reserved stock
5. The final result is returned to the caller

This is a small example of a **saga-style compensation pattern**.

## How to run

```bash
cd 03-technologies/workflow-engines/orleans/labs/04-grain-communication
dotnet run
```

## What the program demonstrates

- A successful order
- A failure caused by not enough inventory
- A failure caused by payment rejection for a large amount
- Compensation that puts stock back when payment fails

## Files in this lab

- `IOrderGrain.cs` / `OrderGrain.cs` — orchestration and final result
- `IInventoryGrain.cs` / `InventoryGrain.cs` — inventory reservation logic
- `IPaymentGrain.cs` / `PaymentGrain.cs` — payment simulation
- `Program.cs` — demo runner

## Key takeaway

Grain-to-grain calls let you break a workflow into small actors with clear responsibilities while still composing them into a larger business process.