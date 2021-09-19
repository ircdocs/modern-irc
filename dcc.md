---
title: Direct Client-to-Client Protocol (DCC)
layout: default
wip: true
copyrights:
  -
    name: "Daniel Oaks"
    org: "ircdocs"
    org_link: "http://ircdocs.horse/"
    email: "daniel@danieloaks.net"
    editor: true
---

{% include copyrights.html %}

<div class="note">
    <p>This document intends to be a useful overview and reference of DCC as it is implemented today. It is a <a href="./about.html#living-specification">living specification</a> which is updated in response to feedback and implementations as they change. This document describes existing behaviour and what we consider best practices for new software.</p>
    <p>If something written in here isn't interoperable with an IRC client you know of, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a>.</p>
</div>

<div class="warning">
    <p>NOTE: This is NOWHERE NEAR FINISHED and may be ENTIRELY INACCURATE. Dragons be here, insane stuff be here.</p>
    <p>Regardless of the accuracy of this specification, DCC in general is not encrypted (apart from the SDCC extension which is not widely-supported and does not verify any certificate details). I don't particularly like where DCC is at the moment, but with this document I'm hoping to start the discussion around properly encrypting direct connections, and/or building something that does so with the knowledge of what's currently out there.</p>
    <p>You can contribute by sending pull requests to our <a href="https://github.com/ircdocs/modern-irc">Github repository</a>!</p>
</div>

<div id="printable-toc" style="display: none"></div>


---


# Introduction

The Direct Client-to-Client Protocol (DCC) has been the primary method of establishing connections directly between IRC clients for a long time now. Once established, DCC connections bypass the IRC network and servers, allowing for all sorts of data to be transferred between clients including files and direct chat sessions.

There have been many extensions to DCC through the years, such as XDCC, SDCC and others. This document intends to describe DCC as it works today and provide a useful specification for new client authors implementing this feature.

