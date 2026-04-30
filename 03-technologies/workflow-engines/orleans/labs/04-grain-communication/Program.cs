using GrainCommunication;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Orleans.Hosting;

using var host = new HostBuilder()
    .UseOrleans(builder =>
    {
        builder.UseLocalhostClustering();
        builder.AddMemoryGrainStorage("Default");
    })
    .Build();

await host.StartAsync();

var grainFactory = host.Services.GetRequiredService<IGrainFactory>();

var order1 = grainFactory.GetGrain<IOrderGrain>("order-001");
var result1 = await order1.PlaceOrder("Widget", 5, 9.99m);

var order2 = grainFactory.GetGrain<IOrderGrain>("order-002");
var result2 = await order2.PlaceOrder("Widget", 20, 9.99m);

var order3 = grainFactory.GetGrain<IOrderGrain>("order-003");
var result3 = await order3.PlaceOrder("Gadget", 2, 600m);

PrintResult("Successful order", result1);
PrintResult("Inventory failure", result2);
PrintResult("Payment failure with compensation", result3);

var inventory = grainFactory.GetGrain<IInventoryGrain>("warehouse");
Console.WriteLine();
Console.WriteLine($"Widget stock after processing: {await inventory.GetStock("Widget")}");
Console.WriteLine($"Gadget stock after processing: {await inventory.GetStock("Gadget")}");

await host.StopAsync();

static void PrintResult(string label, OrderResult result)
{
    Console.WriteLine();
    Console.WriteLine($"{label}:");
    Console.WriteLine($"- OrderId: {result.OrderId}");
    Console.WriteLine($"- Success: {result.Success}");
    Console.WriteLine($"- Message: {result.Message}");
    Console.WriteLine($"- AmountCharged: {result.AmountCharged:C}");
}