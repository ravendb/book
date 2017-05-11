
# Introduction

RavenDB is a high performance, distributed, NoSQL document database. Phew, that is a mouthful. But it will probably
hit all the right buzzwords of the month. What does this actually _mean_?

Let me try to explain those in reversed order. A document database is a database that stores "documents",  meaning
structured information in the form of self-contained data (as opposed to a Word or Excel document). Usually, a
document is in JSON or XML format. RavenDB is, essentially, a database for storing and working with JSON data.

RavenDB can run on a single node (suitable for development or for small applications) or on a cluster of nodes
(high availability, load balancing, geo distribution of data and work, etc). A single cluster can host multiple
databases, each of them can span some or all of the nodes in the cluster. 

With RavenDB 4.0 the team has put a major emphasis on extreme high performance, I am going to assume that I'm not
going to have to explain why that is a good thing :-). Throughout the book, I'm going to explain how that decision
has impacted both the architecture and implementation of RavenDB.

In addition to the tagline, RavenDB is also an ACID database, unlike many other NoSQL databases. ACID stands for 
(Atomic, Consistent, Isolated and Durable) and is a fancy way to say that RavenDB has real transactions. The kind 
of transactions that developers can rely on. If you send work to RavenDB, you can be assured that it will either be
done completely and persisted to disk, or it will fail completely, no half way measures and no needing to roll your
own transactions.

That seems silly to talk about, I'm aware, but there are databases out there who don't have this. Given how much 
work this particular feature has brought us, I can emphasis with the feeling, because making a database that is 
both high performance and fully transactional is anything by trivial. That said, I think that this is one of 
the most basic requirements from a database, so RavenDB has it out of the box. 

There are certain things that the database should provide, transactions are one, but also manageability and a 
certain level of ease of use. A common thread we'll explore in this book is how RavenDB was designed to reduce the 
load on the operations team by dynamically adjusting to load, environment and the kind of work it is running. 
Working with a database shouldn't be easy and obvious, and to a large extent, RavenDB allows that.

I'm a developer at heart. That means that one of my favorite activities is writing code. Writing documentation, on
the other hand, is so far down the list of my favorite activities that one could say it isn't even on the list. I
do like writing blog posts, and I've been maintaining an [active blog](http://ayende.com/blog) for over a decade
now.

Documentation tends to be dry and, while informative, it hardly makes for good reading (or for an interesting time
writing it). RavenDB has quite a bit of documentation that tells you how to use it, what to do and why. This book
isn't about providing documentation; we've got plenty of that. A blog post tells a story -- even if most of mine 
are technical stories. I like writing those, and I've been pleasantly surprised that a large number of people also
seem to like reading them.

## What is this?

This book is effectively a book-length blog post. The main idea here is that I want to give you a way to
_grok_^[Grok means to understand so thoroughly that the observer becomes a part of the observed—to merge, blend, 
intermarry, lose identity in group experience.  Robert A. Heinlein, Stranger in a Strange Land] RavenDB. This 
means not only gaining knowledge of what it does, but also all the reasoning behind the bytes. In effect, I want
you to understand all the _whys_ of RavenDB.

