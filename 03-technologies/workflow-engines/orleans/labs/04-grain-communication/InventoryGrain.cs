namespace GrainCommunication;

public sealed class InventoryGrain : Grain, IInventoryGrain
{
    private readonly Dictionary<string, int> _stock = new(StringComparer.OrdinalIgnoreCase)
    {
        ["Widget"] = 10,
        ["Gadget"] = 5
    };

    public Task<bool> Reserve(string product, int quantity)
    {
        var currentStock = _stock.GetValueOrDefault(product, 0);

        if (currentStock < quantity)
        {
            Console.WriteLine(
                $"[Inventory {this.GetPrimaryKeyString()}] Reserve failed for {product}. Requested {quantity}, available {currentStock}.");
            return Task.FromResult(false);
        }

        _stock[product] = currentStock - quantity;
        Console.WriteLine(
            $"[Inventory {this.GetPrimaryKeyString()}] Reserved {quantity} {product}. Remaining {_stock[product]}.");
        return Task.FromResult(true);
    }

    public Task Release(string product, int quantity)
    {
        _stock[product] = _stock.GetValueOrDefault(product, 0) + quantity;
        Console.WriteLine(
            $"[Inventory {this.GetPrimaryKeyString()}] Released {quantity} {product}. Available {_stock[product]}.");
        return Task.CompletedTask;
    }

    public Task<int> GetStock(string product)
    {
        var currentStock = _stock.GetValueOrDefault(product, 0);
        Console.WriteLine($"[Inventory {this.GetPrimaryKeyString()}] Stock for {product}: {currentStock}.");
        return Task.FromResult(currentStock);
    }
}