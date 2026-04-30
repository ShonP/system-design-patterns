namespace GrainCommunication;

[GenerateSerializer]
public sealed class OrderResult
{
    [Id(0)] public string OrderId { get; set; } = "";
    [Id(1)] public bool Success { get; set; }
    [Id(2)] public string Message { get; set; } = "";
    [Id(3)] public decimal AmountCharged { get; set; }
}

public interface IOrderGrain : IGrainWithStringKey
{
    Task<OrderResult> PlaceOrder(string product, int quantity, decimal price);
}