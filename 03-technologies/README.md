# Technologies

Labs that go deep on a specific technology: a database, a message broker,
a coordination service, a reference system from a canonical paper, or a
workflow engine.

## Databases

| Lab | What it covers |
|---|---|
| [`databases/postgres/`](./databases/postgres/) | MVCC, WAL, indexing, replication |
| [`databases/cassandra/`](./databases/cassandra/) | Wide-column, tunable consistency, gossip |
| [`databases/dynamodb/`](./databases/dynamodb/) | Partition keys, single-table design |
| [`databases/redis/`](./databases/redis/) | In-memory data structures, streams, pub/sub |
| [`databases/elasticsearch/`](./databases/elasticsearch/) | Inverted index, shards, aggregations |
| [`databases/time-series-databases/`](./databases/time-series-databases/) | Time-indexed data, retention, downsampling |
| [`databases/vector-databases/`](./databases/vector-databases/) | Embeddings, ANN indexes, hybrid search |

## Messaging

| Lab | What it covers |
|---|---|
| [`messaging/kafka/`](./messaging/kafka/) | Topics, partitions, delivery semantics |

## Coordination

| Lab | What it covers |
|---|---|
| [`coordination/zookeeper/`](./coordination/zookeeper/) | ZAB consensus, watches, leader election |

## Reference systems (canonical papers)

| Lab | Paper |
|---|---|
| [`reference-systems/gfs/`](./reference-systems/gfs/) | Google File System |
| [`reference-systems/hdfs/`](./reference-systems/hdfs/) | Hadoop Distributed File System |
| [`reference-systems/bigtable/`](./reference-systems/bigtable/) | Google Bigtable |
| [`reference-systems/dynamo/`](./reference-systems/dynamo/) | Amazon Dynamo |
| [`reference-systems/chubby/`](./reference-systems/chubby/) | Google Chubby lock service |
| [`reference-systems/s3/`](./reference-systems/s3/) | Amazon S3 |

## Workflow engines

| Lab | What it covers |
|---|---|
| [`workflow-engines/temporal/`](./workflow-engines/temporal/) | Durable workflows, activities, replay |

Every lab follows the same skeleton: `README.md`, `references/designgurus.md`,
`CHANGELOG.md`, plus the existing `notebooks/`, `docker-compose.yml` etc. where
present. See [`../docs/restructure-proposal.md`](../docs/restructure-proposal.md)
for the overall repo structure and [`../docs/content-map.md`](../docs/content-map.md)
for the lesson → lab mapping.
