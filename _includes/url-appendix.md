# Examples

While examples of every situation cannot be shown here, the following examples provide a rough overview of how the IRC URL can be used.

      <irc://irc.undernet.org/>

The above URL is used to direct a client to connect to a specific IRC server, which in this case is `"irc.undernet.org"`. The client should use default port settings.

      <irc://irc.ircnet.net/#worldchat,ischannel>
      <irc://irc.ircnet.net/worldchat,ischannel>
      <irc://irc.ircnet.net/#worldchat>
      <irc://irc.ircnet.net:6667/worldchat>

All of these URLs connect to the IRCnet network, and will join the client to the channel `"#worldchat"` upon connection. The four URLs listed above are considered identical.

      <irc://irc.alien.net.au/pickle,isuser>

This will connect to the server `irc.alien.net.au` and will provoke the client to open up a window (or similar) associated with sending messages to the nickname `'pickle'`.

      <irc://irc.austnet.org/%23foobar?key=bazqux>

This will connect to AUSTnet and join the channel `"#foobar"`, using the [channel key](./index.html#key-channel-mode) `"bazqux"`.

      <irc://undernet/pickle%25butcher.id.au,isuser>

This will open a dialogue box prepared to send a message to `"pickle"` with the server name `"butcher.id.au"`. This URL will connect to the network named as `"undernet"`. For this to work correctly, the client must be configured appropriately to know the address of at least one server associated with this network.

      <irc://:pass@irc.efnet.org:194/>

The above URL specifies that the IRC client should try to connect to `"irc.efnet.org"` on the port 194 rather than use the default port(s). It also tells the IRC client it should try to connect to the server using the server password `"pass"`.

      <irc://%C4%B0dil:g%C3%BCzel@irc.austnet.org/>

This shows a [UTF-8](https://tools.ietf.org/html/rfc2279) encoded URL, specifying the username `"İdil"` (the first character being a Turkish Latin capital letter `"I"` with a dot above it, Unicode codepoint `U+0130`) and the password `"güzel"` (with a diaeresis on the u, codepoint `U+00FC`).
