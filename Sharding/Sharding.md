
## Sharding

[Sharding]: #sharding

***TODO: This is meant to be chapter 9, after the distributed nature discussion, before ETL***

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
holds documents such as `Customers` and `Orders`. We'll create a sharded database called `Orders` 

**TODO: exact steps on how to do that**

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

> **Beware of the obese shard**
>
> Placing documents in the same shard can be extremely useful for ensuring locallity, but you also need to take
> into account the behavior of the system as a whole. Because RavenDB can't breakup a shard to individual pieces,
> it is unable to respond to a scenario where a shard grows too large.
>
> For example, in the `Orders` and `Customers` scenario, we have sharded the database according to the customer id.
> Each `Order` will reside in the same shard as its `Customer`. This works great if the number of orders of a customer
> is up to a certain limit. But if we have customers that may have hundreds or thousands of orders, that create very
> large shards that RavenDB is not going to be able to break up. 
>
> In the context of the `Orders` database, it is unlikely to be too sever of a problem. At worst, we'll end up with a 
> single fragement holding a single (very large) shard and all the other fragements hosting all the other shards in 
> the system.
>
> In other systems, however, that can be a major issue. If you are sharding based on geographical location and the
> majority of your users are in New York City, you are going to end up with one very large and hot shard, with no
> way to split the load among the various nodes.
>
> By default, RavenDB will assign documents to shards on a fair basis, so you generally don't need to think about this
> unless you define you own sharding policy. We'll discuss this in more details later in this chapter.

In a distributed database, locality matters, a *lot*. When you shard your data, you are explicitly partitioning it. But
while you might want to partition the overall data set, you still want to maintain locality for related documents. 
For example, if two documents strongly relate to one another, operations that touches both of them will be more 
efficient if they reside on the same shard.

The actual behavior is a bit more nuanced, however. Let's consider the following documents: `customers/6-A` (shard id: 
`16312`) and `orders/1-A` (shard id: `151326`). Using the sharp allocation map in Table XYZ.1, you can see that both
of them are going to reside in `Orders$0`. In this case, for all intents and purposes, they are going to be local to
one another. A query on `orders/1-A` that *includes* the `Customer` property will not have to do any extra network
roundtrips to complete, for example.

> **Why is RavenDB using the document id for sharding?**
>
> RavenDB uses the document id to determine what is the shard id of a document. You can customize that using 
> conventions like so: `orders/2-A$customers/1-A`. The question is why is that required? There are several 
> important reasons for this decision.
> 
> The most important issue is that we need to shard by *something*. If we would *not* shard by document id,
> we run the risk of writing the same document id to different nodes. The issue has plagued other databases 
> and can lead to subtle (and hard to recover from) errors. RavenDB multi-master nature means that it is 
> entirely possible for two requests to be processed independently by two nodes in the cluster at the same
> time, with no coordination required.
>
> The fact that we can rely only on the document id to find the relevant shard means that we don't have to
> worry about duplicate ids in different shards or fragile system setups. RavenDB's sharding design is a 
> natural extension of the rest of its distibuted nature. 
>
> RavenDB also offers several features around document ids (`include`, `load` and graph queries, to name a few)
> that greatly benefit from being able to go from a document id to a shard id. This allows the sharded database
> to perform several important optimizations along the way.
>
> RavenDB also offers a way to handle content based sharding, where the shard location is determined by the 
> content of this document. This is done the first time a document is stored in RavenDB (indicated by a `$` 
> suffix, such as `orders/1-A$`). RavenDB will use the user-defined content based sharding to determine which
> shard this document should go to. 
>
> What is important to understasnd is that the client supplied id of `orders/1-A$` will be mutated by the server
> to create a new id that belong to a specific shard. Assuming this order belongs to `customers/1-A`, the final
> document id will be `orders/1-A$@982173`.
>
> We'll cover content based sharding and the generated ids in depth later in this chapter. 

These two documents, however, reside on different shards. That means that RavenDB is free to re-assign them to 
different nodes if it so wishes. Documents that share the same shard id, on the other hand, are guaranteed to always
be placed togheter with one another.

I mentioned that RavenDB uses the hash of the document id to generate the document id. But that isn't actually the full
story. RavenDB used the following conventions for finding the shard based on the document id:

* If the document id has a `$@` followed by a number between 0 and 1048576, the shard id will be that number. This 
  feature is used if we want to static assignment of a document to a particular shard. The `$@<num>` feature is
  mostly used in content based sharding.
* If the document is has a `$` in it, take the string from the last `$` and use that as the value to hash to get the
  shard id. In other wordss, `orders/1-A$customers/1-A` will use `hash("customers/1-A")` to find the shard for this
  document.
* Otherwise, hash the entire document id to find the shard id.

It is important to understand that as far as RavenDB is concerned, the following are *all* document ids:

* `orders/1-A$@982173`
* `customers/1-A`
* `orders/1-A$customers/1-A`

The *entire* value (including the parts past the `$`) is the document id. The fact that the sharding infrastructure
assigns meaning to the `$` value isn't reelevant for any other aspect of RavenDB. It is legal to have both:
`orders/1-A$@982173` and `orders/1-A$customers/1-A`. Note that in this case, both reside in the same shard, and that
is fine. They have different document ids.

