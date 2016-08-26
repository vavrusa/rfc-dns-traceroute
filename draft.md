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

Client: A Stub Resolver, Forwarding Resolver, or Recursive Resolver. A client to a Recursive Resolver or a Forwarding Resolver.

Intermediate Nameserver: Any nameserver in between the Stub Resolver and the Authoritative Nameserver, such as a Recursive Resolver or a Forwarding Resolver.

Authoritative Nameserver:  A nameserver that has authority over one or more DNS zones.  These are normally not contacted by Stub Resolver or end user clients directly but by Recursive Resolvers. Described in [@!RFC1035] Section 6.

Server: An Intermediate Nameserver or Authoritative Nameserver.

Hop: A DNS message exchange between Client and Server, e.g. client sending query to resolver and potentially receiving an answer.

Resolution Path: A sequence of hops that are necessary to generate answer to original query, i.e. exchange between client and resolver, exchange between resolver and authoritative.

Leaf: A Server that doesn't make additional DNS requests in order to resolve the query, e.g. Authoritative Nameserver.

Open path: A path in which the last Hop is not leaf. 

Complete path: A path in which the last Hop is leaf.

TRACE: An abbreviated EDNS "TRACE" option defined in this document.

# Protocol

The path information is encoded as a sequence of TRACE options, one for each hop on the query resolution path. The order of TRACE options in the OPT data establishes the order of resolution hops, e.g. first TRACE option in the response corresponds to first hop.

Any Client on resolution path MAY attach an empty TRACE option to outgoing query, which starts the request to trace path starting from the next hop. Any Intermediate Nameserver compliant with this document that receives such query MUST copy the TRACE option to outgoing queries, and subsequently copy all non-empty TRACE options from upstream answers to final answer. If all such answers contained an empty TRACE option, the server MUST append a single empty TRACE option. This empty TRACE serves as a path terminator, and is not transitive.

## EDNS Support Requirement

This draft requires EDNS.

## Behaviour of Authoritative Nameservers

Authoritative Nameservers or other Leafs in DNS resolution path MUST append an empty TRACE option to signalise compliance with this draft. This enables client to determine whether the Resolution Path is complete or open.

If an Authoritative Nameserver generates an error response due to an internal failure, it MAY NOT append the TRACE option.

## Behaviour of Intermediate Nameservers

DNS resolvers and other non-leafs in DNS propagate TRACE option to outgoing queries. An upstream server may respond with a (possibly empty) sequence of TRACE options terminated with an empty TRACE option. If the terminator TRACE option is not present, it either means that upstream server is not compatible with this document or deliberately chose to left the Resolution Path open (e.g. for privacy, or to avoid exposing internal network). The resolver MUST NOT append terminator TRACE option to final answer in this situation, but still MUST append all non-empty TRACE options.

After each exchange of messages between Intermediate Nameserver and upstream Server, the Intermedia Server MUST add a TRACE describing the transaction.

It may happen that the Intermediate Server answers from local cache, in this case it MUST respond with an empty TRACE option as it is Leaf.

When upstream Server responds with an error response, it may not attach a TRACE. Intermediate Server should interpret this it as open path, as it cannot determine whether the upstream Server is Leaf or not.

## Behaviour of Clients

Client MAY interpret the sequence of TRACE options in the received answer to establish Resolution Path.
If the response doesn't contain TRACE option, it means that the upstream Server is not compliant with this document.

## The TRACE option

This protocol uses an EDNS0 [@!RFC6891]) option to encode information about Hop.
The option is structured as follows:

{#fig-trace-option type="ascii-art" align=center}

                +0 (MSB)                            +1 (LSB)
      +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
   0: |                          OPTION-CODE                          |
      +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
   2: |                         OPTION-LENGTH                         |
      +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
   4: |                           HOP-FLAGS                           |
      +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
   6: |           NSID-LENGTH         |            FAMILY             |
      +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
   8: |                             NSID...                           /
      +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
   /: |                        SOURCE ADDRESS...                      /
      +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
   /: |                     DESTINATION ADDRESS...                    /
      +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+

* (Defined in [@!RFC6891]) OPTION-CODE, 2 octets, for TRACE is 14 (0x00 0x0E).

* (Defined in [@!RFC6891]) OPTION-LENGTH, 2 octets, contains the length of the payload (everything after OPTION-LENGTH) in octets.

* HOP-FLAGS, 2 octets, contains bitfield of flags pertinent for this Hop defined in this document. It must be padded with 0 bits to end of the field.

* NSID-LENGTH, 1 octet, contains the length of the NSID field length.

* FAMILY, 2 octets, indicates the family of the address contained in the option, using address family codes as assigned by IANA in Address Family Numbers [Address_Family_Numbers]. The length and format of the address parts depends on the value of FAMILY. This document only defines the format for FAMILY 0 (undisclosed), FAMILY 1 (IP version 4) and 2 (IP version 6), which are as follows:

  * SOURCE ADDRESS, DESTINATION ADDRESS, variable number of octets, contains either an IPv4 or IPv6 address, depending on FAMILY, padding with 0 bits to pad to the end of the last octet needed. If the FAMILY 0 (undisclosed), the length of these fields is 0.

* An Intermediate Server receiving an TRACE option that uses far too many ADDRESS or NSID octets, MUST treat this option as malformed, and it MAY truncate the lengths of the fields to configured length.

* All fields are in network byte order ("big-endian", per [@!RFC1700], Data Notation).

* An empty TRACE option has OPTION-LENGTH equal to 0 and no other data.

# Examples

## Complete Path example

* Client (C) inserts an empty TRACE option to query to Resolver (R).
* Resolver (R) copies empty TRACE option to query to Authoritative (A).
* Authoritative is Leaf, and attaches an empty TRACE to response.
* Resolver receives the empty TRACE, and appends TRACE between Resolver and Authoritative: {FLAGS: 0, NSID-LENGTH: 1, FAMILY: 1, ['A'], [SRC-IP], [DST-IP]}
* Resolver establishes Closed Path and appends terminal TRACE: {}.
* Client receives answer with 2 TRACE options in OPT: {{FLAGS: 0, NSID-LENGTH: 1, FAMILY: 1, ['A'], [SRC-IP], [DST-IP]}, {}}
* Client establishes a Closed Path between Client - Resolver - Authoritative.

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

This mechanism exposes information about the Resolution Path to Client. Since the information trickles down in responses, no additional information about the downstream path is exposed to upstream Servers, unlike in [@RFC7871], Section 11.1.

Any Intermediate Nameserver MAY hide complete or partial information about upstream Path, for example if the upstream is in private network, or its location should not be disclosed. 

Any Intermediate Nameserver MAY strip or modify information about upstream path, the trust model is similar to DNS without DNSSEC as the OPT record encoding EDNS data (including TRACE) is not signed.

TBD

# Performance Considerations

Appending TRACE options increases response size. Any Server MAY choose to limit availability to queries over TCP, [@!RFC7858] DNS over Transport Layer Security, or queries containing valid [@!RFC7873] DNS Cookies.

TBD

# Acknowledgements

# Notes

[@RFC4892] identification through special names in CHAOS class is not applicable as the special zones are not part of the Internet class namespace.

{backmatter}

[Address_Family_Numbers]: http://www.iana.org/assignments/address-family-numbers/address-family-numbers.xhtml

