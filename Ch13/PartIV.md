
# Part IV - Running in production

We have spent a lot of time talking about what RavenDB can do in this book. What is the best way to put data into it and get it
out, how indexes work, how it runs as a distributed cluster and how you can work with the database from your applications. What
we haven't talked about, except a few tidbits here and there, is how you are actually going to run it in production.

The production environment differs from running in a development mode in several key factors. The amount of data you have is 
typically _much_ larger, the important of the data is higher, you may need to protect your documents from prying eyes and most
importantly, you need it there, at all times. Production systems should be available, speedy and functional.

Production systems also typically run under heavy constraints. From limited network access to airgapped systems to (true story)
an old PC that is thrown in an unventilated cupboard and expected to serve business critical functionality.
The common thread is that what you can do in production is limited. You can't just attach a debugger, or run invasive procedures
or even assume that there is a person that is monitoring the system and can react when it beeps. 

With cloud deployments thrown in, you might not even be aware what kind of machines you are running on and issue can arise 
because of a noisy neighbour on the same hardware that impacts your operations. Regardless of the environment and the hurdles 
that you need to jump, your operations team need to deliver reliability, performance, security and agility. 

Part of the design goals for RavenDB has been an explicit focus on production. We already saw some of that with the kind of 
alerts and behaviors that were called out in the book so far, but in this part we are going to be taking a deep dive into
yet unexplored parts of RavenDB. 

We'll start with everyone's favorite topic, security. We'll cover that first, even before we talk about deployments, because
security is a hard requirement (if you are properly deployed, but not secured, you aren't properly deployed). RavenDB offers
both encryption in transit and at rest, have several layers of protections for your data and was designed to make it easy for
mere mortals to get the system up securely^[We also designed it so it would be _hard_ to deploy RavenDB in an unsecured 
fashion.]. 

We'll cover deployments at length. In house and on the cloud, on your own machines and as a DB-as-a-service. We'll explore
topologies that range from a single production server to clusters spanning the globe, including how to split manage your
databases for optimal resource usage and maximum survivability. In particular, we'll focus on what RavenDB is expecting 
from the underlying platform, what kind of optimizations you can apply at the deployment level and the kind of resources
you should give to your RavenDB instances.

We'll discuss monitoring. Both as part of ongoing metrics gathering and analysis and when you are exploring a particular issue
and need to gather more information about what is going on _there_. There is a wealth of information that RavenDB externalize
specifically to make such investigation easier and ongoing monitoring will give you a good feel for the "heartbeat" of the 
system, meaning you'll be able to notice changes from expected patterns and head off problems early.

Finally, we deal with troubleshooting issues in production. This includes additional tooling available at the operating system
level and dedicated tools and features meant to help you manage and operate RavenDB. We'll discuss ways to manipluate the 
internal state of RavenDB, impact decision making and behavior at runtime and how to always keep your application running. 

This part is the operations team who is going to support your RavenDB cluster in production, but it is also very useful 
for developers and architects to understand at least the rudimentaries of how RavenDB is being run in your production 
environment and the options you have to inspect and manage it.