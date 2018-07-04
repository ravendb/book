
# Running in production

We have spent a lot of time talking about what RavenDB can do in this book. We've talked about the best way to put data into it and get data
out, how indexes work, how RavenDB runs as a distributed cluster and how to work with the database from your applications. What
we haven't talked about, except for a few tidbits here and there, is how you are actually going to run RavenDB in production.

The production environment differs from running in development mode in several key areas. You typically have _much_ more data that's more important, may need protection from prying eyes and (most importantly) definitely needs to be there at all times. Production systems should be available, speedy and functional.

Production systems also run under heavy constraints, from limited network access to air-gapped systems to (true story)
an old PC that is thrown in an unventilated cupboard and expected to serve business-critical functionality.
The common thread is that what you can do in production is limited. You can't just attach a debugger, run invasive procedures
or even assume that there is a person monitoring the system who can react when it beeps. 

With cloud deployments thrown in, you might not even know what kind of machines you're running on and issues can arise 
because of a noisy neighbour on the same hardware that impacts your operations. Regardless of the environment and the hurdles you need to clear, your operations team needs to deliver reliability, performance, security and agility. 

RavenDB was designed with an explicit focus on production. We already saw some of this earlier in the book when talking about different kinds of alerts and behaviors; in this part, we are going to be taking a deep dive into some
yet unexplored parts of RavenDB. 

We'll cover deployments at length: in house and on the cloud, on your own machines and as a database as a service (DBaaS). We'll explore
topologies that range from single-production servers to clusters spanning the globe and talk about how to manage your 
databases for optimal resource usage and maximum survivability. In particular, we'll focus on what RavenDB is expecting 
from the underlying platform, what kind of optimizations you can apply at the deployment level and the kinds of resources
you should give to your RavenDB instances.

We'll discuss monitoring, both as part of ongoing metrics gathering and analysis and as it applies to when you need to gather information about what is going with a specific issue. There is a wealth of information that RavenDB externalizes
specifically to make such investigation easier and ongoing monitoring will give you a good feel for the "heartbeat" of the 
system, meaning you'll be able to notice changes from expected patterns and head off problems early.

Routine and preventive maintenance is also an important topic that we'll go over. From proper backup and restore procedures to
disaster recovery strategies, it pays to be prepared in case trouble lands in your lap. 
We'll see how to troubleshoot issues in production, covering additional tools available at the operating system
level and dedicated tools and features meant to help you manage and operate RavenDB. We'll discuss ways to manipulate the 
internal state of RavenDB, impact decision making and behavior at runtime and always keep your application running. 

This part is meant for the operations team that will support your RavenDB cluster in production, but it's also very useful 
for developers and architects who want to understand at least the rudimentaries of how RavenDB is being run in the production 
environment and the options you have to inspect and manage it.
The content of this part of the book was composed after over a decade's work supporting RavenDB deployments in production in a variety of environments. You'll note that
the general approach we took is that if there's an error RavenDB can do something about, it will. 

That doesn't mean your operations team has nothing to do, mind. There is quite a lot of work to do, but most of it
should be done before the system is anywhere near a production deployment. We'll cover in detail the notion of capacity planning, 
setting service-level agreements (SLAs) for RavenDB and your system (and measuring compliance with them) and the kinds of machines and 
systems you should expect to use to meet these goals.
