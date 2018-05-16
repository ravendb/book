
# Introduction

[Introduction]: #intro

RavenDB is a high performance, distributed, NoSQL document database. Phew, that is a mouthful. But it will probably
hit all the right buzzwords of the month. What does this actually _mean_?

Let me try to explain those in reversed order. A document database is a database that stores "documents",  meaning
structured information in the form of self-contained data (as opposed to a Word or Excel document). A document is 
usually in JSON or XML format. RavenDB is, essentially, a database for storing and working with JSON data. You can
also store binary data and a few other types, but you'll primarily use RavenDB for JSON documents.

RavenDB can run on a single node (suitable for development or for small applications) or on a cluster of nodes
(to gain high availability, load balancing, geo distribution of data and work, etc.). A single cluster can host multiple
databases, each of them can span some or all of the nodes in the cluster. 

With RavenDB 4.0 the team has put a major emphasis on extremely high performance, I am going to assume that I'm not
going to have to explain why that is a good thing :-). Throughout the book, I'm going to explain how that decision
has impacted both the architecture and implementation of RavenDB.

In addition to the tagline, RavenDB is also an ACID database, unlike many other NoSQL databases. ACID stands for 
Atomic, Consistent, Isolated and Durable and is a fancy way to say that RavenDB has _real_ transactions. Per document,
across multiple documents in the same collection, across multiple documents in multiple collections. It's all there. The kind 
of transactions that developers can rely on. If you send work to RavenDB, you can be assured that it will either be
done completely and persist to disk, or it will fail completely, no half way measures and no needing to roll your
own transactions.

That seems silly to talk about, I'm aware, but there are databases out there who don't have this. Given how much 
work this particular feature has been, I can empathise with the wish to just drop ACID behaviour, because making
a database that is both high performance and fully transactional is anything but trivial. That said, I think that this 
is one of the most basic requirements from a database, and RavenDB has it out of the box. 

There are certain things that the database should provide, transactions are one, but also manageability and a 
certain level of ease of use. A common thread we'll explore in this book is how RavenDB was designed to reduce the 
load on the operations team by dynamically adjusting to load, environment and the kind of work it is running. 
Working with a database should be easy and obvious, and to a large extent, RavenDB allows that.

While informative, documentation tends to be dry and it hardly makes for good reading (or for an 
interesting time writing it). RavenDB has quite a bit of documentation that tells you how to use it, what to do and
why. This book isn't about providing documentation; we've got plenty of that. A blog post tells a story -- even if 
most of mine are technical stories. I like writing those, and I've been pleasantly surprised that a large number of
people also seem to like reading them.

I'm a developer at heart. That means that one of my favorite activities is writing code. Writing documentation, on
the other hand, is so far down the list of my favorite activities that one could say it isn't even on the list. I
do like writing blog posts, and I've been maintaining an [active blog](http://ayende.com/blog)^[You can find it at
http://ayende.com/blog] for close to fifteen years.

## About this book

This book is effectively a book-length blog post. The main idea here is that I want to give you a way to
_grok_^[Grok means to understand so thoroughly that the observer becomes a part of the observed—to merge, blend, 
intermarry, lose identity in group experience.  Robert A. Heinlein, Stranger in a Strange Land] RavenDB. This 
means not only gaining knowledge of what it does, but also all the reasoning behind the bytes. In effect, I want
you to understand all the _whys_ of RavenDB.

