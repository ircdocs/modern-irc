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
  -
    name: "Val Lorentz"
    org: "Limnoria"
    org_link: "https://limnoria.net"
    email: "vlorentz.ircdocs@isometry.eu"
    editor: true
toc: true
---

{% include copyrights.html %}

<div class="note">
    <p>This document intends to be a useful overview and reference of the IRC client protocol as it is implemented today. It is a <a href="./about.html#living-specifications">living specification</a> which is updated in response to feedback and implementations as they change. This document describes existing behaviour and what I consider best practices for new software.</p>
    <p>This <strong>is not a new protocol</strong> &ndash; it is the standard IRC protocol, just described in a single document with some already widely-implemented/accepted features and capabilities. Clients written to this spec will work with old and new servers, and servers written this way will service old and new clients.</p>
    <p>TL;DR if a new RFC was released today describing how IRC works, this is what I think it would look like.</p>
    <p>If something written in here isn't correct for or interoperable with an IRC server / network you know of, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a> or <a href="mailto:daniel@danieloaks.net">contact me</a>.</p>
</div>

<div class="warning">
    <p>NOTE: This is NOWHERE NEAR FINISHED. Dragons be here, insane stuff be here.</p>
    <p>You can contribute by sending pull requests to our <a href="https://github.com/ircdocs/modern-irc">GitHub repository</a>!</p>
</div>

---


# Introduction

The Internet Relay Chat (IRC) protocol has been designed over a number of years, with multitudes of implementations and use cases appearing. This document describes the IRC Client-Server protocol.

IRC is a text-based chat protocol which has proven itself valuable and useful. It is well-suited to running on many machines in a distributed fashion. A typical setup involves multiple servers connected in a distributed network. Messages are delivered through this network and state is maintained across it for the connected clients and active channels.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).


<!--toc-->

---


# IRC Concepts

{% include concepts.md %}

---


# Connection Setup

IRC client-server connections work over TCP/IP. The standard ports for client-server connections are TCP/6667 for plaintext, and TCP/6697 for TLS connections.


---


# Server-to-Server Protocol Structure

