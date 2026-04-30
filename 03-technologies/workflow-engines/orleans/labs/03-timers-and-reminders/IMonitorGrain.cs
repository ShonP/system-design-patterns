namespace TimersAndReminders;

public interface IMonitorGrain : IGrainWithStringKey
{
    Task StartTimer();
    Task StopTimer();
    Task ScheduleReminder();
    Task<int> GetTimerTickCount();
    Task<int> GetReminderTickCount();
}