When you store references between documents in your model, you'll use the the document id (include the portion after the
`$`). This make it possible to use features such as `include` or `load` efficiently. If you are on the same shard, the 
operation is guranteed to be local. If you are on the same fragement, the operation will be local (but there is no 
guarantee that the value will remain on the fragement). If the value is on a different fragement, the sharding 
infrastructure in RavenDB will fetch it from the relevant node for you.

### Content based sharding

Using document ids for sharding gives you a simple model that is easy to follow. The client can distribute the 
documents fairly among the shards (by doing nothing, and letting RavenDB assign shards automatically). If you want
more control, you can use the `$` suffix option to control which shard a document should reside on.

The documents `customers/1-A` and `orders/1-A$customers/1-A` will reside on the same shard, as we have already seen.
In this section, I want to focus on what this *means*. The advantage of having related data reside in the same shard
is obvious. Data locality can improve performance significantly. 

The question is how you achieve that goal without also getting into problematic issues with overly large shards. Another
aspect of sharding and controling where a document would go is the issue of query optimization.  

> **Pre-requisite: RavenDB queries and RQL**
>
> In order to fully understand sharding, I'm going to go over RavenDB sharding behavior with queries. We have touched 
> this a little bit in Chapter 4, but the full disucssion of queries in RavenDB is in next part of the book. 
>
> I tried to discuss using simple queries that should be understandable without any background, but if you have any
> questions about how RavenDB process queries normally, you might want to skim through Part III and then come back 
> here.
>
> Like most other aspects of sharding in RavenDB, the query behavior is a natural extension of how RavenDB handle 
> queries in the unsharded case.

Let's consider the following query: `from Orders where id() = 'orders/1-A'`. When you send such a query to a sharded
database, RavenDB can easily figure out that this index can only reside in `Orders$0` (the shard id is `151326` and that
is mapped to `$0`). The sharding infrastructure will forward the query to that particular fragement only.

On the other hand, if we are querying on the *content* of documents, RavenDB has far fewer options. Consider this query, 
instead: `from Orders where Customer = 'customers/1-A'`. Even though we have been careful to create all orders for
a customer with the `$` suffix (the document ids are: `orders/1-A$customers/1-A`, `orders/2-A$customers/1-A`), RavenDB
has no way to understand that. In order to process this query, RavenDB will have to talk to all the fragements in the 
database.

This is where content based sharding come into play. We can *teach* RavenDB that a particular property (or properties)
should be accounted for during queries. Take a look at Listing XYZ.1, where we give RavenDB enough information about 
our sharding configuration to understand how it can better query the data.

```{caption="Database configuration for content based sharding" .json}
"Sharding": {
  "ByContent": {
    "Orders": {
      "Fields": [
        "Customer"
      ]
    }
}
```

In Listing XYZ.1, you can see that we provide a `ByContent` configuration for sharding. In particular, we tell RavenDB
that for the `Orders` collection, we'll shard the data by the `Customer` field. This hubmle configuration has quite a few
interesting results.

The most obvious one is that RavenDB is able to optimize this query: `from Orders where Customer = 'customers/1-A'`. Instead
of having to query all nodes in the database, RavenDB figures out what is the fragement that owns this query and uses that 
alone.

> **Smart content based sharding**
>
> When using content based sharding, for the most parts, we are going to use the hash of the value you marked. However,
> there are a few ways that you can modify this behavior. For example, if you want to shard by zip code, you can use:
> `"Fields": ["Address.ZipCode"]`, which will use the hash of the zip code, or: `"Fields": ["numeric(Address.ZipCode)"]`
> which will use the *numeric value* of the zip code, instead. In this case, the specific field *must* be a numeric value
> and the value will be modulus with 1048576 to get the find shard id.
>
> When using dates, you can use the `ticks` function, like so: `"Fields": ["ticks(OrderedAt)"]`, which accepts a date time
> value and modulus the `Ticks` of the date time value with 1048576 to find the shard id. This is useful if you want to get
> time based sharding (but beware of creating hot spots).
>
> An interesting case of content based sharding is uding the `id()` function, like so: `"Fields": ["id()"]`. This is 
> identical to *not* having any content based sharding and is mostly used while you are migrating between 
> sharading strategies.
>
> You can find the full listing of available functions for content based shards in the online documentation.

There are other aspects for this configuration, however. We talked earlier about saving documents with an id that has `$` in
the end, such as `orders/1-A$`. Without a content based sharding configuration, such an operation would result in an error. 
Document ids cannot end with `$` when using a sharded database. 

*With* such a configuration, RavenDB will hash the content of the `Customer` property and update the final document id. In 
this case, we'll have `orders/1-A$@982173`. The `$@<num>` allow us to refer to a particular shard directly, without needing
to hash the value. This process occurs only on the very first time that you save a document (indicated by the fact 
that your document id ends with `$`). The document id will change to its final form and RavenDB will return the new id to
the client. From the client side, you'll get the final document id only after the `SaveChanges()` call has been 
successfully processed and returned.

Sometimes, you don't want to wait for the `SaveChanges()` to return. For example, you may want to modify multiple documents
in a single database transaction. For example, let's say that we want to write two documents an `Order` (which need to 
reside in the same shard as its `Customer`) and a `ShippingManifest` that reference the order but may live on another
shard entirely. 

