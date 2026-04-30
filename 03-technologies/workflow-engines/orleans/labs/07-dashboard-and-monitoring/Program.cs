using Orleans;
using Orleans.Hosting;
using OrleansDashboard;

namespace DashboardAndMonitoring;

public static class Program
{
    public static async Task Main(string[] args)
    {
        Console.WriteLine("=== Lab 07: Dashboard & Monitoring ===\n");

        var builder = WebApplication.CreateBuilder(args);
        builder.WebHost.UseUrls("http://localhost:5000");

        builder.Host.UseOrleans(silo =>
        {
            silo.UseLocalhostClustering();
            silo.ConfigureApplicationParts(parts => parts.AddFromApplicationBaseDirectory());
            silo.AddMemoryGrainStorage("Default");
            silo.UseInMemoryReminderService();
            silo.UseDashboard(options =>
            {
                options.HostSelf = false;
            });
        });

        builder.Services.AddHealthChecks();

        var app = builder.Build();

        app.Map("/dashboard", dashboard => dashboard.UseOrleansDashboard());
        app.MapHealthChecks("/health");
        app.MapGet("/", () => "Orleans Dashboard Lab — visit /dashboard or POST /activate/{count}");

        app.MapPost("/activate/{count:int}", async (int count, IGrainFactory grains) =>
        {
            var tasks = Enumerable.Range(1, count)
                .Select(i => grains.GetGrain<IHelloGrain>($"grain-{i}").SayHello($"User-{i}"));

            var results = await Task.WhenAll(tasks);
            return Results.Ok(new { activated = count, sample = results.Take(3) });
        });

        Console.WriteLine("✅ Orleans silo + dashboard started!");
        Console.WriteLine("   Dashboard: http://localhost:5000/dashboard");
        Console.WriteLine("   Health:    http://localhost:5000/health");
        Console.WriteLine("   Activate:  curl -X POST http://localhost:5000/activate/10\n");

        await app.RunAsync();
    }
}

public interface IHelloGrain : IGrainWithStringKey
{
    Task<string> SayHello(string name);
}

public sealed class HelloGrain : Grain, IHelloGrain
{
    private int _calls;

    public Task<string> SayHello(string name)
    {
        _calls++;
        return Task.FromResult($"Hello {name} from {this.GetPrimaryKeyString()} (call #{_calls})");
    }
}
