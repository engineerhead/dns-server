## How to Build DNS Server in X Programming Language

DNS stands for Domain Name Service which is like the phone book of the Internet. Users access the websites on the Internet through domain names while Web Browsers use IP addresses. DNS turns domain names into numerical IP addresses. For example, if user types example.com in a web browser, a server turns that human readable name to the attached IP address which looks like this 93.184.216.34.

 Before DNS, Stanford Research Institute maintained a file named HOSTS.TXT. The file contained the host names and corresponding numerical address of the computers. As the Internet grew, maintaining a single centralised host file became cumbersome. In 1983, Paul Mockapetris created the Domain Name System which saw refinements over time[\[1\]](https://en.wikipedia.org/wiki/Domain_Name_System#History).

Web browsing and other internet activities depend upon DNS to provide the relevant information required to connect users to remote hosts. DNS mapping is distributed in a hierarchy of authorities/zones which will be explained later when we get to the recursive DNS resolver.

This guide came into being as a goal to utilise free time and to understand DNS more deeply. The guides don't describe the whole journey and obviously the server implementation is for educational purposes. Final goal is to implement the toy DNS server in multiple languages. First language of choice is Javscript(Node JS)

- [**DNS Zone Master File**](https://engineerhead.github.io/dns-server/dns-zone-master-file-format) 

- [**Parsing DNS Zone Master File: Part 1**](https://engineerhead.github.io/dns-server/parsing-dns-master-zone-file-1)

- [**Parsing DNS Zone Master File: Part 2**](https://engineerhead.github.io/dns-server/parsing-dns-master-zone-file-2)


Resources

 - [howDns](https://github.com/howCodeORG/howDNS)
 - [RFC 1035](https://datatracker.ietf.org/doc/html/rfc1035)
 - [RFC 1034](https://datatracker.ietf.org/doc/html/rfc1034)
 - [Wireshark](http://wireshark.org)

