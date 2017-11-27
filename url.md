---
title: URL Schemes for IRC
layout: default
wip: true
copyrights:
  -
    name: "Simon Butcher"
    org: "Alien Internet Services"
    org_link: "https://www.alien.net.au/"
    email: "simonb@alien.net.au"
  -
    name: "Daniel Oaks"
    org: "ircdocs"
    org_link: "http://ircdocs.horse/"
    email: "daniel@danieloaks.net"
    editor: true
---

{% include copyrights.html %}

<div class="note">
    <p>This document intends to be a useful reference of the URL schemes used for and by IRC software today. It is a <a href="./about.html#living-specification">living specification</a> which is updated in response to feedback and implementations. This document describes existing behaviour and what we consider best practices for new software.</p>
    <p>If something written in here isn't correct for or interoperable with an IRC client you know of, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a> or <a href="mailto:daniel@danieloaks.net">contact me</a>.</p>
</div>

<div class="warning">
    <p>NOTE: This is NOT FINISHED. Dragons be here, insane stuff be here.</p>
    <p>You can contribute by sending pull requests to our <a href="https://github.com/ircdocs/modern-irc">Github repository</a>!</p>
</div>

<div id="printable-toc" style="display: none"></div>

---


# Introduction

Internet Relay Chat (IRC) is a text-based chat protocol which provides real-time chat services to thousands of users across the globe. IRC is used for many different purposes such as software support, business communications, and casual conversations.

A URL scheme for the IRC protocol has been in use for years. This document describes the formats of the IRC URL schemes and how clients should process these links. Applications for IRC URL schemes range widely, from server lists on an IRC network's site, technical support contact details, to being able to link meeting places in emails.

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).

In this document, the term "client" is defined as the IRC client software, and the term "user" is the end-user of that software. The term "entity" refers to an addressable IRC entity such as a client or a channel.


---


# URL Definition

