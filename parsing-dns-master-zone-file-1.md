
## Parsing DNS Zone Master File: Part 1
DNS Zone master file's structure has been discussed in [previous guide](https://engineerhead.github.io/dns-server/dns-zone-master-file-format). There are some other rules which we need to follow.

 - There can be only one SOA record in master file and it needs to be
   defined at the top after $ORIGIN or $TTL directives.

Let's dive into the code now.

       import fs from 'fs';
       import readline from 'readline';

We need two modules from Node's standard library. First is [fs](https://nodejs.org/dist/latest-v18.x/docs/api/fs.html) and second is [readline](https://nodejs.org/dist/latest-v18.x/docs/api/readline.html). fs is needed to access the master file from filesystems while readline will helps us iterated overs the file contents line by line. 

	  async function processBindFile(filePath) {}
    
Next we define an async function *processBindFile* which is going to do all the work. It takes *filePath* as a parameter which specifies the master file. 

	const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({
					    input: fileStream,
					    crlfDelay: Infinity
				});

*fileStream* holds the file data in a stream format. *rl* creates the necessary readable stream to access file contents asynchronously. 

    

    let origin;
    let ttl;
    let previousTtl;
    let previousName;

    let records = [];
    let recordsType = ['NS', 'A', 'CNAME', 'MX'];
    recordsType.forEach(element => {
      records[element] = [];
    })

    let soa = {};
    let soaLine = 0;
    let multiLineSoa = false;
    
    let containsTtl = false;

Necessary variables are created which are going to hold resource records. Some other variables are created to assist in parsing the records.
			    
	for await (const line of rl) {  
      if (line.length > 1){
      }
    }
Contents of the master file are read line by line and processed if the line is not empty.

	let commentedLine = false;
    let l = line.trim()
                 .replace(/\t/g, ' ')
                 .replace(/\s+/g, ' ');

    let commentIndex = l.indexOf(';');
    if(commentIndex != -1){
        if (commentIndex != 0) {
          let m = l.split(';');
          l = m[0];
        }
        else{
          commentedLine = true;
        }
        
    }

Once we get the line, some necessary house keeping is done by trimming the line, replacing tab characters and whitespace with a single space. After that, the location of comments is found out if there are any in the line. If the comment is somewhere besides start of the line, we split the line and ignore the commented part. Otherwise we set the *commentedLine* flag to true.


	 if (!commentedLine) {
         let splittedLine = l.split(' ');
         switch (splittedLine[0]) {
           case '$ORIGIN':
             origin = splittedLine[1];
             break;
          
          case '$TTL':
            ttl = splittedLine[1];
            break;
          
          case '$INCLUDE':
            break;
    }

If the *commentedLine* flag is set, we ignore the line. Next, we split the line by single space. As a result we get the items of resource record which are separated by space. We employ *switch* statement to parse the items. In case of $ORIGIN or $TTL directives, we set the relevant variables to the value obtained. $INCLUDE directive is not supported as of now.


	   default:
	     if (splittedLine.includes('SOA')){
	       previousName = splittedLine[0]
	       soa.mname = splittedLine[3];
	       soa.rname = splittedLine[4];
	       
	       if (splittedLine.includes(')')){
	         soa.serial = splittedLine[6]; 
	         soa.refresh = splittedLine[7];
	         soa.retry = splittedLine[8];
	         soa.expire = splittedLine[9];
	         soa.title = splittedLine[10];
	       }
	       else{
	         multiLineSoa= true;
	         soaLine++;
	         
	       }
	       
	     }

	     
*default* case is where heavy lifting of parsing is done. First, we are going to process *SOA* record if there is one. *SOA* record can be scattered on multiple lines or a single line. In case of single line, we find the opening *'('* and closing *')'* parenthesis on same line given below. 

> @	IN	SOA	dns1.example.com.	hostmaster.example.com. ( 2001062501 21600 3600 604800 86400 )    

*SOA* record is different from other resource records. In case of single line, we get the record values in one go otherwise we set the *multiLineSoa*  flag to true and increment the *soaLine* variable. Code for parsing multiline *SOA* record is below.

    if(multiLineSoa){
      switch (soaLine) {
        case 2:
          // console.log(splittedLine);
          soa.serial = splittedLine[0];
          break;
        case 3:
          soa.refresh = splittedLine[0];
          break;
        case 4:
          soa.retry = splittedLine[0];
          break;
        case 5:
          soa.expire = splittedLine[0];
          break;
        case 6:
          soa.ttl = splittedLine[0];
          break;
        default:
          break;
      }
      // console.log(splittedLine);
      if(splittedLine.includes(')')){
        multiLineSoa = false;
      }
      soaLine++;
    }

A *switch* condition is used to parse relevant value for the record items spread over multiple lines.


	@ IN SOA ns1.example.com. hostmaster.example.com. (
													2001062501 
													21600 
													3600 
													604800 
													86400
												)
 Once we found the closing parentheses, multiLineSoa flag is set to false and our processing of multi line SOA is done.

    recordsType.forEach(element => {
      if (splittedLine.includes(element)){
        
        let type = element;
        
        let rr;
        [rr, previousName, previousTtl] = processRr(splittedLine, containsTtl, previousTtl, previousName, origin, ttl);
        records[type].push(rr);
      }
    })

After SOA resource record is processed, we are left with single line resource records. Currently, resource record of type ['NS', 'A', 'CNAME', 'MX'] are supported.

	recordsType.forEach(element => {
        if (splittedLine.includes(element)){
         
         let type = element;
         
         let rr;
         [rr, previousName, previousTtl] = processRr(splittedLine, containsTtl, previousTtl, previousName, origin, ttl);
         
         records[type].push(rr);
       }
     });

The line is processed if it matches the supported resource records' definition. After matching, the line is passed to a function *processRr* which takes other arguments as well. We will go through the *processRr* function in next part of this guide.



 