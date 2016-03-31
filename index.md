---
title: Modern IRC
layout: default
copyrights:
  -
    name: "Jack Allnutt"
    org: "Kiwi IRC"
    email: "jack@allnutt.eu"
  -
    name: "Daniel Oaks"
    email: "daniel@danieloaks.net"
---

{% include copyrights.html %}

<div class="warning">
    <p>This is NOT an authoritative document. It does not purport to be anything more than a hopefully-useful overview of the IRC protocol as it is generally implemented today. If something written in here isn't correct for or interoperable with an IRC server / network you know of, please open an issue or <a href="mailto:daniel@danieloaks.net">contact me!</a></p>
    <p>For something which aims to be an RFC, please see the <a href="https://github.com/kaniini/ircv3-harmony">ircv3-harmony</a> project.</p>
</div>

<div class="warning">
    <p>NOTE: This is NOWHERE NEAR FINISHED. Dragons be here, insane stuff be here.</p>
    <p>Please feel free to contribute by sending pull requests to our <a href="https://github.com/DanielOaks/modern-irc">Github repository</a>.</p>
</div>


---


# Introduction

The Internet Relay Chat (IRC) protocol has been designed over a number of years, with multitudes of implementations and use cases appearing. This document describes the IRC Client-Server protocol.

IRC is a text-based teleconferencing protocol, which has proven itself very valuable and useful. It is well-suited to running on many machines in a distributed fashion. A typical setup involves multiple servers connected in a distributed network. Messages are delivered through this network and state is maintained across it for the connected clients and active channels.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).


## Servers

Servers form the backbone of IRC, providing a point to which clients may connect and talk to each other, and a point for other servers to connect to, forming an IRC network.

The most common network configuration for IRC servers is that of a spanning tree [see the figure below], where each server acts as a central node for the rest of the network it sees. Other topologies are being experimented with, but right there are no others widely used in production.

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

These terms are not generally used in IRC protocol documentation, but may be used by the administrators of a network in order to differentiate the servers they run and their roles.


## Clients

A client is anything connecting to a server that is not another server. Each client is distinguished from other clients by a unique nickname. See the protocol grammar rules for what may and may not be used in a nickname. In addition to the nickname, all servers must have the following information about all clients: The real name/address of the host that the client is connecting from, the username of the client on that host, and the server to which the client is connected.

### Operators

To allow a reasonable amount of order to be kept within the IRC network, a special class of clients (operators) are allowed to perform general maintenance functions on the network. Although the powers granted to an operator can be considered as 'dangerous', they are nonetheless required.

The tasks operators can perform vary with different server software and the specific privileges granted to each operator. Some can perform network maintenence tasks, such as disconnecting and reconnecting servers as needed to prevent long-term use of bad network routing. Some operators can also remove a user from their server or the IRC network by 'force', i.e. the operator is able to close the connection between a client and server.

The justification for operators being able to remove users from the network is delicate since its abuse is both destructive and annoying. However, IRC network policies and administrators handle operators who abuse their privileges, and what is considered abuse by that network.


## Channels

A channel is a named group of one or more clients. All clients in the channel will receive all messages addressed to that channel. The channel is created implicitly when the first client joins it, and the channel ceases to exist when the last client leaves it. While the channel exists, any client can reference the channel using the name of the channel. Networks that support the concept of 'channel ownership' may persist specific channels in some way while no clients are connected to them.

