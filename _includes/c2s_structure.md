While a client is connected to a server, they send a stream of bytes to each other. This stream contains messages separated by `CR` `('\r', 0x0D)` and `LF` `('\n', 0x0A)`. These messages may be sent at any time from either side, and may generate zero or more reply messages.

Software SHOULD use the [UTF-8](http://tools.ietf.org/html/rfc3629) character encoding to encode and decode messages, with fallbacks as described in the [Character Encodings](#character-encodings) implementation considerations appendix.

Names of IRC entities (clients, servers, channels) are casemapped. This prevents, for example, someone having the nickname `'Dan'` and someone else having the nickname `'dan'`, confusing other users. Servers MUST advertise the casemapping they use in the [`RPL_ISUPPORT`](#feature-advertisement) numeric that's sent when connection registration has completed.


## Message Format

An IRC message is a single line, delimited by a pair of `CR` `('\r', 0x0D)` and `LF` `('\n', 0x0A)` characters.

- When reading messages from a stream, read the incoming data into a buffer. Only parse and process a message once you encounter the `\r\n` at the end of it. If you encounter an empty message, silently ignore it.
- When sending messages, ensure that a pair of `\r\n` characters follows every single message your software sends out.

---

Messages have this format, as rough ABNF:

      message         ::= ['@' <tags> SPACE] [':' <source> SPACE] <command> <parameters> <crlf>
      SPACE           ::=  %x20 *( %x20 )   ; space character(s)
      crlf            ::=  %x0D %x0A        ; "carriage return" "linefeed"

The specific parts of an IRC message are:

- **tags**: Optional metadata on a message, starting with `('@', 0x40)`.
- **source**: Optional note of where the message came from, starting with `(':', 0x3A)`.
- **command**: The specific command this message represents.
- **parameters**: If it exists, data relevant to this specific command.

These message parts, and parameters themselves, are separated by one or more ASCII SPACE characters `(' ', 0x20)`.

Most IRC servers limit messages to 512 bytes in length, including the trailing `CR-LF` characters. Implementations which include [message tags](https://ircv3.net/specs/extensions/message-tags.html) need to allow additional bytes for the **tags** section of a message; clients must allow 8191 additional bytes and servers must allow 4096 additional bytes.

---

The following sections describe how to process each part, but here are a few complete example messages:

      :irc.example.com CAP LS * :multi-prefix extended-join sasl

      @id=234AB :dan!d@localhost PRIVMSG #chan :Hey what's up!

      CAP REQ :sasl


### Tags

This is the format of the **tags** part:

      <tags>          ::= <tag> [';' <tag>]*
      <tag>           ::= <key> ['=' <escaped value>]
      <key>           ::= [ <client_prefix> ] [ <vendor> '/' ] <sequence of letters, digits, hyphens (`-`)>
      <client_prefix> ::= '+'
      <escaped value> ::= <sequence of any characters except NUL, CR, LF, semicolon (`;`) and SPACE>
      <vendor>        ::= <host>

Basically, a series of `<key>[=<value>]` segments, separated by `(';', 0x3B)`.

The **tags** part is optional, and MUST NOT be sent unless explicitly enabled by [a capability](#capability-negotiation). This message part starts with a leading `('@', 0x40)` character, which MUST be the first character of the message itself. The leading `('@', 0x40)` is stripped from the value before it gets processed further.

Here are some examples of tags sections and how they could be represented as [JSON](https://www.json.org/) objects:

      @id=123AB;rose         ->  {"id": "123AB", "rose": ""}

      @url=;netsplit=tur,ty  ->  {"url": "", "netsplit": "tur,ty"}

For more information on processing tags – including the naming and registration of them, and how to escape values – see the IRCv3 [Message Tags specification](http://ircv3.net/specs/core/message-tags-3.2.html).


### Source

      source          ::=  servername / ( nickname [ "!" user ] [ "@" host ] )

The **source** (formerly known as **prefix**) is optional and starts with a `(':', 0x3A)` character (which is stripped from the value), and if there are no tags it MUST be the first character of the message itself.

The source indicates the true origin of a message. If the source is missing from a message, it's is assumed to have originated from the client/server on the other end of the connection the message was received on.

Clients MUST NOT include a source when sending a message.

Servers MAY include a source on any message, and MAY leave a source off of any message. Clients MUST be able to process any given message the same way whether it contains a source or does not contain one.


### Command

      command         ::=  letter* / 3digit

The **command** must either be a valid IRC command or a numeric (a three-digit number represented as text).

Information on specific commands / numerics can be found in the [Client Messages](#client-messages) and [Numerics](#numerics) sections, respectively.


### Parameters

This is the format of the **parameters** part:

      parameter       ::=  *( SPACE middle ) [ SPACE ":" trailing ]
      nospcrlfcl      ::=  <sequence of any characters except NUL, CR, LF, colon (`:`) and SPACE>
      middle          ::=  nospcrlfcl *( ":" / nospcrlfcl )
      trailing        ::=  *( ":" / " " / nospcrlfcl )

**Parameters** (or 'params') are extra pieces of information added to the end of a message. These parameters generally make up the 'data' portion of the message. What specific parameters mean changes for every single message.

Parameters are a series of values separated by one or more ASCII SPACE characters `(' ', 0x20)`. However, this syntax is insufficient in two cases: a parameter that contains one or more spaces, and an empty parameter. To permit such parameters, the final parameter can be prepended with a `(':', 0x3A)` character, in which case that character is stripped and the rest of the message is treated as the final parameter, including any spaces it contains. Parameters that contain spaces, are empty, or begin with a `':'` character MUST be sent with a preceding `':'`; in other cases the use of a preceding `':'` on the final parameter is OPTIONAL.

Software SHOULD AVOID sending more than 15 parameters, as older client protocol documents specified this was the maximum and some clients may have trouble reading more than this. However, clients MUST parse incoming messages with any number of them.

Here are some examples of messages and how the parameters would be represented as [JSON](https://www.json.org/) lists:

      :irc.example.com CAP * LIST :         ->  ["*", "LIST", ""]

      CAP * LS :multi-prefix sasl           ->  ["*", "LS", "multi-prefix sasl"]

      CAP REQ :sasl message-tags foo        ->  ["REQ", "sasl message-tags foo"]

      :dan!d@localhost PRIVMSG #chan :Hey!  ->  ["#chan", "Hey!"]

      :dan!d@localhost PRIVMSG #chan Hey!   ->  ["#chan", "Hey!"]

      :dan!d@localhost PRIVMSG #chan ::-)   ->  ["#chan", ":-)"]

As these examples show, a trailing parameter (a final parameter with a preceding `':'`) has the same semantics as any other parameter, and MUST NOT be treated specially or stored separately once the `':'` is stripped.

### Compatibility with incorrect software

Servers SHOULD handle single `\n` character, and MAY handle a single `\r` character, as if it was a `\r\n` pair, to support existing clients that might send this. However, clients and servers alike MUST NOT send single `\r` or `\n` characters.

Servers and clients SHOULD ignore empty lines.

Servers SHOULD gracefully handle messages over the 512-bytes limit. They may:

* Send an error numeric back, preferably {% numeric ERR_INPUTTOOLONG %}
* Truncate on the 510th byte (and add `\r\n` at the end) or, preferably, on the last UTF-8 character or grapheme that fits.
* Ignore the message or close the connection – but this may be confusing to users of buggy clients.

Finally, clients and servers SHOULD NOT use more than one space (`\x20`) character as `SPACE` as defined in the grammar above.

## Numeric Replies

Most messages sent from a client to a server generates a reply of some sort. The most common form of reply is the numeric reply, used for both errors and normal replies. Distinct from a normal message, a numeric reply MUST contain a `<source>` and use a three-digit numeric as the command. A numeric reply SHOULD contain the target of the reply as the first parameter of the message. A numeric reply is not allowed to originate from a client.

In all other respects, a numeric reply is just like a normal message. A list of numeric replies is supplied in the [Numerics](#numerics) section.


## Wildcard Expressions

When wildcards are allowed in a string, it is referred to as a "mask".

For string matching purposes, the protocol allows the use of two special characters: `('?', 0x3F)` to match one and only one character, and `('*', 0x2A)` to match any number of any characters. These two characters can be escaped using the `('\', 0x5C)` character.

The ABNF syntax for this is:

      mask        =  *( nowild / noesc wildone / noesc wildmany )
      wildone     =  %x3F
      wildmany    =  %x2A
      nowild      =  %x01-29 / %x2B-3E / %x40-FF
                       ; any octet except NUL, "*", "?"
      noesc       =  %x01-5B / %x5D-FF
                       ; any octet except NUL and "\"

      matchone    =  %x01-FF
                       ; matches wildone
      matchmany   =  *matchone
                       ; matches wildmany

Examples:

      a?c         ; Matches any string of 3 characters in length starting
                  with "a" and ending with "c"

      a*c         ; Matches any string of 2 or more characters in length
                  starting with "a" and ending with "c"

