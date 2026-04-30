using Orleans;
using System.Threading.Tasks;

namespace HelloGrain;

/// <summary>
/// Grain interface — the contract that clients use to call the grain.
/// IGrainWithStringKey means the grain's identity is a string.
/// </summary>
public interface IHelloGrain : IGrainWithStringKey
{
    Task<string> SayHello(string name);
    Task<int> GetCallCount();
}
