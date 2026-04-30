using Orleans.Runtime;
using Orleans.Streams;

namespace Streams;

public sealed class ProducerGrain : Grain, IProducerGrain
{
    public async Task StartProducing(int count)
    {
        var streamProvider = GetStreamProvider("events");
        var streamId = StreamId.Create("sensor-data", this.GetPrimaryKeyString());
        var stream = streamProvider.GetStream<SensorEvent>(streamId);

        for (var index = 1; index <= count; index++)
        {
            var sensorEvent = new SensorEvent
            {
                DeviceId = this.GetPrimaryKeyString(),
                Temperature = Math.Round(20 + (Random.Shared.NextDouble() * 20), 1),
                Timestamp = DateTime.UtcNow
            };

            Console.WriteLine(
                $"[Producer {sensorEvent.DeviceId}] Publishing event #{index} with temperature {sensorEvent.Temperature:F1}°C.");

            await stream.OnNextAsync(sensorEvent);
            await Task.Delay(TimeSpan.FromMilliseconds(500));
        }
    }
}