using Orleans.Serialization;
using System;

namespace StatefulGrain;

/// <summary>
/// State class for the CounterGrain.
/// [GenerateSerializer] tells Orleans to source-generate a serializer.
/// [Id(n)] tags each property for versioned serialization.
/// To evolve the schema, add new [Id] fields — never reuse old IDs.
/// </summary>
[GenerateSerializer]
public sealed class CounterState
{
    [Id(0)]
    public int Value { get; set; }

    [Id(1)]
    public DateTime LastModified { get; set; }

    [Id(2)]
    public int TotalOperations { get; set; }
}
