---
nav_order: 7
---
## Implementing DNS Server's Response: Part 1
After discussion of actual messages of DNS, we are going to start implementation of sending those messages over the connection.
```js
import dgram from 'dgram';
import { processBindFile } from './parser.js';

const server = dgram.createSocket('udp4');

server.bind(53);

server.on('message', async (msg, rinfo) => {
    let TID = msg.slice(0,2);
    let FLAGS = getFlags(msg.slice(2, 4));

    FLAGS = new Buffer.from(parseInt(FLAGS,2).toString(16), 'hex');

    let QDCOUNT = new Buffer.from('0001', 'hex');
    
    let recordsResult;
    let qt;
    let domainParts;
    let askedRecord;
    [recordsResult, qt, domainParts, askedRecord] = await getRecords(msg.slice(12));
    
    let askedRecords = recordsResult[qt].filter(ele => ele.name == askedRecord);    
    

    let ANCOUNT = askedRecords.length.toString(16).padStart(4,0);
    
    ANCOUNT = new Buffer.from(ANCOUNT, 'hex');

    let NSCOUNT = new Buffer.from('0000', 'hex');

    let ARCOUNT = new Buffer.from('0000', 'hex');

    let domainQuestion = new Buffer.from(buildQuestion(domainParts, qt), 'hex');
    
    let dnsBody = '';

    for (let record of askedRecords) {
        dnsBody += recordToBytes( qt, record); 
    }

    dnsBody = new Buffer.from(dnsBody, 'hex');


    server.send([TID,FLAGS, QDCOUNT, ANCOUNT, NSCOUNT, ARCOUNT, domainQuestion, dnsBody], rinfo.port)
});
```
After importing the parser for DNS Zone file, we create a UDP socket and start listening on port 53. Next, we bind a listener to the socket which is going to respond on receiving a DNS query. As discussed earlier, first two bytes are Transaction ID and they are sent back as received. Next two bytes are flags, we extract them and send to *getFlags* function.

```js
function getFlags(flags) {
    let QR = '1';

    let byte1 = flags.slice(0,1);
    
    let OPCode = bitsExtract(byte1);

    let AA = '1';

    let TC = '0';

    let RD = '0';
    
    // Byte 2
    let RA = '0';

    let Z = '000';

    let RCODE = '0000';
    
    let header1 = QR + OPCode + AA + TC + RD;
    let header2 = RA + Z + RCODE;
    
    return header1 + header2;
}
```
We set the QR bit to  1 which specifies that the DNS packet is carrying a response to the query sent. Further first byte is extracted and sent to *bitsExtract* function which returns the OPCODE. It extracts bits 1 to 5 which form the OPCODE.

```js
function bitsExtract(data) {
    let opcode = '';
    for(let bit = 1; bit < 5; bit++){
        opcode += ( (data.toString().charCodeAt())&(1<<bit)).toString();
    }
    return opcode
}
```
Further flags' values are set accordingly and they are returned as a binary string at the end. The following line get the binary string and parse them as int to eventually convert it into hex string. The hex string is passed to Buffer constructor which is sent on the wire.
```js
FLAGS = new Buffer.from(parseInt(FLAGS,2).toString(16), 'hex');
```
For simplicity we assume that there is only one question in the DNS query. So! QDCOUNT is set to 1.
```js
let QDCOUNT = new Buffer.from('0001', 'hex');
```
Now comes the heavy part of extracting domain queries, query type, and getting relevant records from the DNS Zone file. *getRecords* is responsible for all this functionality. We pass it the remains part of DNS query after the first twelve bytes
```js
async function getRecords(data){
    let result = getDomain(data);

    let domain = result[0];
    let domainName;
    let askedRecord = '@';
    if(domain.length > 2){
        askedRecord = result[0][0];
        domainName = result[0][1] + '.' + result[0][2]
    }else{
        domainName = result[0].join('.');
    }
    
    
    let qt = getRecordType(result[1])
    

    let filePath = `zones/${domainName}.zone`;
    let records = await processBindFile(filePath);
    
    
    return [records, qt, result[0], askedRecord]
    
}
```
*getRecords* further relies on *getDomain* function which we are going to discuss in next guide. The only part left is to construct the body i.e actual resource records being asked. 

