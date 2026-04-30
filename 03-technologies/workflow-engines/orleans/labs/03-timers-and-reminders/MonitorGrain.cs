using Orleans.Runtime;

namespace TimersAndReminders;

public sealed class MonitorGrain : Grain, IMonitorGrain, IRemindable
{
    private const string ReminderName = "scheduled-check";
    private IGrainTimer? _timer;
    private int _timerTicks;
    private int _reminderTicks;

    public override Task OnActivateAsync(CancellationToken cancellationToken)
    {
        Console.WriteLine($"[Monitor {this.GetPrimaryKeyString()}] Activated at {DateTime.UtcNow:O}");
        return Task.CompletedTask;
    }

    public Task StartTimer()
    {
        if (_timer is not null)
        {
            Console.WriteLine($"[Monitor {this.GetPrimaryKeyString()}] Timer already running.");
            return Task.CompletedTask;
        }

        // Timers are fast and live only inside the current grain activation.
        _timer = this.RegisterGrainTimer(
            static (grain, cancellationToken) => grain.OnTimerTick(cancellationToken),
            this,
            new GrainTimerCreationOptions
            {
                DueTime = TimeSpan.FromSeconds(2),
                Period = TimeSpan.FromSeconds(3),
                KeepAlive = true
            });

        Console.WriteLine($"[Monitor {this.GetPrimaryKeyString()}] Timer started.");
        return Task.CompletedTask;
    }

    public Task StopTimer()
    {
        _timer?.Dispose();
        _timer = null;
        Console.WriteLine($"[Monitor {this.GetPrimaryKeyString()}] Timer stopped.");
        return Task.CompletedTask;
    }

    public async Task ScheduleReminder()
    {
        // Reminders are Orleans-managed scheduled messages that can outlive this activation.
        await this.RegisterOrUpdateReminder(
            ReminderName,
            TimeSpan.FromSeconds(10),
            TimeSpan.FromMinutes(1));

        Console.WriteLine($"[Monitor {this.GetPrimaryKeyString()}] Reminder scheduled.");
    }

    public Task<int> GetTimerTickCount() => Task.FromResult(_timerTicks);

    public Task<int> GetReminderTickCount() => Task.FromResult(_reminderTicks);

    public Task ReceiveReminder(string reminderName, TickStatus status)
    {
        if (reminderName != ReminderName)
        {
            return Task.CompletedTask;
        }

        _reminderTicks++;
        Console.WriteLine(
            $"[Monitor {this.GetPrimaryKeyString()}] Reminder tick #{_reminderTicks} at {DateTime.UtcNow:O}");

        return Task.CompletedTask;
    }

    private Task OnTimerTick(CancellationToken cancellationToken)
    {
        _timerTicks++;
        Console.WriteLine($"[Monitor {this.GetPrimaryKeyString()}] Timer tick #{_timerTicks} at {DateTime.UtcNow:O}");
        return Task.CompletedTask;
    }
}