using Orleans.Streams;

namespace Streams;

public sealed class ConsumerGrain : Grain, IConsumerGrain, IAsyncObserver<SensorEvent>
{
    private StreamSubscriptionHandle<SensorEvent>? _subscriptionHandle;
    private int _receivedCount;

    public async Task Subscribe(string producerId)
    {
        var streamProvider = GetStreamProvider("events");
        var streamId = StreamId.Create("sensor-data", producerId);
        var stream = streamProvider.GetStream<SensorEvent>(streamId);

        if (_subscriptionHandle is not null)
        {
            await _subscriptionHandle.UnsubscribeAsync();
        }

        _subscriptionHandle = await stream.SubscribeAsync(this);
        Console.WriteLine($"[Consumer {this.GetPrimaryKeyString()}] Subscribed to {producerId}.");
    }

    public Task<int> GetReceivedCount() => Task.FromResult(_receivedCount);

    public Task OnNextAsync(SensorEvent item, StreamSequenceToken? token = null)
    {
        _receivedCount++;
        Console.WriteLine(
            $"[Consumer {this.GetPrimaryKeyString()}] Event #{_receivedCount} from {item.DeviceId}: {item.Temperature:F1}°C at {item.Timestamp:HH:mm:ss}." );
        return Task.CompletedTask;
    }

    public Task OnCompletedAsync()
    {
        Console.WriteLine($"[Consumer {this.GetPrimaryKeyString()}] Stream completed.");
        return Task.CompletedTask;
    }

    public Task OnErrorAsync(Exception ex)
    {
        Console.WriteLine($"[Consumer {this.GetPrimaryKeyString()}] Stream error: {ex.Message}");
        return Task.CompletedTask;
    }
}