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
* **Services**: A 'services' server is a special type of server that extends the capabilities of the server software on the network (ie, they provide *services* to the network). Services are not used on all networks, and the capabilities typically provided by them may be built-into server software itself rather than being provided by a separate software package. Features usually handled by services include client account registration (as are typically used for [SASL authentication](#authenticate-message)), channel registration (allowing client accounts to 'own' channels), and further modifications and extensions to the IRC protocol. 'Services' themselves are **not** specified in any way by the protocol, they are different from the [services](#services) defined by the RFCs. What they provide depends entirely on the software packages being run.

A trend these days is to hide the real structure of a network from regular users. Networks that implement this may restrict or modify commands like {% command MAP %} so that regular users see every other server on the network as linked directly to the current server. When this is done, servers that do not handle client connections may also be hidden from users (hubs hidden in this way can be called 'hidden hubs'). Generally, IRC operators can always see the true structure of a network.

These terms are not generally used in IRC protocol documentation, but may be used by the administrators of a network in order to differentiate the servers they run and their roles.

Servers SHOULD pick a name which contains a dot character `(".", 0x2E)`. This can help clients disambiguate between server names and nicknames in a message source.

### Clients

A client is anything connecting to a server that is not another server. Each client is distinguished from other clients by a unique nickname. In addition to the nickname, all servers must have the following information about all clients: the real name/address of the host that the client is connecting from, the username of the client on that host, and the server to which the client is connected.

Nicknames are non-empty strings with the following restrictions:

- They MUST NOT contain any of the following characters: space `(' ', 0x20)`, comma `(',', 0x2C)`, asterisk `('*', 0x2A)`, question mark `('?', 0x3F)`, exclamation mark `('!', 0x21)`, at sign `('@', 0x40)`.
- They MUST NOT start with any of the following characters: dollar `('$', 0x24)`, colon `(':', 0x3A)`.
- They MUST NOT start with a character listed as a [channel type](#channel-types), [channel membership prefix](#channel-membership-prefixes), or prefix listed in the IRCv3 [`multi-prefix` Extension](https://ircv3.net/specs/extensions/multi-prefix).
- They SHOULD NOT contain any dot character `('.', 0x2E)`.

Servers MAY have additional implementation-specific nickname restrictions and SHOULD avoid the use of nicknames which are ambiguous with commands or command parameters where this could lead to confusion or error.

### Services

Services were a different kind of clients than users, defined in the [RFC2812](https://tools.ietf.org/html/rfc2812.html#section-1.2.2). They were to provide or collect information about the IRC network. They are no longer used now. As such the service-related messages (`SERVICE`, `SERVLIST` and `SQUERY`) are also deprecated.

#### Operators

To allow a reasonable amount of order to be kept within the IRC network, a special class of clients (operators) are allowed to perform general maintenance functions on the network. Although the powers granted to an operator can be considered as 'dangerous', they are nonetheless required.

The tasks operators can perform vary with different server software and the specific privileges granted to each operator. Some can perform network maintenance tasks, such as disconnecting and reconnecting servers as needed to prevent long-term use of bad network routing. Some operators can also remove a user from their server or the IRC network by 'force', i.e. the operator is able to close the connection between a client and server.

The justification for operators being able to remove users from the network is delicate since its abuse is both destructive and annoying. However, IRC network policies and administrators handle operators who abuse their privileges, and what is considered abuse by that network.

### Channels

A channel is a named group of one or more clients. All clients in the channel will receive all messages addressed to that channel. The channel is created implicitly when the first client joins it, and the channel ceases to exist when the last client leaves it. While the channel exists, any client can reference the channel using the name of the channel. Networks that support the concept of 'channel ownership' may persist specific channels in some way while no clients are connected to them.

Channel names are strings (beginning with specified prefix characters). Apart from the requirement of the first character being a valid [channel type](#channel-types) prefix character; the only restriction on a channel name is that it may not contain any spaces `(' ', 0x20)`, a control G / `BELL` `('^G', 0x07)`, or a comma `(',', 0x2C)` (which is used as a list item separator by the protocol).

There are several types of channels used in the IRC protocol. The first standard type of channel is a [regular channel](#regular-channels-), which is known to all servers that are connected to the network. The prefix character for this type of channel is `('#', 0x23)`. The second type are server-specific or [local channels](#local-channels-), where the clients connected can only see and talk to other clients on the same server. The prefix character for this type of channel is `('&', 0x26)`. Other types of channels are described in the [Channel Types](#channel-types) section.

Along with various channel types, there are also channel modes that can alter the characteristics and behaviour of individual channels. See the [Channel Modes](#channel-modes) section for more information on these.

To create a new channel or become part of an existing channel, a user is required to join the channel using the {% message JOIN %} command. If the channel doesn't exist prior to joining, the channel is created and the creating user becomes a channel operator. If the channel already exists, whether or not the client successfully joins that channel depends on the modes currently set on the channel. For example, if the channel is set to `invite-only` mode (`+i`), the client only joins the channel if they have been invited by another user or they have been exempted from requiring an invite by the channel operators.

Channels also contain a [topic](#topic-message). The topic is a line shown to all users when they join the channel, and all users in the channel are notified when the topic of a channel is changed. Channel topics commonly state channel rules, links, quotes from channel members, a general description of the channel, or whatever the [channel operators](#channel-operators) want to share with the clients in their channel.

A user may be joined to several channels at once, but a limit may be imposed by the server as to how many channels a client can be in at one time. This limit is specified by the {% isupport CHANLIMIT %} `RPL_ISUPPORT` parameter. See the [Feature Advertisement](#feature-advertisement) section for more details on `RPL_ISUPPORT`.

If the IRC network becomes disjoint because of a split between servers, the channel on either side is composed of only those clients which are connected to servers on the respective sides of the split, possibly ceasing to exist on one side. When the split is healed, the connecting servers ensure the network state is consistent between them.

#### Channel Operators

Channel operators (or "chanops") on a given channel are considered to 'run' or 'own' that channel. In recognition of this status, channel operators are endowed with certain powers which let them moderate and keep control of their channel.

Most IRC operators do not concern themselves with 'channel politics'. In addition, a large number of networks leave the management of specific channels up to chanops where possible, and try not to interfere themselves. However, this is a matter of network policy, and it's best to consult the [Message of the Day](#motd-message) when looking at channel management.

IRC servers may also define other levels of channel moderation. These can include 'halfop' (half operator), 'protected' (protected user/operator), 'founder' (channel founder), and any other positions the server wishes to define. These moderation levels have varying privileges and can execute, and not execute, various channel management commands based on what the server defines.

The commands which may only be used by channel moderators include:

- {% command KICK %}: Eject a client from the channel
- {% command MODE %}: Change the channel's modes
- {% command INVITE %}: Invite a client to an invite-only channel (mode +i)
- {% command TOPIC %}: Change the channel topic in a mode +t channel

Channel moderators are identified by the channel member prefix (`'@'` for standard channel operators, `'%'` for halfops) next to their nickname whenever it is associated with a channel (e.g. replies to the {% command NAMES %}, {% command WHO %}, and {% command WHOIS %} commands).

Specific prefixes and moderation levels are covered in the [Channel Membership Prefixes](#channel-membership-prefixes) section.


## Communication Types

*This section describes how current implementations deliver different classes of messages and is not normative.*

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

Servers should be able to send a message from any one client to any other. Servers send a message in exactly one direction along the spanning tree to reach any client. Thus the path of a message being delivered is the shortest path between any two points on the spanning tree.

The following examples all refer to the figure above.

1. A message between clients 1 and 2 is only seen by server A, which sends it straight to client 2.

2. A message between clients 1 and 3 is seen by servers A, B, and client 3. No other clients or servers are allowed to see the message.

3. A message between clients 2 and 4 is seen by servers A, B, C, D, and client 4 only.

### One-to-many communication

The main goal of IRC is to provide a forum which allows easy and efficient conferencing (one to many conversations). IRC offers several means to achieve this, each serving its own purpose.

#### To A Channel

In IRC, the channel has a role equivalent to that of the multicast group; their existence is dynamic and the actual conversation carried out on a channel is generally sent only to servers which are supporting users on a given channel, and only once to every local link as each server is responsible for fanning the original message to ensure it will reach all recipients.

The following examples all refer to the above figure:

4. Any channel with a single client in it. Messages to this channel go to the server and then nowhere else.

5. Two clients in a channel. All messages traverse a path as if they were private messages between the two clients outside a channel.

6. Clients 1, 2, and 3 are in a channel. All messages to this channel are sent to all clients and only those servers which must be traversed by the message if it were a private message to a single client. If client 1 sends a message, it goes back to client 2 and then via server B to client 3.

#### To A Host/Server Mask

To provide with some mechanism to send messages to a large body of related users, host and server mask messages are available. These messages are sent to users whose host or server information match that of the given mask. The messages are only sent to locations where the users are, in a fashion similar to that of channels.

#### To A List

The least efficient style of one-to-many conversation is through clients talking to a 'list' of targets (client, channel, ask). How this is done is almost self-explanatory: the client gives a list of destinations to which the message is to be delivered and the server breaks it up and dispatches a separate copy of the message to each given destination.

This is not as efficient as using a channel since the destination list may be broken up and the dispatch sent without checking to make sure duplicates aren't sent down each path.

### One-To-All

The one-to-all type of message is better described as a broadcast message, sent to all clients or servers or both. On a large network of users and servers, a single message can result in a lot of traffic being sent over the network in an effort to reach all of the desired destinations.

For some class of messages, there is no option but to broadcast it to all servers to that the state information held by each server is consistent between them.

#### Client-to-Client

IRC Operators may be able to send a message to every client currently connected to the network. This depends on the specific features and commands implemented in the server software.

#### Client-to-Server

Most of the commands which result in a change of state information (such as channel membership, channel modes, user status, etc.) MUST be sent to all servers by default, and this distribution SHALL NOT be changed by the client.

#### Server-to-Server

While most messages between servers are distributed to all 'other' servers, this is only required for any message that affects a user, channel, or server. Since these are the basic items found in IRC, nearly all messages originating from a server are broadcast to all other connected servers.
