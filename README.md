# Modern IRC

This is an attempt to create an updated document about how the IRC client protocol works these days.

This document does not specify brand new stuff -- only existing behaviour and what we consider best-practices for new software. Where external, up-to-date and authoritative specifications exist for commands and messages, we prefer to link to those rather than needlessly rewrite sections (see the [`CAP`](http://modern.ircdocs.horse/#cap-message) message for an example of this).

We specify commands, messages and numerics as SHOULD and MUST based on how much of the IRC software out there today uses them (as well as the guidance of the RFCs and common-sense). Someone writing a client or server based off this document SHOULD end up with an implementation that interacts nicely with most IRC software and networks out there today.

This document is not an RFC. Writing an RFC and putting it through the IETF process is the job of someone else, and whoever does it is free to use anything from this document. Just try to respect the authors section at the top of the page if a decent amount of text is used. Look at [ircv3-harmony](https://github.com/kaniini/ircv3-harmony) for something which aims to be an RFC.

If something written in here isn't correct for or interoperable with an IRC server / network you know of, please open an issue or send me an [email](mailto:daniel@danieloaks.net). Pull requests are appreciated.

This covers the client-server protocol only, and does not touch the S2S protocol. The reasons for this are discussed in the document. This document includes bits and pieces cherry-picked from the RFCs, [IRCv3](http://ircv3.net/), Internet-Drafts, and commands/replies that have generally been accepted by the IRC community.

---

This document draws from [RFC1459](https://tools.ietf.org/html/rfc1459) and [RFC2812](https://tools.ietf.org/html/rfc2812), as well as other specifications and drafts [listed](http://modern.ircdocs.horse/#acknowledgements).
