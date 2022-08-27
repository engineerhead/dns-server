---
nav_order: 5
---
## DNS message sections: Part 1 
We started with discussing [basics of DNS](https://engineerhead.github.io/dns-server/). After that, we discussed the [format](https://engineerhead.github.io/dns-server/dns-zone-master-file-format) for master files of DNS which are also called zone files. Next we discussed how to parse such files in [part 1](https://engineerhead.github.io/dns-server/parsing-dns-master-zone-file-1) and [part 2](https://engineerhead.github.io/dns-server/parsing-dns-master-zone-file-2).

Now, we are going to discuss the actual protocol and its specific message format. There are five sections of the message. Header is always present. Header describes what comes next.Besides telling which other sections are present, it also tells whether the message is a query or a response and many other things.

```
	+---------------------+
    |        Header       |
    +---------------------+
    |       Question      | the question for the name server
    +---------------------+
    |        Answer       | RRs answering the question
    +---------------------+
    |      Authority      | RRs pointing toward an authority
    +---------------------+
    |      Additional     | RRs holding additional information
    +---------------------+
```
The question section describes the question to the name server. The fields in question section are query type(QTYPE), a query class(QCLASS), and a query domain(QNAME). Usually we have a single question along with query domain. The remaining sections have the same format and can also be empty. Let's discuss the fields of header section in bit details.

```
	+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                      ID                       |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |QR|   Opcode  |AA|TC|RD|RA|   Z    |   RCODE   |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    QDCOUNT                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    ANCOUNT                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    NSCOUNT                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
    |                    ARCOUNT                    |
    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
```
Header has a fixed width of 12 bytes in DNS message.

|    |    |
|:---|:---|
|ID  |A 16 bit random identifier which is replicated in the response  |
|QR  | A bit field which tells whether message is query(0) or response(1) |
|OPCODE  | 4 bit field that tells kind of query. It is also replicated in the response  |
|AA  | Single bit which is valid in responses and tells that responding name server is authority over the questioned domain |
|TC  | This bit is set when the message exceeds the limit |
|RD  | If this bit is set, it directed name server to pursue query recursively |
|RA  | This is set by name server in response to indicated whether recursive query support is amiable or not. |
|Z  | Zero in all cases as reserved for future |
|RCODE  | 4 bit field describing the result in responses. Valid values and their description can be found in RFC 1035 |
|QDCOUNT  | 16 bit integer specifying number of entries in question section |
|ANCOUNT  | 16 bit integer specifying number of resource records in answer section |
|NSCOUNT  | 16 bit integer specifying number of name server records in authority section |
|ARCOUNT  | 16 bit integer specifying number of RRs in additional records section |

Details of question and answer section will be discussed in [next instalment](https://engineerhead.github.io/dns-server/dns-message-sections-2).  