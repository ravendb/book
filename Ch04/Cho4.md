
# Deep dive into the RavenDB Client API

In this chapter we are going to take a deep dive into how the client API works. We are going to show mostly C# code examples, but the 
same concepts apply to any of the RavenDB Client APIs, regardless of platforms, with minor changes to make it fit the platform.

There are still some concepts that we haven't gotten around to (clustering or indexing, for example) which will be covered in 
their own chapters. But the Client API is very rich and has a lot of useful functionality on its own, quite aside from the server
side behavior. 

We already looked into the document store and the document session, the basic building blocks of CRUD in RavenDB. But in this chapter we
are going to look beyond the obvious and into the more advanced features. One thing we'll _not_ talk about in this chapter is querying.
We'll talk about that extensively in [Chapter 9](#map-indexes), so we'll keep it there. You already know the basic of querying in RavenDB
but there is a _lot_ more power waiting for you to discover there.

But in the meantime 

### Writing documents

#### Working with the document metadata

#### Change tracking and `SaveChanges`

#### Patching documents

#### Optimistic concurrency and change vectors

#### Bulk insert

#### Working with attachments

#### Deferring commands

#### Waiting for replication or indexing

### Reading documents

#### Lazy requests

#### Streaming data

### Cross cutting concerns on the client

#### Conventions

#### Listeners

### Versioning and revisions

#### Changes API

### Caching

### Data Subscriptions

#### Versioned Subscriptions
