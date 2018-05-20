
# Distributed RavenDB

[Distributed RavenDB]: #distributed-ravendb

We've looked into RavenDB with an eye to finding out what it can do, but we've only just scratched the surface.
We've covered enough for you to be able to write simple CRUD applications, but there's a lot more we haven't covered yet. The 
chief topics we've yet to cover are running RavenDB in a distributed cluster and querying data.

I struggled to decide the order in which these two topics should show up in the book. Queries are _important_, but 
RavenDB is quite capable of handling a lot of the decisions around them on its own. And while queries and indexing can have a 
major impact on coding decisions, the distributed aspect of RavenDB should be a core part of the design of your 
architecture. For that reason, I decided to cover RavenDB's distributed nature first. If you only intend to run RavenDB as a single node, you can 
skip this part and go directly to the next, but I still recommend reading through it to understand what's available to you. 

A cluster s always recommended for production deployments. For the high availability, fault tolerance and the load-balancing features the cluster brings to the table.

You may have noticed that the RavenDB philosophy is to make things as obvious and easy to use as possible. Admittedly, working in a distributed environment is not a trivial task, given the challenges you'll face with your data residing on multiple (sometimes disconnected) nodes, but RavenDB makes it easier than the vast majority of other 
distributed solutions.

The next chapter will first cover a bit of theory around RavenDB's design. Then we'll set out to build a mulit node cluster on your local machine and see what kind of tricks we can teach it. We'll finish with practical advice on how to best
use the distributed nature of RavenDB to your advantage. Following that, we'll dive deep into the innards of the 
distributed engine inside RavenDB. You'll learn how the sausage is made, knowledge that can be very useful when troubleshooting.

Next, we'll talk about integrating RavenDB with the rest of your environment. RavenDB is rarely deployed on 
pure greenfield projects that don't have to talk to anything else. We'll discuss integration strategies with the rest
of your organization, ETL processes between different systems and how we mesh it all into a single whole.