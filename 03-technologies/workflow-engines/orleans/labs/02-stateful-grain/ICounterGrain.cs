using Orleans;
using System.Threading.Tasks;

namespace StatefulGrain;

public interface ICounterGrain : IGrainWithStringKey
{
    Task<int> Add(int amount);
    Task<int> Get();
    Task Reset();
    Task<CounterState> GetFullState();
}
