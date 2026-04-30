namespace GrainCommunication;

public sealed class PaymentGrain : Grain, IPaymentGrain
{
    public Task<bool> Charge(string orderId, decimal amount)
    {
        Console.WriteLine($"[Payment {this.GetPrimaryKeyString()}] Charging order {orderId} for {amount:C}.");

        if (amount > 1000)
        {
            Console.WriteLine($"[Payment {this.GetPrimaryKeyString()}] Charge declined for order {orderId}.");
            return Task.FromResult(false);
        }

        Console.WriteLine($"[Payment {this.GetPrimaryKeyString()}] Charge approved for order {orderId}.");
        return Task.FromResult(true);
    }

    public Task Refund(string orderId, decimal amount)
    {
        Console.WriteLine($"[Payment {this.GetPrimaryKeyString()}] Refunding order {orderId} for {amount:C}.");
        return Task.CompletedTask;
    }
}