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
    This is NOT an authoritative document. It does not purport to be anything more than a hopefully-useful overview of the IRC protocol as it is generally implemented today.
    For something which aims to be an RFC, please see the <a href="https://github.com/kaniini/ircv3-harmony">ircv3-harmony</a> project.
</div>

<div class="warning">
    NOTE: This is NOWHERE NEAR FINISHED. Dragons be here, insane stuff be here.
</div>


---


# Introduction

The Internet Relay Chat (IRC) protocol has been designed over a number of years, with multitudes of implementations and use cases appearing. This document describes the IRC Client-Server protocol.

IRC is a text-based teleconferencing system, which has proven itself as a very valuable and useful protocol. It is well-suited to running on many machines in a distributed fashion. A typical setup involves multiple servers connected in a distributed network, through which messages are delivered and state is maintained across the network for the connected clients and active channels.

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

To create a new channel or become part of an existing channel, a user is required to join the channel using the [`JOIN`](#join-message). If the channel doesn't exist prior to joining, the channel is created and the creating user becomes a channel operator. If the channel already exists, whether or not the client successfully joins that channel depends on the modes currently set on the channel. For example, if the channel is set to `invite-only` mode (`+i`), the client only joins the channel if they have been invited by another user or they have been exempted from requiring an invite by the channel operators.

A user may be a part of several channels at once, but a limit may be imposed by the server as to how many channels a client can be in at one time. This limit is specified by the [`CHANLIMIT`](#chanlimit) `RPL_ISUPPORT` token. See the [Feature Advertisement](#feature-advertisement) section for more details on `RPL_ISUPPORT`.

If the IRC network becomes disjoint because of a split between servers, the channel on either side is only composed of those clients which are connected to servers on the respective sides of the split, possibly ceasing to exist on one side of the split. When the split is healed, the connecting servers ensure the network state is consistent between them.

### Channel Operators

Channel operators (also referred to as "chanops") on a given channel are considered to 'run' or 'own' that channel. In recognition of this status, channel operators are endowed with certain powers which let them moderate and keep control of their channel.

As owners of a channel, chanops are **not** required to have reasons for their actions in the management of their channel. Most IRC operators do not concern themselves with 'channel politics', and try to not interfere with the management of specific channels. Most IRC networks consider the management of specific channels, and/or 'abusive' channel operators to be outside their domain. However, for specific details it is best to consult the network policy (usually presented on connection with the Message of the Day ([`MOTD`](#motd-message))).

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

This section is devoted to describing the concepts behind the organisation of the IRC protocol and how the current implementations deliver different classes of messages.

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

It is widely recognized that this protocol does not scale sufficiently well when used in a large arena. The main problem comes from the requirement that all servers know about all other servers, clients, and channels, and that information regarding them be updated as soon as it changes.

### Reliability

As the only network configuration used for IRC servers is that of a spanning tree, each link between two servers is an obvious and serious point of failure.

Various software authors are experimenting with alternative topologies such as mesh networks, but there is not yet a production implementation or specification of any topology other than the standard spanning-tree configuration.


---


# Protocol Structure


## Overview

The protocol as described herein is used for client to server connections.

Various server to server protocols have been defined over the years, with [TS6](https://github.com/grawity/irc-docs/blob/725a1f05b85d7a935986ae4f49b058e9b67e7ce9/server/ts6.txt) and [P10](http://web.mit.edu/klmitch/Sipb/devel/src/ircu2.10.11/doc/p10.html) among the most popular (both based on the original client-server protocol). However, with the fragmented nature of IRC server to server protocols and differences in server implementations, features and network designs, it is at this point impossible to define a single standard server to server protocol.

### Character Codes

Clients SHOULD use the [UTF-8](http://tools.ietf.org/html/rfc3629) character encoding on outgoing messages. Clients MUST be able to handle incoming messages encoded with alternative encodings, and even lines they cannot decode with any of their standard encodings.

The `'ascii'` casemapping defines the characters `a` to `z` to be considered the lower-case equivalents of the characters `A` to `Z` only. The `'rfc1459'` casemapping defines the same casemapping as `'ascii'`, with the addition of the characters `'{'`, `'}'`, and `'|'` being considered the lower-case equivalents of the characters `'['`, `']'`, and `'\'` respectively. For other casemappings used by servers, see the [`CASEMAPPING`](#casemapping-token) `RPL_ISUPPORT` token.

Servers MUST specify the casemapping they use in the [`RPL_ISUPPORT`](#feature-advertisement) numeric sent on completion of client registration.


## Messages

Servers and clients send each other messages which may or may not generate a reply; client to server communication is essentially asynchronous in nature.

Each IRC message may consist of up to four main parts: tags (optional), the prefix (optional), the command, and the command parameters (of which there may be up to 15).

Servers may supply tags (when negotiated) and a prefix on any or all messages they send to clients.

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

Information on specific commands can be found in the [Commands](#commands) section.

### Parameters

Parameters (or 'params') are extra pieces of information added to the end of a message. These parameters generally make up the 'data' portion of the message. The meaning of specific parameters changes for every single message.


## Wire Format

The protocol messages are extracted from a contiguous stream of octets. A pair of characters, `CR` `('\r', 0x13)` and `LF` `('\n', 0x10)`, act as message separators. Empty messages are silently ignored, which permits use of the sequence CR-LF between messages.

The tags, prefix, command, and all parameters are separated by one (or more) ASCII space character(s) `(' ', 0x20)`.

The presense of tags is indicated with a single leading 'at sign' character `('@', 0x40)`, which MUST be the first character of the message itself. There MUST NOT be any whitespace between this leading character and the list of tags.

The presence of a prefix is indicated with a single leading colon character `(':', 0x3b)`. If there are no tags it MUST be the first character of the message itself. There MUST NOT be any whitespace between this leading character and the prefix

Most IRC servers limit lines to 512 bytes in length, including the trailing `CR-LF` characters. Implementations which include message tags allow an additional 512 bytes for the tags section of a message, including the leading `'@'` and trailing space character. There is no provision for continuation message lines.

The proposed [`LINELEN`](#linelen-token) `RPL_ISUPPORT` token lets a server specify the maximum allowed length of IRC lines, comprising of both the tags section and the rest of the message. However, use of this token is not widespread and is only used in an experimental server right now.

### Wire format in 'pseudo' ABNF

The extracted message is parsed into the components `tags`, `prefix`, `command`, and a list of parameters (`params`).

The ABNF representation for this is:

      message     =  ["@" tags SPACE ] [ ":" prefix SPACE ] command
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

In all other respects, a numeric reply is just like a normal message, except that the keyword is made up of 3 numeric digits rather than a string of letters. A list of replies is supplied in the [Replies](#replies) section.


## Wildcard Expressions

When wildcards are allowed in a string, it is referred to as a "mask".

For string matching purposes, the protocol allows the use of two special characters: `'?'` `(0x3F)` to match one and only one character, and `'*'` `(0x2A)` to match any number of any characters. These two characters can be escaped using the `'\'` `(0x5C)` character.

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

1. `CAP`
2. `SASL` (if negotiated)
3. `PASS`
4. `NICK`
5. `USER`

If the server supports capability negotiation, the [`CAP`](#cap-message) command suspends the registration process and immediately starts the [capability negotiation](#capability-negotiation) process. The capability negotiation process is resumed when the client sends `CAP END` to the server.

If the client supports [`SASL`](#sasl) authentication and wishes to authenticate with the server, it should attempt this after a successful `CAP ACK` of the `sasl` capability is received and while registration is suspended.

The [`PASS`](#pass-message) command is not required for the connection to be registered, but if included it MUST precede the latter of the NICK and USER commands.

The [`NICK`](#nick-message) and [`USER`](#user-message) commands are used to set the user's nickname, username, and "real name". Unless the registration is suspended by a CAP negotiation or the server is waiting to complete a lookup of client information (such as hostname or ident), these commands will end the registration process immediately.

Upon successful completion of the registration process, the server MUST send the [`RPL_WELCOME`](#rplwelcome-001) `(001)`, [`RPL_YOURHOST`](#rplyourhost-002) `(002)`, [`RPL_CREATED`](#rplcreated-003) `(003)`, [`RPL_MYINFO`](#rplmyinfo-004) `(004)`, and at least one [`RPL_ISUPPORT`](#rplisupport-005) `(005)` numeric to the client. The server SHOULD also send the Message of the Day ([`MOTD`](#motd-message)) if one exists (or [`ERR_NOMOTD`](#errnomotd-422) if it does not), and MAY send other numerics.


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

Capability negotiation is started by the client issuing a `CAP LS 302` command (referring to IRCv3.2 capability negotiation). Negotiation is then performed with the `CAP REQ`, `CAP ACK`, and `CAP NAK` commands, and is ended with the `CAP END` command.

If used during initial registration, and the server supports capability negotiation, the `CAP` command will suspend registration. Once capability negotiation has ended the registration process will continue.

Clients and servers should implement capability negotiation and the `CAP` command based on the [IRCv3.1](http://ircv3.net/specs/core/capability-negotiation-3.1.html) and [IRCv3.2](http://ircv3.net/specs/core/capability-negotiation-3.2.html) Capability Negotiation specifications. Updates, improvements, and new versions of capability negotiation are managed by the [IRCv3 Working Group](http://ircv3.net/irc/).


---


# Client Messages

Messages are client-to-server only unless otherwise specified. If messages may be sent from the server to a connected client, it will be noted in the message's description. For server-to-client messages of this type, the message `<source>` usually indicates the client the message relates to, but this will be noted in the description.

In message descriptions, 'command' generally refers to the message's behaviour when sent from a client to the server.


## Connection Messages

### CAP message

         Command: CAP
      Parameters: <subcommand> [:<capabilities>]

The CAP command takes a single required subcommand, optionally followed by a single parameter of space-separated capability identifiers. Each capability in the list MAY be preceded by a capability modifier as described in the [IRCv3.1](http://ircv3.net/specs/core/capability-negotiation-3.1.html) and [IRCv3.2](http://ircv3.net/specs/core/capability-negotiation-3.2.html) Capability Negotiation specifications.

The `CAP` message may be sent from the server to the client. The exact semantics are described in the IRCv3 Capability Negotiation specifications above.

For the specific semantics of the `CAP` command and subcommands, please see the IRCv3 specifications linked above.

### PASS message

         Command: PASS
      Parameters: <password>

The PASS command is used to set a 'connection password'. If set, the password must be set before any attempt to register the connection is made. This requires that clients send a PASS command before sending the `NICK` / `USER` combination.

The password supplied must match the one defined in the server configuration. It is possible to send multiple `PASS` commands before registering but only the last one sent is used for verification and it may not be changed once the client has been registered.

Servers may also consider requiring [`SASL` Authentication](#sasl) upon connection as an alternative to this, when more information or an alternate form of identity verification is desired.

Numeric replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_ALREADYREGISTRED`](#erralreadyregistered-462) `(462)`

Example:

      PASS secretpasswordhere

### NICK message

         Command: NICK
      Parameters: <nickname>

The NICK command is used to give the client a nickname or change the previous one.

If the server receives a NICK command from a client where the desired nickname is already in use on the network, it should issue an `ERR_NICKNAMEINUSE` numeric and ignore the `NICK` command.

If the server does not accept the new nickname supplied by the client as valid (for instance, due to containing invalid characters), it should issue an `ERR_ERRONEUSNICKNAME` numeric and ignore the `NICK` command.

If the server does not receive the `<nickname>` parameter with the `NICK` command, it should issue an `ERR_NONICKNAMEGIVEN` numeric and ignore the `NICK` command.

The `NICK` message may be sent from the server to client to inform clients about other clients changing their nicknames. In this case, the `<source>` of the message will be the user who is changing their nickname.

Numeric Replies:

* [`ERR_NONICKNAMEGIVEN`](#errnonicknamegiven-431) `(431)`
* [`ERR_ERRONEUSNICKNAME`](#errerroneusnickname-432) `(432)`
* [`ERR_NICKNAMEINUSE`](#errnicknameinuse-433) `(433)`
* [`ERR_NICKCOLLISION`](#errnickcollision-436) `(436)`

Example:

      NICK Wiz                  ; Introducing the new nick "Wiz".

      :WiZ NICK Kilroy          ; WiZ changed his nickname to Kilroy.

### USER message

         Command: USER
      Parameters: <username> * * <realname>

The `USER` command is used at the beginning of a connection to specify the username, hostname, servername and realname of a new user.

It must be noted that `<realname>` must be the last parameter, because it may contain space characters and should be prefixed with a colon (`:`) to make sure this is recognised as such.

Since it is easy for a client to lie about its username by relying solely on the USER command, the use of an "Identity Server" is recommended. This lookup can be performed by the server using the [Ident Protocol](http://tools.ietf.org/html/rfc1413). If the host which a user connects from has such an "Identity Server" enabled, the username is set to that as in the reply from that server. If the host does not have such a server enabled, the username is set to the value of the `<username>` parameter, prefixed by a tilde `('~', 0x7F)` to show that this value is user-set.

The second and third parameters of this command SHOULD be sent as one literal asterix character for each parameter `('*', 0x2A)` by the client, as the meaning of these two parameters varies between different versions of the IRC protocol.

If a client tries to send the `USER` command after they have already completed registration with the server, the `ERR_ALREADYREGISTERED` reply should be sent and the attempt should fail.

If the client sends a `USER` command after the server has successfully received a username using the Ident Protocol, the `<username>` parameter from this command should be ignored in favour of the one received from the identity server.

Numeric Replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_ALREADYREGISTRED`](#erralreadyregistred-462) `(462)`

Examples:

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
      Parameters: <user> <password>

The OPER command is used by a normal user to obtain IRC operator privileges. Both parameters are required for the command to be successful.

If the client does not send the correct password for the given user, the server replies with an `ERR_PASSWDMISMATCH` message and the request is not successful.

If the client is not connecting from a valid host for the given user, the server replies with an `ERR_NOOPERHOST` message and the request is not successful.

If the supplied username and password are both correct, and the user is connecting from a valid host, the `RPL_YOUREOPER` message is sent to the user. The user will also receive a [`MODE` message](#mode-message) indicating their new user modes, and other messages may be sent.

The `<user>` specified by this command is separate to the accounts specified by SASL authentication.

Numeric Replies:

* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_PASSWDMISMATCH`](#errpasswdmismatch-464) `(464)`
* [`ERR_NOOPERHOST`](#errnooperhost-491) `(491)`
* [`RPL_YOUREOPER`](#erryoureoper-381) `(381)`

Example:

      OPER foo bar                ; Attempt to register as an operator
                                  using a username of "foo" and the password
                                  "bar".

### QUIT message

        Command: QUIT
     Parameters: [<reason>]

The QUIT command is used to terminate a client's connection to the server. The server acknowledges this by replying with an [`ERROR` message](#error-message) and closing the connection to the client.

This message may also be sent from the server to a client to show that a client has exited from the network. This is typically only dispatched to clients that share a channel with the exiting user. When the `QUIT` message is sent to clients, `<source>` represents the client that has exited the network.

When connections are terminated by a client-sent `QUIT` command, servers SHOULD prepend `<reason>` with the ascii string `"Quit: "` when sending `QUIT` messages to other clients, to represent that this user terminated the connection themselves. This applies even if `<reason>` is empty, in which case the reason sent to other clients SHOULD be just this `"Quit: "` string. However, clients SHOULD NOT change behaviour based on the prefix of `QUIT` message reasons, as this is not required.

When a netsplit (the disconnecting of two servers) occurs, a `QUIT` message is generated for each client that has exited the network, distributed in the same way as ordinary `QUIT` messages. The `<reason>` on these `QUIT` messages SHOULD be composed of the names of the two servers involved, separated by a space. The first name is that of the server which is still connected and the second name is that of the server which has become disconnected. If servers wish to hide or obscure the names of the servers involved, the `<reason>` on these messages MAY also be the literal ascii string `"*.net *.split"`.

If a client connection is closed without the client issuing a `QUIT` command to the server, the server MUST distribute a `QUIT` message to other clients informing them of this, distributed in the same was an an ordinary `QUIT` message. Servers MUST fill `<reason>` with a message reflecting the nature of the event which caused it to happen. For instance, `"Ping timeout: 120 seconds"`, `"Excess Flood"`, and `"Too many connections from this IP"` are examples of relevant reasons for closing or for a connection with a client to have been closed.

Numeric Replies:

* None

Example:

      QUIT :Gone to have lunch         ; Client exiting from the network


## Server Queries and Commands

### VERSION message

         Command: VERSION
      Parameters: [<server>]

The VERSION command is used to query the version of the server software and to request the server's ISUPPORT tokens. An optional parameter `<server>` is used to query the version of the given server instead of the server the client is directly connected to.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`RPL_ISUPPORT`](#rplisupport-005) `(005)`
* [`RPL_VERSION`](#rplversion-351) `(351)`

Examples:

      :Wiz VERSION *.se               ; message from Wiz to check the
                                      version of a server matching "*.se"

      VERSION tolsun.oulu.fi          ; check the version of server
                                      "tolsun.oulu.fi".

### CONNECT message

         Command: CONNECT
      Parameters: <target server> [<port> [<remote server>]]

The CONNECT command forces a server to try to establish a new connection to another server. CONNECT is a privileged command and is available only to IRC Operators. If a remote server is given, the connection is attempted by that remote server to `<target server>` using `<port>`.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) `(461)`
* [`ERR_NOPRIVILEGES`](#errnoprivileges-481) `(481)`
* [`ERR_NOPRIVS`](#errnoprivs-723) `(723)`

Examples:

      CONNECT tolsun.oulu.fi
      ; Attempt to connect the current server to tololsun.oulu.fi

      CONNECT  eff.org 12765 csd.bu.edu
      ; Attempt to connect csu.bu.edu to eff.org on port 12765

### TIME message

         Command: TIME
      Parameters: [<server>]

The TIME command is used to query local time from the specified server. If the server parameter is not given, the server handling the command must reply to the query.

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
* [`RPL_TIME`](#rpltime-391) `(391)`

Examples:

      TIME tolsun.oulu.fi             ; check the time on the server
                                      "tolson.oulu.fi"

      Angel TIME *.au                 ; user angel checking the time on a
                                      server matching "*.au"

### STATS message

         Command: STATS
      Parameters: [<query> [<server>]]

The STATS command is used to query statistics of a certain server. If the `<server>` parameter is omitted, only the end of stats reply is sent back. The specific queries supported by this command depend on the server that replies, although the server must be able to supply information as described by the queries below (or similar).

A query may be given by any single letter which is only checked by the destination server and is otherwise passed on by intermediate servers, ignored and unaltered.

The following queries are those found in current IRC implementations and provide a large portion of the setup information for that server. All servers should be able to supply a valid reply to a `STATS` query which is consistent with the reply formats currently used and the purpose of the query.

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

Numeric Replies:

* [`ERR_NOSUCHSERVER`](#errnosuchserver-402) `(402)`
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

Examples:

      STATS m                         ; check the command usage for the
                                      server you are connected to

      :Wiz STATS c eff.org            ; request by WiZ for C/N line
                                      information from server eff.org


---



# Numerics

As mentioned in the [numeric replies](#numeric-replies) section, the first parameter of most numerics is the target of that numeric (the nickname of the client that is receiving it). Underneath the name and numeric of each reply, we list the parameters sent by this message.

Clients MUST not fail because the number of parameters on a given incoming numeric is larger than the number of parameters we list for that numeric here. Most IRC servers extends some of these numerics with their own special additions. For example, if a message is listed here as having 2 parameters, and your client receives it with 5 parameters, your client should not fail to parse or handle that message correctly because of the extra parameters.

Optional parameters are surrounded with the standard square brackets `([<optional>])` -- this means clients MUST NOT assume they will receive this parameter from all servers, and that servers SHOULD send this parameter (unless otherwise specified).

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

This numeric is also known as `RPL_REDIR` by some software.

### `ERR_NOPRIVS (723)`

      "<client> <priv> :Insufficient oper privileges."

Sent by a server to alert an IRC operator that while they they do not have the specific operator privilege required by this server/network to perform the command or action they requested.

`<priv>` is a string that has meaning in the server software and allows an operator the privileges to perform certain commands or actions. These strings are server-defined and may refer to one or multiple commands or actions that may be performed by IRC operators.

Examples of the sorts of privilege strings used by server software today include: `kline`, `dline`, `unkline`, `kill`, `kill:remote`, `die`, `remoteban`, `connect`, `connect:remote`, `rehash`.


---


# Acknowledgements

This document draws from the original [RFC1459](https://tools.ietf.org/html/rfc1459) and [RFC2812](https://tools.ietf.org/html/rfc2812) IRC protocol specifications.

Parts of this document come from the "IRC `RPL_ISUPPORT` Numeric Definition" Internet Draft authored by L. Hardy, E. Brocklesby, and K. Mitchell. Parts of this document come from the "IRC Client Capabilities Extension" Internet Draft authored by K. Mitchell, P. Lorier, L. Hardy, and P. Kucharski. Parts of this document come from the IRCv3 Working Group specifications.
