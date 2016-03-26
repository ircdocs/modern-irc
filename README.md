# Modern IRC

This is an attempt to create an updated document about how the IRC client protocol works these days.

This is **not an authoritative document**. This means that if there are multiple ways something is done, this document doesn't make decisions about which method is better or which one to specify -- it usually notes both down and just tries to show what clients and servers do today. Making decisions is the job of an RFC, and writing an RFC is the job of someone else. I'm just trying to get some relatively sane subset of the IRC protocol written down. Look at [ircv3-harmony](https://github.com/kaniini/ircv3-harmony) for something which aims to be an RFC.

If something written in here isn't correct for or interoperable with an IRC server / network you know of, please open an issue. Pull requests are appreciated.

This covers the client-server protocol only, and does not touch the S2S protocol. The reasons for this are discussed in the document. This document includes bits and pieces cherry-picked from the RFCs, [IRCv3](http://ircv3.net/), Internet-Drafts, and commands/replies that have generally been accepted by the IRC community.

---

This document draws from [RFC1459](https://tools.ietf.org/html/rfc1459) and [RFC2812](https://tools.ietf.org/html/rfc2812), as well as other specifications and drafts [listed](http://modern.ircdocs.horse/#acknowledgements).
