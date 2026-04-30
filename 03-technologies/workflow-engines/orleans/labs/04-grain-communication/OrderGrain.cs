namespace GrainCommunication;

public sealed class OrderGrain : Grain, IOrderGrain
{
    public async Task<OrderResult> PlaceOrder(string product, int quantity, decimal price)
    {
        var orderId = this.GetPrimaryKeyString();
        var total = quantity * price;

        Console.WriteLine($"[Order {orderId}] Starting order for {quantity} x {product} at {price:C} each.");

        var inventory = GrainFactory.GetGrain<IInventoryGrain>("warehouse");
        var reserved = await inventory.Reserve(product, quantity);

        if (!reserved)
        {
            return new OrderResult
            {
                OrderId = orderId,
                Success = false,
                Message = "Inventory reservation failed.",
                AmountCharged = 0
            };
        }

        var payment = GrainFactory.GetGrain<IPaymentGrain>("payments");
        var charged = await payment.Charge(orderId, total);

        if (!charged)
        {
            await inventory.Release(product, quantity);

            return new OrderResult
            {
                OrderId = orderId,
                Success = false,
                Message = "Payment failed. Reserved stock was released.",
                AmountCharged = 0
            };
        }

        return new OrderResult
        {
            OrderId = orderId,
            Success = true,
            Message = "Order completed successfully.",
            AmountCharged = total
        };
    }
}