using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Orleans.Hosting;
using TimersAndReminders;

using var host = new HostBuilder()
    .UseOrleans(builder =>
    {
        builder.UseLocalhostClustering();
        builder.AddMemoryGrainStorage("Default");
        builder.UseInMemoryReminderService();
    })
    .Build();

await host.StartAsync();

var grainFactory = host.Services.GetRequiredService<IGrainFactory>();
var monitor = grainFactory.GetGrain<IMonitorGrain>("server-room");

await monitor.StartTimer();
await monitor.ScheduleReminder();

Console.WriteLine("Waiting 12 seconds so you can observe timer and reminder activity...");
await Task.Delay(TimeSpan.FromSeconds(12));

Console.WriteLine($"Timer ticks observed: {await monitor.GetTimerTickCount()}");
Console.WriteLine($"Reminder ticks observed: {await monitor.GetReminderTickCount()}");

await monitor.StopTimer();

Console.WriteLine();
Console.WriteLine("Key takeaways:");
Console.WriteLine("- Timers are in-memory and fast.");
Console.WriteLine("- Reminders are durable and survive restarts when backed by persistent storage.");
Console.WriteLine("- This lab uses the in-memory reminder service so everything runs locally.");

await host.StopAsync();