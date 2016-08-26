% Title = "DNS Traceroute"
% abbrev = "dns-traceroute"
% category = "std"
% docName = "draft-vavrusa-dnsop-dns-traceroute-00"
% ipr= "trust200902"
% area = "Internet"
% workgroup = ""
% keyword = ["DNS"]
%
% date = 2016-03-21T00:00:00Z
%
% [[author]]
% initials="M."
% surname="Vavrusa"
% fullname="Marek Vavrusa"
% #role="editor"
% organization = "CloudFlare Inc."
%   [author.address]
%   email = "mvavrusa@cloudflare.com"
%   [author.address.postal]
%   street = "101 Townsend St."
%   city = "San Francisco"
%   code = "94107"
%   country = "USA"

.# Abstract

This document describes mechanism for path discovery in DNS query resolution process between the query sender and the authoritative source of the DNS response.

{mainmatter}

# Introduction

[@RFC5001] introduced the NSID option for unique identification of DNS servers, it is however not transitive, so the recursive DNS servers are prohibited from adding NSID information of the authoritative servers contacted. Section 3.2. left transitive variant of this mechanism undefined.

The implication is that the stub resolvers can only trace resolution problems to the first recursive server or forwarder, where the traceability ends. This poses a significant problem when investigating name resolution performance or failures, as the source of the problem is hidden from the client.

An ad-hoc solution to part of the problem is a non-standard extension to authoritative DNS servers that returns the source address and either arbitrary identification of the DNS server instance or destination address, such as "whoami.akamai.net". The drawback is that additional query to special zone is required, only part of the resolution path is visible, and the special zone does not uniquely identify the authoritative server.

This draft proposes a mechanism to store complete resolution path information as EDNS option in a way that provides end to end traceability for DNS clients - a "traceroute" for DNS.

## Requirements

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in [@RFC2119].

## Terminology

The reader is assumed to be familiar with the basic DNS concepts described in [@!RFC1034], [@!RFC1035], [@!RFC2181] and [@!RFC6891]. NSID and server identification problem is described in [@RFC5001].

* Hop is used in this document to represent a DNS message exchange between two parties, e.g. client sending query to resolver and receiving an answer.

* Path is defined as a sequence of hops that are necessary to generate answer to original query, i.e. exchange between client and resolver, exchange between resolver and authoritative.

* Leaf is a DNS server that doesn't make additional DNS requests in order to resolve the query, e.g. traditional authoritative DNS server.

* Open path is such path where the last hop is not leaf. 

* Complete path is such path where the last hop is leaf.

* TRACE is used to abbreviate the a EDNS option TRACE defined in this document.

# Protocol

The path information is encoded as a sequence of TRACE options, one for each hop on the query resolution path. The order of TRACE options in the OPT data establishes the order of resolution hops, e.g. first TRACE option in the response corresponds to first hop.

Any DNS software on resolution path MAY attach an empty TRACE option to outgoing query, which starts the request to trace path starting from the next hop. Any DNS server compliant with this document that receives such query MUST copy the TRACE option to outgoing queries, and subsequently copy all non-empty TRACE options from upstream answers to final answer. If all such answers contained an empty TRACE option, the server MUST append a single empty TRACE option. This empty TRACE serves as a path terminator, and is not transitive.

## EDNS Support Requirement

This draft requires EDNS.

## Behaviour of authoritative servers

Authoritative DNS servers or other leafs in DNS resolution path MUST append an empty TRACE option to signalise compliance with this draft. This enables client to determine whether the resolution path is complete or open.

## Behaviour of resolvers

DNS resolvers and other non-leafs in DNS propagate TRACE option to outgoing queries. An upstream server may respond with a (possibly empty) sequence of TRACE options terminated with an empty TRACE option. If the terminator TRACE option is not present, it either means that upstream server is not compatible with this document or deliberately chose to left the resolution path open (e.g. for privacy, or to avoid exposing internal network). The resolver MUST NOT append terminator TRACE option to final answer in this situation, but still MUST append all non-empty TRACE options.

After each exchange of messages between resolver and upstream server, the resolver MUST add TRACE describing the transaction.

It may happen that resolver answers from cache, in this case it MUST behave like a leaf-node and respond with an empty TRACE option.

## Behaviour of clients

Client is an actor in DNS resolution that appended an empty TRACE option to query to indicate the interest in such information. Any on-path resolver may also be a client.

Clients interpret the sequence of TRACE options in received answer to establish resolution path.

## The TRACE option

TBD

## Presentation format

TBD

# Examples

TBD

# Use cases

TBD: Remove this section before publication.

* Debugging failures on resolution path
* Clients consume the TRACE information for detailed error messages
* Test end-end support for new DNS functionality (e.g. if all servers on path support it)
* Path maximum MTU discovery
* Mapping DNS global infrastructure
* Probe resolver cache hit ratios

# Security Considerations

This mechanism exposes information about the DNS resolution path to client. Since the information trickles down in responses, no additional information about the downstream path is exposed to upstream servers.

Any DNS server on resolution path may hide information about upstream path if the upstream is in private network or its location should not be disclosed. 

Any DNS server on resolution path may strip or modify information about upstream path, the trust model is similar to DNS without DNSSEC as the OPT record encoding EDNS data (including TRACE options) is not signed.

TBD

# Performance Considerations

TBD

# Acknowledgements

# Notes

[@RFC4892] identification through special names in CHAOS class is not applicable as the special zones are not part of the Internet class namespace.

{backmatter}