An IRC URL begins with either the scheme `"irc"` or `"ircs"`, denoting plaintext and secured connections respectively. Plaintext sessions connect to the IRC server with a plaintext transport and are considered insecure. Secured sessions connect with a [TLS transport](https://tools.ietf.org/html/rfc7194#section-2).

The URL schemes for IRC conform to the Generic URL Syntax defined in [RFC3986](https://tools.ietf.org/html/rfc3986).

The action that an IRC URL instigates is to open a connection to the specified IRC server using the specified transport, and make contact with the given client or channel if also requested.

Client software handling one of the `"irc"` or `"ircs"` schemes SHOULD also support the other.

## ABNF Syntax

The ABNF representation for the IRC URL scheme is:


      ircURL   = scheme "://" location "/" [ entity ] [ flags ] [ options ]

      scheme   = "irc" / "ircs"
                    ; Plaintext or Secured (TLS) connection.

      location = hostport
                    ; See Section 3.2 RFC3986 for the definition of 'hostport'.
                    ; https://tools.ietf.org/html/rfc3986#section-3.2

      entity   = [ "#" ] *( escaped / unreserved )
                    ; Note the prefix, "#", may be used for channel names without
                    ; the usual URL escapes. See the Channel Names section.

      flags    = ( [ "," enttype ] [ "," hosttype ] )
              /= ( [ "," hosttype ] [ "," enttype ] )

      enttype  = "," ( "isuser" / "isnick" / "ischannel" )

      hosttype = ",isnetwork"

      options  = "?" option *( "&" option )

      option   = optname [ "=" optvalue ]

      optname  = *( ALPHA / "-" )
                    ; Option names are case-insensitive.

      optvalue = optparam *( "," optparam )

      optparam = *( escaped / unreserved )

The definition of "escaped" and "unreserved" is in section [2.1 of RFC3986](https://tools.ietf.org/html/rfc3986#section-2.1). Clients MUST be aware of protocol limitations. For example, the [IRC protocol](./index.html) does not allow the SPACE `(' ', 0x20)` character inside nicknames or channel names.


## Server Names

The server to connect to SHOULD be specified by either its hostname or IP address, as with other URL schemes.

However, IRC URLs MAY also use the network's 'name' rather than a hostname or IP address. Links using this feature SHOULD use the `"hosttype"` option/flag to ensure this is clear for client software. Using the network's name rather than a hostname or IP address is NOT RECOMMENDED as clients may lack a maintained list of major IRC networks, or may include different networks in their list.

When using the 'name' format, the real hostname or IP address is intended to be looked up by the client software using its' internal list of IRC networks and their associated names. If the client does not contain any IRC network name lists and the `"isnetwork"` option/flag has been specified, the client MUST NOT attempt to resolve the name as a hostname.

If the host name is not a raw address (such as an IPv4, IPv6, or other network address), the name cannot be resolved (through DNS or other means), and the name does not contain a period `('.', 0x2E)`, the client MAY consider the given name as a network name to find an appropriate IRC server in its lists.


## Server Ports

Almost all IRC servers are contactable on a variety of standard ports. The below ports are the standard ports that IRC is served on today.

### `irc` Ports

The client SHOULD attempt connection to the port `6667`.

### `ircs` Ports

The client SHOULD attempt connection to the port `6697` as specified by [RFC7194](https://tools.ietf.org/html/rfc7194).


## Entity Names

Only one entity can be named per URL. The named entity SHOULD be presumed to be a channel name, unless the ["enttype" flag/option](#abnf-syntax) of the URL is provided to determine the entity type.

Any automated message MUST NOT be sent to the addressed entity.

### Channel Names

When `<enttype>` contains `"ischannel"`, or `<enttype>` is omitted completely, the entity name provided is a channel name.

Channel names prefixed with the `('#', 0x23)` character SHOULD leave this character out of created IRC URLs. This is due to how clients interpret incoming URLs which include channel names. However, if the channel name starts with more than a single `('#', 0x23)` character, then all of these MUST be included in created URLs. This is an exception to [Section 2.4.3 of RFC2396](https://tools.ietf.org/html/rfc2396#section-2.4.3) which specifies that this character should be encoded as the literal ASCII string `"%23"` – but the advice in RFC2396 is ignored as it is not followed in practice with IRC URLs.

Clients SHOULD attempt to determine valid channel name prefix characters from the server it has connected to via the [`CHANTYPES`](./index.html#chantypes-parameter) parameter of the [`RPL_ISUPPORT`](./index.html#rplisupport-005) `(005)` numeric presented on connection. If the client discovers the channel name given in the URL is missing a valid channel prefix character, the client SHOULD prepend the default prefix character `('#', 0x23)` to the name before attempting to join the channel.

### Nicknames

When the `"enttype"` flag/options contains the flag/option `"isuser"` or `"isnick"`, the entity given is a nickname.


## Additional Options

Additional options may be used to provide additional information about the entity you're addressing.

Clients SHOULD support at least the options listed here. Unsupported options MUST be ignored by the client.

### `key` Option

This option is only valid if the given entity name is parsed as a channel name. If the entity name is not a channel name, this option MUST be ignored.

The option's value provides the [channel key](./index.html#key-channel-mode) to be used when [joining](./index.html#join-message) the given channel. If a [channel key](./index.html#key-channel-mode) is found to be required and one is not provided with this option, the IRC client may wish to prompt the user for the key and attempt to join the channel again.

See the [Security Considerations](#security-considerations) section of this document when implementing this option.


---


# Internationalisation Considerations

<div class="warning">
    <p>Is this actually done in practice?</p>
</div>

IRC URLs MUST be encoded using the [UTF-8](https://tools.ietf.org/html/rfc2279) character set, with unsafe octets encoded using the `%HH` notation (where `HH` is a hexadecimal value) as per the [Percent-Encoding section (2.1) of RFC3986](https://tools.ietf.org/html/rfc3986#section-2.1). An example of this can be found in the [Examples](#examples) appendix.


---


# Interoperability Considerations

Not all clients can parse everything in this document. However, if you parse everything in here then you should be able to correctly parse any URLs that come your way.

Some IRC clients always prepend a `('#', 0x23)` character before joining the given channel. This is why we note both forms as acceptable, and recommend leaving out the leading `('#', 0x23)` when creating these URLs.


---


# Security Considerations

Security problems naturally arise when a server password and/or a [channel key](./index.html#key-channel-mode) is specified in an IRC URL. While the use of the password and channel key sections is considered to be rare, they have been included for uses such as for shortcut/bookmark lists, or to be used as a user command.

As the passwords and channel keys are passed as clear text, any user using the IRC URL and/or people creating IRC URLs should be aware of obvious insecurities. It is strongly discouraged to use these fields in a public setting (such as a website) if they are intended to be kept secret.

Client software MUST ONLY initiate the connection specified by the URL with the knowledge and consent of the user (e.g. if the user clicks on the URL). Doing otherwise would open the user up to a variety of malicious activities including, but not limited to channel advertising spam via "pop-ups" or other means.

When connecting using the secure IRC URI Scheme (`ircs`), if a secure connection cannot be established the connection MUST fail. The client MUST NOT automatically fall back to an insecure connection.

Automated messages MUST NOT be sent to any entity upon connection to an IRC server as a direct result of execution of an IRC URL. Sending messages to channels and other users SHOULD be left up to the user, not the URL author or client software. The facility to send automated messages to channels or other clients with IRC URLs opens users up to unwittingly spamming.

Clients MUST be aware of protocol limitations, especially when dealing with entity names, and SHOULD disallow characters that would break the IRC protocol. For example, a URL with a nickname including the characters `CR` `('\r', 0x13)` and / or `LF` `('\n', 0x10)` could be used to exploit a client as they are used as message delimiters by the [IRC client protocol](./index.html), potentially allowing a malicious URL author to execute any command they wish.

There are also security concerns with regards to associated protocols including [TLS](https://tools.ietf.org/html/rfc7194#section-2) and [UTF-8](https://tools.ietf.org/html/rfc2279), which must be taken into consideration, but are beyond the scope of this document.


---

<div id="appendixes">

{% capture appendixes %}{% include url-appendix.md %}{% endcapture %}
{{ appendixes | markdownify }}

</div>

---


# Acknowledgements

This document is based on the [draft-butcher-irc-url-04](https://tools.ietf.org/html/draft-butcher-irc-url-04) Internet Draft authored by Simon Butcher.

The acknowledgements below are presented verbatim from the above Internet Draft.

I acknowledge the previous work of Mandar Mirashi who originally wrote an Internet-Draft to similar effect.

The input of Petr Baudis, Robert Ginda, Piotr Kucharski, Perry Lorier, Khaled Mardam-Bey, Dominick Meglio, James Ross, and Samuel Sieb, was greatly appreciated, and this draft would not exist without their valued participation. I also thank them for their patience while I was travelling overseas.

I would also like to acknowledge those members of the IRC development community who encouraged me to publish this document, after more than 18 months of pretermission.
