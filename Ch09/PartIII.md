
# Querying and Indexing in RavenDB

[Querying and Indexing]: #indexing

We are pretty far into this book, but we haven't yet really talked about one of the most important aspects of a 
database: queries. We've mentioned queries in passing in previous chapters, but we've been focused on other details. 

This is because as important as querying is, getting your data model right and understanding the distributed nature of RavenDB
is of paramount importance for a successful system. These are often somewhat amorphous topics that are quite hard to relate to, whereas 
queries are much easier to talk about, primiarly because it is so very easy to look at a query and then look at its results.

This book is meant to give you an _in-depth_ view of how RavenDB is working, so we'll start by actually looking into the query
engine and how RavenDB processes queries. We'll dig into the query optimizer and index generation process, as well as how queries are handled,
optimized, executed and sent to clients. These details are important if you're going to make the most of your queries, so I'm going to go through all them before actually diving into what you can do with 
queries in RavenDB.

I suggest at least skimming the next chapter (which talks about the RavenDB query engine) before heading into the one after (which
actually teaches you how to actually query). This is especially important for those trying to analyze the behavior of RavenDB or find a good way to handle a specific scenario.

Personally, I consider this kind of discussion facinating, but I realize that I might be in the minority here. I expect that most readers will have a lot more fun when we get to actually creating queries **(((would "creating" be the right word?)))**. RavenDB has a powerful query language and some unique features
around querying, indexing and managing your data that make it easier to find exactly what you want and shape it just the right
way. MapReduce indexes allow you to perform aggregation queries with very little cost, regardless of the data size. 

Advanced features such as facets allow to slice and dice the data as you show it to the user, and suggestions allow you to correct the user
if they are searching for something that isn't quite right.
RavenDB also allows you to perform full text queries on the cheap, execute geo spatial searches and gain fine-grained control over indexed
data.

After talking about the query engine, we are going to tackle simple queries using the RavenDB query language to get you
familiarized with the way queries work in RavenDB. Next, we are going to look into some of the more advanced features, such as full
text search and various querying options.

We are going to discuss how to use RQL for projections and transformation of the data on the server to select just what you 
are going to get from the query. This allows you to get exactly what you need with very little effort, reducing the number of remote 
operations you have to make. 

Following all of that, we are going to dive directly into _how_ RavenDB indexes data, how you can gain control over that and when
it makes sense to do so. The layered design of RavenDB also shows itself with indexing and querying; you have several 
levels you can plug yourself into, depending on exactly what you need.

Here we'll also discuss how you can use patching and queries together to update your documents en masse, migrate between versions and 
perform operational tasks such as correcting data or adding new behavior to the system. 

We'll tie it all together with a discussion of how you can use these features **(((Is that the right phrasing? It's best to be more specific than just "all of that")))** your application to get the most out of your data. Simply knowing that specific features are possible isn't enough; you have to consider what will happen when you start using several of these features
at all the same time, taking you several levels higher in one shot.

This part of the book targets developers using RavenDB and operations teams supporting RavenDB-based systems, for use inside your 
applications and while you are trawling the data to figure out what's going on in there **(((The "for use" seems a bit awkward, here. Is it that these querying features are for use inside your applications?)))**.
