In the previous [instalment of guide](https://engineerhead.github.io/dns-server/dns-message-sections), DNS header and its fields were discussed. Now we are going to take a look at Question section of DNS message

```
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                                               |
    /                     QNAME                     /
    /                                               /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     QTYPE                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     QCLASS                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```
|  |  |
|:---|:---|
|QName  |A domain name in the form of sequence of labels such that each label consists of length octet followed by that number of octets|
|QType  |Two octet code representing the type of query. The values match with values of TYPE field|
|QClass  |Two octet code specifies the class of query which is usually IN for the internet|

After the Question section, we have to deal with Answer section that contains the Resrouce Records asked in the query. The answer and other sections like authority and additional have same format for the resource record. Obviously, there can be multiple number of resource records whose length is set in Header section.
```
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                                               |
    /                                               /
    /                      NAME                     /
    |                                               |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TYPE                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                     CLASS                     |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      TTL                      |
    |                                               |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                   RDLENGTH                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--|
    /                     RDATA                     /
    /                                               /
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```

|  |  |
|:---|:---|
|Name  |A domain name pointing to a resource record which pertains |
|Type  |Two octets specifying the type code of RR|
|Class  |Two octet code specifies the class of data in RDATA field|
|Type  |Two octets specifying the type code of RR|
|TTL  |Time To Live. A 32 bit unsigned integer specifying the time in seconds for which the RR may be cached|
|RDLENGTH  |An unsigned 16 bit integer pointing to the length in octets of RDATA field|
|RDATA  |A variable length string of octets describing the resource record. Format of this field depends upon TYPE and CLASS of RR.|

For example, if TYPE is A and CLASS is IN, the RDATA field is 4 octet Internet address. Let's take a look how does a DNS query's response looks like using dig utility.
```
; <<>> DiG 9.10.6 <<>> example.com
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 63891
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 512
;; QUESTION SECTION:
;example.com.			IN	A

;; ANSWER SECTION:
example.com.		20223	IN	A	93.184.216.34

;; Query time: 144 msec
;; SERVER: 192.168.10.1#53(192.168.10.1)
;; WHEN: Fri Aug 19 16:41:29 PKT 2022
;; MSG SIZE  rcvd: 56
```

 - The header, question, and answer sections of the response are described separately.
 - In header section, opcode is QUERY. status is NOERROR. id is 63981. Further, flags are described and tells query response(qr), recursions desired(rd), and recursion avaialble(ra) are set.
 - The question section tells about the domain,  class(IN) ,and record type(A) being queried.
 - The answer section describes domain being queried, TTL (20223), record class, record type, and finally the IP address(93.184.216.34) for example.com.

This gives us bird eye view of the query and response packet. Let's go further and take a look at the packets capture by WireShark.
![DNS Query Packet](https://i.imgur.com/4ujxakG.png)

We know that headers is 12 bytes long. Let's get the relevant bytes which are 
```
57 27 01 20 00 01 00 00 00 00 00 01
```

First two bytes 0-1 are id which are *57 27*. ID bytes are copied into response which can be seen in next image. Next two bytes are flags which happen to be *01 20*. Flag bytes in binary are as follows. First bit is zero(QR) as it is a query.
```
0 0 0 0 0 0 0 1 0 0 1 0 0 0 0 0
```
Next 4 bits are *0 0 0 0* (OPCODE) telling it is a standard lookup. AA and TC flags are 0 0 as they are irrelevant. RD is set meaning dig requests recursive looks up always. Second byte starts with RA which is 0 in query's case. Z is set but it is related to DNSSEC. RCODE's 4 bits are 0 for query.

Let's take a look at response packet captured by WireShark. 
![DNS Response Packet](https://i.imgur.com/A4qsLex.png)

First two bytes are *57 27* which match the ID in earlier query packet. Flags are set to *81 a0* which in binary are as follows.
```
1 0 0 0 0 0 0 1 1 0 1 0 0 0 0 0
```
First bit(QR) is set as it is a response message. OPCODE(0000), AA(0), TC(0) are zero. RD is set. First bit of the next byte is set(RD) which indicates that DNS server supports recursion. Next Z and RCODE are zero as they aren't involved in response message.

After header's 12 bytes, we have Question section. Let's take a look at it.
```
07 65 78 61 6d 70 6c 65 03 63 6f 6d 00 00 01 00 01 
``` 
First octet tells the length of following domain label which in this case is seven and describes *example*. After 7 octets, we have length of following label. In the above case, length is 03 denoting *com*. Following 00 indicates the termination of domain labels. Next two octets *0001* describe type and last two octets *0001* describe class.

In response case, we have to further examine the resource records sent by the DNS server.
```
c0 0c 00 01 00 01 00 00 4b 6e 00 04 5d b8 d8 22
```
First two bytes are used for compression of domain labels. It will be described in detail later. Next *0001* tells us the type while another *0001* specifies the class. Following 4 bytes describe the TTL. Two bytes after *0004*  tell us length of resource  record. The address returned by DNS server is *5d b8 d8 22* which results  93.184.216.34 in decimal.

We will start implementing the response part of our DNS server in next part of the guide.