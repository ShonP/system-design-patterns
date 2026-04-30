using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Orleans.Hosting;
using Streams;

using var host = new HostBuilder()
    .UseOrleans(builder =>
    {
        builder.UseLocalhostClustering();
        builder.AddMemoryGrainStorage("Default");
        builder.AddMemoryGrainStorage("PubSubStore");
        builder.AddMemoryStreams("events");
    })
    .Build();

await host.StartAsync();

var grainFactory = host.Services.GetRequiredService<IGrainFactory>();
var consumer = grainFactory.GetGrain<IConsumerGrain>("dashboard");
var producer = grainFactory.GetGrain<IProducerGrain>("sensor-1");

await consumer.Subscribe("sensor-1");
await producer.StartProducing(5);

Console.WriteLine("Waiting 5 seconds so the stream can deliver all events...");
await Task.Delay(TimeSpan.FromSeconds(5));

Console.WriteLine($"Consumer received {await consumer.GetReceivedCount()} events.");
Console.WriteLine();
Console.WriteLine("Key takeaways:");
Console.WriteLine("- Streams decouple producers from consumers.");
Console.WriteLine("- Subscriptions are managed by Orleans.");

await host.StopAsync();