If you are a new software author implementing this feature, please keep in mind that **DCC has no encryption.** If you must implement DCC, please look at the [SDCC](#secure-dcc-sdcc) section at the bottom of this document so that you can implement even the most minor security measures for this protocol.


---


# Architecture

[CTCP](/ctcp.html) messages are used to initiate DCC sessions. Specifically, the [`DCC`](/ctcp.html#dcc) message is used to start and control DCC sessions.

This section details the types of DCC available, and how to open DCC sessions.


## DCC Query Syntax

The initial CTCP `DCC` query message has this format:

    DCC <type> <argument> <host> <port>

`<type>` contains the type of DCC being initiated, such as `CHAT` or `SEND`. `<argument>` refers to a type-specific kind of argument, such as a filename. `<host>` represents to the IP address which should be connected to, and `<port>` refers to a valid port on which the connection should be established (the value of this parameter can also be `0`, in which case the rules below apply.

`<host>`, for legacy reasons, uses a 'fun' mixture of representations. For IPv4 hosts, this parameter is the string representation of the positive integer that is the IP address in network byte order (e.g. `127.0.0.1` is represented as `2130706433` in this param). For IPv6 hosts, clients instead support the standard, widely-implemented IPv6 hex representation separated by colons (e.g. `::1`).

Note that for DCC queries to work, the querying client MUST know its' own public host address, or the address that the other client can use to access it. Clients have discovered this in various ways through the years, and this section doesn't yet describe how to do so. However, clients `MUST NOT` try to discover this through the [`RPL_WELCOME`](/index.html#rpl_welcome-001) numeric, as the prevalence of spoofed hostnames used today makes this infeasible on most public networks and introduces issues.

### Port 0

When port 0 is advertised on a DCC query, it signals that the sending client wishes to open a connection but cannot (or does not wish to) explicitly offer a listening port. This is commonly called Reverse DCC or Firewall-bypassing DCC (we refer to it as Reverse DCC in this document).

When a client receives a reverse DCC query, it means that the sending client wants the receiving client to establish the connection instead (with a valid port number in the `<port>` parameter). If the receiving client wishes to continue, they'll send a request back to the client that originally sent them the query.

Reverse DCC interacts a bit strangely with the `RESUME` type, and is outlined below in the specific section.


## DCC CHAT

`CHAT` is used to establish chat sessions directly between clients. It should be noted that **plain DCC does not use any form of encryption and SHOULD be avoided.**

### Initiating Sessions

To initiate a `DCC CHAT` session, send a `CTCP` query with the format:

    DCC CHAT <unused> <host> <port>

Where `<unused>` is a holding string – we recommend just using `"chat"` here. `<host>` and `<port>` are the host and the port the recipient connect to in order to establish the connection.

After receiving the query, the receiver will have the option of accepting or rejecting the chat request. End users MUST be given the option to either accept or ignore this request, as opening it will expose their public IP address.

To accept a given chat request, open a TCP connection to the given port. To reject a given request, simply ignore the query and do not respond to it.

### Sending Messages

After opening the direct TCP connection, clients will send lines to each other separated by the pair of characters `CR` `('\r', 0x0D)` and `LF` `('\n', 0x0A)`.

There are no prepended commands or verbs such as `PRIVMSG` and `NOTICE`.

#### ACTION

If one wishes to perform a standard [`CTCP ACTION`](/ctcp.html#action)-like message, they should prefix the line with `"\x01ACTION "`. That is, the standard CTCP delimiter `('\x01', 0x01)`, the verb `"ACTION"`, and a single space, before sending the client's message.

Clients that receive a line prefixed with `"\x01ACTION "` MUST display that line as a standard [`CTCP ACTION`](/ctcp.html#action) message would be displayed.

*Example:*

      Raw:        \x01ACTION writes a specification

      Formatted:  * dan writes a specification


## DCC SEND

`SEND` is used to send another client a given file. This is done directly between clients to avoid the overhead of having to transfer files through the IRC server. It should be noted that **plain DCC does not use any form of encryption and SHOULD be avoided.**

### Initiating Sessions

To initiate a `DCC SEND` session, send a `CTCP` query with the format:

    DCC SEND <filename> <host> <port>

`<filename>` is the filename of the file to be sent. `<host>` and `<port>` are the host and the port the recipient connect to in order to establish the connection.

After receiving the query, the receiver will have the option of accepting or rejecting the file send request. End users MUST be given the option to either accept or ignore this request, as opening it will expose their public IP address, and automatically receiving files on certain systems may be used to exploit vulnerabilities.

Clients SHOULD NOT allow saving files into system directories, directories that could affect the operation of the IRC client or the system as a whole. Clients SHOULD instead restrict saved files to a single directory chosen by the user or purposefully chosen to be the destination of received DCC files. End users MUST also be given the option to rename the file and save it under a different filename.

To accept a given chat request, open a TCP connection to the given port. To reject a given request, simply ignore the query and do not respond to it.

### Sending The File

After opening the direct TCP connection, the sending client sends the raw bytes of the file over the newly-established connection.

### Resuming The Send

This section is not yet written.


## DCC RESUME

This section is not yet written.


## DCC ACCEPT

This section is not yet written.


---


# Extensions

These are various extensions that change how DCC connections are established and used. These are detailed here.


## Secure DCC (SDCC)

In this method, the verb `SCHAT` is used instead of `CHAT` and `SSEND` is used instead of `SEND`. When using secure DCC, the direct TCP connection uses TLS rather than plaintext.

Although it uses TLS, the certificate on either side is not verified in any way, which means this is still not secure by today's standards. However, it can help protect against dragnet data collection so it's still a definite step up from regular plaintext DCC.


## Reverse / Firewall-bypassing DCC

This type of DCC request (that we call Reverse DCC) is used to bypass NAT and similar issues. The functionality is described above in the [Port 0](#port-0) section and relevant part of the [DCC RESUME](#dcc-resume) section.


## Extended DCC (XDCC)

XDCC (originally an acronym for Xabi's DCC) is a set of additional commands to allow clients to list files available for download. As well, XDCC allows clients to request downloading a particular advertised file -- upon which a `DCC SEND` session will be established by the side advertising the file.
