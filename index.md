---
title: Modern IRC Client Protocol
html_title: IRC Client Protocol Specification
layout: default
wip: true
copyrights:
  -
    name: "Jack Allnutt"
    org: "Kiwi IRC"
    org_link: "https://kiwiirc.com/"
    email: "jack@allnutt.eu"
  -
    name: "Daniel Oaks"
    org: "ircdocs"
    org_link: "http://ircdocs.horse/"
    email: "daniel@danieloaks.net"
    editor: true
---

{% include copyrights.html %}

<div class="note">
    <p>This document intends to be a useful overview and reference of the IRC client protocol as it is implemented today. It is a <a href="./about.html#living-specifications">living specification</a> which is updated in response to feedback and implementations as they change. This document describes existing behaviour and what I consider best practices for new software.</p>
    <p>This <strong>is not a new protocol</strong> &ndash; it is the standard IRC protocol, just described in a single document with some already widely-implemented/accepted features and capabilities. Clients written to this spec will work with old and new servers, and servers written this way will service old and new clients.</p>
    <p>tl;dr if a new RFC was released today describing how IRC works, this is what I think it would look like.</p>
    <p>If something written in here isn't correct for or interoperable with an IRC server / network you know of, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a> or <a href="mailto:daniel@danieloaks.net">contact me</a>.</p>
</div>

<div class="warning">
    <p>NOTE: This is NOWHERE NEAR FINISHED. Dragons be here, insane stuff be here.</p>
    <p>You can contribute by sending pull requests to our <a href="https://github.com/ircdocs/modern-irc">GitHub repository</a>!</p>
</div>

<div id="printable-toc" style="display: none"></div>

---


# Introduction

The Internet Relay Chat (IRC) protocol has been designed over a number of years, with multitudes of implementations and use cases appearing. This document describes the IRC Client-Server protocol.

IRC is a text-based chat protocol which has proven itself valuable and useful. It is well-suited to running on many machines in a distributed fashion. A typical setup involves multiple servers connected in a distributed network. Messages are delivered through this network and state is maintained across it for the connected clients and active channels.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).


---


# IRC Concepts

This section describes concepts behind the implementation and organisation of the IRC protocol, which are useful in understanding how it works.


## Architectural

A typical IRC network consists of servers and clients connected to those servers, with a good mix of IRC operators and channels. This section goes through each of those, what they are and a brief overview of them.

### Servers

Servers form the backbone of IRC, providing a point to which clients may connect and talk to each other, and a point for other servers to connect to, forming an IRC network.

The most common network configuration for IRC servers is that of a spanning tree [see the figure below], where each server acts as a central node for the rest of the network it sees. Other topologies are being experimented with, but right now there are none widely used in production.

                               [ Server 15 ]  [ Server 13 ] [ Server 14 ]
                                     /                \         /
                                    /                  \       /
            [ Server 11 ] ------ [ Server 1 ]       [ Server 12 ]
                                  /        \          /
                                 /          \        /
                      [ Server 2 ]          [ Server 3 ]
                        /       \                      \
                       /         \                      \
               [ Server 4 ]    [ Server 5 ]         [ Server 6 ]
                /    |    \                           /
               /     |     \                         /
              /      |      \____                   /
             /       |           \                 /
     [ Server 7 ] [ Server 8 ] [ Server 9 ]   [ Server 10 ]

                                      :
                                   [ etc. ]
                                      :

<p class="figure">Format of a typical IRC network.</p>

There have been several terms created over time to describe the roles of different servers on an IRC network. Some of the most common terms are as follows:

