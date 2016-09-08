---
title: About
layout: default
---

This site contains documents describing the IRC protocol and related technologies. The documents hosted here are intended to be useful to software developers working with IRC. They contain existing behaviour and what we consider best-practices for new software.

If something written in these documents isn't correct for or interoperable with an IRC client / server / network you know of, please open an issue or send me an [email](mailto:daniel@danieloaks.net). Pull requests are appreciated.

For suggestions of other documents to create / maintain, please [create an issue](https://github.com/ircdocs/modern-irc/issues) or [send me an email](mailto:daniel@danieloaks.net)!

---

## Guidelines

These documents SHOULD NOT describe brand new behaviour, but existing behaviour present in IRC software and/or networks. These documents should be useful to IRC developers today, not in 10 years time.

The behaviour and constants described in these documents SHOULD converge, and/or be interoperable with the majority of IRC software. These documents should allow a client or server author to build software which can communicate with almost any other piece of IRC software it interacts with.

Where external, up-to-date and authoritative specifications exist for commands/messages/behaviours, we prefer to link to those rather than needlessly rewrite them (see the Client Protocol's [`CAP`](http://modern.ircdocs.horse/#cap-message) message for an example of this).

These document are not RFCs. Writing an RFC and putting it through the IETF process is the job of someone else, and whoever does it is free to use anything from these documents. Just respect the authors section at the top of the document if a decent amount of text is used from it. Look at [ircv3-harmony](https://github.com/kaniini/ircv3-harmony) for something which aims to be an RFC.

---

## Living Specification

We consider the documents on this site to be 'living specifications'. This means they are updated as feedback is received for them and as the protocol is extended and grows. Bugs can be fixed, incorrect behaviours in the specifications can be corrected, and they can be extended as new behaviour becomes widespread.

This term and our use of it is based on the WHATWG definition of a ['living standard'](https://wiki.whatwg.org/wiki/FAQ#What_does_.22Living_Standard.22_mean.3F).

---

## Are these documents standards or signed off by multiple vendors?

These documents are explicitly not standards and not signed off by a collection of vendors. These documents are signed off by the editor of that document (though we gladly accept contributors and PRs).

The reason for this is that these documents are at an early state, and that they intend to describe already existing behaviour (rather than standardise new behaviour). At this point, having a sort of process that involves getting changes signed-off by multiple people/groups before being introduced would be more harmful than helpful.

Regardless, I hope you find these documents useful and investigate protocol extensions with the [IRCv3 Working Group](http://ircv3.net).
