
# Introduction

[Introduction]: #intro

RavenDB is a high performance, distributed, NoSQL document database. Phew, that is a mouthful. But it probably
hits all the right buzzwords **(((I'd suggest taking out "of the month" because it'll date the book to a very specific time.)))**. What does this actually _mean_?

Let me try to explain those terms in reverse order. A document database is a database that stores "documents",  meaning
structured information in the form of self-contained data (as opposed to Word or Excel documents). A document is 
usually in JSON or XML format. RavenDB is, essentially, a database for storing and working with JSON data. You can
also store binary data and a few other types, but you'll primarily use RavenDB for JSON documents.

RavenDB can run on a single node (suitable for development or for small applications) or on a cluster of nodes
(which gives you high availability, load balancing, geo distribution of data and work, etc.). A single cluster can host multiple
databases, each of which can span some or all of the nodes in the cluster. 

With RavenDB 4.0, the team has put a major emphasis on extremely high performance. I am going to assume I don't need to tell you why that's a good thing :-). Throughout this book, I'm going to explain how that decision
has impacted both the architecture and implementation of RavenDB.

In addition to the tagline, RavenDB is also an ACID database, unlike many other NoSQL databases. ACID stands for 
atomic, consistent, isolated and durable and is a fancy way to say that RavenDB has _real_ transactions. Per document,
across multiple documents in the same collection, across multiple documents in multiple collections; it's all there, the kinds 
of transactions developers can rely on. If you send work to RavenDB, you can be assured that either it will be
done completely and persist to disk or it will fail completely: no half-way measures and no needing to roll your
own transactions.

This seems silly to mention, I'm aware, but there are databases out there that don't have this. Given how much 
work we've put into this particular feature, I can empathize with the wish to just drop ACID behaviour, because making
a database that is both high performance and fully transactional is anything but trivial. That said, I think this 
should be one of the most basic requirements of a database, and RavenDB has it out of the box. 

There are certain things that a database should provide; transactions are one, but you also need manageability and a 
certain degree of ease of use. A common thread we'll explore in this book is how RavenDB was designed to reduce the 
load on the operations team by dynamically adjusting to load, environment and the kind of work it is running. 
Working with a database should be easy and obvious, and to a large extent, RavenDB facilitates that.

This book isn't meant to provide documentation; RavenDB has quite a bit of documentation that tells you exactly how to use it. While informative, documentation tends to be dry and it hardly makes for good reading (or for an 
interesting time writing it). A blog post, on the other hand, tells a story -- even if 
most of mine are technical stories. I like writing them, and I've been pleasantly surprised that a large number of
people also seem to like reading them.

I'm a developer at heart. That means that one of my favorite activities is writing code. Writing documentation, on
the other hand, is so far down the list of my favorite activities that one could say it isn't even on the list. I
do like writing blog posts, and I've been maintaining an [active blog](http://ayende.com/blog) for close to fifteen years.^[You can find it at
http://ayende.com/blog]

## About this book

