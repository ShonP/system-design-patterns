namespace GrainCommunication;

public interface IInventoryGrain : IGrainWithStringKey
{
    Task<bool> Reserve(string product, int quantity);
    Task Release(string product, int quantity);
    Task<int> GetStock(string product);
}