Both [RFC1459](https://tools.ietf.org/html/rfc1459.html) and [RFC2813](https://tools.ietf.org/html/rfc2813.html) define a Server-to-Server protocol. But in the decades since, implementations have extended this protocol and diverged (see [TS6](https://github.com/grawity/irc-docs/blob/725a1f05b85d7a935986ae4f49b058e9b67e7ce9/server/ts6.txt) and [P10](http://web.mit.edu/klmitch/Sipb/devel/src/ircu2.10.11/doc/p10.html)), and servers have created entirely new protocols (see [InspIRCd](https://github.com/inspircd/inspircd)). The days where there was one Server-to-Server Protocol that everyone uses hasn't existed for a long time now.

However, different IRC implementations don't _need_ to interact with each other. Networks generally run one server software across their entire network, and use the S2S protocol implemented by that server. The client protocol is important, but how servers on the network talk to each other is considered an implementation detail.


---


# Client-to-Server Protocol Structure

{% include c2s_structure.md %}

---


# Connection Registration

Immediately upon establishing a connection the client must attempt registration, without waiting for any banner message from the server.

Until registration is complete, only a limited subset of commands SHOULD be accepted by the server. This is because it makes sense to require a registered (fully connected) client connection before allowing commands such as {% command JOIN %}, {% command PRIVMSG %} and others.

The recommended order of commands during registration is as follows:

1. `CAP LS 302`
2. `PASS`
3. `NICK` and `USER`
4. [Capability Negotiation](#capability-negotiation)
5. `SASL` (if negotiated)
6. `CAP END`

The commands specified in steps 1-3 should be sent on connection. If the server supports [capability negotiation](#capability-negotiation) then registration will be suspended and the client can negotiate client capabilities (steps 4-6). If the server does not support capability negotiation then registration will continue immediately without steps 4-6.

1. If the server supports capability negotiation, the {% command CAP %} command suspends the registration process and immediately starts the [capability negotiation](#capability-negotiation) process. `CAP LS 302` means that the client supports [version `302`](https://ircv3.net/specs/extensions/capability-negotiation.html#cap-ls-version) of client capability negotiation. The registration process is resumed when the client sends `CAP END` to the server.

2. The {% command PASS %} command is not required for the connection to be registered, but if included it MUST precede the latter of the {% command NICK %} and {% command USER %} commands.

3. The {% command NICK %} and {% command USER %} commands are used to set the user's nickname, username and "real name". Unless the registration is suspended by a {% command CAP %} negotiation, these commands will end the registration process.

4. The client should request advertised capabilities it wishes to enable here.

5. If the client supports [SASL authentication](#authenticate-message) and wishes to authenticate with the server, it should attempt this after a successful [`CAP ACK`](#cap-message) of the `sasl` capability is received and while registration is suspended.

6. If the server support capability negotiation, [`CAP END`](#cap-message) will end the negotiation period and resume the registration.

If the server is waiting to complete a lookup of client information (such as hostname or ident for a username), there may be an arbitrary wait at some point during registration. Servers SHOULD set a reasonable timeout for these lookups.

Additionally, some servers also send a {% message PING %} and require a matching {% command PONG %} from the client before continuing. This exchange may happen immediately on connection and at any time during connection registration, so clients MUST respond correctly to it.

Upon successful completion of the registration process, the server MUST send, in this order, the {% numeric RPL_WELCOME %}, {% numeric RPL_YOURHOST %}, {% numeric RPL_CREATED %}, {% numeric RPL_MYINFO %}, and at least one {% numeric RPL_ISUPPORT %} numeric to the client. The server SHOULD then respond as though the client sent the {% command LUSERS %} command and return the appropriate numerics. If the user has client modes set on them automatically upon joining the network, the server SHOULD send the client the {% numeric RPL_UMODEIS %} reply or a {% message MODE %} message with the client as target, preferably the former. The server MAY send other numerics and messages. The server MUST then respond as though the client sent it the {% message MOTD %} command, i.e. it must send either the successful [Message of the Day](#motd-message) numerics or the {% numeric ERR_NOMOTD %} numeric.

The first parameter of the {% numeric RPL_WELCOME %} message is the nickname assigned by the network to the client. Since it may differ from the nickname the client requested with the `NICK` command (due to, e.g. length limits or policy restrictions on nicknames), the client SHOULD use this parameter to determine its actual nickname at the time of connection. Subsequent nickname changes, client-initiated or not, will be communicated by the server sending a {% message NICK %} message.

---


# Feature Advertisement

IRC servers and networks implement many different IRC features, limits, and protocol options that clients should be aware of. The {% numeric RPL_ISUPPORT %} numeric is designed to advertise these features to clients on connection registration, providing a simple way for clients to change their behaviour based on what is implemented on the server.

Once client registration is complete, the server MUST send at least one `RPL_ISUPPORT` numeric to the client. The server MAY send more than one `RPL_ISUPPORT` numeric and consecutive `RPL_ISUPPORT` numerics SHOULD be sent adjacent to each other.

Clients SHOULD NOT assume a server supports a feature unless it has been advertised in `RPL_ISUPPORT`. For `RPL_ISUPPORT` parameters which specify a 'default' value, clients SHOULD assume the default value for these parameters until the server advertises these parameters itself. This is generally done for compatibility reasons with older versions of the IRC protocol that do not specify the `RPL_ISUPPORT` numeric and servers that do not advertise those specific tokens.

For more information and specific details on tokens, see the {% numeric RPL_ISUPPORT %} reply.

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

Clients and servers should implement capability negotiation and the `CAP` command based on the [Capability Negotiation specification](https://ircv3.net/specs/extensions/capability-negotiation.html). Updates, improvements, and new versions of capability negotiation are managed by the [IRCv3 Working Group](http://ircv3.net/irc/).


---


# Client Messages

Messages are client-to-server only unless otherwise specified. If messages may be sent from the server to a connected client, it will be noted in the message's description. For server-to-client messages of this type, the message `<source>` usually indicates the client the message relates to, but this will be noted in the description.

In message descriptions, 'command' refers to the message's behaviour when sent from a client to the server. Similarly, 'Command Examples' represent example messages sent from a client to the server, and 'Message Examples' represent example messages sent from the server to a client. If a command is sent from a client to a server with less parameters than the command requires to be processed, the server will reply with an {% numeric ERR_NEEDMOREPARAMS %} numeric and the command will fail.

In the `"Parameters:"` section, optional parts or parameters are noted with square brackets as such: `"[<param>]"`. Curly braces around a part of parameter indicate that it may be repeated zero or more times, for example: `"<key>{,<key>}"` indicates that there must be at least one `<key>`, and that there may be additional keys separated by the comma `(",", 0x2C)` character.


## Connection Messages

{% include messages/connection.md %}

## Channel Operations

{% include messages/channel.md %}

## Server Queries and Commands

{% include messages/server_queries.md %}

## Sending Messages

{% include messages/messages.md %}

## User-Based Queries

{% include messages/user_queries.md %}

## Operator Messages

{% include messages/ircop.md %}

## Optional Messages

{% include messages/optional.md %}

<!--
## Miscellaneous Messages

These messages do not fit into any of the above categories but are still REQUIRED by the protocol. All functional servers MUST implement these messages.
-->

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
