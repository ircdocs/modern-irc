---
title: So You're Implementing IRC Software?
layout: default
wip: true
copyrights:
  -
    name: "Daniel Oaks"
    org: "ircdocs"
    org_link: "http://ircdocs.horse/"
    email: "daniel@danieloaks.net"
    editor: true
---

{% include copyrights.html %}

<div class="note">
    <p>This document's going to be updated as we find more pitfalls.</p>
    <p>If you think of a new one, or find an error with this document, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a>.</p>
</div>

<div id="printable-toc" style="display: none"></div>


---


# Introduction

IRC is touted as being one of the easiest protocols to implement. Just send `NICK` and `USER` and a few `JOIN` commands and you're done, right?

Well, yes! But also, no. There are some common pitfalls, fragile patterns, and bad habits that IRC software tends to fall into. Here, we outline those and try to describe why and how to avoid them. We've also written up some nice-to-haves that are relatively common, but not really described anywhere.


---


# The 'Trailing' Parameter

Message parameters normally can't contain spaces (since parameters are separated by spaces). But if the last parameter on a message is prefixed by a colon (`":"`), then it's called a 'trailing' parameter and it can include space characters.

Many clients and libraries split parameters into two sections: Normal parameters, and the Trailing parameter. You should NEVER DO THIS, EVER. The 'trailing' parameter is just a normal parameter, and MUST ALWAYS be just added on to the list of parameters.

Here's how your IRC Message class should expose parameters to your IRC software, in a C-like language:

```c
IRCMessage {
    []string Parameters
    // there is NO separate TrailingParameter variable
}
```

The list of parameters that your IRC software uses and passes around should contain every normal parameter, and also the 'trailing' parameter. Treating the 'trailing' parameter as special or separate in any other way means that you WILL create broken, fragile software.

### Examples In The Wild

- ["Various command parsers do not handle a colon before the last parameter"](https://github.com/hexchat/hexchat/issues/2271)
- ["PR: Rework MODE/RPL_CHANMODEIS handling for trailing args"](https://github.com/znc/znc/pull/1661)
- ["PR: Moving away from Event.Trailing"](https://github.com/lrstanley/girc/pull/36)
- ["PR: strip colon, if present, from ACCOUNT value"](https://github.com/weechat/weechat/pull/1525)
- ["PR: Remove Trailing param"](https://github.com/khlieng/dispatch/pull/4)


### Ways To Ensure This Doesn't Happen

You can test your message parser against the [parser-tests](https://github.com/ircdocs/parser-tests/tree/master/tests) repo. Specifically the [`msg-split` test file](https://github.com/ircdocs/parser-tests/blob/master/tests/msg-split.yaml), which includes tests for this specific issue.


---


# Tags/Prefixes Can Exist On Any Message

A good practice for IRC software is to parse incoming IRC lines into a data structure, and then use that data structure everywhere. If your software, instead, just passes the raw line and then matches bytes and strings from the line, you're probably going to run into this issue.

The gist is that if you enable a capability like [`server-time`](https://ircv3.net/specs/extensions/server-time-3.2.html), then ANY line from the server can contain a `@time` tag. You need to make sure that every command handler including `CAP`, `AUTHENTICATE`, `JOIN`, `PRIVMSG`, etc, can handle having a tag on the message. Along the same lines, any message can contain a `:server.example.com` prefix.

### Examples In The Wild

- ["SASL AUTHENTICATE does not work with a prefix"](https://github.com/znc/znc/issues/1212)




<!-- 
- trailing params being separated from normal params.
- server-time and unexpected tags (re: the lots of software that has broken after enabling server-time and getting authenticate, cap, etc lines with tags on 'em)
- nuh length and privmsg truncation.
- **ERR_NOMOTD** also being valid as the final numeric after connection reg.
- So You Want To Deal With The F*cking Encoding Mess? (or: Just Use UTF-8).
- validating that a last param can be sent as a non-final one, and irc framing generally (maybe include a link to that insp issue where an ISP was including a space or a newline or something in their reverse-lookup hostname and MAJORLY breaking assumptions. it happened in the s2s, but exactly the same could happen with s2c/c2s irc framing so, yeah, worth including as an example that impacts security).
- clients don't send \r\n\0, servers don't relay \r\n\0.
- clients may want to include a way for users to see raw protocol lines if their architecture allows it, ala /server raw
-->