Since a blog post and a book have very different structure, audience and purpose, I'll instead aim to give you the
same easy-reading feeling of your favorite blogger. If I've accomplished what I set out to do, this will be 
neither dry documentation, nor a reference book. If you need either, you can read the 
[online RavenDB documentation](http://ravendb.net/docs). This is not to say that the book is purely my musings;
the content is also borne from the training course we've been teaching for the past five years and the 
formalization of our internal on-boarding training.

By the end of this book, you're going to have a far better understanding of how and why RavenDB is put together. 
More importantly, you'll have the knowledge and skills to make efficient use of RavenDB in your systems.

## Who is this for?

I've tried to make this book useful for a broad category of users. Developers reading this book will come away
with an understanding of how to best use RavenDB features to create awesome applications. Architects will reap the 
knowledge required to design and guide large scale systems with RavenDB clusters at their core. The operations 
team will learn how to monitor, support and nurture RavenDB in production.

Regardless of who you are, you'll come away from this book with a greater understanding of all the moving pieces 
and the ability to mold RavenDB to your needs.

This book assumes that you have working knowledge of .NET and C#, though RavenDB can be used with .NET, Java, 
Go, Node.js, Python, Ruby and PHP. Most things discussed in the book are applicable, even if you aren't writing
code in C#. 

The RavenDB official clients all follow the same model, adjusted to match the platform expectations and API 
standards, so regardless of what platform you are using to talk to RavenDB, this book should still be useful.

## In this book...

One of the major challenges in writing this book came in considering how to structure it. There are so many 
concepts that relate to one another that it can be difficult to try to understand them in isolation. We can't talk
about modeling documents before we understand the kind of features that we have available for us to work with, for
example. Considering this, I'm going to introduce concepts in stages.

### Part I - The basics of RavenDB

Focus: Developers

This part contains a practical discussion on how to build an application using RavenDB, and we'll skip theory 
and concepts in favor of getting things done. This is what you'll want new hires to read before starting to work
with an application using RavenDB, we'll keep the theory and the background information for the next part.

*[Chapter 2](#zero-to-ravendb) - Zero to RavenDB -* focuses on setting you up with a RavenDB instance, introduce 
the studio and some key concepts and walk you through the Hello World equivalent of using RavenDB by building a 
very simple To Do app.

*[Chapter 3](#crud) - CRUD operations -* discusses RavenDB the basics of connecting from your application to 
RavenDB and the basics that you need to know to do CRUD properly. Entities, documents, attachments, collections 
and queries. 

*[Chapter 4](#client-api) - The Client API -* explores more advanced client scenarios, such as lazy requests, 
patching, bulk inserts, and streaming queries and using persistent subscriptions. We'll talk a bit about data 
modeling and working with embedded and related documents.

### Part II - Ravens everywhere

Focus: Architects

This part focuses on the theory of building robust and high performance systems using RavenDB. We'll go directly
to working with a cluster of RavenDB nodes on commodity hardware, discuss distribution of data and work across 
the cluster and how to best structure your systems to take advantage of what RavenDB brings to the table.

*[Chapter 5](#clustering-setup) -* Clustering Setup - walks through the steps to bring up a cluster of RavenDB 
nodes and working with a clustered database. This will also discuss the high availability and load balancing 
features in RavenDB.

*[Chapter 6](#clustering-deep-dive) -* Clustering Deep Dive - takes you through the RavenDB clustering behavior, 
how it works and how the both servers & clients are working together to give you a seamless distributed 
experience. We'll also discuss error handling and recovery in a clustered environment.

*[Chapter 7](#integrations) -* Integrating with the Outside World - explores using RavenDB along side additional 
systems, for integrating with legacy systems, working with dedicated reporting databases, ETL process, long 
running background tasks and in general how to make RavenDB fit better inside your environment.

*[Chapter 8](#clustering-scenarios) -* Clusters Topologies - guides you through setting up several different 
clustering topologies and their pros and cons. This is intend to serve as a set of blueprints for architects to 
start from when they begin building a system.

### Part III - Indexing

Focus: Developers, Architects

This part discuss how RavenDB index data to allow for quick retrieval of information, whatever it is a single 
document or aggregated data spanning years. We'll cover all the different indexing methods in RavenDB and how
you can should use each of them in your systems to implement the features you want.

*[Chapter 9](#map-indexes) - Simple Indexes -* introduces indexes and their usage in RavenDB. Even though we 
have performed queries and worked with the data, we haven't actually dealt with indexes directly so far. Now is 
the time to lift the curtain and see how RavenDB is searching for information and what it means for your 
applications.

*[Chapter 11](#full-text-search) -* Full Text Search - takes a step beyond just querying the raw data and shows 
you how you can search your entities using powerful full text queries. We'll talk about the full text search 
options RavenDB provides, using analyzers to customize this for different usages and languages.

*[Chapter 13](#multi-map-N-load-doc) -* Complex indexes - goes beyond simple indexes and shows us how we can 
query over multiple collections at the same time. We will also see how we can piece together data at indexing time 
from related documents and have RavenDB keep the index consistent for us.

*[Chapter 13](#map-reduce) -* Map/Reduce - gets into data aggregation and how using Map/Reduce indexes allows 
you to get instant results over very large data sets with very little cost. Making reporting style 
queries cheap and accessible at any scale. Beyond simple aggregation, Map/Reduce in RavenDB also allows you to 
reshape the data coming from multiple source into a single whole, regardless of complexity. 

*[Chapter 14](#facets) -* Facet and Dynamic Aggregation - steps beyond static aggregation provided by Map/Reduce 
and give you the ability to run dynamic aggregation queries on your data, or just facet your search results to 
make it easier for the user to find what they are looking for.

*[Chapter 15](#recursive-map-reduce) -* Artificial Documents and Recursive Map/Reduce - guides you through using 
indexes to _generate_ documents, instead of the other way around, and then use that both for normal operations and 
to support recursive Map/Reduce and even more complex reporting scenarios.

*[Chapter 16](#query-optimizier) -* The Query Optimizier - takes you into the RavenDB query optimizer, index 
management and how RavenDB is  treating indexes from the inside out. We'll see the kind of machinery that is 
running behind the scenes to get everything going so when you make a query, the results are there at once.

*[Chapter 17](#ravendb-lucene-usage) -* RavenDB Lucene Usage - goes into (quite gory) details about how RavenDB 
is making use of Lucene to implement its indexes. This is intended mostly for people who need to know what exactly 
is going on and how does everything fit together. This is how the sausage is made.

*[Chapter 18](#advanced-indexes) -* Advanced Indexing Techniques - dig into some specific usages of indexes that 
are a bit... outside the norm. 
Using spatial queries to find geographical information, generating dynamic suggestions on the fly, returning 
highlighted results for full text search queries. All the things that you would use once in a blue moon, but when 
you need them you _really_ need them.

### Part IV - Operations

Focus: Operations

This part deals with running and supporting a RavenDB cluster or clusters in production. From how you spina new 
cluster to decommissioning a downed node to tracking down performance problems. We'll learn all that you need (and
then a bit more) to understand what is going on with RavenDB and how to customize its behavior to fit your own 
environment. 

*[Chapter 19](#prod-deploy) - Deploying to Production -* guides you through several production deployment 
options, including all the gory details about how to spin up a cluster and keep it healthy and happy. We'll 
discuss deploying to anything from a container swarm to bare metal, the networking requirements and configuration 
you need, security implications and anything else that the operation teams will need to comfortably support a 
RavenDB cluster in that hard land called production.

*[Chapter 20](#security) - Security -* focuses solely on security. How you can control who can access which 
database, running an encrypted database for highly sensitive information and securing a RavenDB instance that is 
exposed to the wild world.

*[Chapter 21](#high-availablity) - High Availability -*  brings failure to the table, repeatedly. We'll discuss 
how RavenDB handles failures in production, how to understand, predict and support RavenDB in keeping all of your 
databases accessible and high performance in the face of various errors and disasters. 

*[Chapter 22](#disaster-recovery) - Recovering from Disasters -* covers what happens after disaster strikes. 
When machines melt down and go poof, or someone issues the wrong command and the data just went into the 
incinerator. Yep, this is where we talk about backups and restore and all the various reasons why operations 
consider them sacred. 

*[Chapter 23](#monitoring) - Monitoring -* covers how to monitor and support a RavenDB cluster in 
production. We'll see how RavenDB externalize its own internal state and behavior for the admins to look at and 
how to make sense out of all of this information. 

*[Chapter 24](#performance-tracking) - Tracking Performance -* gets into why a particular query or a node isn't
performing up to spec. We'll discuss how one would track down such an issue and find the root cause responsible for
such a behavior, a few common reasons why such things happen and how to avoid or resolve them.

### Part V - Implementation Details

Focus: RavenDB Core Team, RavenDB Support Engineers, Developers who wants to read the code

This part is the orientation guide that we throw at new hires when we sit them in front of the code. It is full of
implementation details and background information that you probably don't need if all you want to know is how to 
build an awesome system on top of RavenDB.

On the other hand, if you want to go through the code and understand why RavenDB is doing something in a particular
way, this part will likely answer all those questions. 

*[Chapter 25](#blittable) - The Blittable Format -* gets into the details of how RavenDB represents JSON 
documents internally, how we go to this particular format and how to work with it. 

*[Chapter 26](#voron) - The Voron Storage Engine -* breaks down the low-level storage engine we use to put
bits on the disk. We'll walk through how it works, the various features it offers and most importantly, why it 
had ended up in this way. A lot of the discussion is going to be driven by performance consideration, extremely 
low-level and full of operating system and hardware minutiae. 

*[Chapter 27](#tx-merger) - The Transaction Merger -* builds on top of Voron and comprise one of the major 
ways in which RavenDB is able to provide high performance. We'll discuss how it came about, how it is actually 
used and what it means in terms of actual code using it. 

*[Chapter 28](#rachis) - The Rachis Consensus -* talks about how RavenDB is using the Raft consuensus protocol
to connect together different nodes in the cluster, how they are interacting with each other and the internal
details of how it all comes together (and fall apart and recover again).

*[Chapter 31](#cluster-state-machine) - Cluster State Machine -* brings the discussion one step higher by talking
about how the RavenDB uses the result of the distributed consensus to actually manage all the nodes in the cluster
and how we can arrive independently on each node to the same decision reliably. 

*[Chapter 30](#landlord) - Lording over Databases -* peeks inside a single node and explores how a database 
is managed inside that node. More importantly, how we are dealing with multiple databases on the same node and 
what kind of impact each database can have on its neighbors. 

*[Chapter 31](#replication) - Replication -* dives into the details of how RavenDB manages multi master 
distributed database. We'll go over change vectors to ensure conflict detection (and aid in its resolution) 
how the data is actually being replicated between the different nodes in a database group. 

*[Chapter 32](#architecture) - Internal Architecture -* gives you the overall view of the internal architecture 
of RavenDB. How it is built from the inside, and the reasoning why the pieces came together in the way they did.
We'll cover both high-level architecture concepts and micro architecture of the common building blocks in the 
project.

### Part VI - Parting

This part summarizes the entire book and provide some insight about what our future vision for RavenDB is.

*[Chapter 33](#vnext) - What comes next -* discusses what are our (rough) plans for the next major version and 
our basic roadmap for RavenDB.

*[Chapter 34](#summary) - Are we there yet? Yes! -* summarize the book and let you go and start actually 
_using_ all of this awesome information.

