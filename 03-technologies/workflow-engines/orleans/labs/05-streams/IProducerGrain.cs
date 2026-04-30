namespace Streams;

[GenerateSerializer]
public sealed class SensorEvent
{
    [Id(0)] public string DeviceId { get; set; } = "";
    [Id(1)] public double Temperature { get; set; }
    [Id(2)] public DateTime Timestamp { get; set; }
}

public interface IProducerGrain : IGrainWithStringKey
{
    Task StartProducing(int count);
}