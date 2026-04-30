namespace GrainCommunication;

public interface IPaymentGrain : IGrainWithStringKey
{
    Task<bool> Charge(string orderId, decimal amount);
    Task Refund(string orderId, decimal amount);
}