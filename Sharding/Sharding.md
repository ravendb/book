
## Sharding

[Sharding]: #sharding

	TODO: This is meant to be chapter 8, after the distributed nature discussion, before ETL

We spent the previous couple of chapters exploring the distributed nature of RavenDB. Seeing how 
RavenDB cluster operates and how RavenDB replicate data among the diffrent nodes in the cluster.
Now is the time to discuss another layer of RavenDB's distributed behavior, sharding of data.

We talked about databases that spans multiple nodes. Such usage is meant for high availability 
scenario, allowing you to have multiple copies of the data in case a node goes down. RavenDB manages
the distribution of such databases automatically for you. Data replication also allows for load 
distribution using the `read behavior` option. However, this isn't suitable if the amount of data that 
you have to store exceed the amount that can reasonably be held in a single node. 

With RavenDB replication, all the nodes in the database groups will hold full copies of the data. This
is a great strategy that has a surprising long breathing room. The general recommendation is to start
looking at sharding when you data size is expected to be measured in multiple terabytes. We have had
multiple case studies of users running replicated database in the greater than 5 TB range with no issue,
for example. Those do tend to be in the upper end of database size, though.

Sharding, on the other hand, allow you to split the data you have between the different nodes in the 
cluster. For example, let's assume that we have a 100 user documents in our system. With replication, we'll have
three nodes (`A`,`B`,`C`) and each one of them will have 100 documents. With sharding, we'll split them 
evenly between the nodes, so node `A` will have 34 documents and node `B` and `C` will have 33 documents each.

Sharding is actually orthogonal to replication. You'll usually have both of them at the same time. Let's look
at Table XYZ.1, for an example of how a typical topology might look.


|    | A        | B        | C        | D        |
|----|----------|----------|----------|----------|
| $0 | 34 Users | 34 Users |          |          |
| $1 |          | 33 Users | 33 Users |          |
| $2 | 33 Users |          |          | 33 Users |

Table: Distributing 100 users among 4 nodes and 3 shards

In Table XYZ.1 you can see that we have four nodes (`A`,`B`,`C`,`D`) and three shards (`$0`,`$1`,`$2`). Each of the
shards contain some of the data and there are multiple copies of each shard's data. The reason we first covered 
replication in this book is simple, sharding is actually layered on top of replicating databases.

### How sharding works in RavenDB

Sharding allow us to have a unified view of data that has been partitioned (sharded) to multiple nodes. A sharded 
database is managed by RavenDB and appears to the outside world as if it was a (fairly large) single database. From
a client perspective, there is (almost) no change when working with a sharded database or an unsharded one.

As usual, it is easier to explain with a real world example. Let's consider a database for an ordering system, that 
holds documents such as `Customers` and `Orders`. We'll create a sharded database called `Orders` **TODO: exact steps
on how to do that**.

> **Sharding terminology**
>
> To properly understand the rest of this chapter, I want to clarify my intent when I'm using the following terms:
>
> * Sharded database - a virtual database that looks to the outside world as if it was a normal RavenDB database and
>   whose data is partition to multiple nodes in the cluster.
> * Shard (or Shard Id) - the *logical* association of a document to a particular location. A sharded database is 
>   composed of 1,048,576 shards. Many shards can reside in a single node.
> * Fragement - the *phyiscal* database that holds some of the documents in sharded database. A fragement holds all
>   the shards (and the documents contains in them) associated with it. A fragement is a database that may be replicated
>   to multiple nodes.

The `Orders` database has three fragments, which the following shard range allocation: 

* `Orders$0` - shards `0` - `349525`.
* `Orders$1` - shards `349525` - `699050`.
* `Orders$2` - shards `699050` - `1048576`.

Operations such as reads, writes or queries on the sharded `Orders` database will work normally as far as the client
is concerned. On the server side, RavenDB will direct the operations to the right fragement for the documents in 
question. You can control the number of shards and the shard allocations on database creation and during routine 
operations.

RavenDB handles the allocation of documents to shards by hashing the document id. For instance, here are a few examples
of document ids and shard assignments.

* `orders/1-A` - `151326`
* `customers/1-A` - `982173`
* `orders/2-A$customers/1-A` - `982173`

As you can see, `orders/1-A` is going to reside in fragement 0 (`Orders$0`). This is because its shard id is `151326`
and that range falls into `Orders$0`. On the other hand, both `customers/1-A` and `orders/2-A$customers/1-A` are placed
in `Orders$2`. This is not an accident. RavenDB allow you to specify the sharding namespace for a document by 
using the `$` suffix, we'll touch on why this is important later in this chapter.

> **The almight $**
>
> RavenDB gives a special meaning to the `$` character in sharded context. Database fragements are denoted with a 
> `$0` suffix to denote their number in the sharded database. Document ids with `$` in them are treated in a special
> manner and allow you to control what shard a document will reside on.
> 
> Saving a document with just the `$` suffix (such as `orders/3-A$`) will cause RavenDB to invoke the specified content
> based sharding function and assign it to the relevant shard. We'll discuss content based sharding later in 
> this chapter.

