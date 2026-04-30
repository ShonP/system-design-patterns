namespace Streams;

public interface IConsumerGrain : IGrainWithStringKey
{
    Task Subscribe(string producerId);
    Task<int> GetReceivedCount();
}