What you're reading now is effectively a book-length blog post. The main idea here is that I want to give you a way to
_grok_ RavenDB.^[Grok means "to understand so thoroughly that the observer becomes a part of the observed—to merge, blend, 
intermarry, lose identity in group experience." From Robert A. Heinlein, _Stranger in a Strange Land_.] This 
means not only gaining knowledge of what RavenDB does, but also all the reasoning behind the bytes. In effect, I want
you to understand all the _whys_ of RavenDB.

Although blog posts and books have very different structures, audiences and purposes, I'll still aim to give you the
same easy-reading feeling of your favorite blogger. If I've accomplished what I've set out to do, this will be 
neither dry documentation nor a reference book. If you need either, you can read the 
[online RavenDB documentation](http://ravendb.net/docs). This is not to say that the book is purely my musings;
the content is also born from the training course we've been teaching for the past decade and the 
formalization of our internal onboarding training.

By the end of this book, you're going to have a far better understanding of how and why RavenDB is put together the way it is. 
More importantly, you'll have the knowledge and skills needed to make efficient use of RavenDB in your systems.

### Who is this for?

I've tried to make this book useful for a broad category of users. Developers will come away
with an understanding of how to best use RavenDB features to create awesome applications. Architects will gain the 
knowledge required to design and guide large-scale systems with RavenDB clusters at their cores. Operations teams will learn how to monitor, support and nurture RavenDB in production.

Regardless of who you are, you'll come away from this book with a greater understanding of all the moving pieces 
and how you can mold RavenDB to meet your needs.

This book mostly used C# as the language for code samples, though RavenDB can be used with .NET, Java, 
Go, Node.js, Python, Ruby and PHP, among others. Most things discussed in the book are applicable even if you 
aren't writing code in C#. 

All RavenDB official clients follow the same model adjusted to match different platform expectations and API 
standards. So regardless of the platform you use to connect to RavenDB, this book should still be useful.

### Who am I?

My name in Oren Eini and over a decade ago, I got frustrated working with relational databases. At the time, I was
working mostly as a consultant for companies looking to improve the performance of data-driven applications. I kept
seeing customer after customer really struggle with this, not because they were
unqualified for the task, but because they kept using the wrong tools for the job. 

At some point I got so frustrated that I sat down and wrote a blog post about what I thought an ideal
datastore for OLTP applications (online transaction processing applications, a fancy way to say business applications) should 
look like. That blog post turned into a series of blog posts and then into some weekend hacking. Fast-forward a 
few months, and I had the skeleton of what would eventually become RavenDB and a burning desire to make it a reality.

At some point, building RavenDB felt not like I was creating something from scratch, but like I was merely letting out something
that was already fully formed. As I mentioned, that was over a decade ago, and RavenDB has been running production
systems ever since. 

In that decade, we have learned a lot about what it takes to really make a database that _just works_ and doesn't 
force you to jump through so many hoops. In particular, I came from a Microsoft-centric world, and that world had a big
impact on the design of RavenDB. Most NoSQL solutions (especially at the time) had a very different mental model
for how they should operate. They put a lot of attention on speed, scale out or esoteric data models, often at
the severe expense of ease of use, operational simplicity and what I consider to be fundemental features such as
transactions.

I wanted to have a database that would _make sense_ for building web applications and business 
systems; you know, the bread and butter of our industry. I wanted a database that would be ACID, because a database
without transactions just didn't make sense to me. I wanted to get rid of the limitations of the rigid schema of 
relational databases but keep working on domain-driven systems. I wanted something fast but at the same
time could just be thrown on a production server and would work without having to pay for an on-call babysitter.

A lot of the design of RavenDB was heavily influenced by the [Release It!](https://pragprog.com/book/mnee/release-it)
book, which I _highly_ recommend. We tried to get a lot of things right from the get go, and with a decade in production
to look back at, I think we did a good job there.

That doesn't mean that we always hit the bullseye. Almost a decade in production——deployed to hundreds of
thousands of machines (of sometimes dubious origin) and used by teams of wildly different skill levels——will teach you
a _lot_ about what works in theory, what the real world can tolerate and what is really needed. 

For the RavenDB 4.0 release, we took the time to look back at what worked and what didn't and made certain to 
actually _use_ all of that experience and knowhow to build a much better end result. 

I'm insanely proud of what came out of the door as a result of it. RavenDB 4.0 is a really cool database capable of 
doing amazing things, and I'm really glad I have the chance to write this book and explore with you all the 
things you can do with it.


### In this book...

One of the major challenges in writing this book came in considering how to structure it. There are so many 
concepts that relate to one another and trying to understand them in isolation can be difficult. For example, 
we can't talk about modeling documents before we understand the kind of features that are available for us to 
work with. Considering this, I'm going to introduce concepts in stages. 

#### Part I - The basics of RavenDB

Focus: Developers

This is the part you will want new hires to read before starting to work with an application using RavenDB, it 
contains a practical discussion on how to build an application using RavenDB. We'll skip theory, concepts and
background information in favor of getting things done, those will be discussed later in the book.

We'll cover setting up RavenDB on your machine, opening up the RavenDB Studio in the browser and connecting to
the database from your code. After getting beyond the hello world stage, we'll introduce some of the basic
concepts that you need to know in order to work with RavenDB, building a simple CRUD sample, learn how to perform 
basic queries and in general work with the client API.

After covering the basics, we'll move into modeling documents in RavenDB, how to build your application in a way
that mesh well with document based modeling, what sort of features you need to be aware of when designing the
domain model and how to deal with common modeling scenarios, concurrency control and dealing with data that 
don't always match the document model (binary data, as an example).

Following on this high level discussion we'll dive into the client API and explore the kind of advanced options
that RavenDB offers us. From lazy requests to reduce network traffic to the optimal way to read and write a lot
of data very quickly, to peforming partial document update and how caching is an integral part of the client API.

We'll conclude the first part of the book with an overview of batch processing in RavenDB and how we can use a 
highly avaliable reliable subscriptions to manage all sort of background tasks in your application in quite an
elegant fashion.

#### Part II - Distributed RavenDB

Focus: Architects

This part focuses on the theory of building robust and high performance systems using RavenDB. We'll go directly
to working with a cluster of RavenDB nodes on commodity hardware, discuss data and work distribution across 
the cluster and how to best structure your systems to take advantage of what RavenDB brings to the table.

We'll begin by dissect RavenDB's dual distributed nature. RavenDB is using both a consensus protocol and a gossip
protocol to build two layers of communication between the various nodes in the cluster. We'll learn why this is 
done and how this add tremendously to RavenDB's robustness in the precense of failures.

After going over the theory, we'll get practical, setting up RavenDB clusters, exploring different topologies and
how clients interact with a cluster of RavenDB nodes. We'll cover distirubted work, load balancing and ensuring
high availability and zero downtime for your applications.

One of the primary reasons you'll want to go to a distributed system is to handle bigger load. We'll cover how you
can grow your cluster, and even run RavenDB in a geo distributed deployment with nodes all around the world. RavenDB
clusters aren't just a collection of machines. They are self managing entities, sharing load and distributing
tasks among the various nodes. We'll get into how the cluster is self monitoring and self healing, how RavenDB take
active steps to ensure the safety of your data at all times.

Modern systems are rarely composed of a stand alone application. We'll finish this part of the book by exploring how
RavenDB integrates with other systems and databases. 
Part of the distributed nature of RavendB is making this easier. We'll go over how to create data flow
that automatically syncronize data to different destinations, be they RavenDB instances or even relational databases.


#### Part III - Querying and Indexing

Focus: Developers, Architects

This part discusses how data is indexed by RavenDB, allowing quick retrieval of information, whether it is a single 
document or aggregated data spanning years. We'll cover all the different indexing methods in RavenDB and how
each of them can be used to implement the features you want in your systems.

RavenDB has very rich querying and indexing support. We'll start by looking at queries. Exploring the RavenDB Query 
Language (RQL) and the kind of queries that you can perform. How RavenDB processes and optimize your queries and 
work to answer them ever faster.

Then we'll get to the real fun stuff. RavenDB's queries can answer a lot more than just `where Status = 'Active'`. 
We'll look at full text queries, querying multiple collections at once and faceted search. We'll look at how RavenDB
can find similiar documents and suggest to the user different queries to try as they find a particular nugger of 
information.

Spatial queries, searching based on geographical data, will be covered in depth. We'll also cover how you can find
documents not based on their own data, but on related documents' data. Similar to the `JOIN` from relational database
but both simpler and faster, this feature can greatly simplify and speed up your queries. One of the strengths of 
RavenDB is its schemaless nature, and that doesn't stop at just storign the data. RavenDB alos have very powerful
capabilities for querying over dynamic data and user generated content.

MapReduce in RavenDB is a very important feature. It allows RavenDB to perform ligntning fast aggregation queries over
practically any dataset, regardless of size. We'll explore exactly how this feature work, the kind of behaviors it enables
and what you can do with effectively free aggregation queries. 

Finally for this part of the book, we'll go over the care and feeding of indexes in RavenDB. How you can create them
yourself, deploy, monitor and manage them. How the RavenDB query optimizer interacts with your indexes and how to move
them between environments. 

#### Part IV - Security

Focus: Operations, Architects

RavenDB is used to store business critical data, medical information and financial transactions. In this part, we'll 
go over all the steps that have been taken to ensure that you data is safe, the communication channels are secures 
and only authorized access to the database is allowed.

We'll cover how to setup RavenDB securely. RavenDB security model is binary in nature. Either you run in an unsecured
mode (only useful for development) or you run it in a secure mode. There are no half measures or multiple steps to 
take. 

Setting up RavenDB securely is easy^[Although it was certainly not easy to _make_ it easy to setup RavenDB securely.]
and once done, it take care of all aspects of securing your data.
Data in transit is encrypted, clients and servers mutually authenticate themselves. We'll discuss how RavenDB handles 
authentication and authorization. How you can control who gets to the database and what they can access. 

We'll also cover securing your data at rest. RavenDB support full database encryption, ensuring that not even a single
byte of your data is ever saved to disk in plain text. Instead, RavenDB will encrypt all data and indexes using 256 bits
encryption. Your data will be decrypted on the fly as needed and only kept in memory for the duration of an active 
transaction.

We'll also cover other aspects of running an ecnrypted database. How you should manage the encryption keys and how to backup
and restore encrypted databases.

#### Part V - Running in production

Focus: Operations

This part deals with running and supporting a RavenDB cluster or clusters in production. From how you spin a new 
cluster to decommissioning a downed node and to tracking down performance problems. We'll learn all that you need (and
then a bit more) to understand what is going on with RavenDB and how to customize its behavior to fit your own 
environment. 

We'll go over the details you need to successfully deploy to production. How to plan ahead for the kind of resources
you need to handle expected load (and how to handle _unexpected_ load). The kind of deployment topologies you can
choose from and their implications. We'll also go over the network, firewall and operating system configurations that
can make or break a production environment.

Just getting to production isn't good enough, we are also going to cover how you can _stay_ in production, and stay
there healthy. We'll discuss monitoring and troubleshooting. What sort of details you need to keep an eye on and how
RavenDB surfaces potential issues early. 
We'll discover how you can dig into RavenDB and see exactly what is going on inside the engine. The kind of self 
optimizations that RavenDB routinely applies and how you can take advantage of them.

We'll cover common issues and how to troubleshoot them, diagnosing problems, finding the root cause and resolving them
while keeping the cluster up and functioning. How to plan for disaster recovery and actually apply the plan if and when
disaster strikes.

We'll spend a whole chapter discussing backup and restores. RavenDB supports several options for backing up your data.
From the offsite hot spare to full binary snapshot of your data to highly compressei backups meant for long term storage.
We'll discuss backup strategies and options, including backing up directly to the cloud. More importantly, we'll cover
how you can define and execute a restore strategy. An often sadly overlooked but critical part of your overall backup
strategy. 

Finally, we are going to close this book with a set of operational recipes. These are ready made answers to specific
scenarios that you might run into in production. These are meant to serve both as a series of steps for you to follow
if you run into this particular scenarion and as a way to give you better insight on the whole process of working with
RavenDB in production.

### Summary

So there is a lot of things in this book, and I hope that you'll find it both interesting and instructive. However,
one thing that it isn't meant to do is to replace the documentation. The purpose of this book is to give you the
full background and greater understanding of how RavenDB is put together and what it is doing. It isn't going over
the nitty gritty details of every API call and what parameters should be passed to it.

In many cases, I have selected to discuss a feature, give one or two examples of its use and where it is best to 
utilize it and left the reader with the task of reading up about the full details of the particular feature in the 
documentation.

This book is meant to be more than API listing. It is meant to tell a story, how you can make the best use of 
RavenDB in your applications and environment. So, without further ado, turn the page and let's get started...
