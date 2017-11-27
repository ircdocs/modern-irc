# Examples

While examples of every situation cannot be shown here, the following examples provide a rough overview of how the IRC URL can be used.

      irc://irc.undernet.org/

The above URL is used to direct a client to connect to a specific IRC server, which in this case is `"irc.undernet.org"`. The client should use default port settings.

      irc://irc.ircnet.net/#worldchat,ischannel
      irc://irc.ircnet.net/worldchat,ischannel
      irc://irc.ircnet.net/#worldchat
      irc://irc.ircnet.net:6667/worldchat

All of these URLs connect to the IRCnet network, and will join the client to the channel `"#worldchat"` upon connection. The four URLs listed above are considered identical.

      irc://irc.alien.net.au/pickle,isuser

This will connect to the server `irc.alien.net.au` and will provoke the client to open up a dialogue box prepared to send a message to the nickname `'pickle'`.

      irc://irc.austnet.org/%23foobar?key=bazqux

This will connect to AUSTnet and join the channel `"#foobar"`, using the [channel key](./index.html#key-channel-mode) `"bazqux"`.

      ircs://irc.undernet.org:6697/pickle,isuser

This will connect to the server `irc.alien.net.au` using TLS on port 6697, and open a dialogue box prepared to send a message to the nickname `"pickle"`.

      irc://:pass@irc.efnet.org:194/

The above URL specifies that the IRC client should try to connect to `"irc.efnet.org"` on the port 194 rather than use the default port(s). It also tells the IRC client it should try to connect to the server using the server password `"pass"`.

      irc://:g%C3%BCzel@irc.austnet.org/

This shows a [UTF-8](https://tools.ietf.org/html/rfc2279) encoded URL, specifying the password `"güzel"` (with a diaeresis on the u, codepoint `U+00FC`).