A query for documents on a sharded database will be routed to the relevant fragements automatically, and the results
aggregated from the various fragements automatically. Each fragement is effectively an independent database, which can
have its own replication factor and topology. This allow you to define a sharded database with replicas, enjoy the 
usual benefits of RavenDB's high availability, etc. 

Unlike an unsharded database, which can only be accessed from the nodes it resides on, a sharded database is accessible
from all nodes, including nodes that hold no fragements for this database. RavenDB will handle the routing of queries
and operations as needed.

### Using document ids for sharding

RavenDB uses the document id to decide what shard a particular document should reside on. This is computed using a hash
of the document id. The hash algorithm is: `xxhash64( docId.ToLower() ) % (1024 * 1024)`. This 
method gives us good distribution of the data between the shards, which is critical for the success of a sharded 
system.

RavenDB uses 1,048,576 fixed shards. This amount was chosen so with a uniform distribution of data between the shards,
we'll have roughly 1 MB of data per shard for each terrabyte of data in the sharded database. This results in shards
that are small enough to be moved relatively quickly if needed. Indeed, RavenDB will automatically balance the utilized
space between the fragements by moving shards between fragements as needed. You can also define the shard allocation 
map manually.

In a distributed database, locality matters, a *lot*. When you shard your data, you are explicitly partitioning it. But
while you might want to partition the overall data set, you still want to maintain locality for related documents. 
For example, if two documents strongly relate to one another, operations that touches both of them will be more 
efficient if they reside on the same shard.

> **Why is RavenDB using the document id for sharding?**
>
> RavenDB uses the document id to determine what is the shard id of a document. You can customize that using 
> conventions like so: `orders/2-A$customers/1-A`. The question is why is that required? There are several 
> important reasons for this decision.
> 
> The most important issue is that we need to shard by *something*. If we would *not* shard by document id,
> we run the risk of writing the same document id to different nodes. The issue has plagued other databases 
> and can lead to subtle (and hard to recover from) errors. RavenDB multi-master nature
#### todo
>
> RavenDB also offers several features around document ids (`include`, `load` and graph queries, to name a few)
> that greatly benefit from being able to go from a document id to a shard id. This allows the sharded database
> to perform several important optimizations along the way.
>
> RavenDB also offers a way to handle content based sharding, where the shard location is determined by the 
> content of this document. This is done the first time a document is stored in RavenDB (indicated by a `$` 
> suffix, such as `orders/1-A$`). RavenDB will use the user-defined sharding function to determine the shard
> that this document should go to and mutate the document id accordingly. In this case, if `orders/1-A` is 
### todo

The actual behavior is a bit more nuanced, however. Let's consider the following documents: `customers/6-A` (shard id: 
`16312`) and `orders/1-A` (shard id: `151326`). Using the sharp allocation map in Table XYZ.1, you can see that both
of them are going to reside in `Orders$0`. In this case, for all intents and purposes, they are going to be local to
one another. A query on `orders/1-A` that *includes* the `Customer` property will not have to do any extra network
roundtrips to complete, for example.

These two documents, however, reside on different shards. That means that RavenDB is free to re-assign them to 
different nodes if it so wishes. Documents that share the same shard id, on the other hand, are guaranteed to always
be placed togheter with one another.

> **Beware of the obese shard**
>
> Placing documents in the same shard can be extremely useful for ensuring locallity, but you also need to take
> into account the behavior of the system as a whole. Because RavenDB can't breakup a shard to individual pieces,
> it is unable to respond to a scenario where a shard grows too large.
>
> For example, in the `Orders` and `Customers` scenario, we have sharded the database according to the customer id.
> Each `Order` will reside in the same shard as its `Customer`. This works great if the number of orders of a customer
> is up to a certain limit. But if we have customers that may have hundreds or thousands of orders, that create very
> large shards that are RavenDB is not going to be able to break up. 
>
> In the context of the `Orders` database, it is unlikely to be too sever of a problem. At worst, we'll end up with a 
> single fragement holding a single (very large) shard and all the other fragements hosting all the other shards in 
> the system.
>
> In other systems, however, that can be a major issue. If you are sharding based on geographical location and the
> majority of your users are in New York City, you are going to end up with one very large and hot shard, which can
> reside on a single fragement.
>
> We'll discuss how to change your sharding strategy at runtime later in this chapter.

I mentioned that RavenDB uses the hash of the document id to generate the document id. 

### Content based sharding

{
  "ContentBasedSharding": {
    "Orders": {
      "Fields": [
        "Customer"
      ],
      "Prefix": 2,
      "Mutable": false
    },
    "ForRent": {
      "Q": "from ForRent where Address.ZipCode in ($a,$b, $c)",
      "Fields": [
        "Address.ZipCode"
      ],
      "Mutable": false
    },
    "Customers": {
      "Fields": [
        "Address.State",
        "Address.City"
      ],
      "Prefix": 2,
      "Mutable": true
    }
  }
}

### Transactions in a sharded database

