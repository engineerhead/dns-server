---
nav_order: 8
---
## Implementing DNS Protocol Response: Part 2
We set the required variables to process the data given to *getDomain* routine. We know that first byte before the label is length. So it is extracted at the start in *else* statement. Then we iterate over the data for that specified length. Once we reach the length of the label, all initial variables are reset and label value is pushed to *domainParts* holder. Meanwhile we keep checking if the entry is 00 which would mean the end of the label.
```js
function getDomain(data) {
    let state = 0;
    let expectedLength = 0;
    let domainString = '';
    let domainParts = [];
    let x = 0;
    let y = 0;
    for(let pair of data.entries()){
        if (state == 1){
            domainString += String.fromCharCode(pair[1]);
            x++;
            if (x == expectedLength){
                domainParts.push(domainString);
                domainString = '';
                state = 0;
                x = 0;
            }
            if (pair[1] == 0){
                break;
            }
        }
        else{
            state = 1;
            expectedLength = pair[1];
        }
        y++;
    }
    let recordType = data.slice(y, y+2);
    return [domainParts, recordType];
}
``` 
While all this processing is done we keep track of the bytes examined using *y* variable. Once we hit the 00 terminator of the label, we get the next two bytes which tells us the Record Type questioned.

*getRecords* further relies on the Zone file parser which has been already described. *getRecords* finally provides us with records parsed from DNS Zone file, record type, domain questioned, and askedRecord.

We filter the results by  recordType and askedRecord. Once we have the desired results, we count them and set ANCOUNT
```js
    let askedRecords = recordsResult[qt].filter(ele => ele.name == askedRecord); 
    let ANCOUNT = askedRecords.length.toString(16).padStart(4,0);
```
NSCOUNT and ARCOUNT are set to zero as they are not related to our basic implementation.
```js
    let NSCOUNT = new Buffer.from('0000', 'hex');

    let ARCOUNT = new Buffer.from('0000', 'hex');
```
Before sending the resource records, we need to also send the question asked in query as well. This responsibility lies on *buildQuestions* routine.
```js
function buildQuestion(domainParts, recordType) {
    let qBytes = '';

    for(let part of domainParts){
        let length = part.length;
        qBytes +=  length.toString(16).padStart(2, 0);
        for(let char of part){
            qBytes +=  char.charCodeAt(0).toString(16);
        }
    }

    qBytes += '00';

    qBytes += getRecordTypeHex(recordType)

    qBytes +=  '00' + '01';

    return qBytes;
}
```
We iterate over the *domainParts*, get the length. Afte getting the length we further get the single character in domain label and convert it into hex. The hex string we have got so far is terminated by 00 condition, telling the client that domain label is over. Further appending 0001 to the string indicates the end of question section.

