---
title: About
layout: default
---

This site contains documents describing the IRC protocol and related technologies. The documents hosted here are intended to be useful to software developers working with IRC.

* [Modern IRC Client Protocol](./index.html) document.

For suggestions of other documents to create / maintain, please [create an issue](https://github.com/ircdocs/modern-irc/issues) or [send me an email](mailto:daniel@danieloaks.net)!

The behaviour and constants described in these documents SHOULD converge, and/or be interoperable with the majority of IRC software. These documents should allow a client or server author to build software which can communicate with almost any other piece of IRC software it interacts with.

These documents contain existing behaviour and what we consider best-practices for new software. Where external, up-to-date and authoritative specifications exist for commands/messages/behaviours, we prefer to link to those rather than needlessly rewrite them (see the Client Protocol's [`CAP`](http://modern.ircdocs.horse/#cap-message) message for an example of this).

These document are not RFCs. Writing an RFC and putting it through the IETF process is the job of someone else, and whoever does it is free to use anything from these documents. Just respect the authors section at the top of the document if a decent amount of text is used from it. Look at [ircv3-harmony](https://github.com/kaniini/ircv3-harmony) for something which aims to be an RFC.

If something written in these documents isn't correct for or interoperable with an IRC client / server / network you know of, please open an issue or send me an [email](mailto:daniel@danieloaks.net). Pull requests are appreciated.

---

## Living Specification

We consider the documents on this site to be 'living specifications'. This means they are updated as feedback is received for them and as the protocol is extended and grows. Bugs can be fixed, incorrect behaviours in the specifications can be corrected, and they can be extended as new behaviour becomes widespread.

This term and our use of it is based on the WHATWG definition of a ['living standard'](https://wiki.whatwg.org/wiki/FAQ#What_does_.22Living_Standard.22_mean.3F).
