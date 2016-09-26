---
title: Client-to-Client Protocol (CTCP)
layout: default
copyrights:
  -
    name: "Mantas Mikulėnas"
    email: "grawity@gmail.com"
  -
    name: "Daniel Oaks"
    org: "ircdocs"
    org_link: "http://ircdocs.horse/"
    email: "daniel@danieloaks.net"
    editor: true
---

{% include copyrights.html %}

<div class="note">
    <p>This document intends to be a useful overview and reference of CTCP as it is implemented today. It is a <a href="./about.html#living-specification">living specification</a> which is updated in response to feedback and implementations as they change. This document describes existing behaviour and what we consider best practices for new software.</p>
    <p>If something written in here isn't interoperable with an IRC client you know of, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a>.</p>
</div>

<div id="printable-toc" style="display: none"></div>


---


# Introduction

The Client-to-Client Protocol (CTCP) has been in use on IRC for a very long time. Essentially, it provides a way for IRC clients to send each other messages that get parsed and displayed/responded to in special ways. Some examples of how CTCP is used today is to request special formatting on certain messages, query other clients for metadata, and initiate file transfers with other clients.

The original CTCP specifications are lengthy and cover quoting mechanisms which are no longer implemented or followed today. In comparison, this document goes over the subset of CTCP which is commonly implemented and lets your software interact nicely with most other IRC software out there.

The IRCv3 Working Group is investigating replacing some functions currently performed by CTCP with alternate methods such as [Metadata](https://github.com/ircv3/ircv3-specifications/issues/244) and [client-only message tags](http://ircv3.net/specs/core/message-tags-3.3.html), which should also allow these functions to be performed more widely and used to better effect.


---


# Message Syntax

The [`PRIVMSG`](/index.html#privmsg-message) and [`NOTICE`](/index.html#notice-message) messages are used to transmit CTCP frames. To create a CTCP message, you simply replace the body (i.e. the `<text to be sent>`) of a `PRIVMSG` / `NOTICE` with the following:

      delim   = %x01

      command = 1*( %x02-09 / %x0B-0C / %x0E-1F / %x21-FF )
                    ; any octet except NUL, delim, CR, LF, and " "

      params  = 1*( %x02-09 / %x0B-0C / %x0E-FF )
                    ; any octet except NUL, delim, CR, and LF

      body    = delim command [ SPACE params ] [ delim ]

The final `<delim>` MUST be sent, but parsers SHOULD accept incoming messages which lack it (particularly for `CTCP ACTION`). This is due to how some software incorrectly implements message splitting.

CTCP queries are sent with `PRIVMSG`, and replies are sent with `NOTICE`. In addition, CTCP queries sent to channels always generate private replies.

Here are two examples of CTCP queries and replies:

      :dx PRIVMSG SaberUK :\x01VERSION\x01
      :SaberUK NOTICE dx :\x01VERSION Your Mother 6.9\x01

      :mt PRIVMSG #ircv3 :\x01PING 1473523796 918320\x01
      :Jobe NOTICE mt :\x01PING 1473523796 918320\x01


## Changes since 1994 specification

The entire [`PRIVMSG`](/index.html#privmsg-message) / [`NOTICE`](/index.html#notice-message) message body must consist of either a CTCP message or plain text (non-CTCP). The original specification(s) allowed intermixing plain-text chunks and "tagged data" CTCP chunks, which has not been implemented widely enough for regular use.

This document does not include any mechanism for quoting plain text (non-CTCP) messages, as opposed to the original "low-level quoting" specifications (as this has not been widely implemented). Likewise, it does not define any mechanism for quoting CTCP parameters, although individual CTCP message specifications may define their own quoting.


---


# Message Types

CTCP messages generally take on one of these types. These message types are defined here for informational purposes only (to simplify understanding), and aren't specified or differentiated by the protocol itself.

Generally, channel-directed CTCPs should never cause an error reply.


## Extended Formatting

This type of CTCP is used to request special formatting of a user-visible message. That is, to send a user-visible message that should be displayed differently from regular messages - e.g. as an action, a whisper, an announcement.

Extended formatting CTCPs are sent as a `PRIVMSG`. There is no automatic response to this message type, as it is not a query nor reply.

Extended formatting CTCPs are expected to be used in channels as well as between clients. However, many servers implement optional filtering to block CTCPs in channels (apart from `ACTION`). Because of this, any future extended-formatting CTCPs may be restricted to private messages.

These CTCP messages are sent as a [`PRIVMSG`](/index.html#privmsg-message) and generate no reply.

**Example:**

      :dan- PRIVMSG #ircv3 :\x01ACTION is now away (BX-MsgLog:ON)\x01


## Metadata Query

This type of CTCP is used to provide _static_ information about the target client, user or connection.

This CTCP takes the form of a query and a response (as a `PRIVMSG` and `NOTICE`, respectively). Due to how bouncers interact with multiple clients, there may sometimes be multiple responses to queries.

Metadata queries MUST NOT require the recipient to implement any side effects (beyond sending the reply itself); if a CTCP message causes side effects by design, it should be categorized as an [extended query](#extended-query) instead.

**Example:**

      :dx PRIVMSG SaberUK :\x01VERSION\x01
      :SaberUK NOTICE dx :\x01VERSION Your Mother 6.9\x01


## Extended Query

This type of CTCP is used to provide _dynamic_ information or invoke actions from the client.

This CTCP takes the form of a query and a response (as a `PRIVMSG` and `NOTICE`, respectively).

Queries sent to a channel always generate private replies.

**Example:**

      :mt PRIVMSG #ircv3 :\x01PING 1473523796 918320\x01
      :Jobe NOTICE mt :\x01PING 1473523796 918320\x01


---


<div id="appendixes">

{% capture appendixes %}{% include ctcp-appendix.md %}{% endcapture %}
{{ appendixes | markdownify }}

</div>
