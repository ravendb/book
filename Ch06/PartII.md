
# Part II - Distributed RavenDB

[Distributed RavenDB]: #distributed-ravendb

We have looked into how RavenDB with an eye to finding out what it can do, but we have only just scratched the surface.
This is enough to be able to write simple CRUD applications, but there is a lot more that we haven't covered yet. The 
chief topics we have yet to cover is the notion of running in a cluster and querying data.

I had struggled with the decision on the order these two topics should show up in the book. Queries are _important_, but 
RavenDB is actually quite capable of handling a lot of the decisions around them on its own, and while they can have a 
major impact on coding decisions, the distributed aspect of RavenDB should be a core part of the design of your 
architecture. For that reason, I decided to cover it first. If you only intend to run RavenDB as a single node, you can 
skip this part and go directly to the next, but I still recommend reading through it at least to understand what is 
available to you. 

Production deployments are always recommended to use a cluster, for high availability, fault tolerance and the load 
balancing features that it brings to the table.

You might have noticed that the RavenDB philosophy is based around making things as obvious and easy to use as we possibly
could. Admittedly, working in a distributed environment is not a trivial task, given the challenges that you face as your
data start residing on multiple (sometimes disonnected) nodes, but RavenDB make it easier then the vast majority of other 
distributed solutions.

The next chapter will first cover a bit of theory around the design of RavenDB, then we'll set out to build a 5 nodes cluster  on your local machine and see what kind of tricks we can teach it. We'll finish with practical advice on how to 
use the distributed nature of RavenDB for your best advantage. Following that we'll dive deeply into the innards of the 
distributed engine inside RavenDB, this is how the suasage is made, and this knowledge can be very useful if you are 
troubleshooting.

Next, we'll talk about integrating RavenDB with the rest of your environment. RavenDB is rarely deployed on 
pure greenfield projects that don't have to talk to anything else. We'll discuss integration starategies with the rest
of your organization, ETL processes between different systems and how we mesh it all into a single whole.

The final topic in the Distributed RavenDB portion of this book will discuss various deployment topologies and how you 
should structure your cluster and your database to various environments. This is intended to serve as a set of blueprints 
for architects to start from when they begin building a system.

