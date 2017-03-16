---
title: Direct Client-to-Client Protocol (DCC)
layout: default
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

<div id="printable-toc" style="display: none"></div>


---


# Introduction

The Direct Client-to-Client Protocol (DCC) has been the primary method of establishing connections directly between IRC clients for a long time now. Once established, DCC connections bypass the IRC network and servers, allowing for all sorts of data to be transferred between clients including files and direct chat sessions.

There have been many extensions to DCC through the years, such as XDCC and others. This document intends to describe DCC as it works today, and provide a specification for new client authors implementing this feature.


---


# Architecture

[CTCP](/ctcp.html) messages are used to initiate DCC sessions. Specifically, the [`DCC`](/ctcp.html#dcc) message is used to start and control DCC sessions.

This section details the types of DCC available, and how to open DCC sessions.


## DCC Query Syntax

The initial CTCP `DCC` query message has this format:

    DCC <type> <argument> <address> <port>

`<type>` contains the type of DCC being initiated, such as `CHAT` or `SEND`. `<argument>` refers to a type-specific kind of argument, such as a filename. `<address>` refers to the host which should be connected to, and `<port>` refers to the port on which the connection should be established.

Note that for this to work, the querying client MUST know its' own public host address, or the address that the other client can use to access it. Clients have discovered this in various ways through the years, and this section doesn't yet describe how to do so. However, clients `MUST NOT` try to discover this through the [`RPL_WELCOME`](/index.html#rpl_welcome-001) numeric, as the prevelance of spoofed hostnames makes this infeasible and introduces issues.


## DCC CHAT

`CHAT` is used to establish chat sessions directly between clients. It should be noted that **DCC CHAT does not use any form of encryption and SHOULD be avoided.**

### Initiating Sessions

To initiate a `DCC CHAT` session, send a `CTCP` query with the format:

    DCC CHAT <unused> <host> <port>

Where `<unused>` is a holding string – we recommend just using `"chat"` here. `<host>` and `<port>` are the host and the port the recipient will connect to, if they want to establish the connection.

After receiving the query, the receiver will have the option of accepting or rejecting the chat request. End users MUST be given the option to either accept or ignore this request, as opening it will expose their public IP address.

To accept a given chat request, open a TCP connection to the given port. To reject a given request, simply ignore the query and do not respond to it.

### Sending Messages

After opening the direct TCP connection, clients will send lines to each other separated by the pair of characters `CR` `('\r', 0x13)` and `LF` `('\n', 0x10)`.

There are no prepended commands or verbs such as `PRIVMSG` and `NOTICE`.

#### ACTION

If one wishes to perform a standard [`CTCP ACTION`](/ctcp.html#action)-like message, they should prefix the line with `"\x01ACTION "`. That is, the standard CTCP delimiter `('\x01', 0x01)`, the verb `"ACTION"`, and a single space, before sending the client's message.

Clients that receive a line prefixed with `"\x01ACTION "` MUST display that line as a standard [`CTCP ACTION`](/ctcp.html#action) message would be displayed.

*Example:*

      Raw:        \x01ACTION writes a specification

      Formatted:  * dan writes a specification


## DCC SEND

`SEND` is used to send another client a given file. This is done directly between clients to avoid the overhead of having to transfer files through the IRC server. It should be noted that **DCC SEND does not use any form of encryption and SHOULD be avoided.**

### Initiating Sessions

To initiate a `DCC SEND` session, send a `CTCP` query with the format:

    DCC SEND <filename> <host> <port>

`<filename>` is the filename of the file to be sent. `<host>` and `<port>` are the host and the port the recipient will connect to, if they want to establish the connection.

After receiving the query, the receiver will have the option of accepting or rejecting the file send request. End users MUST be given the option to either accept or ignore this request, as opening it will expose their public IP address, and automatically receiving certain files may be used to exploit vulnerabilities.

Clients SHOULD NOT allow saving files into system directories, directories that could affect the operation of the IRC client or the system as a whole. End users MUST also be given the option to rename the file and save it under a different filename.

To accept a given chat request, open a TCP connection to the given port. To reject a given request, simply ignore the query and do not respond to it.

### Sending The File

After opening the direct TCP connection, the sending client sends the raw bytes of the file over the connection.











---

---

---

---

---

---

---


# DCC Sessions

[CTCP](/ctcp.html) messages are used to initiate DCC sessions. Specifically, the [`DCC`](/ctcp.html#dcc) message is used to start and control DCC sessions.

To open a DCC session 


# Explain XDCC, SDCC, etc




