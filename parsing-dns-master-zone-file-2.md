---
nav_order: 4
---
## Parsing DNS Zone Master File: Part 2
First part of the guide about parsing DNS Zone Master file is [here](https://engineerhead.github.io/dns-server/parsing-dns-master-zone-file-1). We are going to discuss *processRr* function.


	function processRr(splittedLine , containsTtl, previousTtl, previousName, origin, ttl) 

	{
					  
		let rr = {};

		let totalLength = splittedLine.length;
		  
		let isMx = Number(splittedLine[totalLength -2]); 

	    switch (totalLength) {
	      case 5:
	        for (let index = 0; index < totalLength; index++) {
	          const element = splittedLine[index];
	          if (!element.includes('.')) {
	            if(parseInt(element)){
	              if(!isMx){
	                containsTtl = true;
	                previousTtl = element;
	                splittedLine.splice(index, 1);
	              }
	              break;
	            }
	          } 
	          
	          
	        }
	        
	        if (!isMx) {
	          previousName =splittedLine[0];
	          rr.class = splittedLine[1];
	          rr.type = splittedLine[2];
	          rr.data = splittedLine[3];
	        }
	        
	        break;
	      case 4:
	        
	        for (let index = 0; index < totalLength; index++) {
	          const element = splittedLine[index];
	          if (!element.includes('.')) {
	            if(parseInt(element)){
	              if(!isMx){  
	                containsTtl = true;
	                previousTtl = element;
	                splittedLine.splice(index, 1);
	              }
	              break;
	            }
	          } 
	          
	          
	        }
	        
	        if(containsTtl){ //Name is missing
	          rr.class = splittedLine[0];
	          rr.type = splittedLine[1];
	          rr.data = splittedLine[2]; 

	        }
	        else{
	          if(isMx){
	            previousName = "@";
	            rr.class = splittedLine[0];
	            rr.type = splittedLine[1];
	            rr.preference = splittedLine[2];
	            rr.data = splittedLine[3];
	            
	          }else{
	            previousName = splittedLine[0];
	            rr.class = splittedLine[1];
	            rr.type = splittedLine[2];
	            rr.data = splittedLine[3];
	          }
	          
	        }
	        
	        break;
	      case 3:
	        rr.class = splittedLine[0];
	        rr.type = splittedLine[1];
	        rr.data = splittedLine[2];
	        
	        break;
	      case 2:
	        break; 
	      default:
	        break;
	    }
	    rr.name = previousName || origin;
	    rr.ttl =  previousTtl || ttl;

	    return [rr, previousName, previousTtl];
	}

First! We need to get the length of items of a resource record. It will decide which items the resource record contains and which are missing. *isMx* flag checks if the second last item of resource record is integer. If it is integer then we are dealing with MX record.

    if (!element.includes('.')) {
       if(parseInt(element)){
         if(!isMx){
           containsTtl = true;
           previousTtl = element;
           splittedLine.splice(index, 1);
         }
         break;
       }
     }

Main processing is done by iterating over the items of resource record one by one. First we check if the element doesn't contain a '.' to exclude IP address. Further, we check that if item is an integer and the record is not MX, then we have TTL item. We set the *containsTtl* flag, extract the TTL value and remove it from the items array.

    if (!isMx) {
      previousName =splittedLine[0];
      rr.class = splittedLine[1];
      rr.type = splittedLine[2];
      rr.data = splittedLine[3];
    }
    else{
    //TODO
    }

If the record is not of type MX then we extract the relevant record's values. In other case meaning the record is of type MX, the extraction of relevant values is on TODO list.

    case 4:
	        
    for (let index = 0; index < totalLength; index++) {
      const element = splittedLine[index];
      if (!element.includes('.')) {
        if(parseInt(element)){
          if(!isMx){  
            containsTtl = true;
            previousTtl = element;
            splittedLine.splice(index, 1);
          }
          break;
        }
      } 
      
      
    }
    
    if(containsTtl){ //Name is missing
      rr.class = splittedLine[0];
      rr.type = splittedLine[1];
      rr.data = splittedLine[2]; 

    }
    else{
      if(isMx){
        previousName = "@";
        rr.class = splittedLine[0];
        rr.type = splittedLine[1];
        rr.preference = splittedLine[2];
        rr.data = splittedLine[3];
        
      }else{
        previousName = splittedLine[0];
        rr.class = splittedLine[1];
        rr.type = splittedLine[2];
        rr.data = splittedLine[3];
      }
      
    }
    
    break;

In case the resource record contains 4 items, either name or TTL is missing. As. described earlier, we try to extract TTL if it is not missing. If we hit TTL value that means name is missing and it would be set to either the value from previous record or origin. The name and TTL of the resource record are set at the end of Switch statement.

    rr.class = splittedLine[0];
	rr.type = splittedLine[1];
	rr.data = splittedLine[2];

If the resource record is comprised of 3 items then we have both name and TTL missing. So! we are left with class, type and value items which are extracted as stated in above code. 

Once processing of resource record is done, we return the extracted resource record along with name and TTL values which are used in processing next resource record. Parsing of Master File is finished. In next guide, we will move on how to structure the responses by our DNS server for the client.