If we would save the `Order` document with the id `orders/1-A$`, the final id is generated on the server side. This means 
that in order to save the `ShippingManifest`, we would need to first save the `Order`, get its new id and only then save
the `ShippingManifest`. 

This is why you can also define the shard that will be used using `orders/1-A$customers/1-A`. That allows you to generate
the value completely on the client, and use a single transaction to write the `Order` and the `ShippingManifest`. The `$`
suffix make it easy to scope documents to their parent. You can also compute the hash of the shard directly, using: 
`xxhash64( docId.ToLower() ) % (1024 * 1024)` and save the document as `orders/1-A$@982173` directly from the client.
Sometimes it is easier to use the actual value, though. This is especially the case if you are working with the data
directly, though the Studio.

#### Modifying fields with content based sharding

I mentioned that content based sharding configuration is applied when we save a new document that ends with `$`. At that 
point, we look at the relevant fields and generate the right shard value. We can also use this knowledge during queries,
to optimize what fragements we need to look at.

An interesting question, arises, though. What happens if we update the `orders/1-A$@982173` document so its `Customer` 
will be `customers/2-B`? The short answer is that RavenDB will raise an error in this case. With a content based 
sharding in place, RavenDB will ensure that the shard of the document according to the configuration is fixed. 
The shard id for `custoemrs/2-B` is `2423`, because it doesn't match the current shard based on the document id, and 
we have content based sharding, RavenDB will reject his as an invalid write.

Note that if we were to replace the `Customer` field in the document with `customers/741135-C`, on the other hand, 
that *would* work. This is because the shard id for `customers/741135-C` is also `982173`, so it is a valid value. 
More importantly, this is going to be the case even if the full document id was `orders/1-A$customers/1-A`. RavenDB
validates only that the value of the content is the same shard, nothing else.

> **What kind of sharding strategy is preferred?**
>
> I'm spending quite a lot of time describing how you can control what shard a document reside on, how RavenDB can
> optimize queries and operations based on that, etc. I'm doing this primarily because this is something that you 
> *might* need for specific scenarios. 
>
> If you can get away with it, having *no* sharding strategy is probably the best. It means that RavenDB will fairly
> distribute the data between the nodes in the cluster. Indeed, if you just use the RavenDB API to work with a 
> sharded database, that is exactly what will happen. The reason for having a sharding strategy is when you can
> significantly benefit it.
>
> For example, in a `Customers` and `Orders` scenario, if most or all of the operations will always be in the scope
> of a particular `Customer`, it may make sense to shard based on the customer id. However, if you are doing a lot
> of operations across customers, there is no benefit to this kind of sharding strategy.
>
> RavenDB allows you to alter the sharding behavior at runtime, without costly migrations, so it is well worth
> remembering that it is hard to predit how the system will actually behave. In many cases, it is easier to modify
> the system after you have actual operational experience with it.

The reason RavenDB performs this validation is to ensure that queries on those values can be properly optimized. If 
we *didn't* do this validation, you might end up with an order on shard `982173` whose `Customer` field is set to
`customers/2-B`. At this point, a query for: `from Orders where Customer = 'customers/2-B'` will be routed to a 
different fragement and will find no results. In order to prevent this, we ensure that the value that you are 
using for content based sharding match the actual shard of the document.

That said, there are cases where you'll want to mutate the values you are sharding on. It is common for other sharded 
database solutions to make the sharding strategy the first thing you'll define and set it in stone. 
Making such immutable choices for your system early on usually leads to needing to change the system down the line, 
once you have weathered production and seen how the system is actually being used.
At that stage, you typically need to do a full migration (which is *costly*, complex operation, has high resource usage
and takes quite a bit of time). 

In contrast, RavenDB's sharding strategy is built to be evolved on the fly. Let's consider the case of sharding 
`Customers`. So far we assumed that we'll be spreading the customers across the shards evenly, but let's assume that
we have had a content based sharding configuration as shown in Listing XYZ.2. The configuration shown here is probably
a bad one, mind. We're intentionally setting things up badly to see how we can recover from operational mistakes.

```{caption="Content sharding using multiple fields for Customers (bad strategy)" .json}
"Sharding": {
  "ByContent": {
    "Customers": {
      "Fields": [
        "Address.State",
        "Address.City"
      ]
    }
}
```

The configuration in Listing XYZ.2 shows how we can shard on multiple fields. Internally, we handle this by concatanting
all the field values and hashing the result. This configuration will put all users in the same `State` and `City` pairs
in the same shard. Just for the record, this is very likely a bad sharding strategy. If you have a lot of users from a 
particular location, that is going to create a single big shard.

> **Query optimization with multiple fields using content based sharding**
>
> RavenDB *can* optimize queries on collections with multiple fields using content based sharding. However, it needs
> to have *all* the fields present in the query in order to do so (the order in which they appear is no relevant).
> 
> This is because RavenDB need to hash the all the fields for content based sharding in order to find the relevant shard
> that apply for a particular query. In the case of the configuration in Listing XYZ.2, it means the following queries
> on `Customers` will be able to take advantage of this optimization: 
> 
> * Queries by id (which always know what shard to use).
> * Queries that include *both* `Address.City` and `Address.State`. 
>
> Queries that do not include these details will be processed normally and sent to all the possible fragements for answers.