Channel names are strings (beginning with specified prefix characters). Apart from the requirement of the first character being a valid [channel type](#channel-types) prefix character; the only restriction on a channel name is that it may not contain any spaces `(' ', 0x20)`, a control G / `BELL` `('^G', 0x07)`, or a comma `(',', 0x2C)` (which is used as a list item separator by the protocol).

There are several types of channels used in the IRC protocol. The first standard type of channel is a distributed channel, which is known to all servers that are connected to the network. The prefix character for this type of channel is `('#', 0x23)`. The second type are server-specific channels, where the clients connected can only see and talk to other clients on the same server. The prefix character for this type of channel is `('&', 0x26)`. Other types of channels are described in the [Channel Types](#channel-types) section.

Along with various channel types, there are also channel modes that can alter the characteristics and behaviour of individual channels. See the [Channel Modes](#channel-modes) section for more information on these.

To create a new channel or become part of an existing channel, a user is required to join the channel using the [`JOIN`](#join-message) command. If the channel doesn't exist prior to joining, the channel is created and the creating user becomes a channel operator. If the channel already exists, whether or not the client successfully joins that channel depends on the modes currently set on the channel. For example, if the channel is set to `invite-only` mode (`+i`), the client only joins the channel if they have been invited by another user or they have been exempted from requiring an invite by the channel operators.

A user may be a part of several channels at once, but a limit may be imposed by the server as to how many channels a client can be in at one time. This limit is specified by the [`CHANLIMIT`](#chanlimit-parameter) `RPL_ISUPPORT` parameter. See the [Feature Advertisement](#feature-advertisement) section for more details on `RPL_ISUPPORT`.

If the IRC network becomes disjoint because of a split between servers, the channel on either side is composed of only those clients which are connected to servers on the respective sides of the split, possibly ceasing to exist on one side. When the split is healed, the connecting servers ensure the network state is consistent between them.

### Channel Operators

Channel operators (or "chanops") on a given channel are considered to 'run' or 'own' that channel. In recognition of this status, channel operators are endowed with certain powers which let them moderate and keep control of their channel.

As owners of a channel, chanops are **not** required to have reasons for their actions in the management of their channel. Most IRC operators do not concern themselves with 'channel politics', and try to not interfere with the management of specific channels. Most IRC networks consider the management of specific channels, and/or 'abusive' channel operators to be outside their domain. However, for specific details it is best to consult the network policy (usually presented on connection with the Message of the Day \[[`MOTD`](#motd-message)\]).

IRC servers may also define other levels of channel moderation. These can include 'halfop' (half operator), 'protected' (protected user/operator), 'founder' (channel founder), and any other positions the server wishes to define. These moderation levels have varying privileges and can execute, and not execute, various channel management commands based on what the server defines.

The commands which may only be used by channel moderators include:

- [`KICK`](#kick-message): Eject a client from the channel
- [`MODE`](#mode-message): Change the channel's modes
- [`INVITE`](#invite-message): Invite a client to an invite-only channel (mode +i)
- [`TOPIC`](#topic-message): Change the channel topic in a mode +t channel

Channel moderators are identified by the channel member prefix (`'@'` for standard channel operators, `'%'` for halfops) next to their nickname whenever it is associated with a channel (ie: replies to the `NAMES`, `WHO`, and `WHOIS` commands).

Specific prefixes and moderation levels are covered in the [Channel Membership Prefixes](#channel-membership-prefixes) section.


---


# IRC Concepts

This section is devoted to describing the concepts behind the organisation of the IRC protocol and how current implementations deliver different classes of messages.

This section ONLY deals with the spanning-tree topology, shown in the figure below. This is because spanning-tree is the topology specified and used in all IRC software today. Other topologies are being experimented with, but are not yet used in production by networks.

                              1--\
                                  A        D---4
                              2--/ \      /
                                    B----C
                                   /      \
                                  3        E

       Servers: A, B, C, D, E         Clients: 1, 2, 3, 4

<p class="figure">Sample small IRC network.</p>


## One-to-one communication

Communication on a one-to-one basis is usually only performed by clients, since most server-server traffic is not a result of servers talking only to each other.

Servers MUST be able to send a message from any one client to any other. It is REQUIRED that all servers be able to send a message in exactly one direction along the spanning tree to reach any client. Thus the path of a message being delivered is the shortest path between any two points on the spanning tree.

The following examples all refer to the figure above.

1. A message between clients 1 and 2 is only seen by server A, which sends it straight to client 2.

2. A message between clients 1 and 3 is seen by servers A, B, and client 3. No other clients or servers are allowed to see the message.

3. A message between clients 2 and 4 is seen by servers A, B, C, D, and client 4 only.


## One-to-many communication

The main goal of IRC is to provide a forum which allows easy and efficient conferencing (one to many conversations). IRC offers several means to achieve this, each serving its own purpose.

### To A Channel

In IRC, the channel has a role equivalent to that of the multicast group; their existence is dynamic and the actual conversation carried out on a channel MUST only be sent to servers which are supporting users on a given channel. Moreover, the message SHALL only be sent once to every local link as each server is responsible for fanning the original message to ensure it will reach all recipients.

The following examples all refer to the above figure:

4. Any channel with a single client in it. Messages to this channel go to the server and then nowhere else.

5. Two clients in a channel. All messages traverse a path as if they were private messages between the two clients outside a channel.

6. Clients 1, 2, and 3 are in a channel. All messages to this channel are sent to all clients and only those servers which must be traversed by the message if it were a private message to a single client. If client 1 sends a message, it goes back to client 2 and then via server B to client 3.

### To A Host/Server Mask

To provide with some mechanism to send messages to a large body of related users, host and server mask messages are available. These messages are sent to users whose host or server information match that of the given mask. The messages are only sent to locations where the users are, in a fashion similar to that of channels.

### To A List

The least efficient style of one-to-many conversation is through clients talking to a 'list' of targets (client, channel, ask). How this is done is almost self-explanatory: the client gives a list of destinations to which the message is to be delivered and the server breaks it up and dispatches a separate copy of the message to each given destination.

This is not as efficient as using a channel since the destination list MAY be broken up and the dispatch sent without checking to make sure duplicates aren't sent down each path.


## One-To-All

The one-to-all type of message is better described as a broadcast message, sent to all clients or servers or both. On a large network of users and servers, a single message can result in a lot of traffic being sent over the network in an effort to reach all of the desired destinations.

For some class of messages, there is no option but to broadcast it to all servers to that the state information held by each server is consistent between them.

### Client-to-Client

IRC Operators may be able to send a message to every client currently connected to the network. This depends on the specific features and commands implemented in the server software.

### Client-to-Server

Most of the commands which result in a change of state information (such as channel membership, channel modes, user status, etc.) MUST be sent to all servers by default, and this distribution SHALL NOT be changed by the client.

### Server-to-Server

While most messages between servers are distributed to all 'other' servers, this is only required for any message that affects a user, channel, or server. Since these are the basic items found in IRC, nearly all messages originating from a server are broadcast to all other connected servers.


## Current Architectural Problems

There are a number of recognized problems with this protocol. This section only addresses the problems related to the architecture of the protocol.

### Scalability

It is widely recognized that this protocol may not scale sufficiently well when used in a very large arena. The main problem comes from the requirement that all servers know about all other servers, clients, and channels, and that information regarding them be updated as soon as it changes.

Some server-to-server protocols may attempt to alleviate this by, as an example, only sending necessary state information to leaf servers. These sort of optimisations are implementation-specific and are not covered in this document. However, server authors should take great care in their protocols to ensure race conditions and other network instability does not happen as a result of these attempts to improve the scalability of their protocol.

### Reliability

As the only network configuration used for IRC servers is that of a spanning tree, each link between two servers is an obvious and serious point of failure.

Various software authors are experimenting with alternative topologies such as mesh networks, but there is not yet a production implementation or specification of any topology other than the standard spanning-tree configuration.


---


# Protocol Structure


## Overview

The protocol as described herein is used for client to server connections.

Various server to server protocols have been defined over the years, with [TS6](https://github.com/grawity/irc-docs/blob/725a1f05b85d7a935986ae4f49b058e9b67e7ce9/server/ts6.txt) and [P10](http://web.mit.edu/klmitch/Sipb/devel/src/ircu2.10.11/doc/p10.html) among the most popular (both based on the original client-server protocol). However, with the fragmented nature of IRC server to server protocols and differences in server implementations, features and network designs, it is at this point impossible to define a single standard server to server protocol.

### Character Codes

Clients SHOULD use the [UTF-8](http://tools.ietf.org/html/rfc3629) character encoding on outgoing messages. Clients MUST be able to handle incoming messages encoded with alternative encodings, and lines they cannot decode correctly with any of their standard encodings.

The `'ascii'` casemapping defines the characters `a` to `z` to be considered the lower-case equivalents of the characters `A` to `Z` only. The `'rfc1459'` casemapping defines the same casemapping as `'ascii'`, with the addition of the characters `'{'`, `'}'`, and `'|'` being considered the lower-case equivalents of the characters `'['`, `']'`, and `'\'` respectively. For other casemappings used by servers, see the [`CASEMAPPING`](#casemapping-parameter) `RPL_ISUPPORT` parameter.

Servers MUST specify the casemapping they use in the [`RPL_ISUPPORT`](#feature-advertisement) numeric sent on completion of client registration.


## Messages

Servers and clients send each other messages which may or may not generate a reply; client to server communication is essentially asynchronous in nature.

Each IRC message may consist of up to four main parts: tags (optional), the prefix (optional), the command, and the command parameters (of which there may be up to 15).

Servers may supply tags (when negotiated) and a prefix on any or all messages they send to clients.

Information on standard client messages are available in the [Client Messages](#client-messages) and [Numerics](#numerics) sections.

### Tags

Tags are additional and optional metadata included with relevant messages.

Every message tag is enabled by a capability (as outlined in the [Capability Negotiation](#capability-negotiation) section). One capability may enable several tags if those tags are intended to be used together.

Each tag may have its own rules about how it can be used: from client to server only, from server to client only, or in both directions.

Servers MUST NOT add a tag to a message if the client has not requested the capability which enables the tag. Servers MUST NOT add a tag to a message before replying to a client's request (`CAP REQ`) for the capability which enables that tag with an acknowledgement (`CAP ACK`). If a client requests a capability which enables one or more message tags, that client MUST be able to parse the tags syntax.

Similarly, clients MUST NOT add a tag to messages before the server replies to the client's request (`CAP REQ`) with an acknowledgement (`CAP ACK`). If the server accepts a capability request which enables tags on messages sent from the client to the server, the server MUST be able to parse the tags syntax on incoming messages from clients.

Both clients and servers MAY parse supplied tags without any capabilities being enabled on the connection. They SHOULD ignore the tags of capabilities which are not enabled.

Clients that enable message tags MUST NOT fail to parse any message because of the presence of tags on that message. In other words, clients that enable message tags MUST assume that any message from the server may contain message tags, and must handle this correctly.

More information on the naming and registration of tags can be found in the [Message Tags](#message-tags) section.

### Prefix

The prefix is used by servers to indicate the true origin of a message. If the prefix is missing from the message, it is assumed to have originated from the connection from which it was received.

Clients SHOULD NOT use a prefix when sending a message from themselves. If they use a prefix, the only valid prefix is the registered nickname associated with the client. If the source identified by the prefix cannot be found in the server's internal database, or if the source is registered from a different link than from which the message arrived, the server MUST ignore the message silently.

Clients MUST be able to correctly parse and handle any message from the server containing a prefix in the same way it would handle the message if it did not contain a prefix. In other words, servers MAY add a prefix to any message sent to clients, and clients MUST be able to handle this correctly.

### Command

The command must either be a valid IRC command or a three-digit number represented as text.

Information on specific commands can be found in the [Client Messages](#client-messages) section.

### Parameters

Parameters (or 'params') are extra pieces of information added to the end of a message. These parameters generally make up the 'data' portion of the message. The meaning of specific parameters changes for every single message.


## Wire Format

The protocol messages are extracted from a contiguous stream of octets. A pair of characters, `CR` `('\r', 0x13)` and `LF` `('\n', 0x10)`, act as message separators. Empty messages are silently ignored, which permits use of the sequence CR-LF between messages.

The tags, prefix, command, and all parameters are separated by one (or more) ASCII space character(s) `(' ', 0x20)`.

The presense of tags is indicated with a single leading 'at sign' character `('@', 0x40)`, which MUST be the first character of the message itself. There MUST NOT be any whitespace between this leading character and the list of tags.

The presence of a prefix is indicated with a single leading colon character `(':', 0x3b)`. If there are no tags it MUST be the first character of the message itself. There MUST NOT be any whitespace between this leading character and the prefix

Most IRC servers limit lines to 512 bytes in length, including the trailing `CR-LF` characters. Implementations which include message tags allow an additional 512 bytes for the tags section of a message, including the leading `'@'` and trailing space character. There is no provision for continuation message lines.

The proposed [`LINELEN`](#linelen-parameter) `RPL_ISUPPORT` parameter lets a server specify the maximum allowed length of IRC lines, comprising of both the tags section and the rest of the message. However, use of this token is not widespread and is only used in an experimental server right now.

### Wire format in ABNF

The extracted message is parsed into the components `tags`, `prefix`, `command`, and a list of parameters (`params`).

The ABNF representation for this is:

      message     =  [ "@" tags SPACE ] [ ":" prefix SPACE ] command
                     [ params ] crlf
      tags        =  tag *[ ";" tag ]
      tag         =  key [ "=" value ]
      key         =  [ vendor "/" ] 1*( ALPHA / DIGIT / "-" )
      value       =  *valuechar
      valuechar   =  %x01-06 / %x08-09 / %x0B-0C / %x0E-1F / %x21-3A / %x3C-FF
                       ; any octet except NUL, BELL, CR, LF, " " and ";"
      vendor      =  hostname
      prefix      =  servername / ( nickname [ [ "!" user ] "@" host ] )
      command     =  1*letter / 3digit
      params      =  *13( SPACE middle ) [ SPACE ":" trailing ]
                  =/ 14( SPACE middle ) [ SPACE [ ":" ] trailing ]

      nospcrlfcl  =  %x01-09 / %x0B-0C / %x0E-1F / %x21-39 / %x3B-FF
                       ; any octet except NUL, CR, LF, " " and ":"
      middle      =  nospcrlfcl *( ":" / nospcrlfcl )
      trailing    =  *( ":" / " " / nospcrlfcl )


      SPACE       =  %x20 *( %x20 )   ; space character(s)
      crlf        =  %x0D %x0A        ; "carriage return" "linefeed"

NOTES:

1. `<SPACE>` consists only of ASCII SPACE character(s) `(' ', 0x20)`. Specifically notice that TABULATION, and all other control characters are not considered a part of `<SPACE>`.
2. After extracting the parameter list, all parameters are equal, whether matched by `<middle>` or `<trailing>`. `<trailing>` is just a syntactic trick to allow `SPACE` `(0x20)` characters within a parameter.
3. The `NUL` `(0x00)` character is not special in message framing, but as it would cause extra complexities in traditional C string handling, it is not allowed within messages.
4. The last parameter may be an empty string.
5. Use of the extended prefix (`[ [ "!" user ] "@" host ]`) is only intended for server to client messages in order to provide clients with more useful information about who a message is from without the need for additional queries. Servers SHOULD provide this extended prefix on any message where the prefix contains a nickname.

Most protocol messages specify additional semantics and syntax for the extracted parameter strings dictated by their position in the list. As an example, for many server commands, the first parameter of that message is a list of targets.

<div class="warning">
    TODO: This section is unfinished. Defining the various names (nickname, username, hostname) and such are likely to require quite a bit of thought. This is to cater for how software can let IRC operators use almost anything in them including formatting characters, etc. We should also make sure that the ABNF block above is correct and defined properly.
</div>


## Numeric Replies

Most messages sent from a client to a server generates a reply of some sort. The most common form of reply is the numeric reply, used for both errors and normal replies. A numeric reply MUST be sent as one message containing the sender prefix and the three-digit numeric. A numeric reply SHOULD contain the target of the reply as the first parameter of the message. A numeric reply is not allowed to originate from a client.

In all other respects, a numeric reply is just like a normal message, except that the keyword is made up of 3 numeric digits rather than a string of letters. A list of numeric replies is supplied in the [Numerics](#numerics) section.


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

Until registration is complete, only a limited subset of commands may be accepted by the server.

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

Upon successful completion of the registration process, the server MUST send the [`RPL_WELCOME`](#rplwelcome-001) `(001)`, [`RPL_YOURHOST`](#rplyourhost-002) `(002)`, [`RPL_CREATED`](#rplcreated-003) `(003)`, [`RPL_MYINFO`](#rplmyinfo-004) `(004)`, and at least one [`RPL_ISUPPORT`](#rplisupport-005) `(005)` numeric to the client. The server MAY send other numerics and messages. The server MUST then respond as though the client sent it the [`MOTD`](#motd-message) command, i.e. it must send either the successful [Message of the Day](#motd-message) numerics or the [`ERR_NOMOTD`](#errnomotd-422) numeric.


---


# Feature Advertisement

IRC servers and networks implement many different IRC features, limits, and protocol options that clients should be aware of. The [`RPL_ISUPPORT`](#rplisupport-005) `(005)` numeric is designed to advertise these features to clients on connection registration, providing a simple way for clients to change their behaviour based on what is implemented on the server.

Once client registration is complete, the server MUST send at least one `RPL_ISUPPORT` numeric to the client. The server MAY send more than one `RPL_ISUPPORT` numeric and consecutive `RPL_ISUPPORT` numerics SHOULD be sent adjacent to each other.

Clients SHOULD NOT assume a server supports a feature unless it has been advertised in `RPL_ISUPPORT`. For `RPL_ISUPPORT` parameters which specify a 'default' value, clients SHOULD assume the default value for these parameters until the server advertises these parameters itself. This is generally done for compatibility reasons with older versions of the IRC protocol that do not specify the `RPL_ISUPPORT` numeric.

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

Command Example:

      PASS secretpasswordhere

### NICK message

         Command: NICK
      Parameters: <nickname>

The `NICK` command is used to give the client a nickname or change the previous one.

If the server receives a `NICK` command from a client where the desired nickname is already in use on the network, it should issue an `ERR_NICKNAMEINUSE` numeric and ignore the `NICK` command.

If the server does not accept the new nickname supplied by the client as valid (for instance, due to containing invalid characters), it should issue an `ERR_ERRONEUSNICKNAME` numeric and ignore the `NICK` command.

If the server does not receive the `<nickname>` parameter with the `NICK` command, it should issue an `ERR_NONICKNAMEGIVEN` numeric and ignore the `NICK` command.

The `NICK` message may be sent from the server to client to inform clients about other clients changing their nicknames. In this case, the `<source>` of the message will be the user who is changing their nickname.

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

The second and third parameters of this command SHOULD be sent as one zero `('0', 0x30)` and one asterix character `('*', 0x2A)` by the client, as the meaning of these two parameters varies between different versions of the IRC protocol.

If a client tries to send the `USER` command after they have already completed registration with the server, the `ERR_ALREADYREGISTERED` reply should be sent and the attempt should fail.

If the client sends a `USER` command after the server has successfully received a username using the Ident Protocol, the `<username>` parameter from this command should be ignored in favour of the one received from the identity server.

Numeric Replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_ALREADYREGISTRED`](#erralreadyregistred-462) `(462)`

Command Examples:

      USER guest tolmoon tolsun :Ronnie Reagan
                                  ; No ident server
                                  ; User gets registered with username
                                  "~guest" and real name "Ronnie Reagan"

      USER guest tolmoon tolsun :Ronnie Reagan
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

The `QUIT` command is used to terminate a client's connection to the server. The server acknowledges this by replying with an [`ERROR` message](#error-message) and closing the connection to the client.

This message may also be sent from the server to a client to show that a client has exited from the network. This is typically only dispatched to clients that share a channel with the exiting user. When the `QUIT` message is sent to clients, `<source>` represents the client that has exited the network.

When connections are terminated by a client-sent `QUIT` command, servers SHOULD prepend `<reason>` with the ascii string `"Quit: "` when sending `QUIT` messages to other clients, to represent that this user terminated the connection themselves. This applies even if `<reason>` is empty, in which case the reason sent to other clients SHOULD be just this `"Quit: "` string. However, clients SHOULD NOT change behaviour based on the prefix of `QUIT` message reasons, as this is not required behaviour from servers.

When a netsplit (the disconnecting of two servers) occurs, a `QUIT` message is generated for each client that has exited the network, distributed in the same way as ordinary `QUIT` messages. The `<reason>` on these `QUIT` messages SHOULD be composed of the names of the two servers involved, separated by a SPACE `(' ', 0x20)`. The first name is that of the server which is still connected and the second name is that of the server which has become disconnected. If servers wish to hide or obscure the names of the servers involved, the `<reason>` on these messages MAY also be the literal ascii string `"*.net *.split"` (i.e. the two server names are replaced with `"*.net"` and `"*.split"`). Software that implements the IRCv3 [`batch` Extension](http://ircv3.net/specs/extensions/batch-3.2.html) should also look at the [`netsplit` and `netjoin`](http://ircv3.net/specs/extensions/batch/netsplit-3.2.html) batch types.

If a client connection is closed without the client issuing a `QUIT` command to the server, the server MUST distribute a `QUIT` message to other clients informing them of this, distributed in the same was an an ordinary `QUIT` message. Servers MUST fill `<reason>` with a message reflecting the nature of the event which caused it to happen. For instance, `"Ping timeout: 120 seconds"`, `"Excess Flood"`, and `"Too many connections from this IP"` are examples of relevant reasons for closing or for a connection with a client to have been closed.

Numeric Replies:

* None

Command Example:

      QUIT :Gone to have lunch         ; Client exiting from the network

Message Example:

      dan-!d@localhost QUIT :Quit: Bye for now!
                                       ; dan- is exiting the network with
                                       the message: "Quit: Bye for now!"


## Channel Operations

This group of messages is concerned with manipulating channels, their properties (channel modes), and their contents (typically clients).

These commands may be requests to the server, in which case the server will or will not grant the request. If a 'request' is granted, it will be acknowledged by the server sending a message containing the same information back to the client. This is to tell the user that the request was successful. These sort of 'request' commands will be noted in the message information.

In implementing these messages, race conditions are inevitable when clients at opposing ends of a network send commands which will ultimately clash. Server-to-server protocols should be aware of this and make sure their protocol ensures consistent state across the entire network.

### JOIN message

         Command: JOIN
      Parameters: <channel>{,<channel>} [<key>{,<key>}]

The `JOIN` command indicates that the client wants to join the given channel(s), each channel using the given key for it. The server receiving the command checks whether or not the client can join the given channel, and processes the request. Servers MUST process the parameters of this command as lists on incoming commands from clients, with the first `<key>` being used for the first `<channel>`, the second `<key>` being used for the second `<channel>`, etc.

While a client is joined to a channel, they receive all relevant information about that channel including the `JOIN`, `PART`, `KICK`, and `MODE` messages affecting the channel. They receive all `PRIVMSG` and `NOTICE` messages sent to the channel, and they also receive `QUIT` messages from other clients joined to the same channel (to let them know those users have left the channel and the network). This allows them to keep track of other channel members and channel modes.

If a client's `JOIN` command to the server is successful, they receive a `JOIN` message from the server with their client as the message `<source>` and the channel they have joined as the first parameter of the message. After this, they are sent the channel's topic (with [`RPL_TOPIC`](#rpltopic-332)), and no message if the channel does not have a topic. They are also sent a list of users currently joined to the channel (with [`RPL_NAMREPLY`](#rplnamreply-353)). This `RPL_NAMREPLY` message sent by the server MUST include the requesting client that has just joined the channel.

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
      Parameters: <channel>{,<channel>}

The `PART` command removes the client from the given channel(s). On sending a successful `PART` command, the user will receive a `PART` message from the server for each channel they have been removed from.

For each channel in the parameter of this command command, if the channel exists and the client is not joined to it, they will receive an [`ERR_NOTONCHANNEL`](#errnotonchannel-442) reply and that channel will be ignored. If the channel does not exist, the client will receive an [`ERR_NOSUCHCHANNEL`](#errnosuchchannel-403) reply and that channel will be ignored.

This message may be sent from a server to a client to notify the client that someone has been removed from a channel. In this case, the message `<source>` will be the client who is being removed, and `<channel>` will be the channel which that client has been removed from. Servers SHOULD NOT send multiple channels in this message to clients, and SHOULD distribute these multiple-channel `PART` messages as a series of messages with a single channel name on each.

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
* [`RPL_STATSQLINE`](#statsqline-217) `(217)`
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

If `<target>` is a nickname, it MUST be the same nickname as the user who sent the command. If a client is trying to set modes for a different user, the [`ERR_USERSDONTMATCH`](#errusersdontmatch-502) numeric is returned and the command will fail.

If `<target>` is a channel, the user sending the command MUST have appropriate channel priveleges to change modes (as well as to change the specific modes it is requesting), such as [halfop](#halfop-prefix) or [chanop](#operator-prefix). If a user does not have permission to change modes on the target channel, the [`ERR_CHANOPRIVSNEEDED`](#errchanoprivsneeded-482) numeric is returned and the command will fail. Servers MAY check permissions once at the start of processing the `MODE` command, or may check it on setting each mode character.

If `<target>` is a nickname and `<modestring>` is not given, the [`RPL_UMODEIS`](#rplumodeis-221) numeric will be sent back containing the current modes of the target user. If `<target>` is a channel and `<modestring>` is not given, the [`RPL_CHANNELMODEIS`](#rplchannelmodeis-324) numeric will be sent back containing the current modes of the target channel.

If `<modestring>` is given and the user has permission to change modes on the target, the supplied modes will be applied and a `MODE` message will be returned containing the mode changes that were applied. For type A, B, and C modes, arguments will be obtained from `<mode arguments>`, sequentially, as required. If a type B or C mode cannot be acted upon as it requires a argument and one has not been supplied, that mode will be silently ignored. If a type A mode has been sent without an argument (i.e., listing the contents of that mode's list), servers SHOULD only send the list for that mode to the client once, regardless of how many times that type A mode is contained in the `<modestring>`.

The `MODE` message is sent from the server to a client to show that the `<target>`'s modes have changed. Mode changes are only sent to clients for channels they are joined to and their own user modes. When the `MODE` message is sent to clients, `<source>` represents the client or server that changed the modes.

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

* **Type A**: Modes that add or remove an address to or from a list. These modes MUST always have a parameter when sent from the server to a client. A client MAY issue this type of mode without an argument to obtain the current contents of the list. The numerics used to retrieve contents of Type A modes depends on the specific mode.
* **Type B**: Modes that change a setting on a channel. These modes MUST always have a parameter.
* **Type C**: Modes that change a setting on a channel. These modes MUST have a parameter when being set, and MUST NOT have a parameter when being unset.
* **Type D**: Modes that change a setting on a channel. These modes MUST NOT have a parameter.

Channel mode letters, along with their types, are defined in the [`CHANMODES`](#chanmodes-parameter) `RPL_ISUPPORT` parameter. User mode letters are always **Type D** modes.

The meaning of standard (and/or well-used) channel and user mode letters can be found in the [Channel Modes](#channel-modes) and [User Modes](#user-modes) sections. The meaning of any mode letters not in this list are defined by the server software and configuration.

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
                                      operator priveleges to bunny on #foobar.


## Sending Messages

### PRIVMSG message

         Command: PRIVMSG
      Parameters: <target>{,<target>...} <text to be sent>

The `PRIVMSG` command is used to send private messages between users, as well as to send messages to channels. `<target>` is the nickname of a client or the name of a channel.

If `<target>` is a channel name and the client is [banned](#ban-channel-mode) and not covered by a [ban exemption](#ban-exemption-channel-mode), the message will not be delivered and the command will silently fail. Channels with the [moderated](#moderated-channel-mode) mode active may block messages from certain users. Other channel modes may affect the delivery of the message or cause the message to be modified before delivery, and these modes are defined by the server software and configuration being used.

If a message cannot be delivered to a channel, the server SHOULD respond with an [`ERR_CANNOTSENDTOCHAN`](#errcannotsendtochan-404) numeric to let the user know that this message could not be delivered.

If `<target>` is a channel name, it may be prefixed with a [channel membership prefix character (`@`, `+`, etc)](#channel-membership-prefixes) and the message will be delivered only to the members of that channel with the given or higher status in the channel. Servers that support this feature will list the prefixes which this is supported for in the [`STATUSMSG`](#statusmsg-parameter) `RPL_ISUPPORT` parameter, and this SHOULD NOT be attempted by clients unless the prefix has been advertised in this token.

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

Message Examples:

      :Angel PRIVMSG Wiz :Hello are you receiving this message ?
                                      ; Message from Angel to Wiz.

      :dan!~h@localhost PRIVMSG #coolpeople :Hi everyone!
                                      ; Message from dan to the channel
                                      #coolpeople

### NOTICE message

         Command: NOTICE
      Parameters: <target>{,<target>...} <text to be sent>

The `NOTICE` command is used to send notices between users, as well as to send notices to channels. `<target>` is interpreted the same way as it is for the [`PRIVMSG`](#privmsg-message) command.

The `NOTICE` message is used similarly to [`PRIVMSG`](#privmsg-message). The difference between `NOTICE` and [`PRIVMSG`](#privmsg-message) is that automatic replies must never be sent in response to a `NOTICE` message. This rule also applies to servers -- they must not send any error back to the client on receipt of a `NOTICE` command. The intention of this is to avoid loops between a client automatically sending something in response to something it received. This is typically used by 'bots' (a client with a program, and not a user, controlling their actions) and also for server messages to clients.

One thing for bot authors to note is that the `NOTICE` message may be interpreted differently by various clients. Some clients highlight or interpret any `NOTICE` sent to a channel in the same way that a `PRIVMSG` with their nickname gets interpreted. This means that users may be irritated by the use of `NOTICE` messages rather than `PRIVMSG` messages by clients or bots, and they are not commonly used by client bots for this reason.


---


# Modes

Modes affect the behaviour and reflect details about targets -- clients and channels. The modes listed here are the ones that have been adopted and are used by the IRC community at large. If we say a mode is 'standard', that means it is defined in the official IRC specification documents.

The status and letter used for each mode is defined in the description of that mode.

We only cover modes that are widely-used by IRC software today and whose meanings should stay consistent between different server software. For more extensive lists (including conflicting and obsolete modes), see the external `irc-defs` [client](http://defs.ircdocs.horse/defs/usermodes.html) and [channel](http://defs.ircdocs.horse/defs/chanmodes.html) mode lists.


## User Modes

### Invisible User Mode

This mode is standard, and the mode letter used for it is `"+i"`.

If a user is set to 'invisible', they will not show up in commands such as [`WHO`](#who-command) unless they share a channel with the user that submitted the command. In addition, the only channels that will show up in a [`WHOIS`](#whois-command) of an invisible user will be those they share with the user that submitted the command.

### Oper User Mode

This mode is standard, and the mode letter used for is it `"+o"`.

If a user has this mode, this indicates that they are a network [operator](#operators).

### Local Oper User Mode

This mode is standard, and the mode letter used for it is `"+O"`.

If a user has this mode, this indicates that they are a server [operator](#operators). A local operator only has [operator](#operators) priveleges for their server, and not for the rest of the network.

### Registered User Mode

This mode is widely-used, and the mode letter used for it is typically `"+r"`. The character used for this mode, and whether it exists at all, may vary depending on server software and configuration.

If a user has this mode, this indicates that they have logged into a user account.

IRCv3 extensions such as [`account-notify`](http://ircv3.net/specs/extensions/account-notify-3.1.html), [`account-tag`](http://ircv3.net/specs/extensions/account-tag-3.2.html), and [`extended-join`](http://ircv3.net/specs/extensions/extended-join-3.1.html) provide the account name of logged-in users, and are more accurate than trying to detect this user mode due to the capability name remaining consistent.

### `WALLOPS` User Mode

This mode is standard, and the mode letter used for it is `"+w"`.

If a user has this mode, this indicates that they will receive [`WALLOPS`](#wallops-message) messages from the server.


## Channel Modes

### Ban Channel Mode

This mode is standard, and the mode letter used for it is `"+b"`.

This channel mode controls a list of client masks that are 'banned' from joining or speaking in the channel. If this mode has values, each of these values should be a client mask.

If this mode is set on a channel, and a client sends a `JOIN` request for this channel, their nickmask (the combination of `nick!user@host`) is compared with each banned client mask set with this mode. If they match one of these banned masks, they will receive an [`ERR_BANNEDFROMCHAN`](#errbannedfromchan-474) reply and the `JOIN` command will fail. See the [ban exemption](#ban-exemption-channel-mode) mode for more details.

### Ban Exemption Channel Mode

This mode is used in almost all IRC software today. The standard mode letter used for it is `"+e"`, but it SHOULD be defined in the [`EXCEPTS`](#excepts-parameter) `RPL_ISUPPORT` parameter on connection.

This channel mode controls a list of client masks that are exempt from the ['ban'](#ban-channel-mode) channel mode. If this mode has values, each of these values should be a client mask.

If this mode is set on a channel, and a client sends a `JOIN` request for this channel, their nickmask is compared with each 'exempted' client mask. If their nickmask matches any one of the masks set by this mode, and their nickmask also matches any one of the masks set by the [ban](#ban-channel-mode) channel mode, they will not be blocked from joining due to the [ban](#ban-channel-mode) mode.

### Client Limit Channel Mode

This mode is standard, and the mode letter used for it is `"+l"`.

This channel mode controls whether new users may join based on the number of users who already exist in the channel. If this mode is set, its value is an integer and defines the limit of how many clients may be joined to the channel.

If this mode is set on a channel, and the number of users joined to that channel matches or exceeds the value of this mode, new users cannot join that channel. If a client sends a `JOIN` request for this channel, they will receive an [`ERR_CHANNELISFULL`](#errchannelisfull-471) reply and the command will fail.

### Invite-Only Channel Mode

This mode is standard, and the mode letter used for it is `"+i"`.

This channel mode controls whether new users need to be invited to the channel before being able to join.

If this mode is set on a channel, a user must have received an [`INVITE`](#invite-message) for this channel before being allowed to join it. If they have not received an invite, they will receive an [`ERR_INVITEONLYCHAN`](#errinviteonlychan-473) reply and the command will fail.

### Invite Exemption Channel Mode

This mode is used in almost all IRC software today. The standard mode letter used for it is `"+I"`, but it SHOULD be defined in the [`INVEX`](#invex-parameter) `RPL_ISUPPORT` parameter on connection.

This channel mode controls a list of channel masks that are exempt from the [invite-only](#invite-only-channel-mode) channel mode. If this mode has values, each of these values should be a client mask.

If this mode is set on a channel, and a client sends a `JOIN` request for that channel, their nickmask is compared with each 'exempted' client mask. If their nickmask matches any one of the masks set by this mode, and the channel is in [invite-only](#invite-only-channel-mode) mode, they do not need to require an `INVITE` in order to join the channel.

### Key Channel Mode

This mode is standard, and the mode letter used for it is `"+k"`.

This mode letter sets a 'key' that must be supplied in order to join this channel. If this mode is set, its' value is the key that is required.

If this mode is set on a channel, and a client sends a `JOIN` request for that channel, they must supply `<key>` in order for the command to succeed. If they do not supply a `<key>`, or the key they supply does not match the value of this mode, they will receive an [`ERR_BADCHANNELKEY`](#errbadchannelkey-475) reply and the command will fail.

### Moderated Channel Mode

This mode is standard, and the mode letter used for it is `"+m"`.

This channel mode controls whether users may freely talk on the channel, and does not have any value.

If this mode is set on a channel, only users who have channel privileges may send messages to that channel. The [voice](#voice-prefix) channel mode is designed to let a user talk in a moderated channel without giving them other channel moderation abilities, and users of higher privileges (such as [halfops](#halfop-prefix) or [chanops](#operator-prefix)) may also speak in moderated channels.

### Secret Channel Mode

This mode is standard, and the mode letter used for it is `"+s"`.

This channel mode controls whether the channel is 'secret', and does not have any value.

A channel that is set to secret will not show up in responses to the [`LIST`](#list-message) or [`NAMES`](#names-message) command unless the client sending the command is joined to the channel. Likewise, secret channels will not show up in the [`RPL_WHOISCHANNELS`](#rplwhoischannels-319) numeric unless the user the numeric is being sent to is joined to that channel.

### Protected Topic Mode

This mode is standard, and the mode letter used for it is `"+t"`.

This channel mode controls whether channel priveleges are required to set the topic, and does not have any value.

If this mode is enabled, users must have channel priveledges such as [halfop](#halfop-prefix) or [operator](#operator-prefix) status in order to change the topic of a channel. In a channel that does not have this mode enabled, anyone may set the topic of the channel using the [`TOPIC`](#topic-message) command.

### No External Messages Mode

This mode is standard, and the mode letter used for it is `"+n"`.

This channel mode controls whether users who are not joined to the channel can send messages to it, and does not have any value.

If this mode is enabled, users MUST be joined to the channel in order to send [private messages](#privmsg-message) and [notices](#notice-message) to the channel. If this mode is enabled and they try to send one of these to a channel they are not joined to, they will receive an [`ERR_CANNOTSENDTOCHAN`](#errcannotsendtochan-404) numeric and the message will not be sent to that channel.

## Channel Membership Prefixes

Users joined to a channel may get certain privileges or status in that channel based on channel modes given to them. These users are given prefixes before their nickname whenever it is associated with a channel (ie, in [`NAMES`](#names-message), [`WHO`](#who-message) and [`WHOIS`](#whois-message) messages). The standard and common prefixes are listed here, and MUST be advertised by the server in the [`PREFIX`](#prefix-parameter) `RPL_ISUPPORT` parameter on connection.

### Founder Prefix

This mode is used in a large number of networks. The prefix and mode letter typically used for it, respectively, are `"~"` and `"+q"`.

This prefix shows that the given user is the 'founder' of the current channel and has full moderation control over it -- ie, they are considered to 'own' that channel by the network. This prefix is typically only used on networks that have the concept of client accounts, and ownership of channels by those accounts.

### Protected Prefix

This mode is used in a large number of networks. The prefix and mode letter typically used for it, respectively, are `"&"` and `"+a"`.

Users with this mode cannot be kicked and cannot have this mode removed by other protected users. In some software, they may perform actions that operators can, but at a higher privilege level than operators. This prefix is typically only used on networks that have the concept of client accounts, and ownership of channels by those accounts.

### Operator Prefix

This mode is standard. The prefix and mode letter used for it, respectively, are `"@"` and `"+o"`.

Users with this mode may perform channel moderation tasks such as kicking users, applying channel modes, and set other users to operator (or lower) status.

### Halfop Prefix

This mode is widely used in networks today. The prefix and mode letter used for it, respectively, are `"%"` and `"+h"`.

Users with this mode may perform channel moderation tasks, but at a lower privilege level than operators. Which channel moderation tasks they can and cannot perform varies with server software and configuration.

### Voice Prefix

This mode is standard. The prefix and mode letter used for it, respectively, are `"+"` and `"+v"`.

Users with this mode may send messages to a channel that is [moderated](#moderated-channel-mode).


---


# Numerics

As mentioned in the [numeric replies](#numeric-replies) section, the first parameter of most numerics is the target of that numeric (the nickname of the client that is receiving it). Underneath the name and numeric of each reply, we list the parameters sent by this message.

Clients MUST not fail because the number of parameters on a given incoming numeric is larger than the number of parameters we list for that numeric here. Most IRC servers extends some of these numerics with their own special additions. For example, if a message is listed here as having 2 parameters, and your client receives it with 5 parameters, your client should not fail to parse or handle that message correctly because of the extra parameters.

Optional parameters are surrounded with the standard square brackets `([<optional>])` -- this means clients MUST NOT assume they will receive this parameter from all servers, and that servers SHOULD send this parameter unless otherwise specified in the numeric description. Parameters and parts of parameters surrounded with curly brackets `({ <repeating>})` may be repeated zero or more times.

Server authors that wish to extend one of the numerics listed here SHOULD make their extension into a [client capability](#capability-negotiation). If your extension would be useful to other client and server software, you should consider submitting it to the [IRCv3 Working Group](http://ircv3.net/) for standardisation.

Note that for numerics with very "human-readable" informational strings for the last parameter which are not designed to be parsed, such as in `RPL_WELCOME`, servers commonly change this last-param text. Clients SHOULD NOT rely on these sort of parameters to have exactly the same human-readable string as described in this document. Clients that rely on the format of these human-readable final informational strings may fail.
We do try to note numerics where this is the case with a message like *"The text used in the last param of this message varies wildly"*.

### `RPL_WELCOME (001)`

      "<client> :Welcome to the <networkname> Network, <nick>[!<user>@<host>]"

The first message sent after client registration, this message introduces the client to the network. The text used in the last param of this message varies wildly.

Servers that implement spoofed hostmasks in any capacity SHOULD NOT include the extended (complete) hostmask in the last parameter of this reply, either for all clients or for those whose hostnames have been spoofed. This is because some clients try to extract the hostname from this final parameter of this message and resolve this hostname, in order to discover their 'local IP address'.

Clients MUST NOT try to extract the hostname from the final parameter of this message and then attempt to resolve this hostname. This method of operation WILL BREAK and will cause issues when the server returns a spoofed hostname.

### `RPL_YOURHOST (002)`

      "<client> :Your host is <servername>, running version <version>"

Part of the post-registration greeting, this numeric returns the name and software/version of the server the client is currently connected to. The text used in the last param of this message varies wildly.

### `RPL_CREATED (003)`

      "<client> :This server was created <datetime>"

Part of the post-registration greeting, this numeric returns a human-readable date/time that the server was started or created. The text used in the last param of this message varies wildly.

### `RPL_MYINFO (004)`

      "<client> <servername> <version> <available user modes>
      <available channel modes> [<channel modes with a parameter>]"

Part of the post-registration greeting. Clients SHOULD discover available features using `RPL_ISUPPORT` tokens rather than the mode letters listed in this reply.

### `RPL_ISUPPORT (005)`

      "<client> <1-13 tokens> :are supported by this server"

The ABNF representation for an `RPL_ISUPPORT` token is:

      token      =  parameter *1( "=" value )
      parameter  =  1*20 letter
      value      =  * letpun
      letter     =  ALPHA / DIGIT
      punct      =  %d33-47 / %d58-64 / %d91-96 / %d123-126
      letpun     =  letter / punct

As the maximum number of parameters to any reply is 15, the maximum number of   `RPL_ISUPPORT` tokens that can be advertised is 13. To counter this, a server MAY issue multiple `RPL_ISUPPORT` numerics. A server MUST issue at least one `RPL_ISUPPORT` numeric after client registration has completed. It MUST be issued before further commands from the client are processed.

As with other local numerics, when `RPL_ISUPPORT` is delivered remotely, it MUST be converted into a `105` numeric before delivery to the client.

A token is of the form `PARAMETER` or `PARAMETER=VALUE`. A server MAY send an empty value field, and a parameter MAY have a default value. A server MUST send the parameter as upper-case text. Unless otherwise stated, when a parameter contains a value, the value MUST be treated as being case sensitive. The value MAY contain multiple fields, if this is the case the fields MUST be delimited with a comma character (`,`).

See the [Feature Advertisement](#feature-advertisement) section for more details on this numeric. A list of `RPL_ISUPPORT` parameters is available in the [`RPL_ISUPPORT` Parameters](#rplisupport-parameters) section.

### `RPL_BOUNCE (010)`

      "<client> <hostname> <port> :<info>"

Sent to the client to redirect it to another server. The `<info>` text varies between server software and reasons for the redirection.

Because this numeric does not specify whether to enable SSL and is not interpreted correctly by all clients, it is recommended that this not be used.

This numeric is also known as `RPL_REDIR` by some software.

### `RPL_UMODEIS (221)`

      "<client> <user modes>"

Sent to a client to inform that client of their currently-set user modes.

### `RPL_LUSERCLIENT (251)`

      "<client> :There are <u> users and <i> invisible on <s> servers"

Sent as a reply to the [`LUSER`](#luser-message) command. `<u>`, `<i>`, and `<s>` are non-negative integers, and represent the number of total users, invisible users, and other servers connected to this server.

### `RPL_LUSEROP (252)`

      "<client> <ops> :operator(s) online"

Sent as a reply to the [`LUSER`](#luser-message) command. `<ops>` is a positive integer and represents the number of [IRC operators](#operators) connected to this server. The text used in the last param of this message may vary.

### `RPL_LUSERUNKNOWN (253)`

      "<client> <connections> :unknown connection(s)"

Sent as a reply to the [`LUSER`](#luser-message) command. `<connections>` is a positive integer and represents the number of connections to this server that are currently in an unknown state. The text used in the last param of this message may vary.

### `RPL_LUSERCHANNELS (254)`

      "<client> <channels> :channels formed"

Sent as a reply to the [`LUSER`](#luser-message) command. `<channels>` is a positive integer and represents the number of channels that currently exist on this server. The text used in the last param of this message may vary.

### `RPL_LUSERME (255)`

      "<client> :I have <c> clients and <s> servers"

Sent as a reply to the [`LUSER`](#luser-message) command. `<c>` and `<s>` are non-negative integers and represent the number of clients and other servers connected to this server, respectively.

### `RPL_ADMINME (256)`

      "<client> <server> :Administrative info"

Sent as a reply to an [`ADMIN`](#admin-message) command, this numeric establishes the name of the server whose administrative info is being provided. The text used in the last param of this message may vary.

### `RPL_ADMINLOC1 (257)`

      "<client> :<info>"

Sent as a reply to an [`ADMIN`](#admin-message) command, `<info>` is a string intended to provide information about the location of the server (i.e. city, state and country). The text used in the last param of this message varies wildly.

### `RPL_ADMINLOC2 (258)`

      "<client> :<info>"

Sent as a reply to an [`ADMIN`](#admin-message) command, `<info>` is a string intended to provide information about whoever runs the server (i.e. details of the institution hosting it). The text used in the last param of this message varies wildly.

### `RPL_ADMINEMAIL (259)`

      "<client> :<info>"

Sent as a reply to an [`ADMIN`](#admin-message) command, `<info>` MUST contain the email address to contact the administrator(s) of the server. The text used in the last param of this message varies wildly.

### `RPL_TRYAGAIN (263)`

      "<client> <command> :Please wait a while and try again."

When a server drops a command without processing it, this numeric MUST be sent to inform the client. The text used in the last param of this message varies wildly, and commonly provides the client with more information about why the command could not be processed (i.e., due to rate-limiting).

### `RPL_LOCALUSERS (264)`

      "<client> [<u> <m>] :Current local users <u>, max <m>"

Sent as a reply to the [`LUSER`](#luser-message) command. `<u>` and `<m>` are non-negative integers and represent the number of clients currently and the maximum number of clients that have been connected directly to this server at one time, respectively.

The two optional parameters SHOULD be supplied to allow clients to better extract these numbers.

### `RPL_GLOBALUSERS (265)`

      "<client> [<u> <m>] :Current global users <u>, max <m>"

Sent as a reply to the [`LUSER`](#luser-message) command. `<u>` and `<m>` are non-negative integers. `<u>` represents the number of clients currently connected to this server, globally (directly and through other server links). `<m>` represents the maximum number of clients that have been connected to this server at one time, globally.

The two optional parameters SHOULD be supplied to allow clients to better extract these numbers.

### `RPL_WHOISCERTFP (276)`

      "<client> <nick> :has client certificate fingerprint <fingerprint>"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric shows the SSL/TLS certificate fingerprint used by the client with the nickname `<nick>`. Clients MUST only be sent this numeric if they are either using the `WHOIS` command on themselves or they are an [operator](#operators).

### `RPL_NONE (300)`

`RPL_NONE` is a dummy numeric. It does not have a defined use nor format.

### `RPL_AWAY (301)`

      "<client> <nick> :<message>"

Indicates that the user with the nickname `<nick>` is currently away and sends the away message that they set.

### `RPL_USERHOST (302)`

      "<client> :[<reply>{ <reply>}]"

Sent as a reply to the [`USERHOST`](#userhost-message) command, this numeric lists nicknames and the information associated with them. The last parameter of this numeric (if there are any results) is a list of `<reply>` values, delimited by a SPACE character `(' ', 0x20)`.

The ABNF representation for `<reply>` is:

      reply   =  nickname [ isop ] "=" isaway hostname
      isop    =  "*"
      isaway  =  ( "+" / "-" )

`<isop>` is included if the user with the nickname of `<nickname>` has registered as an [operator](#operators). `<isaway>` represents whether that user has set an [away] message. `"+"` represents that the user is not away, and `"-"` represents that the user is away.

### `RPL_ISON (303)`

      "<client> :[<nickname>{ <nickname>}]"

Sent as a reply to the [`ISON`](#ison-message) command, this numeric lists the nicks that are present on the network. The last parameter of this numeric (if there are any results) is a list of nicknames, delimited by a SPACE character `(' ', 0x20)`.

### `RPL_UNAWAY (305)`

      "<client> :You are no longer marked as being away"

Sent as a reply to the [`AWAY`](#away-message) command, this lets the client know that they are no longer set as being away. The text used in the last param of this message may vary.

### `RPL_NOWAWAY (306)`

      "<client> :You have been marked as being away"

Sent as a reply to the [`AWAY`](#away-message) command, this lets the client know that they are set as being away. The text used in the last param of this message may vary.

### `RPL_WHOISUSER (311)`

      "<client> <nick> <username> <host> * :<realname>"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric shows details about the client with the nickname `<nick>`. `<username>` and `<realname>` represent the names set by the [`USER`](#user-message) command (though `<username>` may be set by the server in other ways). `<host>` represents the host used for the client in nickmasks (which may or may not be a real hostname or IP address). The second-last parameter is a literal asterix character `('*', 0x2A)` and does not mean anything.

### `RPL_WHOISSERVER (312)`

      "<client> <nick> <server> :<server info>"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric shows which server the client with the nickname `<nick>` is connected to. `<server>` is the name of the server (as used in message prefixes). `<server info>` is a string containing a description of that server.

### `RPL_WHOISOPERATOR (313)`

      "<client> <nick> :is an IRC operator"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric indicates that the client with the nickname `<nick>` is an [operator](#operators). This command MAY also indicate what type or level of operator the client is by changing the text in the last parameter of this numeric. The text used in the last param of this message varies wildly, and SHOULD be displayed as-is by IRC clients to their users.

### `RPL_WHOWASUSER (314)`

      "<client> <nick> <username> <host> * :<realname>"

Sent as a reply to the [`WHOWAS`](#whowas-message) command, this numeric shows details about the last client that used the nickname `<nick>`. The purpose of each argument is the same as with the [`RPL_WHOISUSER`](#rplwhoisuser-311) numeric.

### `RPL_WHOISIDLE (317)`

      "<client> <nick> <secs> [<signon>] :seconds idle, signon time

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric indicates how long the client with the nickname `<nick>` has been idle. `<secs>` is the number of seconds since the client has been active. Servers generally denote specific commands (for instance, perhaps [`JOIN`](#join-message), [`PRIVMSG`](#privmsg-message), [`NOTICE`](#notice-message), etc) as updating the 'idle time', and calculate this off when the idle time was last updated. `<signon>` is a unix timestamp representing when the user joined the network. The text used in the last param of this message may vary.

### `RPL_ENDOFWHOIS (318)`

      "<client> <nick> :End of /WHOIS list"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric indicates the end of a `WHOIS` response for the client with the nickname `<nick>`. This numeric is sent after all other `WHOIS` response numerics have been sent to the client.

### `RPL_WHOISCHANNELS (319)`

      "<client> <nick> :[prefix]<channel>{ [prefix]<channel>}

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric lists the channels that the client with the nickname `<nick>` is joined to and their status in these channels. `<prefix>` is the highest [channel membership prefix](#channel-membership-prefixes) that the client has in that channel, if the client has one. `<channel>` is the name of a channel that the client is joined to. The last parameter of this numeric is a list of `[prefix]<channel>` pairs, delimited by a SPACE character `(' ', 0x20)`.

The channels in this response are affected by the [secret](#secret-channel-mode) channel mode and the [invisible](#invisible-user-mode) user mode, and may be affected by other modes depending on server software and configuration.

### `RPL_LISTSTART (321)`

      "<client> Channel :Users  Name"

Sent as a reply to the [`LIST`](#list-message) command, this numeric marks the start of a channel list. As noted in the command description, this numeric MAY be skipped by the server so clients MUST NOT depend on receiving it.

### `RPL_LIST (322)`

      "<client> <channel> <visible clients> :<topic>"

Sent as a reply to the [`LIST`](#list-message) command, this numeric sends information about a channel to the client. `<channel>` is the name of the channel. `<visible clients>` is an integer indicating how many clients are joined to that channel. `<topic>` is the channel's topic (as set by the [`TOPIC`](#topic-message) command).

### `RPL_LISTEND (323)`

      "<client> :End of /LIST"

Sent as a reply to the [`LIST`](#list-message) command, this numeric indicates the end of a `LIST` response.

### `RPL_CHANNELMODEIS (324)`

      "<client> <channel> <modestring> <mode arguments>..."

Sent to a client to inform them of the currently-set modes of a channel. `<channel>` is the name of the channel. `<modestring>` and `<mode arguments>` are a mode string and the mode arguments (delimited as separate parameters) as defined in the [`MODE`](#mode-message) message description.

### `RPL_NOTOPIC (331)`

      "<client> <channel> :No topic is set"

Sent as a reply to the [`TOPIC`](#topic-message) command, this numeric indicates that the channel with the name `<channel>` does not have any topic set.

### `RPL_TOPIC (332)`

      "<client> <channel> :<topic>"

Sent to a client to inform them of the current [topic](#topic-message) of the channel.

### `RPL_INVITING (341)`

      "<client> <channel> <nick>"

Sent as a reply to the [`INVITE`](#invite-message) command to indicate that the attempt was successful and the client with the nickname `<nick>` has been invited to `<channel>`.

### `RPL_VERSION (351)`

      "<client> <version> <server> :<comments>"

Sent as a reply to the [`VERSION`](#version-message) command, this numeric indicates information about the desired server. `<version>` is the name and version of the software being used (including any revision information). `<server>` is the name of the server. `<comments>` may contain any further comments or details about the specific version of the server.

### `RPL_ENDOFWHOWAS (369)`

      "<client> <nick> :End of WHOWAS"

Sent as a reply to the [`WHOWAS`](#whowas-message) command, this numeric indicates the end of a `WHOWAS` reponse for the nickname `<nick>`. This numeric is sent after all other `WHOWAS` response numerics have been sent to the client.

### `RPL_MOTDSTART (375)`

      "<client> :- <server> Message of the day - "

Indicates the start of the [Message of the Day](#motd-message) to the client. The text used in the last param of this message may vary, and SHOULD be displayed as-is by IRC clients to their users.

### `RPL_MOTD (372)`

      "<client> :<line of the motd>"

When sending the [`Message of the Day`](#motd-message) to the client, servers reply with each line of the `MOTD` as this numeric. `MOTD` lines MAY be wrapped to 80 characters by the server.

### `RPL_ENDOFMOTD (376)`

      "<client> :End of /MOTD command."

Indicates the end of the [Message of the Day](#motd-message) to the client. The text used in the last param of this message may vary.

### `RPL_YOUREOPER (381)`

      "<client> :You are now an IRC operator"

Sent to a client which has just successfully issued an [`OPER`](#oper-message) command and gained [operator](#operators) status. The text used in the last param of this message varies wildly.

### `RPL_REHASHING (382)`

      "<client> <config file> :Rehashing"

Sent to an [operator](#operators) which has just successfully issued a [`REHASH`](#rehash-message) command. The text used in the last param of this message may vary.

### `ERR_NOSUCHNICK (401)`

      "<client> <nickname> :No such nick/channel"

Indicates that no client can be found for the supplied nickname. The text used in the last param of this message may vary.

### `ERR_NOSUCHSERVER (402)`

      "<client> <server name> :No such server"

Indicates that the given server name does not exist. The text used in the last param of this message may vary.

### `ERR_NOSUCHCHANNEL (403)`

      "<client> <channel> :No such channel"

Indicates that no channel can be found for the supplied channel name. The text used in the last param of this message may vary.

### `ERR_CANNOTSENDTOCHAN (404)`

      "<client> <channel> :Cannot send to channel"

Indicates that the `PRIVMSG` / `NOTICE` could not be delivered to `<channel>`. The text used in the last param of this message may vary.

This is generally sent in response to channel modes, such as a channel being [moderated](#moderated-channel-mode) and the client not having permission to speak on the channel, or not being joined to a channel with the [no external messages](#no-external-messages-mode) mode set.

### `ERR_TOOMANYCHANNELS (405)`

      "<client> <channel> :You have joined too many channels"

Indicates that the `JOIN` command failed because the client has joined their maximum number of channels. The text used in the last param of this message may vary.

### `ERR_UNKNOWNCOMMAND (421)`

      "<client> <command> :Unknown command"

Sent to a registered client to indicate that the command they sent isn't known by the server. The text used in the last param of this message may vary.

### `ERR_NOMOTD (422)`

      "<client> :MOTD File is missing"

Indicates that the [Message of the Day](#motd-message) file does not exist or could not be found. The text used in the last param of this message may vary.

### `ERR_ERRONEUSNICKNAME (432)`

      "<client> <nick> :Erroneus nickname"

Returned when a [`NICK`](#nick-message) command cannot be successfully completed as the desired nickname contains characters that are disallowed by the server. See the [wire format](#wire-format-in-abnf) section for more information on characters which are allowed in various IRC servers. The text used in the last param of this message may vary.

### `ERR_NICKNAMEINUSE (433)`

      "<client> <nick> :Nickname is already in use"

Returned when a [`NICK`](#nick-message) command cannot be successfully completed as the desired nickname is already in use on the network. The text used in the last param of this message may vary.

### `ERR_NOTREGISTERED (451)`

      "<client> :You have not registered"

Returned when a client command cannot be parsed as they are not yet registered. Servers offer only a limited subset of commands until clients are properly registered to the server. The text used in the last param of this message may vary.

### `ERR_NEEDMOREPARAMS (461)`

      "<client> <command> :Not enough parameters"

Returned when a client command cannot be parsed because not enough parameters were supplied. The text used in the last param of this message may vary.

### `ERR_ALREADYREGISTERED (462)`

Returned when a client tries to change a detail that can only be set during registration (such as resending the [`PASS`](#pass-command) or [`USER`](#user-command) after registration). The text used in the last param of this message may vary.

### `ERR_PASSWDMISMATCH (464)`

      "<client> :Password incorrect"

Returned to indicate that the connection could not be registered as the [password](#pass-message) was either incorrect or not supplied. The text used in the last param of this message may vary.

### `ERR_YOUREBANNEDCREEP (465)`

      "<client> :You are banned from this server."

Returned to indicate that the server has been configured to explicitly deny connections from this client. The text used in the last param of this message varies wildly and typically also contains the reason for the ban and/or ban details, and SHOULD be displayed as-is by IRC clients to their users.

### `ERR_CHANNELISFULL (471)`

      "<client> <channel> :Cannot join channel (+l)"

Returned to indicate that a [`JOIN`](#join-message) command failed because the [client limit](#client-limit-channel-mode) mode has been set and the maximum number of users are already joined to the channel. The text used in the last param of this message may vary.

### `ERR_UNKNOWNMODE (472)`

      "<client> <modechar> :is unknown mode char to me"

Indicates that a mode character used by a client is not recognized by the server. The text used in the last param of this message may vary.

### `ERR_INVITEONLYCHAN (473)`

      "<client> <channel> :Cannot join channel (+i)"

Returned to indicate that a [`JOIN`](#join-message) command failed because the channel is set to [invite-only] mode and the client has not been [invited](#invite-message) to the channel or had an [invite exemption](#invite-exemption-channel-mode) set for them. The text used in the last param of this message may vary.

### `ERR_BANNEDFROMCHAN (474)`

      "<client> <channel> :Cannot join channel (+b)"

Returned to indicate that a [`JOIN`](#join-message) command failed because the client has been [banned](#ban-channel-mode) from the channel and has not had a [ban exemption](#ban-exemption-channel-mode) set for them. The text used in the last param of this message may vary.

### `ERR_BADCHANNELKEY (475)`

      "<client> <channel> :Cannot join channel (+k)"

Returned to indicate that a [`JOIN`](#join-message) command failed because the channel requires a [key](#key-channel-mode) and the key was either incorrect or not supplied. The text used in the last param of this message may vary.

### `ERR_NOPRIVILEGES (481)`

      "<client> :Permission Denied- You're not an IRC operator"

Indicates that the command failed because the user is not an [IRC operator](#operators). The text used in the last param of this message may vary.

### `ERR_CHANOPRIVSNEEDED (482)`

      "<client> <channel> :You're not channel operator"

Indicates that a command failed because the client does not have the appropriate [channel priveleges](#channel-operators). This numeric can apply for different prefixes such as [halfop](#halfop-prefix), [operator](#operator-prefix), etc. The text used in the last param of this message may vary.

### `ERR_CANTKILLSERVER (483)`

      "<client> :You cant kill a server!"

Indicates that a [`KILL`](#kill-message) command failed because the user tried to kill a server. The text used in the last param of this message may vary.

### `ERR_NOOPERHOST (491)`

      "<client> :No O-lines for your host"

Indicates that an [`OPER`](#oper-message) command failed because the server has not been configured to allow connections from this client's host to become an operator. The text used in the last param of this message may vary.

### `ERR_UMODEUNKNOWNFLAG (501)`

      "<client> :Unknown MODE flag"

Indicates that a [`MODE`](#mode-message) command affecting a user contained a `MODE` letter that was not recognized. The text used in the last param of this message may vary.

### `ERR_USERSDONTMATCH (502)`

      "<client> :Cant change mode for other users"

Indicates that a [`MODE`](#mode-message) command affecting a user failed because they were trying to set or view modes for other users. The text used in the last param of this message varies, for instance when trying to view modes for another user, a server may send: `"Can't view modes for other users"`.

### `ERR_NOPRIVS (723)`

      "<client> <priv> :Insufficient oper privileges."

Sent by a server to alert an IRC [operator](#operators) that they they do not have the specific operator privilege required by this server/network to perform the command or action they requested. The text used in the last param of this message may vary.

`<priv>` is a string that has meaning in the server software, and allows an operator the privileges to perform certain commands or actions. These strings are server-defined and may refer to one or multiple commands or actions that may be performed by IRC operators.

Examples of the sorts of privilege strings used by server software today include: `kline`, `dline`, `unkline`, `kill`, `kill:remote`, `die`, `remoteban`, `connect`, `connect:remote`, `rehash`.


---


# `RPL_ISUPPORT` Parameters

Used to [advertise features](#feature-advertisement) to clients, the [`RPL_ISUPPORT`](#rplisupport-005) numeric lists parameters that let the client know which features are active and their value, if any.

The parameters listed here are standardised and/or widely-advertised by IRC servers today and do not include deprecated parameters. Servers SHOULD support at least the following parameters where appropriate, and may advertise any others. For a more complete list of parameters advertised by this numeric, see the `irc-defs` [`RPL_ISUPPORT` list](http://defs.ircdocs.horse/defs/isupport.html).

If a 'default value' is listed for a parameter, this is the assumed value of the parameter until and unless it is advertised by the server. This is primarily to interoperate with servers that don't advertise particular well-known and well-used parameters. If an 'empty value' is listed for a parameter, this is the assumed value of the parameter if it is advertised without a value.

### `AWAYLEN` Parameter

The `AWAYLEN` parameter indicates the maximum length for the `<reason>` of an [`AWAY`](#away-message) command. If an [`AWAY`](#away-message) `<reason>` has more characters than this parameter, it may be silently truncated by the server before being passed on to other clients. Clients MAY receive an [`AWAY`](#away-message) `<reason>` that has more characters than this parameter.

The value MUST be specified and MUST be a positive integer.

Examples:

      AWAYLEN=200

      AWAYLEN=307

### `CASEMAPPING` Parameter

      Format: CASEMAPPING=<casemap>

The `CASEMAPPING` parameter indicates what method the server uses to compare equality of case-insensitive strings (such as channel names and nicks).

The value MUST be specified and MUST be a string representing the method that the server uses.

The specified casemappings are as follows:

* **`ascii`**: Defines the characters `a` to be considered the lower-case equivalents of the characters `A` to `Z` only.
* **`rfc1459`**: Defines the same casemapping as `'ascii'`, with the addition of the characters `'{'`, `'}'`, and `'|'` being considered the lower-case equivalents of the characters `'['`, `']'`, and `'\'` respectively.
* **`rfc3454`**: Proposed casemapping which defines that strings are to be compared using the nameprep method described in [`RFC3454`](http://tools.ietf.org/html/rfc3454) and [`RFC3491`](https://tools.ietf.org/html/rfc3491).

The value MUST be specified and is a string. Servers MAY advertise alternate casemappings to those above, but clients MAY NOT be able to understand or perform them.

<div class="warning">
      We should see whether the <code>rfc1459/strict-rfc1459</code> difference and warning at the end of <a href="https://tools.ietf.org/html/draft-hardy-irc-isupport-00#section-4.1">this section</a> is still applicable these days.
</div>

Examples:

      CASEMAPPING=ascii

      CASEMAPPING=rfc1459

### `CHANLIMIT` Parameter

      Format: CHANLIMIT=<prefixes>:[limit],<prefixes>:[limit],...

The `CHANLIMIT` parameter indicates the number of channels a client may join.

The value MUST be specified and is a list of `"<prefixes>:<limit>"` pairs, delimited by a comma `(',',` `0x2C)`. `<prefixes>` is a list of channel prefix characters as defined in the [`CHANTYPES`](#chantypes-parameter) parameter. `<limit>` is OPTIONAL and if specified is a positive integer indicating the maximum number of these types of channels a client may join. If there is no limit to the number of these channels a client may join, `<limit>` will not be specified.

Clients should not assume other clients are limited to what is specified in the `CHANLIMIT` parameter.

Examples:

      CHANLIMIT=#:25           ; indicates that clients may join 25 '#' channels

      CHANLIMIT=#&:50          ; indicates that clients may join 50 '#' and 50 '&' channels

      CHANLIMIT=#:70,&:        ; indicates that clients may join 70 '#' channels and any
                               number of '&' channels

### `CHANMODES` Parameter

      Format: CHANMODES=A,B,C,D[,X,Y...]

The `CHANMODES` parameter specifies the channel modes available and which types of arguments they do or do not take when using them with the [`MODE`](#mode-message) command.

The value lists the channel mode letters of **Type A**, **B**, **C**, and **D**, respectively, delimited by a comma `(',',` `0x2C)`. The channel mode types are defined in the the [`MODE`](#mode-message) message description.

To allow for future extensions, a server MAY send additional types, delimited by a comma `(',',` `0x2C)`. However, server authors SHOULD NOT extend this parameter without good reason, and SHOULD CONSIDER whether their mode would work as one of the existing types instead. The behaviour of any additional types is undefined.

Server MUST NOT list modes in this parameter that are also advertised in the [`PREFIX`](#prefix-parameter) parameter. However, modes within the [`PREFIX`](#prefix-parameter) parameter may be treated as type B modes.

Examples:

      CHANMODES=b,k,l,imnpst

      CHANMODES=beI,k,l,BCMNORScimnpstz

      CHANMODES=beI,kfL,lj,psmntirRcOAQKVCuzNSMTGZ

### `CHANNELLEN` Parameter

      Format: CHANNELLEN=<string>

The `CHANNELLEN` parameter specifies the maximum length of a channel name that a client may join. A client elsewhere on the network MAY join a channel with a larger name, but network administrators should take care to ensure this value stays consistent across the network.

The value MUST be specified and MUST be a positive integer.

Examples:

      CHANNELLEN=32

      CHANNELLEN=50

      CHANNELLEN=64

### `CHANTYPES` Parameter

       Format: CHANTYPES=[string]
      Default: CHANTYPES=#

The `CHANTYPES` parameter indicates the channel prefix characters that are available on the current server. Common channel types are listed in the [Channel Types](#channel-types) section.

The value is OPTIONAL and if not specified indicates that no channel types are supported.

Examples:

      CHANTYPES=#

      CHANTYPES=&#

      CHANTYPES=#&

### `ELIST` Parameter

      Format: ELIST=<string>

The `ELIST` parameter indicates that the server supports search extensions to the [`LIST`](#list-message) command.

The value MUST be specified, and is a non-delimited list of letters, each of which denote an extension. The letters MUST be treated as being case-insensitive.

The following search extensions are defined:

* **C**: Searching based on channel creation time, via the `"C<val"` and `"C>val"` modifiers to search for a channel creation time that is higher or lower than `val`.
* **M**: Searching based on a mask.
* **N**: Searching based on a non-matching mask. i.e., the opposite of `M`.
* **T**: Searching based on topic set time, via the `"T<val"` and `"T>val"` modifiers to search for a topic time that is higher or lower than `val`.
* **U**: Searching based on user count within the channel, via the `"U<val"` and `"U>val"` modifiers to search for a channel that has less or more user than `val`.

Examples:

      ELIST=MNUCT

      ELIST=MU

      ELIST=CMNTU

### `EXCEPTS` Parameter

      Format: EXCEPTS=[character]
       Empty: e

The `EXCEPTS` parameter indicates that the server supports ban exceptions, as specified in the [ban exemption](#ban-exemption-channel-mode) channel mode section.

The value is OPTIONAL and when not specified indicates that the letter `"e"` is used as the channel mode for ban exceptions. If the value is specified, the character indicates the letter which is used for ban exceptions.

Examples:

      EXCEPTS

      EXCEPTS=e

### `EXTBAN` Parameter

      Format: EXTBAN=<prefix>,<types>

The `EXTBAN` parameter indicates the types of "extended ban masks" that the server supports.

`<prefix>` denotes the character that indicates an extban to the server and `<types>` is a list of characters indicating the types of extended bans the server supports.

Extbans may allow clients to issue bans based on account name, SSL certificate fingerprints and other attributes, based on what the server supports.

Extban masks SHOULD also be supported for the [ban exemption](#ban-exemption-channel-mode) and [invite exemption](#invite-exemption-channel-mode) modes.

<div class="warning">
    <p>Ensure that extban masks are actually typically supported in ban exemption and invite exemption modes.</p>

    <p>We should include a list of 'typical' extban characters and their associated meaning, but make sure we specify that these are not standardised and may change based on server software. See also: <a href="https://github.com/DanielOaks/irc-defs/issues/9"><code>irc-defs#9</code></a></p>
</div>

Examples:

      EXTBAN=~,cqnr

      EXTBAN=~,qjncrRa

### `INVEX` Parameter

      Format: INVEX=[character]
       Empty: I

The `INVEX` parameter indicates that the server supports invite exceptions, as specified in the [invite exemption](#invite-exemption-channel-mode) channel mode section.

The value is OPTIONAL and when not specified indicates that the letter `"I"` is used as the channel mode for invite exceptions. If the value is specified, the character indicates the letter which is used for invite exceptions.

Examples:

      INVEX

      INVEX=I

### `KICKLEN` Parameter

The `KICKLEN` parameter indicates the maximum length for the `<reason>` of a [`KICK`](#kick-message) command. If a [`KICK`](#kick-message) `<reason>` has more characters than this parameter, it may be silently truncated by the server before being passed on to other clients. Clients MAY receive a [`KICK`](#kick-message) `<reason>` that has more characters than this parameter.

The value MUST be specified and MUST be a positive integer.

Examples:

      KICKLEN=255

      KICKLEN=307

### `MAXLIST` Parameter

      Format: MAXLIST=<modes>:<limit>[,<modes>:<limit>,...]

The `MAXLIST` parameter specifies how many "variable" modes of type A that have been defined in the [`CHANMODES`](#chanmodes-parameter) parameter that a client may set in total on a channel.

The value MUST be specified and is a list of `<modes>:<limit>` pairs, delimited by a comma `(',',` `0x2C)`. `<modes>` is a list of type A modes defined in [`CHANMODES`](#chanmodes-parameter). `<limit>` is a positive integer specifying the maximum number of entries that all of the modes in `<modes>`, combined, may set on a channel.

A client MUST NOT make any assumptions on how many mode entries may actually exist on any given channel. This limit only applies to the client setting new modes of the given types, and other clients may have different limits.

Examples:

      MAXLIST=beI:25           ; indicates that a client may set up to a total of 25 of a
                               combination of "b", "e", and "I" modes.

      MAXLIST=b:60,e:60,I:60   ; indicates that a client may set up to 60 "b" modes,
                               "e" modes, and 60 "I" modes.

      MAXLIST=beI:100,q:50     ; indicates that a client may set up to a total of 100 of
                               a combination of "b", "e", and "I" modes, and that they
                               may set up to 50 "q" modes.

### `MAXTARGETS` Parameter

      Format: MAXTARGETS=[number]

The `MAXTARGETS` parameter specifies the maximum number of targets a [`PRIVMSG`](#privmsg-message) or [`NOTICE`](#notice-message) command may have, and may apply to other commands based on server software.

The value is OPTIONAL and if specified, `[number]` is a positive integer representing the maximum number of targets those commands may have. If there is no limit, then `[number]` MAY not be specified.

The [`TARGMAX`](#targmax-parameter) parameter SHOULD be advertised instead of or in addition to this parameter. [`TARGMAX`](#targmax-parameter) is intended to replace `MAXTARGETS` as that parameter is more clear about which commands limits apply to.

Examples:

      MAXTARGETS=4

      MAXTARGETS=20

### `MODES` Parameter

      Format: MODES=[number]

The `MODES` parameter specifies how many 'variable' modes may be set on a channel by a single [`MODE`](#mode-message) command from a client. A 'variable' mode is defined as being a type A, B or C mode as defined in the [`CHANMODES`](#chanmodes-parameter) parameter, or in the channel modes specified in the [`PREFIX`](#prefix-parameter) parameter.

A client SHOULD NOT issue more 'variable' modes than this in a single [`MODE`](#mode-message) command. A server MAY however issue more 'variable' modes than this in a single [`MODE`](#mode-message) message. The value is OPTIONAL and when not specified indicates that there is no limit to the number of 'variable' modes that may be set in a single client [`MODE`](#mode-message) command.

If the value is specified, it MUST be a positive integer.

Examples:

      MODES=4

      MODES=12

      MODES=20

### `NETWORK` Parameter

      Format: NETWORK=<string>

The `NETWORK` parameter indicates the name of the IRC network that the client is connected to. This parameter is advertised for INFORMATIONAL PURPOSES ONLY. Clients SHOULD NOT use this value to make assumptions about supported features on the server as networks may change server software and configuration at any time.

Examples:

      NETWORK=EFNet

      NETWORK=Rizon

### `NICKLEN` Parameter

       Format: NICKLEN=<number>

The `NICKLEN` parameter indicates the maximum length of a nickname that a client may set. Clients on the network MAY have longer nicks than this.

The value MUST be specified and MUST be a positive integer. `30` or `31` are typical values for this parameter advertised by servers today.

Examples:

      NICKLEN=9

      NICKLEN=30

      NICKLEN=31

### `PREFIX` Parameter

       Format: PREFIX=[(modes)prefixes]
      Default: PREFIX=(ov)@+

Within channels, clients can have different statuses, denoted by single-character prefixes. The `PREFIX` parameter specifies these prefixes and the channel mode characters that they are mapped to. There is a one-to-one mapping between prefixes and channel modes. The prefixes in this parameter are in descending order, from the prefix that gives the most privileges to the prefix that gives the least.

The typical prefixes advertised in this parameter are listed in the [Channel Membership Prefixes](#channel-membership-prefixes) section.

The value is OPTIONAL and when it is not specified indicates that no prefixes are supported.

Examples:

      PREFIX=(ov)@+

      PREFIX=(ohv)@%+

      PREFIX=(qaohv)~&@%+

### `SAFELIST` Parameter

      Format: SAFELIST

If `SAFELIST` parameter is advertised, the server ensures that a client may perform the [`LIST`](#list-message) command without being disconnected due to the large volume of data the [`LIST`](#list-message) command generates.

The `SAFELIST` parameter MUST NOT be specified with a value.

Examples:

      SAFELIST

### `SILENCE` Parameter

      Format: SILENCE[=<limit>]

The `SILENCE` parameter indicates the maximum number of entries a client can have in their silence list.

The value is OPTIONAL and if specified is a positive integer. If the value is not specified, the server does not support the [`SILENCE`](#silence-message) command.

Most IRC clients also include client-side filter/ignore lists as an alternative to this command.

Examples:

      SILENCE

      SILENCE=15

      SILENCE=32

### `STATUSMSG` Parameter

      Format: STATUSMSG=<string>

The `STAUSMSG` parameter indicates that the server supports a method for clients to send a message via the [`PRIVMSG`](#privmsg-message) / [`NOTICE`](#notice-message) commands to those people on a channel with the specified [channel membership prefixes](#channel-membership-prefixes).

The value MUST be specified and MUST be a list of prefixes as specified in the [`PREFIX`](#prefix-parameter) parameter. Most servers today advertise every prefix in their [`PREFIX`](#prefix-parameter) parameter in `STATUSMSG`.

Examples:

      STATUSMSG=@+

      STATUSMSG=@%+

      STATUSMSG=~&@%+

### `TARGMAX` Parameter

      Format: TARGMAX=[<command>:[limit],<command>:[limit],...]

Certain client commands MAY contain multiple targets, delimited by a comma `(',',` `0x2C)`. The `TARGMAX` parameter defines the maximum number of targets allowed for commands which accept multiple targets.

The value is OPTIONAL and is a set of `<command>:<limit>` pairs, delimited by a comma `(',',` `0x2C)`. `<command>` is the name of a client command. `<limit>` is the maximum number of targets which that command accepts. If `<limit>` is specified, it is a positive integer. If `<limit>` is not specified, then there is no maximum number of targets for that command. Clients MUST treat `<command>` as case-insensitive.

Examples:

      TARGMAX=PRIVMSG:3,WHOIS:1,JOIN:

      TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR:

      TARGMAX=ACCEPT:,KICK:1,LIST:1,NAMES:1,NOTICE:4,PRIVMSG:4,WHOIS:1

### `TOPICLEN` Parameter

      Format: TOPICLEN=<number>

The `TOPICLEN` parameter indicates the maximum length of a topic that a client may set on a channel. Channels on the network MAY have topics with longer lengths than this.

The value MUST be specified and MUST be a positive integer. `307` is the typical value for this parameter advertised by servers today.

Examples:

      TOPICLEN=307

      TOPICLEN=390


---


# Obsolete Numerics

These are numerics contained in [RFC1459](https://tools.ietf.org/html/rfc1459) and [RFC2812](https://tools.ietf.org/html/rfc2812) that are not contained in this document or that should be considered obsolete.

* **`RPL_BOUNCE (005)`**: `005` is now used for [`RPL_ISUPPORT`](#rplisupport-005). `RPL_BOUNCE` was moved to [`010`](#rplbounce-010).


---


# Acknowledgements

This document draws from the original [RFC1459](https://tools.ietf.org/html/rfc1459) and [RFC2812](https://tools.ietf.org/html/rfc2812) IRC protocol specifications.

Parts of this document come from the "IRC `RPL_ISUPPORT` Numeric Definition" Internet Draft authored by L. Hardy, E. Brocklesby, and K. Mitchell. Parts of this document come from the "IRC Client Capabilities Extension" Internet Draft authored by K. Mitchell, P. Lorier, L. Hardy, and P. Kucharski. Parts of this document come from the IRCv3 Working Group specifications.