Although a blog post and a book have very different structure, audience and purpose, I'll still aim to give you the
same easy-reading feeling of your favorite blogger. If I've accomplished what I have set out to do, this will be 
neither dry documentation, nor a reference book. If you need either, you can read the 
[online RavenDB documentation](http://ravendb.net/docs). This is not to say that the book is purely my musings;
the content is also born from the training course we've been teaching for the past decade and the 
formalization of our internal on-boarding training.

By the end of this book, you're going to have a far better understanding of how and why RavenDB is put together. 
More importantly, you'll have the knowledge and skills to make efficient use of RavenDB in your systems.

### Who is this for?

I've tried to make this book useful for a broad category of users. Developers reading this book will come away
with an understanding of how to best use RavenDB features to create awesome applications. Architects will reap the 
knowledge required to design and guide large scale systems with RavenDB clusters at their core. The operations 
team will learn how to monitor, support and nurture RavenDB in production.

Regardless of who you are, you'll come away from this book with a greater understanding of all the moving pieces 
and the ability to mold RavenDB to your needs.

This book mostly used C# as the language for code samples, though RavenDB can be used with .NET, Java, 
Go, Node.js, Python, Ruby and PHP, among others. Most things discussed in the book are applicable, even if you 
aren't writing code in C#. 

All RavenDB official clients follow the same model, adjusted to match the platform expectations and API 
standards, so regardless of what platform you are using to connect to RavenDB, this book should still be useful.

### Who am I?

My name in Oren Eini and over a decade ago I got frustrated with working with relational databases. At the time I was
working mostly as a consultant for companies looking to improve the performance of data driven applications. I kept
coming to a customer after customer and seeing them having hard time and really struggling. Not because they were
unqualified for the task but because they kept using the wrong tool for the job. 

At some point I got so frustrated that I sat down and wrote a blog post about what I considered would be the ideal
datastore for an OLTP^[Online transaction processing, a fancy way to say a business application] applications should 
look like. That blog post turned into a series of blog posts, and then into some weekend hacking. Fast forward a 
few months later, and I had the skeleton of what will eventually become RavenDB and a burning desire to have it
get out of my head.

At some point, it felt not like I was building something from scratch, but that I was merely letting out something
that was already fully formed. As I mentioned, that was over a decade ago, and RavenDB has been running production
systems ever since. 

In that decade we have learned a lot about what it takes to really make a database that _just works_ and doesn't 
force you to jump through so many hoops. In particular, I came from a Microsoft centric world, and that had a big
impact on the design of RavenDB. Most NoSQL solutions (especially at the time) had a very different mental model
for how they should operate. They put a lot of attention on speed, or scale out or esoteric data models. Often at
a severe expense of ease of use, operational simplicity and what I consider to be fundemental features (such as
transactions).

On the other hand, I wanted to have a database that would make _sense_ for building web applications and business 
systems. You know, the bread and butter of our industry. I wanted a database that would be ACID, because a database
without transactions just doesn't make sense to me. I wanted to get rid of the limitations of the rigid schema of 
relational database but keep working on Domain Driven systems. I wanted something that is fast but at the same
time can be just thrown on a production server and work without having to pay for an on-call babysitter.

A lot of the design of RavenDB was heavily influenced by the [Release It!](https://pragprog.com/book/mnee/release-it)
book, which I _highly_ recommend. We tried to get a lot of things right from the get go, and with a decade in production
to look back at, I think we did a good job there.

That doesn't mean that we always hit the bullseye. Almost a decade in production, deployed to hundreds of
thousands of machines (of sometimes dubious origin) and used by teams of wildly different skill levels will teach you
a _lot_ about what works in theory, what the real world can tolerate and what is needed. 

We took the time for the RavenDB 4.0 release to go back and look at what worked and what didn't and make certain to 
actually _use_ all of that experience and knowhow that we accrued to build a much better end result. 

I'm insanely proud in what came out of the door as a result of it. RavenDB 4.0 a really cool database, capable of 
doing amazing things, and I'm really glad that I have the chance to write this book and explore with you all the 
things that you can do with it.


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

//TODO: Complete this when writing it is completed


#### Part III - Indexing

Focus: Developers, Architects

This part discusses how data is indexed by RavenDB, allowing quick retrieval of information, whether it is a single 
document or aggregated data spanning years. We'll cover all the different indexing methods in RavenDB and how
each of them can be used to implement the features you want in your systems.

//TODO: Complete this when writing it is completed


#### Part IV - Operations

Focus: Operations

This part deals with running and supporting a RavenDB cluster or clusters in production. From how you spin a new 
cluster to decommissioning a downed node and to tracking down performance problems. We'll learn all that you need (and
then a bit more) to understand what is going on with RavenDB and how to customize its behavior to fit your own 
environment. 

//TODO: Complete this when writing it is completed

#### Part V - Implementation Details

Focus: RavenDB Core Team, RavenDB Support Engineers, Developers who want to read the code

This part is the orientation guide that we throw at new hires when we sit them in front of the code. It is full of
implementation details and background information that you probably don't need if all you want to know is how to 
build an awesome system on top of RavenDB.

On the other hand, if you want to go through the code and understand why RavenDB is doing something in a particular
way, this part will likely answer all those questions. 

//TODO: Complete this when writing it is completed


### Summary

So there is a lot of things in this book, and I hope that you'll find it both interesting and instructive. However,
one thing that it isn't meant to do is to replace the documentation. The purpose of this book is to give you the
full background and greater understanding of how RavenDB is put together and what it is doing. It isn't going over
the nitty gritty details of every API call and what parameters should be passed to it.

In many cases, I have selected to discuss a feature, give one or two examples of its use and where it is best to 
utilize it and left the reader with the task of reading up about the full details of the particular feature in the 
documentation.

This book is already long enough, and the intent is to familiarize yourself with RavenDB itself, not to allow you to
skip reading the full details in the documentation.

