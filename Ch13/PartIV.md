
# Part IV - Security, encryption and authentication

Databases are very tempting target, for an intruder. They typically contain all sort of juicy bits (your data, and more 
importantly, your _customers_ data), attacking them is very much like attacking the heart of any organization. In fact,
the end goal in many introtions is to get to the database and its data.

The goal can be to steal data, either for espionage purposes or for resale purposes. In many cases, the entity purchasing
the stolen data is the same organization it was stolen from. Either because they don't have the data any more or to prevent
it from being leaked to others. Some intruders has noticed that and shorten the feedback loop here by creating ransomware,
forcing organization to ransom their own data back.
This is often done by encrypting the data in the database and then holding the decryption key until a ransom is paid 
(usually in bitcoins or similar cryptocurrency). 

Especially valued targets, repeated introtions and widely publicized breaches with severe consequences for the organizations
that suffered them. You would expect that a database holding production data will be stored in a hole in the ground, 
surrounded by laser bearing sharks and vicious, hug-hungry, puppies. Or at least the digital equivalent of such a setting.

In truth, many databases are properly deployed, but security has become so complex that it is actually common for people to
give up on it completely. I'm not sure if this is done intentionally, out of ignorance or inattention, but the end result is
that there are literally hundreds of thousands of databases running on publicly visible networks, containing production data
and having _no_ security whatsoever.

In 2017 there were several waves of attacks on such databases, encrypting the data and demanding ransom to decrypt it. This
included databases containing medical and pateint records, recording of conversations between children and parents and 
pretty much everything you _don't_ want to fall into unauthorized hands. 

Large part of the reason, I believe, is that security is often so hard, obtuse and complex that people often defer that to 
"later". Of course, eventually they go to production, and the issue of actually closing down the hatches and ensuring that
not every Joe and Harry can go into the database and ransack it.

Security is a hard requirement (if you are properly deployed, but not secured, you _aren't_ properly deployed). RavenDB 
offers both encryption in transit and at rest, have several layers of protections for your data and was designed to make 
it easy for mere mortals to get the system up securely^[We also designed it so it would be _hard_ to deploy RavenDB in 
an unsecured fashion.]. 

We invested a lot of time not just in our security infrastructure but also in making it approachable, easy to use and on
by default. Intead of having to go through a 60 page document detailing all the steps you need to go through to secure your
database, RavenDB is secured by default. 

We'll cover exactly how RavenDB handles security, how to properly deploy your clusters into hostile network in a safe manner
and how you can ensure that your data is protected. 