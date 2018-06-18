
\newpage \vspace*{8cm}
\pdfbookmark{Dedication}{dedication}
\thispagestyle{empty}
\begin{center}
  \Large \emph{Dedicated to Rachel and Tamar, with all my love.}
\end{center}

# Introduction

## Welcome to RavenDB

[Introduction]: #intro

RavenDB is a high performance, distributed, NoSQL document database. Phew, that is a mouthful. But it probably
hits all the right buzzwords. What does this actually _mean_?

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
done completely and persist to disk or it will fail completely (and let you know about the failure): 
no half-way measures and no needing to roll your own "transactions."

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
do like writing blog posts, and I've been maintaining an [active blog](http://ayende.com/blog) for close to fifteen years.^[You can find it at http://ayende.com/blog]

### About this book

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

#### Acknowledgments

This book has been written and re-written several times. In fact, looking at the commit logs, I started writing it in
July of 2014. Writing something of this scope, and at the same time pushing the product itself forward is not easy and
would not have been possible without the help of many people. 

On the technical side, I want to thank Adi Avivi, Dan Bishop , Maxim Buryak, Danielle Greenberg, Judah Himango,
Karmel Indych, Elemar Junior, Grisha Kotler, Rafal Kwiatkowski, Grzegorz Lachowski, Marcin Lewandowski, Jonathan Matheus,
Tomasz Opalach, Arkadiusz Palinski, Pawel Pekrol, Aviv Rahmany, Idan Ben Shalom, Efrat Shenhar, Tal Weiss, 
Michael Yarichuk, Fitzchak Yitzchaki and Iftah Ben Zaken.

The editors, who had the harsh task of turning raw text into a legible book. Erik Dietrich, Laura Lattimer,
Katherine Mechling and Amanda Muledy. All the errors you find were put it by myself after the last round of edits, I 
assure you. 

The early readers of this book, who had gone above merely giving feedback and actively contributed to making this better. 
Andrej Krivulcik, Jason Ghent, Bobby Johnson,Sean Killeen, Gabriel Schmitt Kohlrausch, Cathal McHale, Daniel Palme, Alessandro Riolo, Clinton Sheppard, Jan Ove Skogheim, Daniel Wonisch and Stephen Zeng.

Thanks you all, it would have been much harder, and likely not possible, without you.

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

One of the major challenges in writing this book was figuring out how to structure it. There are so many 
concepts that interweave with another and trying to understand them in isolation can be difficult. For example, 
we can't talk about modeling documents before we understand the kind of features that are available for us to 
work with. Considering this, I'm going to introduce concepts in stages. 

#### Part I — The basics of RavenDB

Focus: Developers

This is the part you will want new hires to read before starting to work with RavenDB, as it 
contains a practical discussion on how to build an application using RavenDB. We'll skip over theory, concepts and
background information in favor of getting things done; the more theoretical concepts will be discussed later in the book.

We'll cover setting up RavenDB on your machine, opening up the RavenDB Studio in the browser and connecting to
the database from your code. After we get beyond the "hello world" stage, we'll introduce some of the basic
concepts that you need to know in order to work with RavenDB: building a simple CRUD application,
learning how to perform basic queries and in general working with the client API.

After covering the basics, we'll move into modeling documents in RavenDB; how to build your application so that it meshes well with document-based modeling; what sort of features you need to be aware of when designing the
domain model and how to deal with common modeling scenarios; concurrency control and dealing with data that 
doesn't always match the document model (binary data, for example).

Following on this high level discussion, we'll dive into the client API and explore the advanced options RavenDB offers: from lazy requests to reduce network traffic, to the optimal way to read and write a lot
of data very quickly, to peforming partial document updates, to how caching is an integral part of the client API.

We'll conclude the first part of the book with an overview of batch processing in RavenDB and how you can use
highly avaliable, reliable subscriptions to manage all sorts of background tasks in your application in quite an
elegant fashion.

#### Part II — Distributed RavenDB

Focus: Architects

This part focuses on the theory of building robust and high performance systems using RavenDB. We'll go directly
to working with a cluster of RavenDB nodes on commodity hardware, discuss data and work distribution across 
the cluster and learn how to best structure systems to take advantage of what RavenDB brings to the table.

We'll begin by dissecting RavenDB's dual-distributed nature. RavenDB is using both a consensus protocol and a gossip
protocol to build two layers of communication between the various nodes in the cluster. We'll learn why we 
use this dual-mode and how it adds tremendously to RavenDB's robustness in the precense of failures.

After going over the theory, we'll get practical: setting up RavenDB clusters, exploring different topologies and studying
how clients interact with a cluster of RavenDB nodes. We'll cover distirubted work, load balancing and ensuring
high availability and zero downtime for your applications.

One key reason you'll want to use a distributed system is to handle bigger load. We'll cover how you
can grow your cluster and even run RavenDB in a geo-distributed deployment with nodes all around the world. RavenDB
clusters aren't just collections of machines. They are self-managing entities, sharing load and distributing
tasks among the various nodes. We'll talk about how clusters are self-monitoring and self-healing and how RavenDB takes
active steps to ensure the safety of your data at all times.

Modern systems are rarely composed of a stand-alone application. So to finish up this section, we'll explore how
RavenDB integrates with other systems and databases. 
RavenDB was explicitly designed to make such integration easier. We'll go over how to create data flow
that automatically syncronizes data to different destinations, be they RavenDB instances or even relational databases.


