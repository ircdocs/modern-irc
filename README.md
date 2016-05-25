# Modern IRC Documents

This site contains documents describing the IRC protocol and related technologies. The documents hosted here are intended to be useful to software developers working with IRC.

* [Modern IRC Client Protocol](http://modern.ircdocs.horse/) document
* [IRC Formatting](http://modern.ircdocs.horse/formatting.html) document

For suggestions of other documents to create / maintain, please [create an issue](https://github.com/ircdocs/modern-irc/issues) or [send me an email](mailto:daniel@danieloaks.net)!

The behaviour and constants described in these documents SHOULD converge, and/or be interoperable with the majority of IRC software. These documents should allow a client or server author to build software which can communicate with almost any other piece of IRC software it interacts with.

These documents contain existing behaviour and what we consider best-practices for new software. Where external, up-to-date and authoritative specifications exist for commands/messages/behaviours, we prefer to link to those rather than needlessly rewrite them (see the Client Protocol's [`CAP`](http://modern.ircdocs.horse/#cap-message) message for an example of this).

These document are not RFCs. Writing an RFC and putting it through the IETF process is the job of someone else, and whoever does it is free to use anything from these documents. Just respect the authors section at the top of the document if a decent amount of text is used from it. Look at [ircv3-harmony](https://github.com/kaniini/ircv3-harmony) for something which aims to be an RFC.

If something written in these documents isn't correct for or interoperable with an IRC client / server / network you know of, please open an issue or send me an [email](mailto:daniel@danieloaks.net). Pull requests are appreciated.

---

## Modern IRC Client Protocol

This is an attempt to create an updated document about how the IRC client protocol works these days.

We specify commands, messages and numerics as SHOULD and MUST based on how much of the IRC software out there today uses them (as well as the guidance of the RFCs and common-sense). Someone writing a client or server based off this document SHOULD end up with an implementation that interacts nicely with most IRC software and networks out there today.

This ignores the S2S protocol. The reasons for this are discussed in the document. This document includes bits and pieces cherry-picked from the RFCs, [IRCv3](http://ircv3.net/), Internet-Drafts, and commands/replies that have generally been accepted by the IRC community.

---

## IRC Formatting

Describes what I consider to be the formatting characters and methods understood by basically everything. This includes colors, bold, italics, formatting reset codes, etc.

In this document, I describe what I think is the most sane way to interpret them. This includes the edge-cases that aren't normally explored in similar documents, based on what clients tend to do today.
