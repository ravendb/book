
# Security, encryption and authentication

Databases are very tempting targets for intruders. They typically contain all sort of juicy bits of info (your data and, more 
importantly, your _customers'_ data); attacking them is very much like attacking the heart of an organization. In fact,
the end goal of many intrusions is to get to the database and the data it holds.

The goal of an information security attack is often to steal data, either for espionage purposes or for resale purposes. In many cases, the entity purchasing
the stolen data is the same organization it was stolen from, either because they don't have the data anymore or in order to prevent
it from being leaked elsewhere. Some intruders have noticed this and shorten the feedback loop by creating ransomware,
which forces organizations to pay ransom to get their own data back.
This is often done by encrypting the data in the database and then holding the decryption key until a ransom is paid 
(usually in bitcoin or similar cryptocurrency). 

Given that we've seen repeated intrusions and widely publicized breaches with severe consequences for the organizations
that suffered them, you half expect to see a database holding production data stored in a hole in the ground, 
surrounded by laser-bearing sharks and vicious, hug-hungry puppies. Or at least the digital equivalent of such a setting.

In truth, many databases are properly deployed, but security has become so complex that it is actually common for people to
give up on it completely. I'm not sure if this is done intentionally, out of ignorance or due to inattention, but the end result is
that there are literally hundreds of thousands of databases running on publicly visible networks, containing production data
and having _no security whatsoever_.

In 2017, there were several waves of attacks on such databases that encrypted data and demanded ransom in order to decrypt it. This
included databases containing medical and patient records, recordings of conversations between children and parents and 
pretty much everything you _don't_ want to fall into unauthorized hands. 

A large part of the reason for these attacks, I believe, is that security has gotten so hard, obtuse and complex that people often put it off until 
"later". Of course, eventually they go to production. But at this point, it is easy to forget that all the doors are opened and there is a welcome mat for every Joe and Harry who wants to go into the database and ransack it. Securing the database
is a task that is easy to defer for later, when we "really" need it. In some cases, it is deferred until right after the point
when the entire database is in the hands of Mr. Unsavory and the rest of his gang.

Security is a hard requirement; if you are properly deployed, but not secured, you _aren't_ properly deployed. RavenDB 
offers both encryption in transit and at rest, has several layers of protection for your data and was designed to make 
it easy for mere mortals to get the system up securely.^[At the same time, we also designed RavenDB so that it would be harder to deploy when it is set in an unsecured mode.]

We invested a lot of time not just in our security infrastructure, but also in making it approachable, easy to use and switched on
by default. Instead of having to go through a 60-page document detailing all the steps you need to go through to secure your
database, RavenDB is secure by default. 

We'll cover how RavenDB ensures the safety of your data as it travels the network, using strong encryption to ensure that no
outside party can read what is being sent, even when the traffic is sent through channels you don't own. Another
important piece of security is knowing who you're talking to; after all, if you're securely sending secrets to a bad guy, the most
sophisticated encryption in the world won't help you.
RavenDB uses `X509` certificates to mutually authenticate both clients and servers, ensuring that your data goes only to 
those it was authorized to go to. 

Beyond encryption of data in transit, we'll also look at how RavenDB can protect your data at rest, encrypting all data on 
disk and ensuring that even if your hard disk is stolen, the thief will end up with seemingly random bits on the disk and without
a way to actually get to your data.

Proper security is _important_, which is why we cover this topic in detail before we get to actual deployment scenarios. I 
believe that you should first have a good grounding in running a secure system before you take it out into the wild, chaotic
environment that is production.