#### Part III — Querying and indexing

Focus: Developers and architects

This part discusses RavenDB indexes data to allow for quick retrieval of information, whether a single 
document or aggregated data spanning years. We'll cover all the different indexing methods in RavenDB and how
each of them can be used to implement the features you want in your systems.

RavenDB has very rich querying and indexing support. We'll start by exploring the RavenDB Query 
Language (RQL) and the kind of queries that you can perform. We'll look at how RavenDB processes and optimizes your 
queries to answer them as fast as possible. 

Then we'll get to the really fun stuff. RavenDB's queries can answer a lot more than just `where Status = 'Active'`. 
We'll look at full text queries, querying multiple collections at once and faceted search. We'll look at how RavenDB
can find similiar documents and suggest to the user different queries to try as the user tries to find a particular 
nugget of  information.

Spatial queries (searching based on geographical data) will be covered in depth. We'll also cover how you can find
documents not based on their own data, but on related documents' data. Similar to but simpler and faster than `JOIN` from relational databases, the ability to efficently find documents using related documents can greatly simplify and speed up 
your queries. One of the strengths of 
RavenDB is that it is schema-less by nature, and that doesn't stop at data storage. RavenDB also has very powerful
capabilities for querying over dynamic data and user-generated content.

MapReduce in RavenDB is a very important feature. It allows RavenDB to perform lightning-fast aggregation queries over
practically any dataset, regardless of size. We'll explore exactly how this feature works, the kind of behaviors it enables
and what you can do with what are effectively free aggregation queries. 

Finally, we'll go over the care and feeding of indexes in RavenDB: how you can create, deploy, monitor and manage them yourself. We'll talk about how the RavenDB query optimizer interacts with your indexes and how to move
them between environments. 

#### Part IV — Security

Focus: Operations and architects

RavenDB is used to store business-critical data such as medical information and financial transactions. In this part, we'll 
go over all the steps that have been taken to ensure that your data is safe, the communication channels are secure 
and only authorized users are able to access your database.

We'll cover how to set up RavenDB securely. RavenDB's security model is binary in nature. Either you run RavenDB in an unsecured
mode (only useful for development) or you run it in a secured mode. There are no half measures or multiple steps to 
take. 

Setting up RavenDB securely is easy——although making it easy was certainly not easy——and once set up, RavenDB takes care of all aspects of securing your data.
Data in transit is encrypted, and clients and servers mutually authenticate themselves. We'll discuss how RavenDB handles 
authentication and authorization, as well as how you can control who gets to the database and what they can access. 

We'll also cover securing your data at rest. RavenDB supports full database encryption, ensuring that not even a single
byte of your data is ever saved to disk in plain text. Instead, RavenDB will encrypt all data and indexes using 256-bit
encryption. Your data will be decrypted on the fly as needed and only kept in memory for the duration of an active 
transaction.

We'll also cover other aspects of running an encrypted database: how you should manage encryption keys and how to back up
and restore encrypted databases.

#### Part V — Running in production

Focus: Operations

This part deals with running and supporting a RavenDB cluster or clusters in production, from spinning a new
cluster, to decommissioning a downed node, to tracking down performance problems. We'll learn all you need (plus a bit more) in order to understand how RavenDB works and how to customize its behavior to fit your own 
environment. 

We'll go over the details you'll need to successfully deploy to production, like how to plan ahead for the resources
you'll need to handle expected load (and how to handle _unexpected_ load) and the kind of deployment topologies you can
choose from and their implications. We'll also go over the network, firewall and operating system configurations that
can make or break a production environment.

Just getting to production isn't good enough; we are also going to cover how you can _stay_ in production and stay
there healthily. We'll discuss monitoring and troubleshooting, what sort of details you need to keep an eye on and how
RavenDB surfaces potential issues early on. 
We'll discover how you can dig into RavenDB and see exactly what is going on inside the engine. We'll go over the kinds of self-optimizations RavenDB routinely applies and how you can take advantage of them.

We'll cover common issues and how to troubleshoot them, diagnosing and resolving problems
while keeping the cluster up and functioning. We'll learn how to plan for disaster recovery and actually apply the plan if (and when)
disaster strikes.

We'll spend a whole chapter discussing backups and restores. RavenDB supports several options for backing up your data: offsite hot spares, full binary snapshots of your data and highly compressed backups meant for long term storage.
We'll discuss backup strategies and options, including backing up directly to the cloud. More importantly, we'll cover
how you can define and execute a restore strategy, a critical——though often (sadly) overlooked——part of your overall backup
strategy. 

Finally, we are going to close this book with a set of operational recipes. These are ready-made answers to specific
scenarios that you might run into in production. These are meant to serve both as a series of steps for you to follow
if you run into a particular scenario and as a way to give you better insight into the process of working with
RavenDB in production.

### Summary

So there's a lot going on in this book, and I hope you'll find it both interesting and instructive. But remember, the
one thing it _isn't_ meant to do is replace the documentation. The purpose of this book is to give you a
full background on and greater understanding of how RavenDB works. I'm not covering the nitty-gritty details of every API call and what parameters should be passed to it.

In many cases, I have elected to discuss a feature, give one or two examples of its use and where it's best utilized and leave the reader with the task of reading up on the full details in the documentation.

This book is meant to be more than API listing. It is meant to tell a story, the story of how you can make the best use of 
RavenDB in your applications and environment. So, without further ado, turn the page and let's get started.