But this configuration is also bad for another reason, it assumes that a customer can never change their 
`Address.State` or `Address.City` fields. To be rather more exact, it means that a customer can only move to a 
`Address.State`/`Address.City` pair that has the same shard id as the previous one. I think you'll agree that 
it is unreasonable from our application to expect users to take the internal sharding architecture of your
application when they decide where they should move.

Luckily, there is a solution for that. Let's look at Listing XYZ.3, where we have made a small but significant change to
the content based configuration. We have added the `"Mutable": true` option to the configuration.

```{caption="Allowing mutation of the fields forming the content based sharding" .json}
"Sharding": {
  "ByContent": {
    "Customers": {
      "Mutable": true,
      "Fields": [
        "Address.State",
        "Address.City"
      ]
    }
}
```

The configuration in Listing XYZ.3 shows a mutable content based sharding. This is an interesting concept. It tells RavenDB
that if there are documents saved with ids that ends with `$`, it should generate the full document id as usual. However,
because these fields are mutable, RavenDB also:

* Allow the user to modify these fields, regardless of what shard the content *should* reside on. 
* Content based sharding it applied only on the first save of the document, never on updates.
* RavenDB cannot rely on the value of these fields for the purpose of routing queries and has to disable sharded 
  query optimizations.

You can start out with having a content based sharding without the `Mutable` flag, in which case RavenDB will enforce the
rules and optimize the queries. You can then set the `Mutable` flag and allow changing the sharded values. The purpose of
this feature is to allow you to do such changes *safely*. You lose on the sharded query optimizations, admittedly, but you
don't have to rebuild your entire database.

> **Going from mutable to immutable content based sharding**
>
> RAvenDB *allows* you to have `"Mutable": true` and update this to `false`. However, it does **not** validate that the
> underlying documents have content matching their allocated shard. This is done so you'll be able to go from immutable
> to mutable (losing the benefit of optimized queries), modify your data at your leisure and then go back to immutable.
> In such cases, it is the *operator responsability* to ensure that the data match RavenDB's expectations. 

Changing the shard strategy is an online operation that can be done at any time. This make it an operationally lightweight
option, and much more feasible as you evolve your data strategy. It is expected that you'll have several such evolutions as
your data and load grows. Obviously, if you can set things right from the get go, that is ideal, but I have found that 
expecting perfection from the start is unrealistic. RavenDB's sharding is meant to be deployed in an imperfect world, and has
been designed explicitly to allow these kind of changes over time.

#### Changing the fields for content based sharding

In the same way you can change the `Mutable` field, you are also able to change other aspects of content based sharding.
For example, you may have started sharding `Customers` by state and city, only to realize that this is a bad idea. You
can change that to sharding by zip code, instead. The process itself is straightforward, and mostly depends if you want
to try to get optimized queries or not. 

* Set `Mutable` to `true` - RavenDB now knows that it can't rely on content based sharding for the collection.
* Modify the fields that you want to use for content based sharding - RavenDB will use this for all new documents.

*Existing* documents, on the other hand, are unmodified and may reside in different shard according to the new sharding
strategy. That is why we have had to set `Mutable` to `true`, after all. 

