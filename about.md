---
title: About
layout: default
---

This site contains documents describing the IRC protocol and related technologies (affectionately called the 'Modern docs'). The documents hosted here are intended to be useful to software developers working with IRC. They contain existing behaviour and what we consider best-practices for new software.

If something written in these documents isn't correct for or interoperable with an IRC client / server / network you know of, please open an issue or send me an [email](mailto:daniel@danieloaks.net). Pull requests are appreciated.

For suggestions of other documents to create / maintain, please [create an issue](https://github.com/ircdocs/modern-irc/issues) or [send me an email](mailto:daniel@danieloaks.net)!

---

## Guidelines

These documents SHOULD NOT describe brand new behaviour, but existing behaviour present in IRC software and/or networks (new extensions are IRCv3's area). These documents should be useful to IRC developers **today**, not in 10 years time.

The behaviour and constants described in these documents SHOULD converge, and/or be interoperable with the majority of IRC software. These documents should let a client or server author build software which can communicate with almost any other piece of IRC software it interacts with.

Where external, up-to-date and authoritative specifications exist for commands/messages/behaviours, we prefer to link to those rather than needlessly rewrite them (see the Client Protocol's [`CAP`](http://modern.ircdocs.horse/#cap-message) message for an example of this).

These document are not RFCs. Writing an RFC and putting it through the IETF process is a long slog that's probably going to be completed by someone else if at all, and whoever does it is free to use anything from these documents. Just respect the authors section at the top of the document if a decent amount of text is used from it.

---

## Living Specifications

We consider the documents on this site to be 'living specifications'. This means they are updated as feedback is received for them and as the protocol is extended and grows. Bugs can be fixed, incorrect behaviours in the specifications can be corrected, and they can be extended as new behaviour becomes widespread.

These documents are called 'specifications' rather than standards because they're descriptive, not prescriptive. These specifications are written in response to observed behaviour, rather than changing already-widespread behaviour to match what's written here.

This term and our use of it is based on the WHATWG definition of a ['living standard'](https://wiki.whatwg.org/wiki/FAQ#What_does_.22Living_Standard.22_mean.3F).

---

## Are these documents standards or signed off by multiple vendors?

These documents are explicitly not standards and not signed off by a collection of vendors. These documents are signed off by the editor of that document (though we gladly accept contributors and PRs).

Regardless, I hope you find these documents useful and investigate protocol extensions with the [IRCv3 Working Group](http://ircv3.net).

---

## What are your plans for these documents?

There have been questions about doing this work with IRCv3, the IETF, etc. I'm keeping it separate for now, and this section explains why.

I started writing the Modern doc on my own site because I like being able to work at my own pace. When you introduce standards orgs like IRCv3 and the IETF, changes end up having to get signed-off by multiple people. This slows things down, and as a result I lose interest and stop putting time into it. Having the documents here lets me (and any other editors) work at their own pace, and put changes online without needing to worry about getting them approved or having to argue for them.

That slower, multiple-people signoff process is necessary for new standards, and those other standards groups are great. However, I feel like those processes don't work as well for these documents in particular, with where they are right now and their aim.

This work will probably end up being integrated into one of those groups down the line, and be submitted as some sort of RFC. However, for now I'm happy working on them, productively, with this sort of editor-focused process.
