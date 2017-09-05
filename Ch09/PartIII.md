
# Part III - Querying and Indexing in RavenDB

[Querying and Indexing]: #indexing

We are pretty far into this book, but we haven't yet really talked about one of the most important things you can do with a 
database, queries. We mentioned this in passing in previous chapters, but we have been focused on other details. 

This is because as important as querying is, getting your data model right and understanding the distributed nature of RavenDB
is even more paramount for a successful system. These are often somewhat amorphous topics that are quite hard to relate to. But 
queries are much easier to talk about, primiarly because it is so very easy to look at the query and then look at its results.

This book is meant to give you an _in depth_ view of how RavenDB is working, so we'll start by actually looking into the query
engine and how RavenDB is processing queries. We'll dig into the query optimizer, index generation and how queries are handled,
optimized, executed and sent to the client. I'm going to put all those details before actually diving into what you can do with 
queries in RavenDB because these details are important for you to be able to make the most of your queries. 

I suggest at least skimming the next chapter, which talks about the RavenDB query engine, before heading into the one after, which
actually teaches you how to actually query. This is especially true if you are trying to analyze the behavior of RavenDB or trying
to find a good way to handle a specific scenario.

Personally, consider that kind of discussion facinating, but I realize that I might be in the minority here and I expect that most
of the readers will have a lot more fun when we get to actual queries. RavenDB has a powerful query language and some unique features
around querying, indexing and managing your data that make it easier to find exactly what you want and shape it just the right
way. Map/reduce indexes allow you to perform aggregation queries with very little cost, regardless of the data size. 

Advanced features such as facets allow to slice & dice the data as you show it to the user and suggestions allow you to correct the user
if they are searching for something that isn't _quite_ right.
RavenDB also allows you to perform full text queries cheaply, execute geo spatial searches and gain fine grained control over the indexed
data.

Then, we are going to tackle simple queries and the RavenDB Query Language, to get yourself
familiarized with the way queries work with RavenDB. Next, we are going to look into some of the more advanced features, such as full
text search and various querying options.

We are going to discuss how to use RQL for projections and transformation of the data on the server to select just what you 
are going to get from the query, allowing you to get exactly what you need with very little effort and reducing the number of remote 
operations that you have to make. 

Following all of that, we are going to dive directly into _how_ RavenDB index the data and how you can gain control over that (and when
it makes sense for you to do so). The layered design RavenDB favors also show itself with indexing and querying, you have several 
levels that you can plug yourself into, depending on exactly what you need.

Here we'll also discuss how you can use patching and queries together for updating your documents enmass, for migrating between versions or 
doing operational tasks such as correcting data or adding new behavior to the system. 

We'll tie it all together with a discussion of how you can use all of that in your application to get the most out of your data. Knowing
that specific features are possible is not enough until you start considering what happens when you start using several of these features
at all the same time, taking you several levels higher, in one shot.

This part is intended for developers using RavendB and the operations team who supports RavenDB based systems, for use inside your 
applications and while you are trawling the data trying to see what is going on in there.
