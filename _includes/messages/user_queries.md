### WHO message

         Command: WHO
      Parameters: <mask>

This command is used to query a list of users who match the provided mask.
The server will answer this command with zero, one or more [`RPL_WHOREPLY`](#rplwhoreply-352), and end the list with [`RPL_ENDOFWHO`](#rplendofwho-315).

The mask can be one of the following:

* A channel name, in which case the channel members are listed.
* An exact nickname, in which case a single user is returned.
* A mask pattern, in which case all visible users whose nickname matches are listed. Servers MAY match other user-specific values, such as the hostname, server, real name or username. Servers MAY not support mask patterns and return an empty list.

Visible users are users who either aren't invisible ([user mode `+i`](#invisible-user-mode)) or have a common channel with the requesting client.
Servers MAY filter or limit visible users replies arbitrarily.

Numeric Replies:

* {% numeric RPL_WHOREPLY %}
* {% numeric RPL_ENDOFWHO %}

See also:

* IRCv3 [`multi-prefix` Extension](https://ircv3.net/specs/extensions/multi-prefix)
* [WHOX](https://ircv3.net/specs/extensions/whox)

#### Examples

Command Examples:

      WHO emersion        ; request information on user "emersion"
      WHO #ircv3          ; list users in the "#ircv3" channel

Reply Examples:

      :calcium.libera.chat 352 dan #ircv3 ~emersion sourcehut/staff/emersion calcium.libera.chat emersion H :1 Simon Ser
      :calcium.libera.chat 315 dan emersion :End of WHO list
                                      ; Reply to WHO emersion

      :calcium.libera.chat 352 dan #ircv3 ~emersion sourcehut/staff/emersion calcium.libera.chat emersion H :1 Simon Ser
      :calcium.libera.chat 352 dan #ircv3 ~val limnoria/val calcium.libera.chat val H :1 Val
      :calcium.libera.chat 315 dan #ircv3 :End of WHO list
                                      ; Reply to WHO #ircv3

### WHOIS message

         Command: WHOIS
      Parameters: [<target>] <nick>

This command is used to query information about a particular user.
The server SHOULD answer this command with numeric messages with information about the nick, ending with [`RPL_ENDOFWHOIS`](#rplendofwhois-318), even if they did not send any other numeric message. This allows clients to stop waiting for new numerics. In exceptional error conditions, servers MAY not reply to a `WHOIS` command. Clients SHOULD implement a hard timeout to avoid waiting for a reply which won't come.

Client MUST NOT not assume all numeric messages are sent at once, as server can interleave other messages before the end of the WHOIS response.

If the `<target>` parameter is specified, it SHOULD be a server name or the nick of a user. Servers SHOULD send the query to a specific server with that name, or to the server `<target>` is connected to, respectively.
Typically, it is used by clients who want to know how long the user in question has been idle (as typically only the server the user is directly connected to knows that information, while everything else this command returns is globally known).

The following numerics MAY be returned as part of the whois reply:

* {% numeric ERR_NOSUCHNICK %}
* {% numeric ERR_NOSUCHSERVER %}
* {% numeric ERR_NONICKNAMEGIVEN %}
* {% numeric RPL_WHOISCERTFP %}
* {% numeric RPL_WHOISREGNICK %}
* {% numeric RPL_WHOISUSER %}
* {% numeric RPL_WHOISSERVER %}
* {% numeric RPL_WHOISOPERATOR %}
* {% numeric RPL_WHOISIDLE %}
* {% numeric RPL_WHOISCHANNELS %}
* {% numeric RPL_WHOISSPECIAL %}
* {% numeric RPL_WHOISACCOUNT %}
* {% numeric RPL_WHOISACTUALLY %}
* {% numeric RPL_WHOISHOST %}
* {% numeric RPL_WHOISMODES %}
* {% numeric RPL_WHOISSECURE %}
* {% numeric RPL_AWAY %}

Servers typically send some of these numerics only to the client itself and to servers operators, as they contain privacy-sensitive information that should not be revealed to other users.

Server implementers wishing to send information not covered by these numerics may send other vendor-specific numerics, such that:

* the first and second parameters MUST be the client's nick, and the target nick, and
* the last parameter SHOULD be designed to be human-readable, so that user interfaces can display unknown numerics

Additionally, server implementers should consider submitting these to [IRCv3](https://ircv3.net/) for standardization, if relevant.

#### Optional extensions

This section describes extension to the common `WHOIS` command above.
They exist mainly on historical servers, and are rarely implemented, because of resource usage they incur.

* Servers MAY allow more than one target nick.
  They can advertise the maximum the number of target users per `WHOIS` command via the {% isupport TARGMAX %} `RPL_ISUPPORT` parameter, and silently drop targets if the number of targets exceeds the limit.

* Servers MAY allow wildcards in `<nick>`. Servers who do SHOULD reply with information about all matching nicks. They may restrict what information is available in this case, to limit resource usage.

* IRCv3 [`multi-prefix` Extension](https://ircv3.net/specs/extensions/multi-prefix)

#### Examples

Command Examples:

      WHOIS val                     ; request information on user "val"
      WHOIS val val                 ; request information on user "val",
                                    from the server they are on
      WHOIS calcium.libera.chat val ; request information on user "val",
                                    from server calcium.libera.chat

Reply Example:

      :calcium.libera.chat 311 val val ~val limnoria/val * :Val
      :calcium.libera.chat 319 val val :#ircv3 #libera +#limnoria
      :calcium.libera.chat 319 val val :#weechat
      :calcium.libera.chat 312 val val calcium.libera.chat :Montreal, CA
      :calcium.libera.chat 671 val val :is using a secure connection [TLSv1.3, TLS_AES_256_GCM_SHA384]
      :calcium.libera.chat 317 val val 657 1628028154 :seconds idle, signon time
      :calcium.libera.chat 330 val val pinkieval :is logged in as
      :calcium.libera.chat 318 val val :End of /WHOIS list.

### WHOWAS message

         Command: WHOWAS
      Parameters: <nick> [<count>]

Whowas asks for information about a nickname which no longer exists.
This may either be due to a nickname change or the user leaving IRC.
In response to this query, the server searches through its nickname history, looking for any nicks which are lexically the same (no wild card matching here).
The history is searched backward, returning the most recent entry first.
If there are multiple entries, up to `<count>` replies will be returned (or all of them if no `<count>` parameter is given).

If given, `<count>` SHOULD be a positive number. Otherwise, a full search is done.

Servers MUST reply with either {% numeric ERR_WASNOSUCHNICK %} or a non-empty list of WHOWAS entries,
both followed with {% numeric RPL_ENDOFWHOWAS %}

A WHOWAS entry is a series of numeric messages starting with {% numeric RPL_WHOWASUSER %}, optionally followed by other numerics relevant to that user, such as {% numeric RPL_WHOISACTUALLY %} and {% numeric RPL_WHOISSERVER %}.
Clients MUST NOT assume any particular numeric other than {% numeric RPL_WHOWASUSER %} is present in a WHOWAS entry.

If the `<nick>` argument is missing, they SHOULD send a single reply, using either {% numeric ERR_NONICKNAMEGIVEN %} or {% numeric ERR_NEEDMOREPARAMS %}.

#### Examples

Command Examples:

      WHOWAS someone
      WHOWAS someone 2

Reply Examples:

      :inspircd.server.example 314 val someone ident3 127.0.0.1 * :Realname
      :inspircd.server.example 312 val someone My.Little.Server :Sun Mar 20 2022 10:59:26
      :inspircd.server.example 314 val someone ident2 127.0.0.1 * :Realname
      :inspircd.server.example 312 val someone My.Little.Server :Sun Mar 20 2022 10:59:16
      :inspircd.server.example 369 val someone :End of WHOWAS

      :ergo.server.example 314 val someone ~ident3 127.0.0.1 * Realname
      :ergo.server.example 314 val someone ~ident2 127.0.0.1 * Realname
      :ergo.server.example 369 val someone :End of WHOWAS

      :solanum.server.example 314 val someone ~ident3 localhost * :Realname
      :solanum.server.example 338 val someone 127.0.0.1 :actually using host
      :solanum.server.example 312 val someone solanum.server.example :Sun Mar 20 10:07:44 2022
      :solanum.server.example 314 val someone ~ident2 localhost * :Realname
      :solanum.server.example 338 val someone 127.0.0.1 :actually using host
      :solanum.server.example 312 val someone solanum.server.example :Sun Mar 20 10:07:34 2022
      :solanum.server.example 369 val someone :End of WHOWAS

      :server.example 406 val someone :There was no such nickname
      :server.example 369 val someone :End of WHOWAS