* **Hub**: A 'hub' is a server that connects to multiple other servers. For instance, in the figure above, Server 2, Server 3, and Server 4 would be examples of hub servers.
* **Core Hub**: A 'core hub' is typically a hub server that connects fairly major parts of the IRC network together. What is considered a core hub will change depending on the size of a network and what the administrators of the network consider important. For instance, in the figure above, Server 1, Server 2, and Server 3 may be considered core hubs by the network administrators.
* **Leaf**: A 'leaf' is a server that is only connected to a single other server on the network. Typically, leafs are the primary servers that handle client connections. In the figure above, Servers 7, 8, 10, 13, 14, and others would be considered leaf servers.
* **Services**: A 'services' server is a special type of server that extends the capabilities of the server software on the network (ie, they provide *services* to the network). Services are not used on all networks, and the capabilities typically provided by them may be built-into server software itself rather than being provided by a separate software package. Features usually handled by services include client account registration (as are typically used for [SASL authentication](#authenticate-message)), channel registration (allowing client accounts to 'own' channels), and further modifications and extensions to the IRC protocol. 'Services' themselves are **not** specified in any way by the protocol. What they provide depends entirely on the software packages being run.

A trend these days is to hide the real structure of a network from regular users. Networks that implement this may restrict or modify commands like [`MAP`](#map-message) so that regular users see every other server on the network as linked directly to the current server. When this is done, servers that do not handle client connections may also be hidden from users (hubs hidden in this way can be called 'hidden hubs'). Generally, IRC operators can always see the true structure of a network.

These terms are not generally used in IRC protocol documentation, but may be used by the administrators of a network in order to differentiate the servers they run and their roles.

### Clients

A client is anything connecting to a server that is not another server. Each client is distinguished from other clients by a unique nickname. See the protocol grammar rules for what may and may not be used in a nickname. In addition to the nickname, all servers must have the following information about all clients: The real name/address of the host that the client is connecting from, the username of the client on that host, and the server to which the client is connected.

#### Operators

To allow a reasonable amount of order to be kept within the IRC network, a special class of clients (operators) are allowed to perform general maintenance functions on the network. Although the powers granted to an operator can be considered as 'dangerous', they are nonetheless required.

The tasks operators can perform vary with different server software and the specific privileges granted to each operator. Some can perform network maintenance tasks, such as disconnecting and reconnecting servers as needed to prevent long-term use of bad network routing. Some operators can also remove a user from their server or the IRC network by 'force', i.e. the operator is able to close the connection between a client and server.

The justification for operators being able to remove users from the network is delicate since its abuse is both destructive and annoying. However, IRC network policies and administrators handle operators who abuse their privileges, and what is considered abuse by that network.

### Channels

A channel is a named group of one or more clients. All clients in the channel will receive all messages addressed to that channel. The channel is created implicitly when the first client joins it, and the channel ceases to exist when the last client leaves it. While the channel exists, any client can reference the channel using the name of the channel. Networks that support the concept of 'channel ownership' may persist specific channels in some way while no clients are connected to them.

Channel names are strings (beginning with specified prefix characters). Apart from the requirement of the first character being a valid [channel type](#channel-types) prefix character; the only restriction on a channel name is that it may not contain any spaces `(' ', 0x20)`, a control G / `BELL` `('^G', 0x07)`, or a comma `(',', 0x2C)` (which is used as a list item separator by the protocol).

There are several types of channels used in the IRC protocol. The first standard type of channel is a [regular channel](#regular-channels-), which is known to all servers that are connected to the network. The prefix character for this type of channel is `('#', 0x23)`. The second type are server-specific or [local channels](#local-channels-), where the clients connected can only see and talk to other clients on the same server. The prefix character for this type of channel is `('&', 0x26)`. Other types of channels are described in the [Channel Types](#channel-types) section.

Along with various channel types, there are also channel modes that can alter the characteristics and behaviour of individual channels. See the [Channel Modes](#channel-modes) section for more information on these.

To create a new channel or become part of an existing channel, a user is required to join the channel using the [`JOIN`](#join-message) command. If the channel doesn't exist prior to joining, the channel is created and the creating user becomes a channel operator. If the channel already exists, whether or not the client successfully joins that channel depends on the modes currently set on the channel. For example, if the channel is set to `invite-only` mode (`+i`), the client only joins the channel if they have been invited by another user or they have been exempted from requiring an invite by the channel operators.

Channels also contain a [topic](#topic-message). The topic is a line shown to all users when they join the channel, and all users in the channel are notified when the topic of a channel is changed. Channel topics commonly state channel rules, links, quotes from channel members, a general description of the channel, or whatever the [channel operators](#channel-operators) want to share with the clients in their channel.

A user may be joined to several channels at once, but a limit may be imposed by the server as to how many channels a client can be in at one time. This limit is specified by the [`CHANLIMIT`](#chanlimit-parameter) `RPL_ISUPPORT` parameter. See the [Feature Advertisement](#feature-advertisement) section for more details on `RPL_ISUPPORT`.

If the IRC network becomes disjoint because of a split between servers, the channel on either side is composed of only those clients which are connected to servers on the respective sides of the split, possibly ceasing to exist on one side. When the split is healed, the connecting servers ensure the network state is consistent between them.

#### Channel Operators

Channel operators (or "chanops") on a given channel are considered to 'run' or 'own' that channel. In recognition of this status, channel operators are endowed with certain powers which let them moderate and keep control of their channel.

Most IRC operators do not concern themselves with 'channel politics'. In addition, a large number of networks leave the management of specific channels up to chanops where possible, and try not to interfere themselves. However, this is a matter of network policy, and it's best to consult the [Message of the Day](#motd-message) when looking at channel management.

IRC servers may also define other levels of channel moderation. These can include 'halfop' (half operator), 'protected' (protected user/operator), 'founder' (channel founder), and any other positions the server wishes to define. These moderation levels have varying privileges and can execute, and not execute, various channel management commands based on what the server defines.

The commands which may only be used by channel moderators include:

- [`KICK`](#kick-message): Eject a client from the channel
- [`MODE`](#mode-message): Change the channel's modes
- [`INVITE`](#invite-message): Invite a client to an invite-only channel (mode +i)
- [`TOPIC`](#topic-message): Change the channel topic in a mode +t channel

Channel moderators are identified by the channel member prefix (`'@'` for standard channel operators, `'%'` for halfops) next to their nickname whenever it is associated with a channel (ie: replies to the `NAMES`, `WHO`, and `WHOIS` commands).

Specific prefixes and moderation levels are covered in the [Channel Membership Prefixes](#channel-membership-prefixes) section.


## Communication Types

This section describes how current implementations deliver different classes of messages.

This section ONLY deals with the spanning-tree topology, shown in the figure below. This is because spanning-tree is the topology specified and used in all IRC software today. Other topologies are being experimented with, but are not yet used in production by networks.

                              1--\
                                  A        D---4
                              2--/ \      /
                                    B----C
                                   /      \
                                  3        E

       Servers: A, B, C, D, E         Clients: 1, 2, 3, 4

<p class="figure">Sample small IRC network.</p>

### One-to-one communication

Communication on a one-to-one basis is usually only performed by clients, since most server-server traffic is not a result of servers talking only to each other.

Servers MUST be able to send a message from any one client to any other. It is REQUIRED that all servers be able to send a message in exactly one direction along the spanning tree to reach any client. Thus the path of a message being delivered is the shortest path between any two points on the spanning tree.

The following examples all refer to the figure above.

1. A message between clients 1 and 2 is only seen by server A, which sends it straight to client 2.

2. A message between clients 1 and 3 is seen by servers A, B, and client 3. No other clients or servers are allowed to see the message.

3. A message between clients 2 and 4 is seen by servers A, B, C, D, and client 4 only.

### One-to-many communication

The main goal of IRC is to provide a forum which allows easy and efficient conferencing (one to many conversations). IRC offers several means to achieve this, each serving its own purpose.

#### To A Channel

In IRC, the channel has a role equivalent to that of the multicast group; their existence is dynamic and the actual conversation carried out on a channel MUST only be sent to servers which are supporting users on a given channel. Moreover, the message SHALL only be sent once to every local link as each server is responsible for fanning the original message to ensure it will reach all recipients.

The following examples all refer to the above figure:

4. Any channel with a single client in it. Messages to this channel go to the server and then nowhere else.

5. Two clients in a channel. All messages traverse a path as if they were private messages between the two clients outside a channel.

6. Clients 1, 2, and 3 are in a channel. All messages to this channel are sent to all clients and only those servers which must be traversed by the message if it were a private message to a single client. If client 1 sends a message, it goes back to client 2 and then via server B to client 3.

#### To A Host/Server Mask

To provide with some mechanism to send messages to a large body of related users, host and server mask messages are available. These messages are sent to users whose host or server information match that of the given mask. The messages are only sent to locations where the users are, in a fashion similar to that of channels.

#### To A List

The least efficient style of one-to-many conversation is through clients talking to a 'list' of targets (client, channel, ask). How this is done is almost self-explanatory: the client gives a list of destinations to which the message is to be delivered and the server breaks it up and dispatches a separate copy of the message to each given destination.

This is not as efficient as using a channel since the destination list MAY be broken up and the dispatch sent without checking to make sure duplicates aren't sent down each path.

### One-To-All

The one-to-all type of message is better described as a broadcast message, sent to all clients or servers or both. On a large network of users and servers, a single message can result in a lot of traffic being sent over the network in an effort to reach all of the desired destinations.

For some class of messages, there is no option but to broadcast it to all servers to that the state information held by each server is consistent between them.

#### Client-to-Client

IRC Operators may be able to send a message to every client currently connected to the network. This depends on the specific features and commands implemented in the server software.

#### Client-to-Server

Most of the commands which result in a change of state information (such as channel membership, channel modes, user status, etc.) MUST be sent to all servers by default, and this distribution SHALL NOT be changed by the client.

#### Server-to-Server

While most messages between servers are distributed to all 'other' servers, this is only required for any message that affects a user, channel, or server. Since these are the basic items found in IRC, nearly all messages originating from a server are broadcast to all other connected servers.


---


# Connection Setup

IRC client-server connections work over TCP/IP. The standard ports for client-server connections are TCP/6667 for plaintext, and TCP/6697 for TLS connections.


---


# Server-to-Server Protocol Structure

Various server to server (S2S) protocols have been defined over the years, with [TS6](https://github.com/grawity/irc-docs/blob/725a1f05b85d7a935986ae4f49b058e9b67e7ce9/server/ts6.txt) and [P10](http://web.mit.edu/klmitch/Sipb/devel/src/ircu2.10.11/doc/p10.html) among the most popular (both based on the client-server protocol as described below). However, with the fragmented nature of server implementations, features, network designs and S2S protocols, right now it is impossible to define a single standard server to server protocol.


---


# Client-to-Server Protocol Structure

While a client is connected to a server, they send a stream of bytes to each other. This stream contains messages separated by `CR` `('\r', 0x13)` and `LF` `('\n', 0x10)`. These messages may be sent at any time from either side, and may generate zero or more reply messages.

Software SHOULD use the [UTF-8](http://tools.ietf.org/html/rfc3629) character encoding to encode and decode messages, with fallbacks as described in the [Character Encodings](#character-encodings) implementation considerations appendix.

Names of IRC entities (clients, servers, channels) are casemapped. This prevents, for example, someone having the nickname `'Dan'` and someone else having the nickname `'dan'`, confusing other users. Servers MUST advertise the casemapping they use in the [`RPL_ISUPPORT`](#feature-advertisement) numeric that's sent when connection registration has completed.


## Messages

An IRC message is a single line, delimited by with a pair of `CR` `('\r', 0x13)` and `LF` `('\n', 0x10)` characters.

- When reading messages from a stream, read the incoming data into a buffer. Only parse and process a message once you encounter the `\r\n` at the end of it. If you encounter an empty message, silently ignore it.
- When sending messages, ensure that a pair of `\r\n` characters follows every single message your software sends out.

---

Messages have this format:

      [@tags] [:source] <command> <parameters>

The specific parts of an IRC message are:

- **tags**: Optional metadata on a message, starting with `('@', 0x40)`.
- **source**: Optional note of where the message came from, starting with `(':', 0x3a)`. Also called the **prefix**.
- **command**: The specific command this message represents.
- **parameters**: If it exists, data relevant to this specific command.

These message parts, and parameters themselves, are separated by one or more ASCII SPACE characters `(' ', 0x20)`.

Most IRC servers limit messages to 512 bytes in length, including the trailing `CR-LF` characters. Implementations which include message tags allow an additional 512 bytes for the **tags** section of a message, including the leading `'@'` and trailing space character(s). There is no provision for continuation messages at this time.

---

The following sections describe how to process each part, but here are a few complete example messages:

      :irc.example.com CAP LS * :multi-prefix extended-join sasl

      @id=234AB :dan!d@localhost PRIVMSG #chan :Hey what's up!

      CAP REQ :sasl


### Tags

The **tags** part is optional. Messages may omit the part entirely. This message part starts with a leading `('@', 0x40)` character, which MUST be the first character of the message itself. The leading `('@', 0x40)` is stripped from the value before it's processed further.

This is the format of the **tags** part, as rough ABNF:

      <tags>          ::= '@' <tag> [';' <tag>]*
      <tag>           ::= <key> ['=' <escaped value>]
      <key>           ::= [ <vendor> '/' ] <sequence of letters, digits, hyphens (`-`)>
      <escaped value> ::= <sequence of any characters except NUL, CR, LF, semicolon (`;`) and SPACE>
      <vendor>        ::= <host>

Basically, a series of `<key>[=<value>]` segments, separated by `(';', 0x3b)`.

Here are some examples of tags sections and how they could be represented as [JSON](https://www.json.org/) objects:

      @id=123AB;rose         ->  {"id": "123AB", "rose": true}

      @url=;netsplit=tur,ty  ->  {"url": "", "netsplit": "tur,ty"}

For more information on processing tags – including the naming and registration of them, and how to escape values – see the IRCv3 [Message Tags specification](http://ircv3.net/specs/core/message-tags-3.2.html).


### Source

The **source** is optional and starts with a `(':', 0x3a)` character (which is stripped from the value), and if there are no tags it MUST be the first character of the message itself.

The source indicates the true origin of a message. If the source is missing from a message, it's is assumed to have originated from the client/server on the other end of the connection the message was received on.

Clients SHOULD NOT include a source when sending a message. If they do include one, the only valid source is the current nickname of the client.

Servers MAY include a source on any message, and MAY leave a source off of any message. Clients MUST be able to process any given message the same way whether it contains a source or does not contain one.


### Command

The **command** must either be a valid IRC command or a numeric (a three-digit number represented as text).

Information on specific commands / numerics can be found in the [Client Messages](#client-messages) and [Numerics](#numerics) sections, respectively.


### Parameters

**Parameters** (or 'params') are extra pieces of information added to the end of a message. These parameters generally make up the 'data' portion of the message. What specific parameters mean changes for every single message.

This is the format of the **parameters** part, as rough ABNF:

      params      =  *( SPACE middle ) [ SPACE ":" trailing ]
      nospcrlfcl  =  <sequence of any characters except NUL, CR, LF, colon (`:`) and SPACE>
      middle      =  nospcrlfcl *( ":" / nospcrlfcl )
      trailing    =  *( ":" / " " / nospcrlfcl )

Parameters are a series of values separated by one or more ASCII SPACE characters `(' ', 0x20)`. However, to allow a value itself to contain spaces, the final parameter can be prepended by a `(':', 0x3a)` character. If the final parameter is prefixed with a colon `':'`, the prefix is stripped and the rest of the message is treated as the final parameter, no matter what characters it contains.

Software SHOULD AVOID sending more than 15 parameters, as older client protocol documents specified this was the maximum and some clients may have trouble reading more than this. However, clients MUST parse incoming messages with any number of them.

Here are some examples of messages and how the parameters would be represented as [JSON](https://www.json.org/) lists:

      :irc.example.com CAP * LIST :         ->  ["*", "LIST", ""]

      CAP * LS :multi-prefix sasl           ->  ["*", "LS", "multi-prefix sasl"]

      CAP REQ :sasl message-tags foo        ->  ["REQ", "sasl message-tags foo"]

      :dan!d@localhost PRIVMSG #chan :Hey!  ->  ["#chan", "Hey!"]

      :dan!d@localhost PRIVMSG #chan Hey!   ->  ["#chan", "Hey!"]

As the last two examples show, a trailing parameter (a parameter prefixed with `':'`) is another regular parameter. Once the `':'` is stripped, software MUST just treat it as another param.




<!-- ### Parameters

Parameters (or 'params') are extra pieces of information added to the end of a message. These parameters generally make up the 'data' portion of the message. The meaning of specific parameters changes for every single message.

Older IRC protocol specifications explicitly limited the number of parameters to 15. However, today some clients and servers may return as many parameters as can fit in the message length limit. When sending parameters, try to send a max of 15 to not break older software. When receiving parameters (especially for clients), try not to place a limit on the number of incoming parameters you'll parse.

### Prefix

The prefix is used by servers to indicate the true origin of a message. If the prefix is missing from the message, it is assumed to have originated from the connection from which it was received.

Clients SHOULD NOT use a prefix when sending a message from themselves. If they use a prefix, the only valid prefix is the registered nickname associated with the client. If the source identified by the prefix cannot be found in the server's internal database, or if the source is registered from a different link than from which the message arrived, the server MUST ignore the message silently.

Clients MUST be able to correctly parse and handle any message from the server containing a prefix in the same way it would handle the message if it did not contain a prefix. In other words, servers MAY add a prefix to any message sent to clients, and clients MUST be able to handle this correctly.

### Tags

Tags are additional and optional metadata included with relevant messages.

Every message tag is enabled by a capability (as outlined in the [Capability Negotiation](#capability-negotiation) section). One capability may enable several tags if those tags are intended to be used together.

Each tag may have its own rules about how it can be used: from client to server only, from server to client only, or in both directions.

Servers MUST NOT add a tag to a message if the client has not requested the capability which enables the tag. Servers MUST NOT add a tag to a message before replying to a client's request (`CAP REQ`) for the capability which enables that tag with an acknowledgement (`CAP ACK`). If a client requests a capability which enables one or more message tags, that client MUST be able to parse the tags syntax.

Similarly, clients MUST NOT add a tag to messages before the server replies to the client's request (`CAP REQ`) with an acknowledgement (`CAP ACK`). If the server accepts a capability request which enables tags on messages sent from the client to the server, the server MUST be able to parse the tags syntax on incoming messages from clients.

Both clients and servers MAY parse supplied tags without any capabilities being enabled on the connection. They SHOULD ignore the tags of capabilities which are not enabled.

Clients that enable message tags MUST NOT fail to parse any message because of the presence of tags on that message. In other words, clients that enable message tags MUST assume that any message from the server may contain message tags, and must handle this correctly.

More information on the naming and registration of tags, including how to escape values, can be found in the IRCv3 [Message Tags specification](http://ircv3.net/specs/core/message-tags-3.2.html).

## Messages

Servers and clients send each other messages which may or may not generate a reply; client to server communication is essentially asynchronous in nature.

Each IRC message may consist of up to four main parts: tags (optional), the prefix (optional), the command, and the command parameters.

Clients MAY include a prefix of their nickname on messages they send (after connection registration has been completed). However, I'd avoid doing so as it makes the protocol more fragile and makes messages more likely to be misinterpreted by the server.

Servers may supply tags (when negotiated) and a prefix on any or all messages they send to clients.

Information on standard client messages are available in the [Client Messages](#client-messages) and [Numerics](#numerics) sections.

### Prefix

The prefix is used by servers to indicate the true origin of a message. If the prefix is missing from the message, it is assumed to have originated from the connection from which it was received.

Clients SHOULD NOT use a prefix when sending a message from themselves. If they use a prefix, the only valid prefix is the registered nickname associated with the client. If the source identified by the prefix cannot be found in the server's internal database, or if the source is registered from a different link than from which the message arrived, the server MUST ignore the message silently.

Clients MUST be able to correctly parse and handle any message from the server containing a prefix in the same way it would handle the message if it did not contain a prefix. In other words, servers MAY add a prefix to any message sent to clients, and clients MUST be able to handle this correctly.

### Command

The command must either be a valid IRC command or a three-digit number represented as text.

Information on specific commands can be found in the [Client Messages](#client-messages) section.

### Parameters

Parameters (or 'params') are extra pieces of information added to the end of a message. These parameters generally make up the 'data' portion of the message. The meaning of specific parameters changes for every single message.

Older IRC protocol specifications explicitly limited the number of parameters to 15. However, today some clients and servers may return as many parameters as can fit in the message length limit. When sending parameters, try to send a max of 15 to not break older software. When receiving parameters (especially for clients), try not to place a limit on the number of incoming parameters you'll parse. -->


<!-- ## Wire Format

The protocol messages are extracted from a contiguous stream of octets. A pair of characters, `CR` `('\r', 0x13)` and `LF` `('\n', 0x10)`, act as message separators. Empty messages are silently ignored, which permits use of the sequence CR-LF between messages.

The tags, prefix, command, and all parameters are separated by one (or more) ASCII space character(s) `(' ', 0x20)`.

The presence of tags is indicated with a single leading 'at sign' character `('@', 0x40)`, which MUST be the first character of the message itself. There MUST NOT be any whitespace between this leading character and the list of tags.

The presence of a prefix is indicated with a single leading colon character `(':', 0x3a)`. If there are no tags it MUST be the first character of the message itself. There MUST NOT be any whitespace between this leading character and the prefix

Most IRC servers limit lines to 512 bytes in length, including the trailing `CR-LF` characters. Implementations which include message tags allow an additional 512 bytes for the tags section of a message, including the leading `'@'` and trailing space character. There is no provision for continuation message lines.

The proposed [`LINELEN`](#linelen-parameter) `RPL_ISUPPORT` parameter lets a server specify the maximum allowed length of IRC lines, comprising of both the tags section and the rest of the message. However, use of this token is not widespread and is only used in an experimental server right now. -->

### Wire format in ABNF

Extracted messages are parsed into the components `tags`, `prefix`, `command`, and a list of parameters as described above. This section describes the rough ABNF for this message format, as well as extra parsing notes.

The rough ABNF representation for an IRC message is:

      message     =  [ "@" tags SPACE ] [ ":" prefix SPACE ] command
                     [ params ] crlf

      tags        =  tag *[ ";" tag ]
      tag         =  key [ "=" value ]
      key         =  [ vendor "/" ] 1*( ALPHA / DIGIT / "-" )
      value       =  *valuechar
      valuechar   =  <any octet except NUL, BELL, CR, LF, semicolon (`;`) and SPACE>
      vendor      =  hostname

      prefix      =  servername / ( nickname [ [ "!" user ] "@" host ] )

      command     =  1*letter / 3digit

      params      =  *( SPACE middle ) [ SPACE ":" trailing ]
      nospcrlfcl  =  <any octet except NUL, CR, LF, colon (`:`) and SPACE>
      middle      =  nospcrlfcl *( ":" / nospcrlfcl )
      trailing    =  *( ":" / " " / nospcrlfcl )


      SPACE       =  %x20 *( %x20 )   ; space character(s)
      crlf        =  %x0D %x0A        ; "carriage return" "linefeed"

NOTES:

1. `<SPACE>` consists only of ASCII SPACE character(s) `(' ', 0x20)`. Specifically notice that TABULATION, control characters, and any other whitespace (including Unicode whitespace characters) are not considered a part of `<SPACE>`.
2. After extracting the parameter list, all parameters are equal, whether matched by `<middle>` or `<trailing>`. `<trailing>` is just a syntactic trick to allow `SPACE` `(0x20)` characters within a parameter.
3. The `NUL` `(0x00)` character is not special in message framing, but as it would cause extra complexities in traditional C string handling, it is not allowed within messages.
4. The last parameter may be an empty string.
5. Use of the extended prefix (`[ [ "!" user ] "@" host ]`) is only intended for server to client messages in order to provide clients with more useful information about who a message is from without the need for additional queries. Servers SHOULD provide this extended prefix on any message where the prefix contains a nickname.
6. Software SHOULD AVOID sending messages with more than 14 `<middle>` parts, but MUST parse incoming messages with any number of them as in the ABNF above.

Most protocol messages specify additional semantics and syntax for the extracted parameter strings dictated by their position in the list. As an example, for many server commands, the first parameter of that message is a list of targets.

Please also see our [Message Parsing and Assembly](#message-parsing-and-assembly) implementation considerations, for things you should keep in mind while writing software that parses or assembles IRC messages.

<div class="warning">
    TODO: This section is unfinished. Defining the various names (nickname, username, hostname) and such are likely to require quite a bit of thought. This is to cater for how software can let IRC operators use almost anything in them including formatting characters, etc. We should also make sure that the ABNF block above is correct and defined properly.
</div>


## Numeric Replies

Most messages sent from a client to a server generates a reply of some sort. The most common form of reply is the numeric reply, used for both errors and normal replies. Distinct from a normal message, a numeric reply MUST contain the sender prefix and use a three-digit numeric as the command. A numeric reply SHOULD contain the target of the reply as the first parameter of the message. A numeric reply is not allowed to originate from a client.

In all other respects, a numeric reply is just like a normal message. A list of numeric replies is supplied in the [Numerics](#numerics) section.


## Wildcard Expressions

When wildcards are allowed in a string, it is referred to as a "mask".

For string matching purposes, the protocol allows the use of two special characters: `('?', 0x3F)` to match one and only one character, and `('*', 0x2A)` to match any number of any characters. These two characters can be escaped using the `('\', 0x5C)` character.

The ABNF syntax for this is:

      mask        =  *( nowild / noesc wildone / noesc wildmany )
      wildone     =  %x3F
      wildmany    =  %x2A
      nowild      =  %x01-29 / %x2B-3E / %x40-FF
                       ; any octet except NUL, "*", "?"
      noesc       =  %x01-5B / %x5D-FF
                       ; any octet except NUL and "\"

      matchone    =  %x01-FF
                       ; matches wildone
      matchmany   =  *matchone
                       ; matches wildmany

Examples:

      a?c         ; Matches any string of 3 characters in length starting
                  with "a" and ending with "c"

      a*c         ; Matches any string of 2 or more characters in length
                  starting with "a" and ending with "c"


---


# Connection Registration

Immediately upon establishing a connection the client must attempt registration, without waiting for any banner message from the server.

Until registration is complete, only a limited subset of commands SHOULD be accepted by the server. This is because it makes sense to require a registered (fully connected) client connection before allowing commands such as [`JOIN`](#join-message), [`PRIVMSG`](#privmsg-message) and others.

The recommended order of commands during registration is as follows:

1. `CAP LS 302`
2. `PASS`
3. `NICK` and `USER`
4. [Capability Negotiation](#capability-negotiation)
5. `SASL` (if negotiated)
6. `CAP END`

The commands specified in steps 1-3 should be sent on connection. If the server supports [capability negotiation](#capability-negotiation) then registration will be suspended and the client can negotiate client capabilities (steps 4-6). If the server does not support capability negotiation then registration will continue immediately without steps 4-6.

1. If the server supports capability negotiation, the [`CAP`](#cap-message) command suspends the registration process and immediately starts the [capability negotiation](#capability-negotiation) process. `CAP LS 302` means that the client supports [version `302`](http://ircv3.net/specs/core/capability-negotiation-3.2.html) of client capability negotiation. The capability negotiation process is resumed when the client sends `CAP END` to the server.

2. The [`PASS`](#pass-message) command is not required for the connection to be registered, but if included it MUST precede the latter of the NICK and USER commands.

3. The [`NICK`](#nick-message) and [`USER`](#user-message) commands are used to set the user's nickname, username and "real name". Unless the registration is suspended by a `CAP` negotiation, these commands will end the registration process.

4. The client should request advertised capabilities it wishes to enable here.

5. If the client supports [`SASL` authentication](#authenticate-message) and wishes to authenticate with the server, it should attempt this after a successful [`CAP ACK`](#cap-message) of the `sasl` capability is received and while registration is suspended.

6. If the server support capability negotiation, [`CAP END`](#cap-message) will end the negotiation period and resume the registration.

If the server is waiting to complete a lookup of client information (such as hostname or ident for a username), there may be an arbitrary wait at some point during registration. Servers SHOULD set a reasonable timeout for these lookups.

Additionally, some servers also send a [`PING`](#ping-message) and require a matching [`PONG`](#pong-message) from the client before continuing. This exchange may happen immediately on connection and at any time during connection registration, so clients MUST respond correctly to it.

Upon successful completion of the registration process, the server MUST send, in this order, the [`RPL_WELCOME`](#rplwelcome-001) `(001)`, [`RPL_YOURHOST`](#rplyourhost-002) `(002)`, [`RPL_CREATED`](#rplcreated-003) `(003)`, [`RPL_MYINFO`](#rplmyinfo-004) `(004)`, and at least one [`RPL_ISUPPORT`](#rplisupport-005) `(005)` numeric to the client. The server SHOULD then respond as though the client sent the [`LUSERS`](#lusers-message) command and return the appropriate numerics. If the user has client modes set on them automatically upon joining the network, the server SHOULD send the client the [`RPL_UMODEIS`](#rplumodeis-221) `(221)` reply. The server MAY send other numerics and messages. The server MUST then respond as though the client sent it the [`MOTD`](#motd-message) command, i.e. it must send either the successful [Message of the Day](#motd-message) numerics or the [`ERR_NOMOTD`](#errnomotd-422) numeric.


---


# Feature Advertisement

IRC servers and networks implement many different IRC features, limits, and protocol options that clients should be aware of. The [`RPL_ISUPPORT`](#rplisupport-005) `(005)` numeric is designed to advertise these features to clients on connection registration, providing a simple way for clients to change their behaviour based on what is implemented on the server.

Once client registration is complete, the server MUST send at least one `RPL_ISUPPORT` numeric to the client. The server MAY send more than one `RPL_ISUPPORT` numeric and consecutive `RPL_ISUPPORT` numerics SHOULD be sent adjacent to each other.

Clients SHOULD NOT assume a server supports a feature unless it has been advertised in `RPL_ISUPPORT`. For `RPL_ISUPPORT` parameters which specify a 'default' value, clients SHOULD assume the default value for these parameters until the server advertises these parameters itself. This is generally done for compatibility reasons with older versions of the IRC protocol that do not specify the `RPL_ISUPPORT` numeric and servers that do not advertise those specific tokens.

For more information and specific details on tokens, see the [`RPL_ISUPPORT`](#rplisupport-005) reply.

A list of `RPL_ISUPPORT` parameters is available in the [`RPL_ISUPPORT` Parameters](#rplisupport-parameters) section.


---


# Capability Negotiation

Over the years, various extensions to the IRC protocol have been made by server programmers. Often, these extensions are intended to conserve bandwidth, close loopholes left by the original protocol specification, or add new features for users or for server administrators. Most of these changes are backwards-compatible with the base protocol specifications: A command may be added, a reply may be extended to contain more parameters, etc. However, there are extensions which are designed to change protocol behaviour in a backwards-incompatible way.

Capability Negotiation is a mechanism for the negotiation of protocol extensions, known as **client capabilities**, that makes sure servers implementing backwards-incompatible protocol extensions still interoperate with existing clients, and vice-versa.

Clients implementing capability negotiation will still interoperate with servers that do not implement it; similarly, servers that implement capability negotiation will successfully communicate with clients that do not implement it.

IRC is an asynchronous protocol, which means that clients may issue additional IRC commands while previous commands are being processed. Additionally, there is no guarantee of a specific kind of banner being issued upon connection. Some servers also do not complain about unknown commands during registration, which means that a client cannot reliably do passive implementation discovery at registration time.

The solution to these problems is to allow for active capability negotiation, and to extend the registration process with this negotiation. If the server supports capability negotiation, the registration process will be suspended until negotiation is completed. If the server does not support this, then registration will complete immediately and the client will not use any capabilities.

Capability negotiation is started by the client issuing a `CAP LS 302` command (indicating to the server support for IRCv3.2 capability negotiation). Negotiation is then performed with the `CAP REQ`, `CAP ACK`, and `CAP NAK` commands, and is ended with the `CAP END` command.

If used during initial registration, and the server supports capability negotiation, the `CAP` command will suspend registration. Once capability negotiation has ended the registration process will continue.

Clients and servers should implement capability negotiation and the `CAP` command based on the [IRCv3.1](http://ircv3.net/specs/core/capability-negotiation-3.1.html) and [IRCv3.2](http://ircv3.net/specs/core/capability-negotiation-3.2.html) Capability Negotiation specifications. Updates, improvements, and new versions of capability negotiation are managed by the [IRCv3 Working Group](http://ircv3.net/irc/).


---


# Client Messages

Messages are client-to-server only unless otherwise specified. If messages may be sent from the server to a connected client, it will be noted in the message's description. For server-to-client messages of this type, the message `<source>` usually indicates the client the message relates to, but this will be noted in the description.

In message descriptions, 'command' refers to the message's behaviour when sent from a client to the server. Similarly, 'Command Examples' represent example messages sent from a client to the server, and 'Message Examples' represent example messages sent from the server to a client. If a command is sent from a client to a server with less parameters than the command requires to be processed, the server will reply with an [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) numeric and the command will fail.

In the `"Parameters:"` section, optional parts or parameters are noted with square brackets as such: `"[<param>]"`. Curly braces around a part of parameter indicate that it may be repeated zero or more times, for example: `"<key>{,<key>}"` indicates that there must be at least one `<key>`, and that there may be additional keys separated by the comma `(",", 0x2C)` character.


## Connection Messages

### CAP message

         Command: CAP
      Parameters: <subcommand> [:<capabilities>]

The `CAP` command is used for capability negotiation between a server and a client.

The `CAP` message may be sent from the server to the client.

For the exact semantics of the `CAP` command and subcommands, please see the [IRCv3.1](http://ircv3.net/specs/core/capability-negotiation-3.1.html) and [IRCv3.2](http://ircv3.net/specs/core/capability-negotiation-3.2.html) Capability Negotiation specifications.

### AUTHENTICATE message

         Command: AUTHENTICATE

The `AUTHENTICATE` command is used for SASL authentication between a server and a client. The client must support and successfully negotiate the `"sasl"` client capability (as listed below in the SASL specifications) before using this command.

The `AUTHENTICATE` message may be sent from the server to the client.

For the exact semantics of the `AUTHENTICATE` command and negotiating support for the `"sasl"` client capability, please see the [IRCv3.1](http://ircv3.net/specs/extensions/sasl-3.1.html) and [IRCv3.2](http://ircv3.net/specs/extensions/sasl-3.2.html) SASL Authentication specifications.

### PASS message

         Command: PASS
      Parameters: <password>

The `PASS` command is used to set a 'connection password'. If set, the password must be set before any attempt to register the connection is made. This requires that clients send a `PASS` command before sending the `NICK` / `USER` combination.

The password supplied must match the one defined in the server configuration. It is possible to send multiple `PASS` commands before registering but only the last one sent is used for verification and it may not be changed once the client has been registered.

Servers may also consider requiring [`SASL` Authentication](#authenticate-message) upon connection as an alternative to this, when more information or an alternate form of identity verification is desired.

Numeric replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_ALREADYREGISTRED`](#erralreadyregistered-462) `(462)`
* [`ERR_PASSWDMISMATCH`](#errpasswdmismatch-464) `(464)`

Command Example:

      PASS secretpasswordhere

### NICK message

         Command: NICK
      Parameters: <nickname>

The `NICK` command is used to give the client a nickname or change the previous one.

If the server receives a `NICK` command from a client where the desired nickname is already in use on the network, it should issue an `ERR_NICKNAMEINUSE` numeric and ignore the `NICK` command.

If the server does not accept the new nickname supplied by the client as valid (for instance, due to containing invalid characters), it should issue an `ERR_ERRONEUSNICKNAME` numeric and ignore the `NICK` command.

If the server does not receive the `<nickname>` parameter with the `NICK` command, it should issue an `ERR_NONICKNAMEGIVEN` numeric and ignore the `NICK` command.

The `NICK` message may be sent from the server to clients to acknowledge their `NICK` command was successful, and to inform other clients about the change of nickname. In these cases, the `<source>` of the message will be the old `nickname [ [ "!" user ] "@" host ]` of the user who is changing their nickname.

Numeric Replies:

* [`ERR_NONICKNAMEGIVEN`](#errnonicknamegiven-431) `(431)`
* [`ERR_ERRONEUSNICKNAME`](#errerroneusnickname-432) `(432)`
* [`ERR_NICKNAMEINUSE`](#errnicknameinuse-433) `(433)`
* [`ERR_NICKCOLLISION`](#errnickcollision-436) `(436)`

Command Example:

      NICK Wiz                  ; Requesting the new nick "Wiz".

Message Examples:

      :WiZ NICK Kilroy          ; WiZ changed his nickname to Kilroy.

      :dan-!d@localhost NICK Mamoped
                                ; dan- changed his nickname to Mamoped.

### USER message

         Command: USER
      Parameters: <username> 0 * <realname>

The `USER` command is used at the beginning of a connection to specify the username and realname of a new user.

It must be noted that `<realname>` must be the last parameter because it may contain SPACE `(' ',` `0x20)` characters, and should be prefixed with a colon (`:`) if required.

Since it is easy for a client to lie about its username by relying solely on the `USER` command, the use of an "Identity Server" is recommended. This lookup can be performed by the server using the [Ident Protocol](http://tools.ietf.org/html/rfc1413). If the host which a user connects from has such an "Identity Server" enabled, the username is set to that as in the reply from that server. If the host does not have such a server enabled, the username is set to the value of the `<username>` parameter, prefixed by a tilde `('~', 0x7F)` to show that this value is user-set.

The maximum length of `<username>` may be specified by the [`USERLEN`](#userlen-parameter) `RPL_ISUPPORT` parameter. If this length is advertised, the username MUST be silently truncated to the given length before being used.

The second and third parameters of this command SHOULD be sent as one zero `('0', 0x30)` and one asterisk character `('*', 0x2A)` by the client, as the meaning of these two parameters varies between different versions of the IRC protocol.

If a client tries to send the `USER` command after they have already completed registration with the server, the `ERR_ALREADYREGISTERED` reply should be sent and the attempt should fail.

If the client sends a `USER` command after the server has successfully received a username using the Ident Protocol, the `<username>` parameter from this command should be ignored in favour of the one received from the identity server.

Numeric Replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_ALREADYREGISTRED`](#erralreadyregistred-462) `(462)`

Command Examples:

      USER guest 0 * :Ronnie Reagan
                                  ; No ident server
                                  ; User gets registered with username
                                  "~guest" and real name "Ronnie Reagan"

      USER guest 0 * :Ronnie Reagan
                                  ; Ident server gets contacted and
                                  returns the name "danp"
                                  ; User gets registered with username
                                  "danp" and real name "Ronnie Reagan"

### OPER message

         Command: OPER
      Parameters: <name> <password>

The `OPER` command is used by a normal user to obtain IRC operator privileges. Both parameters are required for the command to be successful.

If the client does not send the correct password for the given name, the server replies with an `ERR_PASSWDMISMATCH` message and the request is not successful.

If the client is not connecting from a valid host for the given name, the server replies with an `ERR_NOOPERHOST` message and the request is not successful.

If the supplied name and password are both correct, and the user is connecting from a valid host, the `RPL_YOUREOPER` message is sent to the user. The user will also receive a [`MODE`](#mode-message) message indicating their new user modes, and other messages may be sent.

The `<name>` specified by this command is separate to the accounts specified by SASL authentication, and is generally stored in the IRCd configuration.

Numeric Replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_PASSWDMISMATCH`](#errpasswdmismatch-464) `(464)`
* [`ERR_NOOPERHOST`](#errnooperhost-491) `(491)`
* [`RPL_YOUREOPER`](#erryoureoper-381) `(381)`

Command Example:

      OPER foo bar                ; Attempt to register as an operator
                                  using a name of "foo" and the password "bar".

### QUIT message

        Command: QUIT
     Parameters: [<reason>]

The `QUIT` command is used to terminate a client's connection to the server. The server acknowledges this by replying with an [`ERROR`](#error-message) message and closing the connection to the client.

This message may also be sent from the server to a client to show that a client has exited from the network. This is typically only dispatched to clients that share a channel with the exiting user. When the `QUIT` message is sent to clients, `<source>` represents the client that has exited the network.

When connections are terminated by a client-sent `QUIT` command, servers SHOULD prepend `<reason>` with the ascii string `"Quit: "` when sending `QUIT` messages to other clients, to represent that this user terminated the connection themselves. This applies even if `<reason>` is empty, in which case the reason sent to other clients SHOULD be just this `"Quit: "` string. However, clients SHOULD NOT change behaviour based on the prefix of `QUIT` message reasons, as this is not required behaviour from servers.

When a netsplit (the disconnecting of two servers) occurs, a `QUIT` message is generated for each client that has exited the network, distributed in the same way as ordinary `QUIT` messages. The `<reason>` on these `QUIT` messages SHOULD be composed of the names of the two servers involved, separated by a SPACE `(' ', 0x20)`. The first name is that of the server which is still connected and the second name is that of the server which has become disconnected. If servers wish to hide or obscure the names of the servers involved, the `<reason>` on these messages MAY also be the literal ascii string `"*.net *.split"` (i.e. the two server names are replaced with `"*.net"` and `"*.split"`). Software that implements the IRCv3 [`batch` Extension](http://ircv3.net/specs/extensions/batch-3.2.html) should also look at the [`netsplit` and `netjoin`](http://ircv3.net/specs/extensions/batch/netsplit-3.2.html) batch types.

If a client connection is closed without the client issuing a `QUIT` command to the server, the server MUST distribute a `QUIT` message to other clients informing them of this, distributed in the same was an ordinary `QUIT` message. Servers MUST fill `<reason>` with a message reflecting the nature of the event which caused it to happen. For instance, `"Ping timeout: 120 seconds"`, `"Excess Flood"`, and `"Too many connections from this IP"` are examples of relevant reasons for closing or for a connection with a client to have been closed.

Numeric Replies:

* None

Command Example:

      QUIT :Gone to have lunch         ; Client exiting from the network

Message Example:

      :dan-!d@localhost QUIT :Quit: Bye for now!
                                       ; dan- is exiting the network with
                                       the message: "Quit: Bye for now!"


## Channel Operations

This group of messages is concerned with manipulating channels, their properties (channel modes), and their contents (typically clients).

These commands may be requests to the server, in which case the server will or will not grant the request. If a 'request' is granted, it will be acknowledged by the server sending a message containing the same information back to the client. This is to tell the user that the request was successful. These sort of 'request' commands will be noted in the message information.

In implementing these messages, race conditions are inevitable when clients at opposing ends of a network send commands which will ultimately clash. Server-to-server protocols should be aware of this and make sure their protocol ensures consistent state across the entire network.

### JOIN message

         Command: JOIN
      Parameters: <channel>{,<channel>} [<key>{,<key>}]
      Alt Params: 0

The `JOIN` command indicates that the client wants to join the given channel(s), each channel using the given key for it. The server receiving the command checks whether or not the client can join the given channel, and processes the request. Servers MUST process the parameters of this command as lists on incoming commands from clients, with the first `<key>` being used for the first `<channel>`, the second `<key>` being used for the second `<channel>`, etc.

While a client is joined to a channel, they receive all relevant information about that channel including the `JOIN`, `PART`, `KICK`, and `MODE` messages affecting the channel. They receive all `PRIVMSG` and `NOTICE` messages sent to the channel, and they also receive `QUIT` messages from other clients joined to the same channel (to let them know those users have left the channel and the network). This allows them to keep track of other channel members and channel modes.

If a client's `JOIN` command to the server is successful, they receive a `JOIN` message from the server with their client as the message `<source>` and the channel they have joined as the first parameter of the message. After this, they are sent the channel's topic (with [`RPL_TOPIC`](#rpltopic-332)), and no message if the channel does not have a topic. They are also sent a list of users currently joined to the channel (with one or more [`RPL_NAMREPLY`](#rplnamreply-353) numerics). These `RPL_NAMREPLY` messages sent by the server MUST include the requesting client that has just joined the channel.

The [key](#key-channel-mode), [client limit](#client-limit-channel-mode) , [ban](#ban-channel-mode) - [exemption](#ban-exemption-channel-mode), [invite-only](#invite-only-channel-mode) - [exemption](#invite-exemption-channel-mode), and other (depending on server software) channel modes affect whether or not a given client may join a channel. More information on each of these modes and how they affect the `JOIN` command is available in their respective sections.

Servers MAY restrict the number of channels a client may be joined to at one time. This limit SHOULD be defined in the [`CHANLIMIT`](#chanlimit-parameter) `RPL_ISUPPORT` parameter. If the client cannot join this channel because they would be over their limit, they will receive an [`ERR_TOOMANYCHANNELS`](#errtoomanychannels-405) reply and the command will fail.

Note that this command also accepts the special argument of `("0", 0x30)` instead of any of the usual parameters, which requests that the sending client leave all channels they are currently connected to. The server will process this command as though the client had sent a [`PART`](#part-message) command for each channel they are a member of.

This message may be sent from a server to a client to notify the client that someone has joined a channel. In this case, the message `<source>` will be the client who is joining, and `<channel>` will be the channel which that client has joined. Servers SHOULD NOT send multiple channels in this message to clients, and SHOULD distribute these multiple-channel `JOIN` messages as a series of messages with a single channel name on each.

Numeric Replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_NOSUCHCHANNEL`](#errnosuchchannel-403) `(403)`
* [`ERR_TOOMANYCHANNELS`](#errtoomanychannels-405) `(405)`
* [`ERR_BADCHANNELKEY`](#errbadchannelkey-475) `(475)`
* [`ERR_BANNEDFROMCHAN`](#errbannedfromchan-474) `(474)`
* [`ERR_CHANNELISFULL`](#errchannelisfull-471) `(471)`
* [`ERR_INVITEONLYCHAN`](#errinviteonlychan-473) `(473)`
* [`RPL_TOPIC`](#rpltopic-332) `(332)`
* [`RPL_NAMREPLY`](#rplnamreply-353) `(353)`

Command Examples:

      JOIN #foobar                    ; join channel #foobar.

      JOIN &foo fubar                 ; join channel &foo using key "fubar".

      JOIN #foo,&bar fubar            ; join channel #foo using key "fubar"
                                      and &bar using no key.

      JOIN #foo,#bar fubar,foobar     ; join channel #foo using key "fubar".
                                      and channel #bar using key "foobar".

      JOIN #foo,#bar                  ; join channels #foo and #bar.

Message Examples:

      :WiZ JOIN #Twilight_zone        ; WiZ is joining the channel
                                      #Twilight_zone

      :dan-!d@localhost JOIN #test    ; dan- is joining the channel #test

### PART message

         Command: PART
      Parameters: <channel>{,<channel>} [<reason>]

The `PART` command removes the client from the given channel(s). On sending a successful `PART` command, the user will receive a `PART` message from the server for each channel they have been removed from. `<reason>` is the reason that the client has left the channel(s).

For each channel in the parameter of this command, if the channel exists and the client is not joined to it, they will receive an [`ERR_NOTONCHANNEL`](#errnotonchannel-442) reply and that channel will be ignored. If the channel does not exist, the client will receive an [`ERR_NOSUCHCHANNEL`](#errnosuchchannel-403) reply and that channel will be ignored.

This message may be sent from a server to a client to notify the client that someone has been removed from a channel. In this case, the message `<source>` will be the client who is being removed, and `<channel>` will be the channel which that client has been removed from. Servers SHOULD NOT send multiple channels in this message to clients, and SHOULD distribute these multiple-channel `PART` messages as a series of messages with a single channel name on each. If a `PART` message is distributed in this way, `<reason>` (if it exists) should be on each of these messages.

Numeric Replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_NOSUCHCHANNEL`](#errnosuchchannel-403) `(403)`
* [`ERR_NOTONCHANNEL`](#errnotonchannel-442) `(442)`

Command Examples:

      PART #twilight_zone             ; leave channel "#twilight_zone"

      PART #oz-ops,&group5            ; leave both channels "&group5" and
                                      "#oz-ops".

Message Examples:

      :dan-!d@localhost PART #test    ; dan- is leaving the channel #test

### TOPIC message

         Command: TOPIC
      Parameters: <channel> [<topic>]

The `TOPIC` command is used to change or view the topic of the given channel. If `<topic>` is not given, either `RPL_TOPIC` or `RPL_NOTOPIC` is returned specifying the current channel topic or lack of one. If `<topic>` is an empty string, the topic for the channel will be cleared.

If the client sending this command is not joined to the given channel, and tries to view its' topic, the server MAY return the [`ERR_NOTONCHANNEL`](#errnotonchannel-442) numeric and have the command fail.

If `RPL_TOPIC` is returned to the client sending this command, `RPL_TOPICWHOTIME` SHOULD also be sent to that client.

If the [protected topic](#protected-topic-mode) mode is set on a channel, then clients MUST have appropriate channel permissions to modify the topic of that channel. If a client does not have appropriate channel permissions and tries to change the topic, the [`ERR_CHANOPRIVSNEEDED`](#errchanoprivsneeded-482) numeric is returned and the command will fail.

If the topic of a channel is changed or cleared, every client in that channel (including the author of the topic change) will receive a `TOPIC` command with the new topic as argument (or an empty argument if the topic was cleared) alerting them to how the topic has changed.

Clients joining the channel in the future with receive either a `RPL_TOPIC` or `RPL_NOTOPIC` numeric accordingly.

Numeric Replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_NOSUCHCHANNEL`](#errnosuchchannel-403) `(403)`
* [`ERR_NOTONCHANNEL`](#errnotonchannel-442) `(442)`
* [`ERR_CHANOPRIVSNEEDED`](#errchanoprivsneeded-482) `(482)`
* [`RPL_NOTOPIC`](#rplnotopic-331) `(331)`
* [`RPL_TOPIC`](#rpltopic-332) `(332)`
* [`RPL_TOPICWHOTIME`](#rpltopicwhotime-333) `(333)`

Command Examples:

      TOPIC #test :New topic          ; Setting the topic on "#test" to
                                      "New topic".

      TOPIC #test :                   ; Clearing the topic on "#test"

      TOPIC #test                     ; Checking the topic for "#test"

### NAMES message

         Command: NAMES
      Parameters: [<channel>{,<channel>}]

The `NAMES` command is used to view the nicknames joined to a channel and their [channel membership prefixes](#channel-membership-prefixes). The param of this command is a list of channel names, delimited by a comma `(",", 0x2C)` character.

The channel names are evaluated one-by-one. For each channel that exists and they are able to see the users in, the server returns one of more `RPL_NAMREPLY` numerics containing the users joined to the channel and a single `RPL_ENDOFNAMES` numeric. If the channel name is invalid or the channel does not exist, one `RPL_ENDOFNAMES` numeric containing the given channel name should be returned. If the given channel has the [secret](#secret-channel-mode) channel mode set and the user is not joined to that channel, one `RPL_ENDOFNAMES` numeric is returned. Users with the [invisible](#invisible-user-mode) user mode set are not shown in channel responses unless the requesting client is also joined to that channel.

Servers MAY only return information about the first `<channel>` and silently ignore the others. This seems to be an attempt to reduce possible abuse. Due to this, clients SHOULD only query information about one channel when using the `NAMES` command.

If no parameter is given for this command, servers SHOULD return one `RPL_ENDOFNAMES` numeric with the `<channel>` parameter set to an asterix character `('*', 0x2A)`. Servers MAY also choose to return information about every single channel and every single user on the network in response to this command being given without a parameter, but most servers these days return nothing.

Numeric Replies:

* [`ERR_NOSUCHNICK`](#errnosuchnick-401) `(401)`
* [`RPL_NAMREPLY`](#rplnamreply-353) `(353)`
* [`RPL_ENDOFNAMES`](#rplendofnames-366) `(366)`

Command Examples:

      NAMES #twilight_zone,#42        ; List all visible users on
                                      "#twilight_zone" and "#42".

      NAMES                           ; Attempt to list all visible users on
                                      the network, which SHOULD be responded to
                                      as specified above.

### LIST message

         Command: LIST
      Parameters: [<channel>{,<channel>}] [<elistcond>{,<elistcond>}]

The `LIST` command is used to get a list of channels along with some information about each channel. Both parameters to this command are optional as they have different syntaxes.

The first possible parameter to this command is a list of channel names, delimited by a comma `(",", 0x2C)` character. If this parameter is given, the information for only the given channels is returned. If this parameter is not given, the information about all visible channels (those not hidden by the [secret](#secret-channel-mode) channel mode rules) is returned.

The second possible parameter to this command is a list of conditions as defined in the [`ELIST`](#elist-parameter) `RPL_ISUPPORT` parameter, delimited by a comma `(",", 0x2C)` character. Clients MUST NOT submit an `ELIST` condition unless the server has explicitly defined support for that condition with the `ELIST` token. If this parameter is supplied, the server filters the returned list of channels with the given conditions as specified in the [`ELIST`](#elist-parameter) documentation.

In response to a successful `LIST` command, the server MAY send one `RPL_LISTSTART` numeric, MUST send back zero or more `RPL_LIST` numerics, and MUST send back one `RPL_LISTEND` numeric.

Numeric Replies:

* [`RPL_LISTSTART`](#rplliststart-321) `(321)`
* [`RPL_LIST`](#rpllist-322) `(322)`
* [`RPL_LISTEND`](#rpllistend-323) `(323)`

Command Examples:

      LIST                            ; Command to list all channels

      LIST #twilight_zone,#42         ; Command to list the channels
                                      "#twilight_zone" and "#42".

      LIST >3                         ; Command to list all channels with
                                      more than three users.


## Server Queries and Commands

### MOTD message

         Command: MOTD
      Parameters: [<target>]

The `MOTD` command is used to get the "Message of the Day" of the given server. If `<target>` is not given, the MOTD of the server the client is connected to should be returned.

If `<target>` is a server, the MOTD for that server is requested. If `<target>` is given and a matching server cannot be found, the server will respond with the `ERR_NOSUCHSERVER` numeric and the command will fail.

If the MOTD can be found, one `RPL_MOTDSTART` numeric is returned, followed by one or more `RPL_MOTD` numeric, then one `RPM_ENDOFMOTD` numeric.

If the MOTD does not exist or could not be found, the `ERR_NOMOTD` numeric is returned.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`ERR_NOMOTD`](#errnomotd-422) `(422)`
* [`RPL_MOTDSTART`](#rplmotdstart-375) `(375)`
* [`RPL_MOTD`](#rplmotd-372) `(372)`
* [`RPL_ENDOFMOTD`](#rplendofmotd-376) `(376)`

### VERSION message

         Command: VERSION
      Parameters: [<target>]

The `VERSION` command is used to query the version of the software and the [`RPL_ISUPPORT`](#rplisupport-parameters) parameters of the given server. If `<target>` is not given, the information for the server the client is connected to should be returned.

If `<target>` is a server, the information for that server is requested. If `<target>` is a client, the information for the server that client is connected to is requested. If `<target>` is given and a matching server cannot be found, the server will respond with the `ERR_NOSUCHSERVER` numeric and the command will fail.

Wildcards are allowed in the `<target>` parameter.

Upon receiving a `VERSION` command, the given server SHOULD respond with one `RPL_VERSION` reply and one or more `RPL_ISUPPORT` replies.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`RPL_ISUPPORT`](#rplisupport-005) `(005)`
* [`RPL_VERSION`](#rplversion-351) `(351)`

Command Examples:

      :Wiz VERSION *.se               ; message from Wiz to check the
                                      version of a server matching "*.se"

      VERSION tolsun.oulu.fi          ; check the version of server
                                      "tolsun.oulu.fi".

### ADMIN message

         Command: ADMIN
      Parameters: [<target>]

The `ADMIN` command is used to find the name of the administrator of the given server. If `<target>` is not given, the information for the server the client is connected to should be returned.

If `<target>` is a server, the information for that server is requested. If `<target>` is a client, the information for the server that client is connected to is requested. If `<target>` is given and a matching server cannot be found, the server will respond with the `ERR_NOSUCHSERVER` numeric and the command will fail.

Wildcards are allowed in the `<target>` parameter.

Upon receiving an `ADMIN` command, the given server SHOULD respond with the `RPL_ADMINME`, `RPL_ADMINLOC1`, `RPL_ADMINLOC2`, and `RPL_ADMINEMAIL` replies.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`RPL_ADMINME`](#rpladminme-256) `(256)`
* [`RPL_ADMINLOC1`](#rpladminloc1-257) `(257)`
* [`RPL_ADMINLOC2`](#rpladminloc2-258) `(258)`
* [`RPL_ADMINEMAIL`](#rpladminemail-259) `(259)`

Command Examples:

      ADMIN tolsun.oulu.fi            ; request an ADMIN reply from
                                      tolsun.oulu.fi

      ADMIN syrk                      ; ADMIN request for the server to
                                      which the user syrk is connected

### CONNECT message

         Command: CONNECT
      Parameters: <target server> [<port> [<remote server>]]

The `CONNECT` command forces a server to try to establish a new connection to another server. `CONNECT` is a privileged command and is available only to IRC Operators. If a remote server is given, the connection is attempted by that remote server to `<target server>` using `<port>`.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_NOPRIVILEGES`](#errnoprivileges-481) `(481)`
* [`ERR_NOPRIVS`](#errnoprivs-723) `(723)`

Command Examples:

      CONNECT tolsun.oulu.fi
      ; Attempt to connect the current server to tololsun.oulu.fi

      CONNECT  eff.org 12765 csd.bu.edu
      ; Attempt to connect csu.bu.edu to eff.org on port 12765

### TIME message

         Command: TIME
      Parameters: [<server>]

The `TIME` command is used to query local time from the specified server. If the server parameter is not given, the server handling the command must reply to the query.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`RPL_TIME`](#rpltime-391) `(391)`

Command Examples:

      TIME tolsun.oulu.fi             ; check the time on the server
                                      "tolson.oulu.fi"

      :Angel TIME *.au                ; user angel checking the time on a
                                      server matching "*.au"

### STATS message

         Command: STATS
      Parameters: <query> [<server>]

The `STATS` command is used to query statistics of a certain server. The specific queries supported by this command depend on the server that replies, although the server must be able to supply information as described by the queries below (or similar).

A query may be given by any single letter which is only checked by the destination server and is otherwise passed on by intermediate servers, ignored and unaltered.

The following queries are those found in current IRC implementations and provide a large portion of the setup and runtime information for that server. All servers should be able to supply a valid reply to a `STATS` query which is consistent with the reply formats currently used and the purpose of the query.

The currently supported queries are:

* `c` - returns a list of servers which the server may connect to or allow connections from;
* `h` - returns a list of servers which are either forced to be treated as leaves or allowed to act as hubs;
* `i` - returns a list of hosts which the server allows a client to connect from;
* `k` - returns a list of banned username/hostname combinations for that server;
* `l` - returns a list of the server's connections, showing how long each connection has been established and the traffic over that connection in bytes and messages for each direction;
* `m` - returns a list of commands supported by the server and the usage count for each if the usage count is non zero;
* `o` - returns a list of hosts from which normal clients may become operators;
* `u` - returns a string showing how long the server has been up.
* `y` - show Y (Class) lines from server's configuration file;

<div class="warning">
    Need to give this a good look-over. It's probably quite incorrect.
</div>

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_NOPRIVILEGES`](#errnoprivileges-481) `(481)`
* [`ERR_NOPRIVS`](#errnoprivs-723) `(723)`
* [`RPL_STATSCLINE`](#statscline-213) `(213)`
* [`RPL_STATSHLINE`](#statshline-244) `(244)`
* [`RPL_STATSILINE`](#statsiline-215) `(215)`
* [`RPL_STATSKLINE`](#statskline-216) `(216)`
* [`RPL_STATSLLINE`](#statslline-241) `(241)`
* [`RPL_STATSOLINE`](#statsoline-243) `(243)`
* [`RPL_STATSLINKINFO`](#rplstatslinkinfo-211) `(211)`
* [`RPL_STATSUPTIME`](#rplstatsuptime-242) `(242)`
* [`RPL_STATSCOMMANDS`](#rplstatscommands-212) `(212)`
* [`RPL_ENDOFSTATS`](#rplendofstats-219) `(219)`

Command Examples:

      STATS m                         ; check the command usage for the
                                      server you are connected to

      :Wiz STATS c eff.org            ; request by WiZ for C/N line
                                      information from server eff.org

### INFO message

         Command: INFO
      Parameters: [<target>]

The `INFO` command is used to return information which describes the specified server. This information usually includes the software name/version and its authors. Some other info that may be returned includes the patch level and compile date of the server, the copyright on the server software, and whatever miscellaneous information the server authors consider relevant.

If `<target>` is not given, the server handling the command must reply to the query. If `<target>` is given and a matching server cannot be found, the server will respond with the `ERR_NOSUCHSERVER` numeric and the command will fail.

Upon receiving an `INFO` command, the given server will respond with zero or more `RPL_INFO` replies, followed by one `RPL_ENDOFINFO` numeric.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`RPL_INFO`](#rplinfo-371) `(371)`
* [`RPL_ENDOFINFO`](#rplendofinfo-374) `(374)`

Command Examples:

     INFO csd.bu.edu                 ; request an INFO reply from
                                     csd.bu.edu

     :Avalon INFO *.fi               ; INFO request from Avalon for first
                                     server found to match *.fi.

     INFO Angel                      ; request info from the server that
                                     Angel is connected to.

### MODE message

         Command: MODE
      Parameters: <target> [<modestring> [<mode arguments>...]]

The `MODE` command is used to set or remove options (or *modes*) from a given target.

#### User mode

If `<target>` is a nickname that does not exist on the network, the [`ERR_NOSUCHNICK`](#errnosuchnick-401) numeric is returned. If `<target>` is a different nick than the user who sent the command, the [`ERR_USERSDONTMATCH`](#errusersdontmatch-502) numeric is returned.

If `<modestring>` is not given, the [`RPL_UMODEIS`](#rplumodeis-221) numeric is sent back containing the current modes of the target user.

If `<modestring>` is given, the supplied modes will be applied, and a `MODE` message will be sent to the user containing the changed modes. If one or more modes sent are not implemented on the server, the server MUST apply the modes that are implemented, and then send the [`ERR_UMODEUNKNOWNFLAG`](#errumodeunknownflag-501) in reply along with the `MODE` message.

#### Channel mode

If `<target>` is a channel that does not exist on the network, the [`ERR_NOSUCHCHANNEL`](#errnosuchchannel-403) numeric is returned.

If `<modestring>` is not given, the [`RPL_CHANNELMODEIS`](#rplchannelmodeis-324) numeric is returned. Servers MAY choose to hide sensitive information such as channel keys when sending the current modes. Servers MAY also return the [`RPL_CREATIONTIME`](#rplcreationtime-329) numeric following `RPL_CHANNELMODEIS`.

If `<modestring>` is given, the user sending the command MUST have appropriate channel privileges on the target channel to change the modes given. If a user does not have appropriate privileges to change modes on the target channel, the server MUST not process the message, and [`ERR_CHANOPRIVSNEEDED`](#errchanoprivsneeded-482) numeric is returned.
If the user has permission to change modes on the target, the supplied modes will be applied based on the type of the mode (see below).
For type A, B, and C modes, arguments will be sequentially obtained from `<mode arguments>`. If a type B or C mode does not have a parameter when being set, the server MUST ignore that mode.
If a type A mode has been sent without an argument, the contents of the list MUST be sent to the user, unless it contains sensitive information the user is not allowed to access.
When the server is done processing the modes, a `MODE` command is sent to all members of the channel containing the mode changes. Servers MAY choose to hide sensitive information when sending the mode changes.

---

`<modestring>` starts with a plus `('+',` `0x53)` or minus `('-',` `0x55)` character, and is made up of the following characters:

* **`'+'`**: Adds the following mode(s).
* **`'-'`**: Removes the following mode(s).
* **`'a-zA-Z'`**: Mode letters, indicating which modes are to be added/removed.

The ABNF representation for `<modestring>` is:

      modestring  =  1*( modeset )
      modeset     =  plusminus *( modechar )
      plusminus   =  %x53 / %x55
                       ; + or -
      modechar    =  ALPHA

There are four categories of channel modes, defined as follows:

* **Type A**: Modes that add or remove an address to or from a list. These modes MUST always have a parameter when sent from the server to a client. A client MAY issue this type of mode without an argument to obtain the current contents of the list. The numerics used to retrieve contents of Type A modes depends on the specific mode. Also see the [`EXTBAN`](#extban-parameter) parameter.
* **Type B**: Modes that change a setting on a channel. These modes MUST always have a parameter.
* **Type C**: Modes that change a setting on a channel. These modes MUST have a parameter when being set, and MUST NOT have a parameter when being unset.
* **Type D**: Modes that change a setting on a channel. These modes MUST NOT have a parameter.

Channel mode letters, along with their types, are defined in the [`CHANMODES`](#chanmodes-parameter) parameter. User mode letters are always **Type D** modes.

The meaning of standard (and/or well-used) channel and user mode letters can be found in the [Channel Modes](#channel-modes) and [User Modes](#user-modes) sections. The meaning of any mode letters not in this list are defined by the server software and configuration.

---

Type A modes are lists that can be viewed. The method of viewing these lists is not standardised across modes and different numerics are used for each. The specific numerics used for these are outlined here:

* **[Ban List `"+b"`](#ban-channel-mode)**: Ban lists are returned with zero or more [`RPL_BANLIST`](#rplbanlist-367) numerics, followed by one [`RPL_ENDOFBANLIST`](#rplendofbanlist-368) numeric.
* **[Exception List `"+e"`](#exception-channel-mode)**: Exception lists are returned with zero or more [`RPL_EXCEPTLIST`](#rplexceptlist-348) numerics, followed by one [`RPL_ENDOFEXCEPTLIST`](#rplendofexceptlist-349) numeric.
* **[Invite-Exception List `"+I"`](#invite-exception-channel-mode)**: Invite-exception lists are returned with zero or more [`RPL_INVITELIST`](#rplinvitelist-346) numerics, followed by one [`RPL_ENDOFINVITELIST`](#rplendofinvitelist-347) numeric.

After the initial `MODE` command is sent to the server, the client receives the above numerics detailing the entries that appear on the given list. Servers MAY choose to restrict the above information to channel operators, or to only those clients who have permissions to change the given list.

---

Command Examples:

      MODE dan +i                     ; Setting the "invisible" user mode on dan.

      MODE #foobar +mb *@127.0.0.1    ; Setting the "moderated" channel mode and
                                      adding the "*@127.0.0.1" mask to the ban
                                      list of the #foobar channel.

Message Examples:

      :dan!~h@localhost MODE #foobar -bl+i *@192.168.0.1
                                      ; dan unbanned the "*@192.168.0.1" mask,
                                      removed the client limit from, and set the
                                      #foobar channel to invite-only.

      :irc.example.com MODE #foobar +o bunny
                                      ; The irc.example.com server gave channel
                                      operator privileges to bunny on #foobar.


## Sending Messages

### PRIVMSG message

         Command: PRIVMSG
      Parameters: <target>{,<target>} <text to be sent>

The `PRIVMSG` command is used to send private messages between users, as well as to send messages to channels. `<target>` is the nickname of a client or the name of a channel.

If `<target>` is a channel name and the client is [banned](#ban-channel-mode) and not covered by a [ban exemption](#ban-exemption-channel-mode), the message will not be delivered and the command will silently fail. Channels with the [moderated](#moderated-channel-mode) mode active may block messages from certain users. Other channel modes may affect the delivery of the message or cause the message to be modified before delivery, and these modes are defined by the server software and configuration being used.

If a message cannot be delivered to a channel, the server SHOULD respond with an [`ERR_CANNOTSENDTOCHAN`](#errcannotsendtochan-404) numeric to let the user know that this message could not be delivered.

If `<target>` is a channel name, it may be prefixed with one or more [channel membership prefix character (`@`, `+`, etc)](#channel-membership-prefixes) and the message will be delivered only to the members of that channel with the given or higher status in the channel. Servers that support this feature will list the prefixes which this is supported for in the [`STATUSMSG`](#statusmsg-parameter) `RPL_ISUPPORT` parameter, and this SHOULD NOT be attempted by clients unless the prefix has been advertised in this token.

If `<target>` is a user and that user has been set as away, the server may reply with an [`RPL_AWAY`](#rplaway-301) numeric and the command will continue.

The `PRIVMSG` message is sent from the server to client to deliver a message to that client. The `<prefix>` of the message represents the user or server that sent the message, and the `<target>` represents the target of that `PRIVMSG` (which may be the client, a channel, etc).

Numeric Replies:

* [`ERR_NOSUCHNICK`](#errnosuchnick-401) `(401)`
* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`ERR_CANNOTSENDTOCHAN`](#errcannotsendtochan-404) `(404)`
* [`ERR_TOOMANYTARGETS`](#errtoomanytargets-407) `(407)`
* [`ERR_NORECIPIENT`](#errnorecipient-411) `(411)`
* [`ERR_NOTEXTTOSEND`](#errnotexttosend-412) `(412)`
* [`ERR_NOTOPLEVEL`](#errnotoplevel-413) `(413)`
* [`ERR_WILDTOPLEVEL`](#errwildtoplevel-414) `(414)`
* [`RPL_AWAY`](#rplaway-301) `(301)`

<div class="warning">
    There are strange "X@Y" target rules and such which are noted in the examples of the original PRIVMSG RFC section. We need to check to make sure modern servers actually process them properly, and if so then specify them.
</div>

Command Examples:

      PRIVMSG Angel :yes I'm receiving it !
                                      ; Command to send a message to Angel.

      PRIVMSG %#bunny :Hi! I have a problem!
                                      ; Command to send a message to halfops
                                      and chanops on #bunny.

      PRIVMSG @%#bunny :Hi! I have a problem!
                                      ; Command to send a message to halfops
                                      and chanops on #bunny. This command is
                                      functionally identical to the above
                                      command.

Message Examples:

      :Angel PRIVMSG Wiz :Hello are you receiving this message ?
                                      ; Message from Angel to Wiz.

      :dan!~h@localhost PRIVMSG #coolpeople :Hi everyone!
                                      ; Message from dan to the channel
                                      #coolpeople

### NOTICE message

         Command: NOTICE
      Parameters: <target>{,<target>} <text to be sent>

The `NOTICE` command is used to send notices between users, as well as to send notices to channels. `<target>` is interpreted the same way as it is for the [`PRIVMSG`](#privmsg-message) command.

The `NOTICE` message is used similarly to [`PRIVMSG`](#privmsg-message). The difference between `NOTICE` and [`PRIVMSG`](#privmsg-message) is that automatic replies must never be sent in response to a `NOTICE` message. This rule also applies to servers -- they must not send any error back to the client on receipt of a `NOTICE` command. The intention of this is to avoid loops between a client automatically sending something in response to something it received. This is typically used by 'bots' (a client with a program, and not a user, controlling their actions) and also for server messages to clients.

One thing for bot authors to note is that the `NOTICE` message may be interpreted differently by various clients. Some clients highlight or interpret any `NOTICE` sent to a channel in the same way that a `PRIVMSG` with their nickname gets interpreted. This means that users may be irritated by the use of `NOTICE` messages rather than `PRIVMSG` messages by clients or bots, and they are not commonly used by client bots for this reason.


## Optional Messages

These messages are not required for a server implementation to work, but SHOULD be implemented. If a command is not implemented, it MUST return the [`ERR_UNKNOWNCOMMAND`](#errunknowncommand-421) numeric.

### USERHOST message

         Command: USERHOST
      Parameters: <nickname>{ <nickname>}

The `USERHOST` command is used to return information about users with the given nicknames. The `USERHOST` command takes up to five nicknames, each a separate parameters. The nicknames are returned in [`RPL_USERHOST`](#rpluserhost-302) numerics.

Numeric Replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`RPL_USERHOST`](#rpluserhost-302) `(302)`

Command Examples:

      USERHOST Wiz Michael Marty p    ;USERHOST request for information on
                                      nicks "Wiz", "Michael", "Marty" and "p"

Reply Examples:

      :ircd.stealth.net 302 yournick :syrk=+syrk@millennium.stealth.net
                                      ; Reply for user syrk


## Miscellaneous Messages

These messages do not fit into any of the above categories but are still REQUIRED by the protocol. All functional servers MUST implement these messages.

### KILL message

         Command: KILL
      Parameters: <nickname> <comment>

The `KILL` command is used to close the connection between a given client and the server they are connected to. `KILL` is a privileged command and is available only to IRC Operators. `<nickname>` represents the user to be 'killed', and `<comment>` is shown to all users and to the user themselves upon being killed.

When a `KILL` command is used, the client being killed receives the `KILL` message, and the `<source>` of the message SHOULD be the operator who performed the command. The user being killed and every user sharing a channel with them receives a [`QUIT`](#quit-message) message representing that they are leaving the network. The `<reason>` on this `QUIT` message typically has the form: `"Killed (<killer> (<reason>))"` where `<killer>` is the nickname of the user who performed the `KILL`. The user being killed then receives the [`ERROR`](#error-message) message, typically containing a `<reason>` of `"Closing Link: <servername> (Killed (<killer> (<reason>)))"`. After this, their connection is closed.

If a `KILL` message is received by a client, it means that the user specified by `<nickname>` is being killed. With certain servers, users may elect to receive `KILL` messages created for other users to keep an eye on the network. This behavior may also be restricted to operators.

Clients can rejoin instantly after this command is performed on them. However, it can serve as a warning to a user to stop their activity. As it breaks the flow of data from the user, it can also be used to stop large amounts of 'flooding' from abusive users or due to accidents. Abusive users may not care and promptly reconnect and resume their abusive behaviour. In these cases, opers may look at the [`KLINE`](#kline-message) command to keep them from rejoining the network for a longer time.

As nicknames across an IRC network MUST be unique, if duplicates are found when servers join, one or both of the clients MAY be `KILL`ed and removed from the network. Servers may also handle this case in alternate ways that don't involve removing users from the network.

Servers MAY restrict whether specific operators can remove users on other servers (remote users). If the operator tries to remove a remote user but is not privileged to, they should receive the [`ERR_NOPRIVS`](#errnoprivs-723) numeric.

`<comment>` SHOULD reflect why the `KILL` was performed. For user-generated KILLs, it is up to the user to provide an adequate reason.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_NOPRIVILEGES`](#errnoprivileges-481) `(481)`
* [`ERR_NOPRIVS`](#errnoprivs-723) `(723)`

<div class="warning">
    <p>NOTE: The <tt>KILL</tt> message is weird, and I need to look at it more closely, add some examples, etc.</p>
</div>


---

<div id="appendixes">

{% capture appendixes %}{% include modern-appendix.md %}{% endcapture %}
{{ appendixes | markdownify }}

</div>


---


# Acknowledgements

This document draws heavily from the original [RFC1459](https://tools.ietf.org/html/rfc1459) and [RFC2812](https://tools.ietf.org/html/rfc2812) IRC protocol specifications.

Parts of this document come from the "IRC `RPL_ISUPPORT` Numeric Definition" Internet Draft authored by L. Hardy, E. Brocklesby, and K. Mitchell. Parts of this document come from the "IRC Client Capabilities Extension" Internet Draft authored by K. Mitchell, P. Lorier, L. Hardy, and P. Kucharski. Parts of this document come from the [IRCv3 Working Group](http://ircv3.net) specifications.

Thanks to the following people for contributing to this document, or to helping with IRC specification efforts:

Simon Butcher, dx, James Wheare, Stephanie Daugherty, Sadie, and all the IRC developers and documentation writers throughout the years.
