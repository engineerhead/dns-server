## DNS Zone Master File
Our goal is to make an authoritative DNS server. So! we are going to need Master Files for the domains  which come under out authority. Master files are defined in [RFC 1035](https://datatracker.ietf.org/doc/html/rfc1035). They are simple text files which contain Resource Records. The list of resource records in a master file defines a zone.

Let's go through the format of Master File. The list of entries are mostly line oriented meaning one line defines one resource record. However, there are resource records like SOA which can expand on multiple lines and use parentheses to indicate a continued list of items. A combination of spaces and tabs defines the separate items of a resource record entry. A record may look like this 

> dns1	IN	A	10.0.1.1

We will discuss the structure of a resource record soon. Before that, we need to describe that there can be blank lines anywhere in the file. The comments in master file start with "**;**". The comment can be at start or end of a line. Eventually, following entries can be defined in master zone file.

> \<**blank**>[\<**comment**>]
> $ORIGIN \<**domain-name**> [\<**comment**>]
> $INCLUDE \<**file-name**> [\<**domain-name**>] [\<**comment**>]
>  \<**domain-name**>\<**rr**> [\<**comment**>]
>   \<**blank**>\<**rr**> [\<**comment**>]

There are two specific entries which start either with $ORIGIN or $INCLUDE. As expressed above, $ORIGIN is followed by a domain name, and resets the current origin for relative domain names to the stated name. $INCLUDE get the content from the named file and inserts into current file. $INCLUDE may be followed by a domain name which set the relative domain name origin for the included file. For now, $INCULDE is not supported in our implementation of dns server.

The last two entries represent resource records. If resource record begins with a blank, then the record is assumed to be owned by the last stated owner. However, if the entry begins with \<domain-name> then the owner name is reset.

Resource Record can be in one for the following forms

> [\<TTL>] [\<class>] \<type> \<RDATA>
> [\<class>] [\<TTL>] \<type> \<RDATA>

Resource Record begins with optional TTL and class fields, followed by a type and RDATA field. TTL is a decimal integer while class and type use the standard mnemonics. If TTL or class is omitted, we use the last stated values.

\<domain-name>s data's length overcomes any other entity in the master file. The labels in domain name are expressed as character strings and separated by dots. Domain names that end with dot are complete while other are relative. Relative domain names are concatenated with an origin that is specified in $ORIGIN, $INCLUDE or as an argument to master file loading routine. Here is an example master file.

    $ORIGIN ISI.EDU
    @   IN  SOA     VENERA      Action\.domains (
                                 20     ; SERIAL
                                 7200   ; REFRESH
                                 600    ; RETRY
                                 3600000; EXPIRE
                                 60)    ; MINIMUM

        NS      A.ISI.EDU.
        NS      VENERA
        NS      VAXA
        MX      10      VENERA
        MX      20      VAXA
        A       A       26.3.0.103
        VENERA  A       10.1.0.52
        A       128.9.0.32
        VAXA    A       10.2.0.27
        A       128.9.0.33
        
Next guide in the series will describe parsing the master file and obtaining records to form proper data structures.