At this point, you can leave the system as is, the new sharding strategy will apply for new documents and start adjusting 
the weight of different shards. In many cases, the reason you want to change the sharding strategy is that your old strategy
created hot spots. Just changing the strategy (maybe by using the `id()` option) is usually enough to remove the hotspots
and put you in a better place.
At this point, queries and operations are going to proceed normally and this operation has no downtime requirement. You lose
the ability to optmize queries by the shard function (since this isn't how the database is currently organized). To get this
back, you can start a migration process, in which you'll locate the documents that need to move and re-write them. 
Remember that you'll need to create *new* documents, with different ids, to go to the new shards. 
This migration process is also something that can happen on an incremental manner. When you are done updating the database,
you can set `Mutable` back to `false` and RavenDB will take into account the content of your queries when it is answering 
them.

*Important:* RavenDB does *not* validate that the existing documents match the expected sharding strategy. It will validate
new or updated documents, but existing ones are not inspected. This means that it is the responsability of the operators
to make sure that after migration, the sharding strategy applies. If in doubt, avoid setting `Mutable` to `false`.

#### Using a fuzzy sharding strategy

I spent a considerable amount of time talking about how you can ensure that two documents reside in the same shard. RavenDB
*gurantees* that two documents that are on the same shard will always be on the same fragement. In other words, we ensure
high degree of locality in this scenario. 

That said, let's take an example of a cluster with 25 nodes in it. A sharded database with a replication factor of 2 means 
that we have 13 fragements overall. However, RavenDB has `1048576` shards that are assigned to these 13 fragements, so each
one of those fragements hosts about 80 thousand shards. If we force documents to reside on the same shard, we may end up
having obese shards. But for the most part, if we just want them to reside on the same fragement, we can take another tack.

RavenDB generally assigns shard *ranges* to a fragement, not individual shards. This means that shards that are near one 
another are likely to be allocated on the same fragement. RavenDB allows you to define content base sharding that isn't 
going to match exactly. Instead, we just need a rough match. Let's look at Listing XYZ.4, for such an example.

```{caption="Specifying fuzzy content based sharding" .json}
"Sharding": {
  "ByContent": {
    "Orders": {
      "Range": 1000,
      "Fields": [
        "Customer"
      ]
    }
}
```

Listing XYZ.4 uses a new option, `Range`, and set it to `1000`. I'm going to show first by example, then explain in more
details. We'll go back to our old friend, `orders/1-A$` which belongs to `customers/1-A`. 
Here are a few important numbers

* `customers/1-A` assigned to shard `982173`. 
* `orders/1-A` assigned to shard `151326`.

We specified a `Range` of `100`, so the shard id that RavenDB will generate for this document will be `982326`. In other 
words, the final shard for the document has to fall within a range of a thousand shards from `982173`. 
In this case, RavenDB simply uses the first three digits from the content based sharding and the rest from the
document id we already got. If the `Range` was `10000` then the output would be `981326`, and so on. 

The idea behind the `Range` is that we no longer *tell* RavenDB what shard this document should be. We... suggest.
And we give eanough leeway for RavenDB to manage it on its own. 

In the case of `Customers` and `Orders`, assuming a `Range` of `1000`, each customer is going to have its orders located
on shards that are within 1,000 shards from the customer's shard. Because RavenDB allocate ranges to fragements, it also
means that there is a high likelihood (but no *gurantee*) that they will reside on the same fragement and have all the 
locality benefits that you would expect.

RavenDB is able to use this information in queries as well. Consider the following query: 
`from Orders where Customer = 'customers/1-A'`. RavenDB will hash the value, resulting in `982173`, it is then going to
send the query to all the fragements that contains shards in the range of `982000 .. 982999`. 

In most cases, this is going to be just one fragement, but it is also possible that this range is allocated to two fragements.
Given that in our scenario (13 fragements, each with about 80,000 shards), it is unlikely that this range will span more than
two fragements. 

> **Increasing the Range property is a Safe operation**
>
> Unlike most content based sharding changes, increasing the value of the `Range` property is a Safe operation to do.
> Let's assume that you started out with the shard configuration shown in Listing XYZ.1. Over time, you realized that
> some of your customers have a *lot* of orders (congrats, what a great problem to have). You are running into issues
> with an obese shard. 
>
> You can update your sharding configuration to the one shown in Listing XYZ.4 *without* having to set `Mutable` to `true`.
> This is because Listing XYZ.4 is a superset of Listing XYZ.1. Any document that was valid under Listing XYZ.1 is also
> valid under Listing XYZ.4.
>
> What this means is that if you run into such issues with your sharding configuration, one of the first things to look at
> is if you can simply increase the `Range` property of the sharding configuration. In many cases, this is all you need to
> do.

In other words, using `Range`, RavenDB is able to narrow the cost of the query from all fragements to just one or two. It also
neatly avoid several issues around obese shards. 

All the usual semantics of content based sharding still apply, mind. You have optimized queries, you cannot change the fields 
specified in the sharding strategy to a value that doesn't match the shard range that this document is located on, etc.

You can always increase the `Range` value of the sharding configuration, so it doesn't require too much upfront thinking 
about it. If you *haven't* specified the `Range`, it is initialized to `1` by default (which efectively disable it).

The one important thing about `Range` that you must remember is that it turns a *gurantee* of two documents always residing
in the same fragement to a *statistically likely scenario*. In other words, you can absolutely count on the fact that 
*some* of the `Orders` documents will reside in different fragements from their `Customer`. That won't happen to all 
customers (it's likely a rare scenario, in fact), but that is something that you'll run into and have to account for.

But aside from the locality of using a single fragement, why does this actually matters? In terms of queries, you are 
unlikely to notice any different. They may be an additional network roundtrip between the nodes in the cluster, but that
isn't likely to matter much for you. 

The most important change is around the system behavior. In particular, around certain types of advanced indexing operations
and most importantly, transactions.

### Transactions in a sharded database

RavenDB is a transactional database. That means that you can modify multiple documents at one time and save them all in an
atomic fashion (as well as durable, and the other ACID properties). These documents can belong to the same collection or 
different collections. You can also have a transaction that spans documents, attachments, counters and time series. 
This is true when we are talking about transactions for unsharded databases, at least. What is the status of things 
when we are dealing with sharded database?

A transaction in unsharded database can have one of two modes. It can be a local transaction, which is committed on a single 
node and utilize RavenDB's multi-master nature to notify the other members in the cluster. Alternatively, it can be a 
cluster-wide transaction. We discussed cluster-wide transactions vs. local transactions in Chapter 7, so you may want to 
check there to remember what are the relevant scenarios for each of them.

For sharded databases, the situation is actually pretty much the same. RavenDB supports local transactions *and* cluster-wide
transactions for sharded databases. A cluster-wide transaction can span any number of shards and fragements and will be
applied as an atomic unit. Things gets more interesting when we are talking about local transactions in sharded environment.

RavenDB ensures that a transaction that apply to multiple documents in the same shard will be atomic. The actual promise is a
bit stronger. A transaction that apply to multiple documents in the same *fragement* is guranteed to be atomic. However, we
don't guarantee that particular shards will always reside on the same fragement. RavenDB is free to move them as it sees fit.

What this means is that if you modify two documents on the same shard, you can rely on there being a single transaction 
binding them together. If they are on different shards *and* you are using a local transaction, that operation is not 
necessarily going to be atomic. 

As I said, the actual behavior is stronger than per-shard transactions, because a transaction actually apply at the 
fragement level. However, I would recommend relying on this fact. If you are want a transaction that will span multiple
shards, it is best to use cluster-wide transactions.

A cluster-wide transaction is typically more costly than a local transaction, of course. That is one reason why you'll
typically want to place documents in the same shard, if they are going to change together and in a transactional manner.

### Static indexes and aggregation queries

RavenDB has two types of queries, the first you have already seen in this chapter, query on a collection, such as: 
`from Orders where ...`. The second, on the other hand, query an _index_ and looks like this: 
`from index 'Orders/Totals' where ...`. We cover these in detail in Part III of the book. This section may not make much 
sense to you at this point without understanding RavenDB indexes in general, so you might want to just make a note of this 
and come back to it later. The interaction of indexes and sharding is quite important, as you can imagine. There are quite a
few options that I need to cover and I don't want to unnecessarily duplicate information that is already better explained
in context in the chapters about indexes. Instead, I'm going to refer to the features and their interaction with sharding
and let you complete the full picture on your own pace.

> **Where do the indexes run?**
>
> RavenDB indexes are run at the level of the individual fragement, over the data local to that fragement. The sharding
> infrastructure is responisble for querying the rights fragements for the query, merging the results and returning a
> result set that appears to have come from a single server.

A query such as `from index '<index name>'` is using an index that was defined by the user. Such indexes can do all *sorts*
of interesting things, such as run computation, aggregate data, index data from related documents, and more. The question is,
how do all these feature work with sharding?

RavenDB attempts to make the process intuitive and simple for the default case, while giving you enough knobs to customize 
the behavior per your needs. The first rule of indexes and sharding is that an index that operates on a single collection
will use, by default, the same sharding strategy as the collection it is covering. 

In other words, the `Orders/Totals` index, which is covering the `Orders` collection, is going to be sharded by RavenDB 
using the same manner as the `Orders` collection. Assuming that we have used content based sharding on `Customer`, then 
any query on `Orders/Totals` that includes the `Customer` field will be directed to the specific fragement for that 
`Customer`. 

This is the casce whatever the index is a simple one or a map/reduce index (one that aggregates data). If the index has a
single `Map` (covering a single collection), it will default to the content based sharding strategy defined for 
its source collection.

> **Caveats for queries in sharded environment**
>
> For the most part, you can run your queries as you would normally would, and RavenDB will make it happen. There are a
> few scenarios that you need to take into account that can have a significant performance impact. 
>
> First, paging, and in particular deep paging, when running a query that uses multiple fragements is likely going to 
> be slow. Consider the following query: `from Orders where OrderedAt > $today limit 10 offset 5000`. 
> This query is going to be *expensive*, but let's see why exactly this is the case, shall we? 
>
> This is a query on `OrderedAt` field, which isn't sharded upon. This means that RavenDB needs to query all the 
> fragements for this query. The query also asks for a single page of 10 results, but 500 pages deep. In order to 
> properly answer this query, RavenDB needs to fetch 5,010 results from *all* the fragements in the database. 
> It then need to sort these results and select the 5000 .. 5010 results to return to the client.
> 
> Assuming we have 13 fragements, that means that retrieving 65,130 results from all the servers, sorting them and
> then returning just 10 the client. That is a significant amount of work to go through. In general, it would be 
> better if you didn't allowed such deep paging operations in sharded environment. 
>
> Second, when issuing full text queries and ordering by the score of the matches, you need to be aware that the 
> score is actually computed on a per fragement level. The sharding infrastructure knows how to scale results from
> different fragements, but it may have an impact on the order of the results.
>
> Third, it is tempting to run queries such as: `from Orders group by Address.City select count(), Address.City` for
> your aggregations. Such queries will *work*, but they require RavenDB to query all the fragements in the cluster. 
> It is often better to define a Map/Reduce index (discussed in Chapter 12) and ETL processes (discussed in the next
> chapter) to a dedicated database. This gives you the best scenario. RavenDB will aggregate the data on each fragement
> independently, then push it to a single location, where it will be aggregated again. 
>
> That final aggregation is likely to be *much* smaller and can reside on a non sharded database. That means that the cost
> of providing the information is drastically lower. We'll discuss such a scenario later in this chapter.

This convention means that you generally don't need to think about sharding for indexes, they are already going to work
as you expected them to. If the sharding fields are in the query, they will be used to optimize the query. Otherwise,
we'll send the query to all the fragements. From experience, when using sharding, you will naturally include the sharding
fields in your index. It *is* important to make sure that you use the same field name as the source collection, of course.

As you can probably tell from the emphasise, indexes can cover more than a single collection. At this point, RavenDB has no
idea which of the collections' sharding strategy to apply. In this case, it isn't going to attempt to guess, you are going 
to have to tell it. Let's look at Listing XYZ.5, which shows how this is done.

```{caption="You can define a shard strategy on indexes as well as collections" .json}
"Sharding": {
  "ByContent": {
    "Orders": {
      "Fields": ["Customer"]
    },
    "Orders/Totals": {
      "Fields": ["CustomerId"]
    },
}
```

Listing XYZ.5 shows how you can define content based routing on an *index*, as well as a collection. In this case, we tell
RavenDB that any queries on the index `Orders/Totals` should treat the `CustomerId` field as the shard field. This feature
is useful for several scenarios.

In the case in Listing XYZ.5, we renamed the `Customer` field to `CustomerId`. If we have a multi map index (which covers
multiple collections), we use the same technique to tell RavenDB which field(s) it should consider for content based sharding.

#### Indexing related documents

An advanced feature avaiable for RavenDB indexes is the ability to index a document using a *related* document data. 
For example, in the case of `Employees`, you can index the `Employee`'s *manager* name in the index. This topic is covered
in depth in Chapter 11, but a quick example of how this looks like can be seen in Listing XYZ.7.

```{caption="Getting values from a related document at indexing time" .cs}
from e in docs.Employees
let manager = LoadDocument(e.ReportsTo, "Employees")
select new // data to index
{
    e.FirstName, 
    e.LastName,
    ManagerFirstName = manager.FirstName,
    ManagerLastName = manager.LastName
}
```

With sharded databases, you can only index related document (using `LoadDocument` or `load` calls from the index) on documents
that reside in the same shard as the document you are indexing. In other words, you can only index the `Employee`'s manager if
the manager is also located on the same shard as the `Employee`.

This limitation applies to *shards*, not to fragements. Even if the related document is physically located in 
the same fragement as the document that is being indexed, if they are not on the same shard, calling `LoadDocument` would
fail. Note that for this limitation, the `Range` specification is not relevant. An exact match on the shard is required, a
range is not sufficent.

Luckily, this feature is already used primarily for data that is already very strong tied together, so if you need to do so, 
it is already very likely to be bound to the same shard.

#### Map/Reduce indexes

RavenDB indexes are used to... well, find stuff. That is their primary purpose, as you would expect. They are also used for
a very different purpose, however. They are the backbone of aggregating information. The whole of Chapter 12 is dedicated for
these types of indexes, called Map/Reduce indexes, so I'm not going to discuss them here. For now, all you need to know is 
that they allow you to run data aggregation *very* cheaply. 

This is the case when we are talking about unsharded environment, but what about a sharded database? As with other indexes,
you can define a content based sharding and RavenDB will optimize your aggregation queries as usual. However, what will
happen if you need to do an aggregation query on a data set that spans multiple fragements? Let's consider Listing XYZ.6
as a good example.

```{caption="Using range specification for indexes" .json}
"Sharding": {
  "ByContent": {
    "Orders/ByCustomer": {
      "Range": 1000,
      "Fields": [
        "Customer"
      ]
    }
}
```

The index `Orders/ByCustomer` is sharded on the `Customer` field, and we have the same `Range` specification we saw before. 
A query such as: `from index 'Orders/ByCustomer' where Customer = 'customers/1-A'` will be processed by the sharding 
infrastructure as usual. We'll find the relevant ranges for this query, and the fragements that they reside on. In this case,
let's say that this particular query touches two separate fragements. RavenDB will query both fragements for their results and
then *merge* them, this include re-aggregating the data from the various fragements into a single whole.
Once that data from all fragements has been aggregated, we'll apply sorting and paging and then return it to the client.

> **Filtering is only applied once**
>
> An interesting caveat of the way RavenDB behaves is that it apply the filtering logic once, at the fragement level.
> The sharding infrastrcuture will aggregate the data again, sort and page it, etc. What it will *not* do is re-apply
> filtering for the results.
>
> Let's inspect a scenario where this can cause some issues. We have the following query: 
> `from index 'Orders/ByCustomer' where Count < 10 limit 2`, which requires us to fetch data from multiple fragements. 
> We get a result with a `Count` of 7 from `Orders$7` and `Count` of 4 from `Orders$8`. RavenDB will 
> re-aggregate the data, giving us a `Count` with a value of 11. 
>
> The reason RavenDB behaves in this manner is simple. Let's say that we'll apply the filter after the aggregation, that 
> means that we'll filter results for the query. Notice that this query has a `limit 2`, so we got only two results from
> the fragements. We'll now need to go back to the fragements and ask them for more results, which may also be filtered,
> etc. 
>
> This can turn *very* expensive very quickly, see also the discssion on deep paging earlier in the chapter. Because this is
> a rare scenario, with devestating consequences if triggered, RavenDB only run the filters on the fragement level and not
> at the sharding infrastrcuture. 

Map/Reduce indexes and aggregation queries in a sharded environment work great if the number of fragements that they need 
to use is limited. There are other ways to handle aggregation in a sharded environment, see the section about Sharding and
ETL later in this chapter. 


### Sharding and ETL

In a sharded database, it is common for most operations to follow the sharding strategy you defined, except that *certain*
tasks require you to go across the shards. This is felt mostly painfully when you need to run aggregations across the entire
data set. 

Let's assume that we have the `Customers` and `Orders` scenario with 13 fragements across 25 nodes. Figuring out how many
orders a particular customer have is going to be trivial. RavenDB is going to be able to use a Map/Reduce index to pull 
the aggregate data from one or two fragements. 

However, if you want to show the number of sales for each product, that is a much more expensive operation. Conceptionally,
it is identical to the query by `Customer`, but in this case, we can lean on the sharding strategy. We have to touch all
the nodes to answer such queries, and that can be expensive. 

Instead, we can combine two separate features of RavenDB to come to a very elegant result. Artifical documents and RavenDB
ETL together give us a very nice way to handle this kind of requirements. Let's go over the skeleton of the solution. 
We cover artifical documents in detail in Chapter 12 and ETL is discussed in the next chapter. I don't intend to repeat
that information, but give you the information require to piece these separate features together into a complete solution.

You can define a Map/Reduce index and set its `Output Collection` value. This setting will cause the index to create an 
artifical document whenever there is a new update to the index. These documents reflect the aggregated status of the index.
The key here is that these are real documents, which you can operate on using other RavenDB tools and in this case, the 
RavenDB ETL feature.

Be aware that the documents will *always* be written to the fragement where they were indexed. Make sure to setup the proper
content based sharding to ensure that RavenDB knows where to find the artificial documents. But the most common use for 
these artifical documents is to allow us to operate on them using the ETL processes.

RavenDB ETL allows you to define an ETL process that would copy documents from one database to another. Unlikely replication,
where the entire state of the database is cloned to the other side, ETL allows you to define exactly what collections, 
documents and data will be sent to the other side.

The underlying idea is to setup Map/Reduce indexes to generate artifical documents, and then push these documents to another
location, typically, a single database. The idea is that the Map/Reduce operation has already significantly... reduced the
amount of data that we are working on, so there is no issue pushing it to a single location.

At that point, you can aggregate the resulting data again using additional means, but the dataset you are working on is
already much smaller, and the existing Map/Reduce indexes and RavenDB ETL processes will keep the data up to date as changes
happen on the cluster. 

> **Ongoing tasks in a sharded database**
>
> RavenDB has the concept of ongoing tasks, such as RavenDB ETL, Subscriptions, backups, etc. These tasks can be defined
> at the database level and will be tasked to a particular node in the database group. In a sharded environment, they work
> in pretty much the same manner.
>
> The sharding infrastructure is going to apply any ongoing task on a sharded database to each of the fragements, as needed.
> For example, if you have an ETL process setup, it will run (concurrently) on all the fragements in the sharded database.

Going back to the example of finding out how many sales we have per product, we'll not try compute that by asking
each fragement in turn. Instead, we'll define a Map/Reduce index to run this aggregation and an ETL process to push this data
to another (unsharded) database. Each fragement will push the data from its own store to the same location, giving us a 
global view of the system. At this point, instead of having to deal with the number of orders (tens / hundreds of 
millions), we have to deal with a record per *product*, a much smaller number.

We can then apply additional Map/Reduce operations to gather the information we want from the summary. It's a good idea to
do just the required level aggregation on the fragements before sending the data out. Just enough so the data size will
not overwhelme the destination. This approach gives us the chance to run more aggregation at the destination, across
multiple dimensions. 

This method isn't really part of the sharding behavior of RavenDB, it is simply a useful approach to dealing with a common
problem. I've given only the higher level view for this, you can read the full details about Map/Reduce artificial documents
in Chapter 12 and about ETL in the next chapter.

### Summary

Sharding is a complex and fascinating topic, which we have spent a *lot* of time thinking about. I tried to strike a balance
between giving you sufficent information to build a system on top of sharded RavenDB while not overwhelming you with 
implemenetation details that are not relevant to you as a user.

We covered how RavenDB's sharding is layered on top of the distributed architectured that we talked in the previous chapters.
In particular, a fragement in a sharded database can be thought as a stand alone database, just managed by the sharding
infrastructure. That means that high availability and replication are there, just as they would be in a normal RavenDB
database, and following the same rules that you are already familiar with it.

RavenDB sharding operates by hashing the document ids (with some fancy moves thrown in to allow for content based sharding)
and assigning each document to a shard id between 0 and 1048576. These shards are then split into ranges and allocated to
fragements. RavenDB will manage the allocation of shards to fragements and use the allocation information to route documents
and queries to the right location.

Content based sharding allows you to define sophisticated sharding strategies based on your needs. RavenDB's approach allow
you to modify the sharding strategy on the fly, without incuring the high costs you'll find with other solutions. The system
allows you to ignore sharding entirely and let RavenDB do what it will or to control exactly where each document will go and
anywhere in between.

The common usage is to ensure that documents that are often accessed and modified together will reside in the same shard. You
can ensure that this is the case by using document id conventions or by defining content based sharding. Documents on the 
same shard are guranteed to be on the same physical location and can participate in an atomic local transaction. For scenarios
where you want to modify multiple documents in different shards, you can use a cluster-wide transaction, which allow for 
cross-shard transactions.

We also covered how RavenDB's indexes work in a sharded environment. The indexes can inherit their behavior from their source
collection or you can define the content based sharding for each index independently. Queries on a sharded database will be
optimized if possible and routed to a single fragement for answers. If they can't be dealt with on a single fragement, RavenDB
will send them to all the relevant shards and combine the answers from the fragements to give you the right final result.

The same behavior also applies for Map/Reduce indexes, used for aggregating data inside RavenDB. The sharding infrastructure
is capable of merging and re-aggregating the data from multiple sources, coming to the correct tally across the entire sharded
database. 

For certain types of queries, this is a great feature, but if most of your aggregated queries are running contrary to your
sharding strategy, you are probably better off with using the approach outlined in the last section. Do minimal level of 
aggregation on the fragement level, and then use ETL to push that to a central location for additional processing. 
Incidently, this is the exact topic of the next chpater.
