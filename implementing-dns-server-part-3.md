---
nav_order: 9
---
## Implementing DNS Protocol Response: Part 3
Finally, we are going to construct the resource records asked into hex stream that will be sent over the connection
```js
    let dnsBody = '';

    for (let record of askedRecords) {
        dnsBody += recordToBytes( qt, record); 
    }

    dnsBody = new Buffer.from(dnsBody, 'hex');
```
Each record from the desired resource records is passed to *recordToBytes* method.
```js
function recordToBytes( recordType, record) {
    let rBytes = 'c00c';

    rBytes += getRecordTypeHex(recordType);

    rBytes +=  '00' + '01';

    rBytes +=  parseInt(record["ttl"]).toString(16).padStart(8, 0);

    let alphabetDomain = '';

    if(recordType == 'A'){
        rBytes +=  '00' + '04'; 

        for(let part of record["data"].split('.')){
            rBytes += parseInt(part).toString(16).padStart(2, 0);
        }
    }
    else if(recordType == 'SOA'){
        let mname = domainToHex(record["mname"]);
        let rname = domainToHex(record["rname"])
        let serial = stringToHex(record["serial"]);
        let refresh = stringToHex(record["refresh"]);
        let retry = stringToHex(record["retry"]);
        let expire = stringToHex(record["expire"])
        let minimum = stringToHex(record["minimum"]);

        alphabetDomain += mname + rname + serial + refresh + retry + expire + minimum;

    }
    else{        
        alphabetDomain = domainToHex(record["data"]);
    }
    
    
    
    if (alphabetDomain != ''){

        
        switch (recordType) {
            case 'CNAME':
                alphabetDomain += '00';     
                break;
            case 'MX':
                alphabetDomain = parseInt(record["preference"]).toString(16).padStart(4, 0) + alphabetDomain;
                break;
        
            default:
                break;
        }
        let totalLength = (alphabetDomain.length / 2).toString(16).padStart(4, 0);
        rBytes += totalLength + alphabetDomain;
    }
    
    return rBytes;
}
```
The response varies with the record type.  The string starts from *c00c* characters which tell the client regarding compression of response being sent and where to start looking for the record. After that we set the record type bits which are obtained from *getRecordTypeHex* function. Next, we set the bits of  resource record's TTL. After that, construction of the actual answer begin.
```js
    if(recordType == 'A'){
        rBytes +=  '00' + '04'; 

        for(let part of record["data"].split('.')){
            rBytes += parseInt(part).toString(16).padStart(2, 0);
        }
    }
```
For A record type, length is always set to 4 as we are going to return an IPv4 address of length 4. Individual numbers froth IP address are converted to hex and adjusted for the length. 

Construction of the answer is same for all other records except SOA record which is evident from the code. *domainToHex* does the main part of converting resource records's details from alphabet to hex encoding. It is sort of similar to the routine which constructed question section.
```js
function domainToHex(domain) {
    let alphabetDomain = '';
    let alphabetDomainLength = 0;
    let bytes;

    for (const word of domain.split('.')) {
        bytes = '';
        for (const char of word) {
            bytes += char.charCodeAt().toString(16).padStart(2, 0)
        }
        alphabetDomainLength = (bytes.length / 2).toString(16).padStart(2, 0);
        
        alphabetDomain += alphabetDomainLength + bytes
        
    } 
    return alphabetDomain;
}
```
This is all for constructing a basic authoritative DNS server in Node.js(Javascript). There are many elements missing from this implementation like compression and recursion which might be implemented in future.