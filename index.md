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
</div>

<div class="warning">
    NOTE: This is NOWHERE NEAR FINISHED. Dragons be here, insane stuff be here.
</div>

---

# Introduction

The Internet Relay Chat (IRC) protocol has been designed and implemented over a number of years, with multitudes of implementations and use cases appearing. This document describes the IRC Client-Server protocol.

IRC is a text-based teleconferencing system, which has proven itself as a very valuable and useful protocol. It is well-suited to running on many machines in a distributed fashion. A typical setup involves multiple servers connected in a distributed network, through which messages are delivered and state is maintained across the network for the connected clients and active channels.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).


## Servers

Servers form the backbone of IRC, providing a point to which clients may connect and talk to each other, and a point for other servers to connect to, forming an IRC network.

The most common network configuration for IRC servers is that of a spanning tree [see the figure below], where each server acts as a central node for the rest of the net it sees. Other topologies are being experimented with, but right there are no others in production.

                               [ Server 15 ]  [ Server 13 ] [ Server 14]
                                     /                \         /
                                    /                  \       /
            [ Server 11 ] ------ [ Server 1 ]       [ Server 12]
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

<span class="figure">Format of a typical IRC network.</span>


## Clients

A client is anything connecting to a server that is not another server. Each client is distinguished from other clients by a unique nickname. See the protocol grammar rules for what may and may not be used in a nickname. In addition to the nickname, all servers must have the following information about all clients: The real name of the host that the client is running on, the username of the client on that host, and the server to which the client is connected.

### Operators

To allow a reasonable amount of order to be kept within the IRC network, a special class of clients (operators) are allowed to perform general maintenance functions on the network. Although the powers granted to an operator can be considered as 'dangerous', they are nonetheless required.

The tasks operators can perform vary from software to software and with the privileges granted to each operator. Some can perform network maintenence tasks, such as disconnecting and reconnecting servers as needed to prevent long-term use of bad network routing.

Some operators can remove a user from their server or the IRC network by 'force', i.e. the operator is able to close the connection between a client and server. The justification for this is delicate since its abuse is both destructive and annoying. However, IRC network policies handle operators who abuse their privileges, and what is considered abuse.


## Channels

A channel is a named group of one or more clients. All clients in the channel will all receive messages addressed to that channel. The channel is created implicitly when the first client joins it, and the channel ceases to exist when the last client leaves is. While the channel exists, any client can reference the channel using the name of the channel.

Channel names are strings (beginning with specified prefix characters). Apart from the requirement of the first character being a valid channel prefix character; the only restriction on a channel name is that it may not contain any spaces (`' '`), a control G (`^G` or `ASCII 7`), or a comma (`','` which is used as a list item separator by the protocol).

There are several types of channels used in the IRC protocol. The first standard type of channel is a distributed channel which is known to all servers that are connected to the network. The prefix character for this type of channel is `'#'`. The second type are server-specific channels, where the clients connected can only see and talk to other clients on the same server. The prefix character for this type of channel is `'&'`. Other types of channels are described in the [Channel Types](#channel-types) section.

Along with the various channel types, there are also channel modes that can alter the characteristics and behaviour of individual channels. See the [Channel Modes](#channel-modes) section for more information on these.

To create a new channel or become part of an existing channel, a user is required to [`JOIN`](#join-command) the channel. If the channel doesn't exist prior to joining, the channel is created and the creating user becomes a channel operator. If the channel already exists, whether or not the client successfully joins that channel depends on the modes currently set on the channel. For example, if the channel is set to `invite-only` mode (`+i`), the client only joins the channel if they have been invited by another user or they have an invite exemption.

A user may be a part of several channels at once, but a limit may be imposed as to how many channels a client can be in at one time. This limit is specified by the [`CHANLIMIT`](#chanlimit) `RPL_ISUPPORT` token. See the [Feature Advertisement](#feature-advertisement) section for more details on `RPL_ISUPPORT`.

If the IRC network becomes disjoint because of a split between servers, the channel on either side is only composed of those clients which are connected to servers on the respective sides of the split, possibly ceasing to exist on one side of the split. When the split is healed, the connecting servers ensure the network state is consistent between them.

### Channel Operators

Channel operators (also referred to as "chanops") on a given channel are considered to 'run' or 'own' that channel. In recognition of this status, channel operators are endowed with certain powers which let them moderate and keep control of their channel.

As owners of a channel, channel operators are not required to have reasons for their actions in the management of that channel. Most IRC operators do not deal with 'channel politics' or 'channel drama'. Most IRC networks consider the management of specific channels, and/or 'abusive' channel operators to be outside the domain of what they deal with. However, it is best to read the network policy (usually presented on connection with the [`MOTD`](#rpl-motd)).

Some IRC software also defines other various levels of channel moderation. These can include 'halfop' (half operator), 'protected' (protected op), 'founder' (channel founder), and any other positions the server wishes to define. These moderation levels have varying privileges and can execute, and not execute, various channel management commands based on what the server defines.

The commands which may only be used by channel moderators include:

- [`KICK`](#kick-command): Eject a client from the channel
- [`MODE`](#mode-command): Change the channel's modes
- [`INVITE`](#invite-command): Invite a client to an invite-only channel (mode +i)
- [`TOPIC`](#topic-command): Change the channel topic in a mode +t channel

Channel moderators are identified by the channel member prefix (`'@'` for standard channel operators) next to their nickname whenever it is associated with a channel (ie: replies to the `NAMES`, `WHO`, and `WHOIS` commands).

Specific prefixes and moderation levels are covered in the [Channel Membership Prefixes](#channel-membership-prefixes) section.

---

# IRC Concepts

This section is devoted to describing the concepts behind the organisation of the IRC protocol and how the current implementations deliver different classes of messages.

                              1--\
                                  A        D---4
                              2--/ \      /
                                    B----C
                                   /      \
                                  3        E

       Servers: A, B, C, D, E         Clients: 1, 2, 3, 4

<span class="figure">Sample small IRC network.</span>


## One-to-one communication

Communication on a one-to-one basis is usually only performed by clients, since most server-server traffic is not a result of servers talking only to each other. This section ONLY deals with the typical spanning-tree topology, shown in the figure above. This is because this is the topology used in all IRC software today, and other topologies are only being experimented with thus far.

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

IRC Operators may be able to send a message to every client currently connected to the network. This depends on the specific features and commands implemented in the running server software.















---

# Acknowledgements

Most of this document draws from the original [RFC1459](https://tools.ietf.org/html/rfc1459) and [RFC2812](https://tools.ietf.org/html/rfc2812) specifications.

Parts of this document come from the "IRC RPL_ISUPPORT Numeric Definition" Internet Draft authored by L. Hardy, E. Brocklesby, and K. Mitchell. Parts of this document came from the "IRC Client Capabilities Extension" Internet Draft authored by K. Mitchell, P. Lorier, L. Hardy, and P. Kucharski. Parts of this document come from the IRCv3 Working Group specifications.
