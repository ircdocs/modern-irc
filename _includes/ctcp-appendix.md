# CTCP Message Registry

_Extended formatting_ messages can have parameters, but usually do not generate an automatic reply.

_Metadata queries_ do not have any parameters, but expect a reply with parameters as the response data.

_Extended queries_ and replies may have parameters.

We only cover messages that are widely-used by IRC software today. For more extensive lists, see the external `irc-defs` [ctcp messages](https://defs.ircdocs.horse/defs/ctcp.html) list.

### ACTION

      Type:    Extended Formatting
      Params:  ACTION <text>

This extended formatting message shows that `<text>` should be displayed as a third-person _action_ or _emote_; in clients, it's generally activated with the command `/me`.

`ACTION` is universally implemented and very commonly used. Clients MUST implement this CTCP message.

*Example:*

      Raw:        :dan!user@host PRIVMSG #ircv3 :\x01ACTION writes a specification\x01

      Formatted:  * dan writes a specification

### CLIENTINFO

      Type:   Metadata Query
      Reply:  CLIENTINFO <token>{ <token>}

This metadata query returns a list of the CTCP messages that this client supports and implements.

`CLIENTINFO` is widely implemented. Clients SHOULD implement this CTCP message.

*Example:*

      Query:     CLIENTINFO
      Response:  CLIENTINFO ACTION DCC CLIENTINFO FINGER PING SOURCE TIME USERINFO VERSION

### DCC

      Type:    Extended Query
      Params:  DCC <type> <argument> <address> <port>

DCC (Direct Client-to-Client) is used to setup and control connections that go directly between clients, bypassing the IRC server. This is typically used for features that require a large amount of traffic between clients or simply wish to bypass the server itself such as file transfer, direct chat, and voice messages.

Properly implementing the various DCC types requires a document all of its own, and are not described here. <!--Check the [`DCC`](/dcc.html) document for more information on how to use DCC.-->

`DCC` is widely implemented. Clients MAY implement this CTCP message.

### FINGER

      Type:   Metadata Query
      Reply:  FINGER <info>

This metadata query returns miscellaneous info about the user, typically the same information that's held in their `realname` field.

However, some implementations return the client name and version instead.

`FINGER` is widely implemented, but largely obsolete. Clients MAY implement this CTCP message.

*Example:*

      Query:     FINGER
      Response:  FINGER WeeChat 1.5

### PING

      Type:    Extended Query
      Params:  PING <info>

This extended query is used to confirm reachability with other clients and to check latency. When receiving a CTCP PING, the reply must contain exactly the same parameters as the original query.

`PING` is universally implemented. Clients MUST implement this CTCP message.

*Example:*

      Query:     PING 1473523721 662865
      Response:  PING 1473523721 662865
      
      Query:     PING foo bar baz
      Response:  PING foo bar baz

### SOURCE

      Type:   Metadata Query
      Reply:  SOURCE <info>

This metadata query is used to return the location of the source code for the client.

`SOURCE` is rarely implemented. Clients MAY implement this CTCP message.

*Example:*

      Query:     SOURCE
      Response:  SOURCE https://weechat.org/download

### TIME

      Type:    Extended Query
      Params:  TIME <timestring>

This extended query is used to return the client's local time in an unspecified human-readable format. We recommend ISO 8601 format, but raw `ctime()` output appears to be the most common in practice.

New implementations SHOULD default to UTC time for privacy reasons.

`TIME` is almost universally implemented. Clients SHOULD implement this CTCP message.

*Example:*

      Query:     TIME
      Response:  TIME 2016-09-26T00:45:36Z

### VERSION

      Type:   Metadata Query
      Reply:  VERSION <verstring>

This metadata query is used to return the name and version of the client software in use. There is no specified format for the version string.

`VERSION` is universally implemented. Clients MUST implement this CTCP message.

*Example:*

      Query:     VERSION
      Response:  VERSION WeeChat 1.5-rc2 (git: v1.5-rc2-1-gc1441b1) (Apr 25 2016)

### USERINFO

      Type:   Metadata Query
      Reply:  USERINFO <info>

This metadata query returns miscellaneous info about the user, typically the same information that's held in their `realname` field.

However, some implementations return `<nickname> (<realname>)` instead.

`USERINFO` is widely implemented, but largely obsolete. Clients MAY implement this CTCP message.

*Example:*

      Query:     USERINFO
      Response:  USERINFO fred (Fred Foobar)
