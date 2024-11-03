# Channel Types

IRC has various types of channels that act in different ways. What differentiates these channels is the character the channel name starts with. For instance, channels starting with `#` are regular channels, and channels starting with `&` are local channels.

Upon joining, clients are shown which types of channels the server supports with the {% isupport CHANTYPES %} parameter.

Here, we go through the different types of channels that exist and are widely-used these days.

### Regular Channels (`#`)

The prefix character for this type of channel is `('#', 0x23)`.

This channel is what's referred to as a normal channel. Clients can join this channel, and the first client who joins a normal channel is made a [channel operator](#channel-operators), along with the appropriate channel membership prefix. On most servers, newly-created channels have then [protected topic `"+t"`](#protected-topic-mode) and [no external messages `"+n"`](#no-external-messages-mode) modes enabled, but exactly what modes new channels are given is up to the server.

Regular channels are persisted across the network. If two clients on different servers join the same regular channel, they'll be able to see that each other are joined, and will see messages sent to the channel by the other client.

On servers that support the concept of 'channel ownership' (a client being able to own a channel and retain control of it with their account), clients may not receive channel operator priveledges on joining an otherwise empty channel.

### Local Channels (`&`)

The prefix character for this type of channel is `('&', 0x26)`.

This channel is what's referred to as a local channel. Clients can join this channel as normal, and the first client who joins a normal channel is made a [channel operator](#channel-operators), but the channel is not persisted across the network. In other words, each server has its own set of local channels that the other servers on the network don't see.

If a client on server A and a client on server B join the channel `&info`, they will not be able to see each other or the messages each posts to their server's local channel `&info`. However, if a client on server A and another client on server A join the channel `&info`, they will be able to see each other and the messages the other posts to that local channel.

Generally, the concept of channel ownership is not supported for local channels. Local channels also aren't as widely available as regular channels. As well, some networks disable or disallow local channels as opers across the network can neither see nor administrate them.


---



# Modes

Modes affect the behaviour and reflect details about targets -- clients and channels. The modes listed here are the ones that have been adopted and are used by the IRC community at large. If we say a mode is 'standard', that means it is defined in the official IRC specification documents.

The status and letter used for each mode is defined in the description of that mode.

We only cover modes that are widely-used by IRC software today and whose meanings should stay consistent between different server software. For more extensive lists (including conflicting and obsolete modes), see the external `irc-defs` [client](https://defs.ircdocs.horse/defs/usermodes.html) and [channel](https://defs.ircdocs.horse/defs/chanmodes.html) mode lists.


## User Modes

### Invisible User Mode

This mode is standard, and the mode letter used for it is `"+i"`.

If a user is set to 'invisible', they will not show up in commands such as {% message WHO %} or {% message NAMES %} unless they share a channel with the user that submitted the command. In addition, some servers hide all channels from the {% message WHOIS %} reply of an invisible user they do not share with the user that submitted the command.

### Oper User Mode

This mode is standard, and the mode letter used for is it `"+o"`.

If a user has this mode, this indicates that they are a network [operator](#operators).

### Local Oper User Mode

This mode is standard, and the mode letter used for it is `"+O"`.

If a user has this mode, this indicates that they are a server [operator](#operators). A local operator has [operator](#operators) privileges for their server, and not for the rest of the network.

### Registered User Mode

This mode is widely-used, and the mode letter used for it is typically `"+r"`. The character used for this mode, and whether it exists at all, may vary depending on server software and configuration.

If a user has this mode, this indicates that they have logged into a user account.

IRCv3 extensions such as [`account-notify`](http://ircv3.net/specs/extensions/account-notify-3.1.html), [`account-tag`](http://ircv3.net/specs/extensions/account-tag-3.2.html), and [`extended-join`](http://ircv3.net/specs/extensions/extended-join-3.1.html) provide the account name of logged-in users, and are more accurate than trying to detect this user mode due to the capability name remaining consistent.

### `WALLOPS` User Mode

This mode is standard, and the mode letter used for it is `"+w"`.

If a user has this mode, this indicates that they will receive {% message WALLOPS %} messages from the server.


## Channel Modes

### Ban Channel Mode

This mode is standard, and the mode letter used for it is `"+b"`.

This channel mode controls a list of client masks that are 'banned' from joining or speaking in the channel. If this mode has values, each of these values should be a client mask.

If this mode is set on a channel, and a client sends a `JOIN` request for this channel, their nickmask (the combination of `nick!user@host`) is compared with each banned client mask set with this mode. If they match one of these banned masks, they will receive an {% numeric ERR_BANNEDFROMCHAN %} reply and the `JOIN` command will fail. See the [ban exception](#ban-exception-channel-mode) mode for more details.

<a id="ban-exception-channel-mode"></a>
### Exception Channel Mode

This mode is used in almost all IRC software today. The standard mode letter used for it is `"+e"`, but it SHOULD be defined in the {% isupport EXCEPTS %} `RPL_ISUPPORT` parameter on connection.

This channel mode controls a list of client masks that are exempt from the ['ban'](#ban-channel-mode) channel mode. If this mode has values, each of these values should be a client mask.

If this mode is set on a channel, and a client sends a `JOIN` request for this channel, their nickmask is compared with each 'exempted' client mask. If their nickmask matches any one of the masks set by this mode, and their nickmask also matches any one of the masks set by the [ban](#ban-channel-mode) channel mode, they will not be blocked from joining due to the [ban](#ban-channel-mode) mode.

### Client Limit Channel Mode

This mode is standard, and the mode letter used for it is `"+l"`.

This channel mode controls whether new users may join based on the number of users who already exist in the channel. If this mode is set, its value is an integer and defines the limit of how many clients may be joined to the channel.

If this mode is set on a channel, and the number of users joined to that channel matches or exceeds the value of this mode, new users cannot join that channel. If a client sends a `JOIN` request for this channel, they will receive an {% numeric ERR_CHANNELISFULL %} reply and the command will fail.

### Invite-Only Channel Mode

This mode is standard, and the mode letter used for it is `"+i"`.

This channel mode controls whether new users need to be invited to the channel before being able to join.

If this mode is set on a channel, a user must have received an {% message INVITE %} for this channel before being allowed to join it. If they have not received an invite, they will receive an {% numeric ERR_INVITEONLYCHAN %} reply and the command will fail.

### Invite-Exception Channel Mode

This mode is used in almost all IRC software today. The standard mode letter used for it is `"+I"`, but it SHOULD be defined in the {% isupport INVEX %} `RPL_ISUPPORT` parameter on connection.

This channel mode controls a list of channel masks that are exempt from the [invite-only](#invite-only-channel-mode) channel mode. If this mode has values, each of these values should be a client mask.

If this mode is set on a channel, and a client sends a `JOIN` request for that channel, their nickmask is compared with each 'exempted' client mask. If their nickmask matches any one of the masks set by this mode, and the channel is in [invite-only](#invite-only-channel-mode) mode, they do not need to require an `INVITE` in order to join the channel.

### Key Channel Mode

This mode is standard, and the mode letter used for it is `"+k"`.

This mode letter sets a 'key' that must be supplied in order to join this channel. If this mode is set, its' value is the key that is required.
Servers may validate the value (eg. to forbid spaces, as they make it harder to use the key in `JOIN` messages). If the value is invalid, they SHOULD return [`ERR_INVALIDMODEPARAM`](#errinvalidmodeparam-696).
However, clients MUST be able to handle any of the following:

* [`ERR_INVALIDMODEPARAM`](#errinvalidmodeparam-696)
* [`ERR_INVALIDKEY`](#errinvalidkey-525)
* `MODE` echoed with a different key (eg. truncated or stripped of invalid characters)
* the key changed ignored, and no `MODE` echoed if no other mode change was valid.

If this mode is set on a channel, and a client sends a `JOIN` request for that channel, they must supply `<key>` in order for the command to succeed. If they do not supply a `<key>`, or the key they supply does not match the value of this mode, they will receive an {% numeric ERR_BADCHANNELKEY %} reply and the command will fail.

### Moderated Channel Mode

This mode is standard, and the mode letter used for it is `"+m"`.

This channel mode controls whether users may freely talk on the channel, and does not have any value.

If this mode is set on a channel, only users who have channel privileges may send messages to that channel. The [voice](#voice-prefix) channel mode is designed to let a user talk in a moderated channel without giving them other channel moderation abilities, and users of higher privileges (such as [halfops](#halfop-prefix) or [chanops](#operator-prefix)) may also speak in moderated channels.

### Secret Channel Mode

This mode is standard, and the mode letter used for it is `"+s"`.

This channel mode controls whether the channel is 'secret', and does not have any value.

A channel that is set to secret will not show up in responses to the {% message LIST %} or {% message NAMES %} command unless the client sending the command is joined to the channel. Likewise, secret channels will not show up in the {% numeric RPL_WHOISCHANNELS %} numeric unless the user the numeric is being sent to is joined to that channel.

### Protected Topic Mode

This mode is standard, and the mode letter used for it is `"+t"`.

This channel mode controls whether channel privileges are required to set the topic, and does not have any value.

If this mode is enabled, users must have channel privileges such as [halfop](#halfop-prefix) or [operator](#operator-prefix) status in order to change the topic of a channel. In a channel that does not have this mode enabled, anyone may set the topic of the channel using the {% message TOPIC %} command.

### No External Messages Mode

This mode is standard, and the mode letter used for it is `"+n"`.

This channel mode controls whether users who are not joined to the channel can send messages to it, and does not have any value.

If this mode is enabled, users MUST be joined to the channel in order to send [private messages](#privmsg-message) and [notices](#notice-message) to the channel. If this mode is enabled and they try to send one of these to a channel they are not joined to, they will receive an {% numeric ERR_CANNOTSENDTOCHAN %} numeric and the message will not be sent to that channel.

## Channel Membership Prefixes

Users joined to a channel may get certain privileges or status in that channel based on channel modes given to them. These users are given prefixes before their nickname whenever it is associated with a channel (ie, in {% message NAMES %}, {% message WHO %} and {% message WHOIS %} messages). The standard and common prefixes are listed here, and MUST be advertised by the server in the {% isupport PREFIX %} `RPL_ISUPPORT` parameter on connection.

### Founder Prefix

This mode is used in a large number of networks. The prefix and mode letter typically used for it, respectively, are `"~"` and `"+q"`.

This prefix shows that the given user is the 'founder' of the current channel and has full moderation control over it -- ie, they are considered to 'own' that channel by the network. This prefix is typically only used on networks that have the concept of client accounts, and ownership of channels by those accounts.

### Protected Prefix

This mode is used in a large number of networks. The prefix and mode letter typically used for it, respectively, are `"&"` and `"+a"`.

Users with this mode cannot be kicked and cannot have this mode removed by other protected users. In some software, they may perform actions that operators can, but at a higher privilege level than operators. This prefix is typically only used on networks that have the concept of client accounts, and ownership of channels by those accounts.

### Operator Prefix

This mode is standard. The prefix and mode letter used for it, respectively, are `"@"` and `"+o"`.

Users with this mode may perform channel moderation tasks such as kicking users, applying channel modes, and set other users to operator (or lower) status.

### Halfop Prefix

This mode is widely used in networks today. The prefix and mode letter used for it, respectively, are `"%"` and `"+h"`.

Users with this mode may perform channel moderation tasks, but at a lower privilege level than operators. Which channel moderation tasks they can and cannot perform varies with server software and configuration.

### Voice Prefix

This mode is standard. The prefix and mode letter used for it, respectively, are `"+"` and `"+v"`.

Users with this mode may send messages to a channel that is [moderated](#moderated-channel-mode).


---


# Numerics

As mentioned in the [numeric replies](#numeric-replies) section, the first parameter of most numerics is the target of that numeric (the nickname of the client that is receiving it). Underneath the name and numeric of each reply, we list the parameters sent by this message.

Clients MUST NOT fail because the number of parameters on a given incoming numeric is larger than the number of parameters we list for that numeric here. Most IRC servers extends some of these numerics with their own special additions. For example, if a message is listed here as having 2 parameters, and your client receives it with 5 parameters, your client should not fail to parse or handle that message correctly because of the extra parameters.

Optional parameters are surrounded with the standard square brackets `([<optional>])` -- this means clients MUST NOT assume they will receive this parameter from all servers, and that servers SHOULD send this parameter unless otherwise specified in the numeric description. Parameters and parts of parameters surrounded with curly brackets `({ <repeating>})` may be repeated zero or more times.

Server authors that wish to extend one of the numerics listed here SHOULD make their extension into a [client capability](#capability-negotiation). If your extension would be useful to other client and server software, you should consider submitting it to the [IRCv3 Working Group](http://ircv3.net/) for standardisation.

Note that for numerics with "human-readable" informational strings for the last parameter which are not designed to be parsed, such as in `RPL_WELCOME`, servers commonly change this last-param text. Clients SHOULD NOT rely on these sort of parameters to have exactly the same human-readable string as described in this document. Clients that rely on the format of these human-readable final informational strings may fail.
We do try to note numerics where this is the case with a message like *"The text used in the last param of this message varies wildly"*.

{% numericheader RPL_WELCOME %}

      "<client> :Welcome to the <networkname> Network, <nick>[!<user>@<host>]"

The first message sent after client registration, this message introduces the client to the network. The text used in the last param of this message varies wildly.

Servers that implement spoofed hostmasks in any capacity SHOULD NOT include the extended (complete) hostmask in the last parameter of this reply, either for all clients or for those whose hostnames have been spoofed. This is because some clients try to extract the hostname from this final parameter of this message and resolve this hostname, in order to discover their 'local IP address'.

Clients MUST NOT try to extract the hostname from the final parameter of this message and then attempt to resolve this hostname. This method of operation WILL BREAK and will cause issues when the server returns a spoofed hostname.

{% numericheader RPL_YOURHOST %}

      "<client> :Your host is <servername>, running version <version>"

Part of the post-registration greeting, this numeric returns the name and software/version of the server the client is currently connected to. The text used in the last param of this message varies wildly.

{% numericheader RPL_CREATED %}

      "<client> :This server was created <datetime>"

Part of the post-registration greeting, this numeric returns a human-readable date/time that the server was started or created. The text used in the last param of this message varies wildly.

{% numericheader RPL_MYINFO %}

      "<client> <servername> <version> <available user modes>
      <available channel modes> [<channel modes with a parameter>]"

Part of the post-registration greeting. Clients SHOULD discover available features using `RPL_ISUPPORT` tokens rather than the mode letters listed in this reply.

{% numericheader RPL_ISUPPORT %}

      "<client> <1-13 tokens> :are supported by this server"

The ABNF representation for an `RPL_ISUPPORT` token is:

      token      =  *1"-" parameter / parameter *1( "=" value )
      parameter  =  1*20 letter
      value      =  * letpun
      letter     =  ALPHA / DIGIT
      punct      =  %d33-47 / %d58-64 / %d91-96 / %d123-126
      letpun     =  letter / punct

As the maximum number of message parameters to any reply is 15, the maximum number of `RPL_ISUPPORT` tokens that can be advertised is 13. To counter this, a server MAY issue multiple `RPL_ISUPPORT` numerics. A server MUST issue at least one `RPL_ISUPPORT` numeric after client registration has completed. It MUST be issued before further commands from the client are processed.

When clients send a {% message VERSION %} command to an external server (i.e. not the one they're currently connected to), they receive the appropriate information from that server. That external server's `ISUPPORT` tokens are sent to the client using the `105` (`RPL_REMOTEISUPPORT`) numeric instead of `005`, to ensure that clients don't process and start using these tokens sent by an external server. The format of the `105` message is exactly the same as `RPL_ISUPPORT` – the numeric itself is the only difference.

A token is of the form `PARAMETER`, `PARAMETER=VALUE` or `-PARAMETER`. Servers MUST send the parameter as upper-case text.

Tokens of the form `PARAMETER` or `PARAMETER=VALUE` are used to advertise features or information to clients. A parameter MAY have a default value and value MAY be empty when sent by servers. Unless otherwise stated, when a parameter contains a value, the value MUST be treated as being case sensitive. The value MAY contain multiple fields, if this is the case the fields SHOULD be delimited with a comma character `(",", 0x2C)`. The value MAY contain escape sequences: `\x20` for the space character `(" ", 0x20)`, `\x5C` for the backslash character `("\", 0x5C)` and `\x3D` for the equal character `("=", 0x3D)`.

If the value of a parameter changes, the server SHOULD re-advertise the parameter with the new value in an `RPL_ISUPPORT` reply. An example of this is a client becoming an [IRC operator](#oper-message) and their {% isupport CHANLIMIT %} changing.

Tokens of the form `-PARAMETER` are used to negate a previously specified parameter. If the client receives a token like this, the client MUST consider that parameter to be removed and revert to the behaviour that would occur if the parameter was not specified. The client MUST act as though the paramater is no longer advertised to it. These tokens are intended to allow servers to change their features without disconnecting clients. Tokens of this form MUST NOT contain a value field.

The server MAY negate parameters which have not been previously advertised; in this case, the client MUST ignore the token.

A single `RPL_ISUPPORT` reply MUST NOT contain the same parameter multiple times nor advertise and negate the same parameter. However, the server is free to advertise or negate the same parameter in separate replies.

See the [Feature Advertisement](#feature-advertisement) section for more details on this numeric. A list of parameters is available in the [`RPL_ISUPPORT` Parameters](#rplisupport-parameters) section.

{% numericheader RPL_BOUNCE %}

      "<client> <hostname> <port> :<info>"

Sent to the client to redirect it to another server. The `<info>` text varies between server software and reasons for the redirection.

Because this numeric does not specify whether to enable SSL and is not interpreted correctly by all clients, it is recommended that this not be used.

This numeric is also known as `RPL_REDIR` by some software.

{% numericheader RPL_STATSCOMMANDS %}

      "<client> <command> <count> [<byte count> <remote count>]"

Sent as a reply to the {% message STATS %} command, when a client requests statistics on command usage.

`<byte count>` and `<remote count>` are optional and MAY be included in responses.

{% numericheader RPL_ENDOFSTATS %}

      "<client> <stats letter> :End of /STATS report"

Indicates the end of a STATS response.

{% numericheader RPL_UMODEIS %}

      "<client> <user modes>"

Sent to a client to inform that client of their currently-set user modes.

{% numericheader RPL_STATSUPTIME %}

      "<client> :Server Up <days> days <hours>:<minutes>:<seconds>"

Sent as a reply to the {% message STATS %} command, when a client requests the server uptime. The text used in the last param of this message may vary.

{% numericheader RPL_LUSERCLIENT %}

      "<client> :There are <u> users and <i> invisible on <s> servers"

Sent as a reply to the {% message LUSERS %} command. `<u>`, `<i>`, and `<s>` are non-negative integers, and represent the number of total users, invisible users, and other servers connected to this server.

{% numericheader RPL_LUSEROP %}

      "<client> <ops> :operator(s) online"

Sent as a reply to the {% message LUSERS %} command. `<ops>` is a positive integer and represents the number of [IRC operators](#operators) connected to this server. The text used in the last param of this message may vary.

{% numericheader RPL_LUSERUNKNOWN %}

      "<client> <connections> :unknown connection(s)"

Sent as a reply to the {% message LUSERS %} command. `<connections>` is a positive integer and represents the number of connections to this server that are currently in an unknown state. The text used in the last param of this message may vary.

{% numericheader RPL_LUSERCHANNELS %}

      "<client> <channels> :channels formed"

Sent as a reply to the {% message LUSERS %} command. `<channels>` is a positive integer and represents the number of channels that currently exist on this server. The text used in the last param of this message may vary.

{% numericheader RPL_LUSERME %}

      "<client> :I have <c> clients and <s> servers"

Sent as a reply to the {% message LUSERS %} command. `<c>` and `<s>` are non-negative integers and represent the number of clients and other servers connected to this server, respectively.

{% numericheader RPL_ADMINME %}

      "<client> [<server>] :Administrative info"

Sent as a reply to an {% message ADMIN %} command, this numeric establishes the name of the server whose administrative info is being provided. The text used in the last param of this message may vary.

`<server>` is optional and MAY be included in responses, the server can also be gained from the `<source>` of this message.

{% numericheader RPL_ADMINLOC1 %}

      "<client> :<info>"

Sent as a reply to an {% message ADMIN %} command, `<info>` is a string intended to provide information about the location of the server (i.e. city, state and country). The text used in the last param of this message varies wildly.

{% numericheader RPL_ADMINLOC2 %}

      "<client> :<info>"

Sent as a reply to an {% message ADMIN %} command, `<info>` is a string intended to provide information about whoever runs the server (i.e. details of the institution hosting it). The text used in the last param of this message varies wildly.

{% numericheader RPL_ADMINEMAIL %}

      "<client> :<info>"

Sent as a reply to an {% message ADMIN %} command, `<info>` MUST contain the email address to contact the administrator(s) of the server. The text used in the last param of this message varies wildly.

{% numericheader RPL_TRYAGAIN %}

      "<client> <command> :Please wait a while and try again."

When a server drops a command without processing it, this numeric MUST be sent to inform the client. The text used in the last param of this message varies wildly, and commonly provides the client with more information about why the command could not be processed (i.e., due to rate-limiting).

{% numericheader RPL_LOCALUSERS %}

      "<client> [<u> <m>] :Current local users <u>, max <m>"

Sent as a reply to the {% message LUSERS %} command. `<u>` and `<m>` are non-negative integers and represent the number of clients currently and the maximum number of clients that have been connected directly to this server at one time, respectively.

The two optional parameters SHOULD be supplied to allow clients to better extract these numbers.

{% numericheader RPL_GLOBALUSERS %}

      "<client> [<u> <m>] :Current global users <u>, max <m>"

Sent as a reply to the {% message LUSERS %} command. `<u>` and `<m>` are non-negative integers. `<u>` represents the number of clients currently connected to this server, globally (directly and through other server links). `<m>` represents the maximum number of clients that have been connected to this server at one time, globally.

The two optional parameters SHOULD be supplied to allow clients to better extract these numbers.

{% numericheader RPL_WHOISCERTFP %}

      "<client> <nick> :has client certificate fingerprint <fingerprint>"

Sent as a reply to the {% message WHOIS %} command, this numeric shows the SSL/TLS certificate fingerprint used by the client with the nickname `<nick>`. Clients MUST only be sent this numeric if they are either using the `WHOIS` command on themselves or they are an [operator](#operators).

{% numericheader RPL_NONE %}

      Undefined format

`RPL_NONE` is a dummy numeric. It does not have a defined use nor format.

{% numericheader RPL_AWAY %}

      "<client> <nick> :<message>"

Indicates that the user with the nickname `<nick>` is currently away and sends the away message that they set.

{% numericheader RPL_USERHOST %}

      "<client> :[<reply>{ <reply>}]"

Sent as a reply to the {% message USERHOST %} command, this numeric lists nicknames and the information associated with them. The last parameter of this numeric (if there are any results) is a list of `<reply>` values, delimited by a SPACE character `(' ', 0x20)`.

The ABNF representation for `<reply>` is:

      reply   =  nickname [ isop ] "=" isaway hostname
      isop    =  "*"
      isaway  =  ( "+" / "-" )

`<isop>` is included if the user with the nickname of `<nickname>` has registered as an [operator](#operators). `<isaway>` represents whether that user has set an [away] message. `"+"` represents that the user is not away, and `"-"` represents that the user is away.

{% numericheader RPL_UNAWAY %}

      "<client> :You are no longer marked as being away"

Sent as a reply to the {% message AWAY %} command, this lets the client know that they are no longer set as being away. The text used in the last param of this message may vary.

{% numericheader RPL_NOWAWAY %}

      "<client> :You have been marked as being away"

Sent as a reply to the {% message AWAY %} command, this lets the client know that they are set as being away. The text used in the last param of this message may vary.

{% numericheader RPL_WHOISREGNICK %}

      "<client> <nick> :has identified for this nick"

Sent as a reply to the {% command WHOIS %} command, this numeric indicates that the client with the nickname `<nick>` was authenticated as the owner of this nick on the network.

See also [`RPL_WHOISACCOUNT`](#rplwhoisaccount-330), for information on the account name of the user.

{% numericheader RPL_WHOISUSER %}

      "<client> <nick> <username> <host> * :<realname>"

Sent as a reply to the {% message WHOIS %} command, this numeric shows details about the client with the nickname `<nick>`. `<username>` and `<realname>` represent the names set by the {% message USER %} command (though `<username>` may be set by the server in other ways). `<host>` represents the host used for the client in nickmasks (which may or may not be a real hostname or IP address). `<host>` CANNOT start with a colon `(':', 0x3A)` as this would get parsed as a trailing parameter – IPv6 addresses such as `"::1"` are prefixed with a zero `('0', 0x30)` to ensure this. The second-last parameter is a literal asterisk character `('*', 0x2A)` and does not mean anything.

{% numericheader RPL_WHOISSERVER %}

      "<client> <nick> <server> :<server info>"

Sent as a reply to the {% message WHOIS %} (or {% message WHOWAS %}) command, this numeric shows which server the client with the nickname `<nick>` is (or was) connected to. `<server>` is the name of the server (as used in message prefixes). `<server info>` is a string containing a description of that server.

{% numericheader RPL_WHOISOPERATOR %}

      "<client> <nick> :is an IRC operator"

Sent as a reply to the {% message WHOIS %} command, this numeric indicates that the client with the nickname `<nick>` is an [operator](#operators). This command MAY also indicate what type or level of operator the client is by changing the text in the last parameter of this numeric. The text used in the last param of this message varies wildly, and SHOULD be displayed as-is by IRC clients to their users.

{% numericheader RPL_WHOWASUSER %}

      "<client> <nick> <username> <host> * :<realname>"

Sent as a reply to the {% message WHOWAS %} command, this numeric shows details about one of the last clients that used the nickname `<nick>`. The purpose of each argument is the same as with the {% numeric RPL_WHOISUSER %} numeric.

{% numericheader RPL_ENDOFWHO %}

      "<client> <mask> :End of WHO list"

Sent as a reply to the {% command WHO %} command, this numeric indicates the end of a `WHO` response for the mask `<mask>`.

`<mask>` MUST be the same `<mask>` parameter sent by the client in its `WHO` message, but MAY be casefolded.

This numeric is sent after all other `WHO` response numerics have been sent to the client.

{% numericheader RPL_WHOISIDLE %}

      "<client> <nick> <secs> <signon> :seconds idle, signon time"

Sent as a reply to the {% message WHOIS %} command, this numeric indicates how long the client with the nickname `<nick>` has been idle. `<secs>` is the number of seconds since the client has been active. Servers generally denote specific commands (for instance, perhaps {% message JOIN %}, {% message PRIVMSG %}, {% message NOTICE %}, etc) as updating the 'idle time', and calculate this off when the idle time was last updated. `<signon>` is a unix timestamp representing when the user joined the network. The text used in the last param of this message may vary.

{% numericheader RPL_ENDOFWHOIS %}

      "<client> <nick> :End of /WHOIS list"

Sent as a reply to the {% command WHOIS %} command, this numeric indicates the end of a `WHOIS` response for the client with the nickname `<nick>`.

`<nick>` MUST be exactly the `<nick>` parameter sent by the client in its `WHOIS` message.
This means the case MUST be preserved, and if the client sent multiple nicks, this MUST be the comma-separated list of nicks, even if some of them were dropped.

This numeric is sent after all other `WHOIS` response numerics have been sent to the client.

{% numericheader RPL_WHOISCHANNELS %}

      "<client> <nick> :[prefix]<channel>{ [prefix]<channel>}

Sent as a reply to the {% message WHOIS %} command, this numeric lists the channels that the client with the nickname `<nick>` is joined to and their status in these channels. `<prefix>` is the highest [channel membership prefix](#channel-membership-prefixes) that the client has in that channel, if the client has one. `<channel>` is the name of a channel that the client is joined to. The last parameter of this numeric is a list of `[prefix]<channel>` pairs, delimited by a SPACE character `(' ', 0x20)`.

`RPL_WHOISCHANNELS` can be sent multiple times in the same whois reply, if the target is on too many channels to fit in a single message.

The channels in this response are affected by the [secret](#secret-channel-mode) channel mode and the [invisible](#invisible-user-mode) user mode, and may be affected by other modes depending on server software and configuration.

{% numericheader RPL_WHOISSPECIAL %}

      "<client> <nick> :blah blah blah"

Sent as a reply to the {% command WHOIS %} command, this numeric is used for extra human-readable information on the client with nickname `<nick>`. This should only be used for non-essential information that does not need to be machine-readable or understood by client software.

{% numericheader RPL_LISTSTART %}

      "<client> Channel :Users  Name"

Sent as a reply to the {% message LIST %} command, this numeric marks the start of a channel list. As noted in the command description, this numeric MAY be skipped by the server so clients MUST NOT depend on receiving it.

{% numericheader RPL_LIST %}

      "<client> <channel> <client count> :<topic>"

Sent as a reply to the {% message LIST %} command, this numeric sends information about a channel to the client. `<channel>` is the name of the channel. `<client count>` is an integer indicating how many clients are joined to that channel. `<topic>` is the channel's topic (as set by the {% message TOPIC %} command).

{% numericheader RPL_LISTEND %}

      "<client> :End of /LIST"

Sent as a reply to the {% message LIST %} command, this numeric indicates the end of a `LIST` response.

{% numericheader RPL_CHANNELMODEIS %}

      "<client> <channel> <modestring> <mode arguments>..."

Sent to a client to inform them of the currently-set modes of a channel. `<channel>` is the name of the channel. `<modestring>` and `<mode arguments>` are a mode string and the mode arguments (delimited as separate parameters) as defined in the {% message MODE %} message description.

{% numericheader RPL_CREATIONTIME %}

      "<client> <channel> <creationtime>"

Sent to a client to inform them of the creation time of a channel. `<channel>` is the name of the channel. `<creationtime>` is a unix timestamp representing when the channel was created on the network.

{% numericheader RPL_WHOISACCOUNT %}

      "<client> <nick> <account> :is logged in as"

Sent as a reply to the {% command WHOIS %} command, this numeric indicates that the client with the nickname `<nick>` was authenticated as the owner of `<account>`.

This does not necessarily mean the user owns their current nickname, which is covered by[`RPL_WHOISREGNICK`](#rplwhoisregnick-307).

{% numericheader RPL_NOTOPIC %}

      "<client> <channel> :No topic is set"

Sent to a client when joining a channel to inform them that the channel with the name `<channel>` does not have any topic set.

{% numericheader RPL_TOPIC %}

      "<client> <channel> :<topic>"

Sent to a client when joining the `<channel>` to inform them of the current [topic](#topic-message) of the channel.

{% numericheader RPL_TOPICWHOTIME %}

      "<client> <channel> <nick> <setat>"

Sent to a client to let them know who set the topic (`<nick>`) and when they set it (`<setat>` is a unix timestamp). Sent after {% numeric RPL_TOPIC %}.

{% numericheader RPL_INVITELIST %}

      "<client> <channel>"

Sent to a client as a reply to the {% command INVITE %} command when used with no parameter, to indicate a channel the client was invited to.

This numeric should not be confused with {% numeric RPL_INVEXLIST %}, which is used as a reply to {% message MODE %}.


<div class="warning">
    <p>Some rare implementations use 346 instead of 336 for this reply.</p>
</div>

{% numericheader RPL_ENDOFINVITELIST %}

      "<client> :End of /INVITE list"

Sent as a reply to the {% message INVITE %} command when used with no parameter, this numeric indicates the end of invitations a client received.

This numeric should not be confused with {% numeric RPL_ENDOFINVEXLIST %}, which is used as a reply to {% message MODE %}.

<div class="warning">
    <p>Some rare implementations use 347 instead of 337 for this reply.</p>
</div>

{% numericheader RPL_WHOISACTUALLY %}

      "<client> <nick> :is actually ..."
      "<client> <nick> <host|ip> :Is actually using host"
      "<client> <nick> <username>@<hostname> <ip> :Is actually using host"

Sent as a reply to the {% command WHOIS %} and {% command WHOWAS %} commands, this numeric shows details about the client with the nickname `<nick>`.

`<username>` represents the name set by the {% command USER %} command (though `<username>` may be set by the server in other ways).

`<host>` and `<ip>` represent the real host and IP address the client is connecting from. `<host>` CANNOT start with a colon `(':', 0x3A)` as this would get parsed as a trailing parameter – IPv6 addresses such as `"::1"` are prefixed with a zero `('0', 0x30)` to ensure this. The resulting IPv6 is equivalent, as this is a partial expansion of the `::` shorthand.

See also: {% numeric RPL_WHOISHOST %}, for similar semantics on other servers.

{% numericheader RPL_INVITING %}

      "<client> <nick> <channel>"

Sent as a reply to the {% message INVITE %} command to indicate that the attempt was successful and the client with the nickname `<nick>` has been invited to `<channel>`.

{% numericheader RPL_INVEXLIST %}

      "<client> <channel> <mask>"

Sent as a reply to the {% message MODE %} command, when clients are viewing the current entries on a channel's [invite-exception list](#invite-exception-channel-mode). `<mask>` is the given mask on the invite-exception list.

This numeric should not be confused with {% numeric RPL_INVITELIST %}, which is used as a reply to {% message INVITE %}.

This numeric is sometimes erroneously called `RPL_INVITELIST`, as this was the name used in RFC2812.

{% numericheader RPL_ENDOFINVEXLIST %}

      "<client> <channel> :End of Channel Invite Exception List"

Sent as a reply to the {% message MODE %} command, this numeric indicates the end of a channel's [invite-exception list](#invite-exception-channel-mode).

This numeric should not be confused with {% numeric RPL_ENDOFINVITELIST %}, which is used as a reply to {% message INVITE %}.

This numeric is sometimes erroneously called `RPL_ENDOFINVITELIST`, as this was the name used in RFC2812.

{% numericheader RPL_EXCEPTLIST %}

      "<client> <channel> <mask>"

Sent as a reply to the {% message MODE %} command, when clients are viewing the current entries on a channel's [exception list](#exception-channel-mode). `<mask>` is the given mask on the exception list.

{% numericheader RPL_ENDOFEXCEPTLIST %}

      "<client> <channel> :End of channel exception list"

Sent as a reply to the {% message MODE %} command, this numeric indicates the end of a channel's [exception list](#exception-channel-mode).

{% numericheader RPL_VERSION %}

      "<client> <version> <server> :<comments>"

Sent as a reply to the {% message VERSION %} command, this numeric indicates information about the desired server. `<version>` is the name and version of the software being used (including any revision information). `<server>` is the name of the server. `<comments>` may contain any further comments or details about the specific version of the server.

{% numericheader RPL_WHOREPLY %}

      "<client> <channel> <username> <host> <server> <nick> <flags> :<hopcount> <realname>"

Sent as a reply to the {% message WHO %} command, this numeric gives information about the client with the nickname `<nick>`. Refer to {% numeric RPL_WHOISUSER %} for the meaning of the fields `<username>`, `<host>` and `<realname>`. `<server>` is the name of the server the client is connected to. If the {% message WHO %} command was given a channel as the `<mask>` parameter, then the same channel MUST be returned in `<channel>`. Otherwise `<channel>` is an arbitrary channel the client is joined to or a literal asterisk character `('*', 0x2A)` if no channel is returned. `<hopcount>` is the number of intermediate servers between the client issuing the `WHO` command and the client `<nick>`, it might be unreliable so clients SHOULD ignore it.

`<flags>` contains the following characters, in this order:

* Away status: the letter H `('H', 0x48)` to indicate that the user is here, or the letter G `('G', 0x47)` to indicate that the user is gone.
* Optionally, a literal asterisk character `('*', 0x2A)` to indicate that the user is a server operator.
* Optionally, the highest [channel membership prefix](#channel-membership-prefixes) that the client has in `<channel>`, if the client has one.
* Optionally, one or more user mode characters and other arbitrary server-specific flags.

{% numericheader RPL_NAMREPLY %}

      "<client> <symbol> <channel> :[prefix]<nick>{ [prefix]<nick>}"

Sent as a reply to the {% message NAMES %} command, this numeric lists the clients that are joined to `<channel>` and their status in that channel.

`<symbol>` notes the status of the channel. It can be one of the following:

* `("=", 0x3D)` - Public channel.
* `("@", 0x40)` - Secret channel ([secret channel mode](#secret-channel-mode) `"+s"`).
* `("*", 0x2A)` - Private channel (was `"+p"`, no longer widely used today).

`<nick>` is the nickname of a client joined to that channel, and `<prefix>` is the highest [channel membership prefix](#channel-membership-prefixes) that client has in the channel, if they have one. The last parameter of this numeric is a list of `[prefix]<nick>` pairs, delimited by a SPACE character `(' ', 0x20)`.

{% numericheader RPL_LINKS %}

      "<client> * <server> :<hopcount> <server info>"

Sent as a reply to the {% message LINKS %} command, this numeric specifies one of the known servers on the network.

`<server info>` is a string containing a description of that server.

{% numericheader RPL_ENDOFLINKS %}

      "<client> * :End of /LINKS list"

Sent as a reply to the {% message LINKS %} command, this numeric specifies the end of a list of channel member names.

{% numericheader RPL_ENDOFNAMES %}

      "<client> <channel> :End of /NAMES list"

Sent as a reply to the {% message NAMES %} command, this numeric specifies the end of a list of channel member names.

{% numericheader RPL_BANLIST %}

      "<client> <channel> <mask> [<who> <set-ts>]"

Sent as a reply to the {% message MODE %} command, when clients are viewing the current entries on a channel's [ban list](#ban-channel-mode). `<mask>` is the given mask on the ban list.

`<who>` and `<set-ts>` are optional and MAY be included in responses. `<who>` is either the nickname or nickmask of the client that set the ban, or a server name, and `<set-ts>` is the UNIX timestamp of when the ban was set.

{% numericheader RPL_ENDOFBANLIST %}

      "<client> <channel> :End of channel ban list"

Sent as a reply to the {% message MODE %} command, this numeric indicates the end of a channel's [ban list](#ban-channel-mode).

{% numericheader RPL_ENDOFWHOWAS %}

      "<client> <nick> :End of WHOWAS"

Sent as a reply to the {% message WHOWAS %} command, this numeric indicates the end of a `WHOWAS` reponse for the nickname `<nick>`. This numeric is sent after all other `WHOWAS` response numerics have been sent to the client.

{% numericheader RPL_INFO %}

      "<client> :<string>"

Sent as a reply to the {% message INFO %} command, this numeric returns human-readable information describing the server: e.g. its version, list of authors and contributors, and any other miscellaneous information which may be considered to be relevant.

{% numericheader RPL_MOTD %}

      "<client> :<line of the motd>"

When sending the {% message Message of the Day %} to the client, servers reply with each line of the `MOTD` as this numeric. `MOTD` lines MAY be wrapped to 80 characters by the server.

{% numericheader RPL_ENDOFINFO %}

      "<client> :End of INFO list"

Indicates the end of an INFO response.

{% numericheader RPL_MOTDSTART %}

      "<client> :- <server> Message of the day - "

Indicates the start of the [Message of the Day](#motd-message) to the client. The text used in the last param of this message may vary, and SHOULD be displayed as-is by IRC clients to their users.

{% numericheader RPL_ENDOFMOTD %}

      "<client> :End of /MOTD command."

Indicates the end of the [Message of the Day](#motd-message) to the client. The text used in the last param of this message may vary.

{% numericheader RPL_WHOISHOST %}

      "<client> <nick> :is connecting from *@localhost 127.0.0.1"

Sent as a reply to the {% command WHOIS %} command, this numeric shows details about where the client with nickname `<nick>` is connecting from.

See also: {% numeric RPL_WHOISACTUALLY %}, for similar semantics on other servers.

{% numericheader RPL_WHOISMODES %}

      "<client> <nick> :is using modes +ailosw"

Sent as a reply to the {% command WHOIS %} command, this numeric shows the client what user modes the target users has.

{% numericheader RPL_YOUREOPER %}

      "<client> :You are now an IRC operator"

Sent to a client which has just successfully issued an {% message OPER %} command and gained [operator](#operators) status. The text used in the last param of this message varies wildly.

{% numericheader RPL_REHASHING %}

      "<client> <config file> :Rehashing"

Sent to an [operator](#operators) which has just successfully issued a {% message REHASH %} command. The text used in the last param of this message may vary.

{% numericheader RPL_TIME %}

      "<client> <server> [<timestamp> [<TS offset>]] :<human-readable time>"

Reply to the {% message TIME %} command. Typically only contains the human-readable time, but it may include a UNIX timestamp.

Clients SHOULD NOT parse the human-readable time.

`<TS offset>` is used by some servers using a TS-based server-to-server protocol (eg. TS6), and represents the offset between the server's system time, and the TS of the network. A positive value means the server is lagging behind the TS of the network.
Clients SHOULD ignore its value.

{% numericheader ERR_UNKNOWNERROR %}

      "<client> <command>{ <subcommand>} :<info>"

Indicates that the given command/subcommand could not be processed. `<subcommand>` may repeat for more specific subcommands.

For example, for an issue with a hypothetical command `PACK`, this may be returned:

      :example.com 400 dan!~d@n PACK :Could not process multiple invalid parameters

For an issue with a hypothetical command `PACK` with the subcommand `BOX`, this may be returned:

      :example.com 400 dan!~d@n PACK BOX :Could not find box to pack

This numeric indicates a very generalised error (which `<info>` should further explain). If there is another more specific numeric which represents the error occuring, that should be used instead.

{% numericheader ERR_NOSUCHNICK %}

      "<client> <nickname> :No such nick/channel"

Indicates that no client can be found for the supplied nickname. The text used in the last param of this message may vary.

{% numericheader ERR_NOSUCHSERVER %}

      "<client> <server name> :No such server"

Indicates that the given server name does not exist. The text used in the last param of this message may vary.

{% numericheader ERR_NOSUCHCHANNEL %}

      "<client> <channel> :No such channel"

Indicates that no channel can be found for the supplied channel name. The text used in the last param of this message may vary.

{% numericheader ERR_CANNOTSENDTOCHAN %}

      "<client> <channel> :Cannot send to channel"

Indicates that the `PRIVMSG` / `NOTICE` could not be delivered to `<channel>`. The text used in the last param of this message may vary.

This is generally sent in response to channel modes, such as a channel being [moderated](#moderated-channel-mode) and the client not having permission to speak on the channel, or not being joined to a channel with the [no external messages](#no-external-messages-mode) mode set.

{% numericheader ERR_TOOMANYCHANNELS %}

      "<client> <channel> :You have joined too many channels"

Indicates that the `JOIN` command failed because the client has joined their maximum number of channels. The text used in the last param of this message may vary.

{% numericheader ERR_WASNOSUCHNICK %}

      "<client> :There was no such nickname"

Returned as a reply to {% message WHOWAS %} to indicate there is no history information for that nickname.


{% numericheader ERR_NOORIGIN %}

      "<client> :No origin specified"

Indicates a PING or PONG message missing the originator parameter which is required by old IRC servers.
Nowadays, this may be used by some servers when the PING `<token>` is empty.

{% numericheader ERR_NORECIPIENT %}

      "<client> :No recipient given (<command>)"

Returned by the {% message PRIVMSG %} command to indicate the message wasn't delivered because there was no recipient given.

{% numericheader ERR_NOTEXTTOSEND %}

      "<client> :No text to send"

Returned by the {% message PRIVMSG %} command to indicate the message wasn't delivered because there was no text to send.

{% numericheader ERR_INPUTTOOLONG %}

      "<client> :Input line was too long"

Indicates a given line does not follow the specified size limits (512 bytes for the main section, 4094 or 8191 bytes for the tag section).

{% numericheader ERR_UNKNOWNCOMMAND %}

      "<client> <command> :Unknown command"

Sent to a registered client to indicate that the command they sent isn't known by the server. The text used in the last param of this message may vary.

{% numericheader ERR_NOMOTD %}

      "<client> :MOTD File is missing"

Indicates that the [Message of the Day](#motd-message) file does not exist or could not be found. The text used in the last param of this message may vary.

{% numericheader ERR_NONICKNAMEGIVEN %}

      "<client> :No nickname given"

Returned when a nickname parameter is expected for a command but isn't given.

{% numericheader ERR_ERRONEUSNICKNAME %}

      "<client> <nick> :Erroneus nickname"

Returned when a {% message NICK %} command cannot be successfully completed as the desired nickname contains characters that are disallowed by the server. See the [`NICK` command](#nick-command) for more information on characters which are allowed in various IRC servers. The text used in the last param of this message may vary.

{% numericheader ERR_NICKNAMEINUSE %}

      "<client> <nick> :Nickname is already in use"

Returned when a {% message NICK %} command cannot be successfully completed as the desired nickname is already in use on the network. The text used in the last param of this message may vary.

{% numericheader ERR_NICKCOLLISION %}

      "<client> <nick> :Nickname collision KILL from <user>@<host>"

Returned by a server to a client when it detects a nickname collision (registered of a NICK that already exists by another server). The text used in the last param of this message may vary.

{% numericheader ERR_USERNOTINCHANNEL %}

      "<client> <nick> <channel> :They aren't on that channel"

Returned when a client tries to perform a channel+nick affecting command, when the nick isn't joined to the channel (for example, `MODE #channel +o nick`).

{% numericheader ERR_NOTONCHANNEL %}

      "<client> <channel> :You're not on that channel"

Returned when a client tries to perform a channel-affecting command on a channel which the client isn't a part of.

{% numericheader ERR_USERONCHANNEL %}

      "<client> <nick> <channel> :is already on channel"

Returned when a client tries to invite `<nick>` to a channel they're already joined to.

{% numericheader ERR_NOTREGISTERED %}

      "<client> :You have not registered"

Returned when a client command cannot be parsed as they are not yet registered. Servers offer only a limited subset of commands until clients are properly registered to the server. The text used in the last param of this message may vary.

{% numericheader ERR_NEEDMOREPARAMS %}

      "<client> <command> :Not enough parameters"

Returned when a client command cannot be parsed because not enough parameters were supplied. The text used in the last param of this message may vary.

{% numericheader ERR_ALREADYREGISTERED %}

      "<client> :You may not reregister"

Returned when a client tries to change a detail that can only be set during registration (such as resending the {% message PASS %} or {% message USER %} after registration). The text used in the last param of this message varies.

{% numericheader ERR_PASSWDMISMATCH %}

      "<client> :Password incorrect"

Returned to indicate that the connection could not be registered as the [password](#pass-message) was either incorrect or not supplied. The text used in the last param of this message may vary.

{% numericheader ERR_YOUREBANNEDCREEP %}

      "<client> :You are banned from this server."

Returned to indicate that the server has been configured to explicitly deny connections from this client. The text used in the last param of this message varies wildly and typically also contains the reason for the ban and/or ban details, and SHOULD be displayed as-is by IRC clients to their users.

{% numericheader ERR_CHANNELISFULL %}

      "<client> <channel> :Cannot join channel (+l)"

Returned to indicate that a {% message JOIN %} command failed because the [client limit](#client-limit-channel-mode) mode has been set and the maximum number of users are already joined to the channel. The text used in the last param of this message may vary.

{% numericheader ERR_UNKNOWNMODE %}

      "<client> <modechar> :is unknown mode char to me"

Indicates that a mode character used by a client is not recognized by the server. The text used in the last param of this message may vary.

{% numericheader ERR_INVITEONLYCHAN %}

      "<client> <channel> :Cannot join channel (+i)"

Returned to indicate that a {% message JOIN %} command failed because the channel is set to [invite-only] mode and the client has not been [invited](#invite-message) to the channel or had an [invite exception](#invite-exception-channel-mode) set for them. The text used in the last param of this message may vary.

{% numericheader ERR_BANNEDFROMCHAN %}

      "<client> <channel> :Cannot join channel (+b)"

Returned to indicate that a {% message JOIN %} command failed because the client has been [banned](#ban-channel-mode) from the channel and has not had a [ban exception](#ban-exception-channel-mode) set for them. The text used in the last param of this message may vary.

{% numericheader ERR_BADCHANNELKEY %}

      "<client> <channel> :Cannot join channel (+k)"

Returned to indicate that a {% message JOIN %} command failed because the channel requires a [key](#key-channel-mode) and the key was either incorrect or not supplied. The text used in the last param of this message may vary.

Not to be confused with [`ERR_INVALIDKEY`](#errinvalidkey-525), which may be returned when setting a key.

{% numericheader ERR_BADCHANMASK %}

      "<channel> :Bad Channel Mask"

Indicates the supplied channel name is not a valid.

This is similar to, but stronger than, {% numeric ERR_NOSUCHCHANNEL %}, which indicates that the channel does not exist, but that it may be a valid name.

The text used in the last param of this message may vary.

{% numericheader ERR_NOPRIVILEGES %}

      "<client> :Permission Denied- You're not an IRC operator"

Indicates that the command failed because the user is not an [IRC operator](#operators). The text used in the last param of this message may vary.

{% numericheader ERR_CHANOPRIVSNEEDED %}

      "<client> <channel> :You're not channel operator"

Indicates that a command failed because the client does not have the appropriate [channel privileges](#channel-operators). This numeric can apply for different prefixes such as [halfop](#halfop-prefix), [operator](#operator-prefix), etc. The text used in the last param of this message may vary.

{% numericheader ERR_CANTKILLSERVER %}

      "<client> :You cant kill a server!"

Indicates that a {% message KILL %} command failed because the user tried to kill a server. The text used in the last param of this message may vary.

{% numericheader ERR_NOOPERHOST %}

      "<client> :No O-lines for your host"

Indicates that an {% message OPER %} command failed because the server has not been configured to allow connections from this client's host to become an operator. The text used in the last param of this message may vary.

{% numericheader ERR_UMODEUNKNOWNFLAG %}

      "<client> :Unknown MODE flag"

Indicates that a {% message MODE %} command affecting a user contained a `MODE` letter that was not recognized. The text used in the last param of this message may vary.

{% numericheader ERR_USERSDONTMATCH %}

      "<client> :Cant change mode for other users"

Indicates that a {% message MODE %} command affecting a user failed because they were trying to set or view modes for other users. The text used in the last param of this message varies, for instance when trying to view modes for another user, a server may send: `"Can't view modes for other users"`.

{% numericheader ERR_HELPNOTFOUND %}

      "<client> <subject> :No help available on this topic"

Indicates that a {% message HELP %} command requested help on a subject the server does not know about.

The `<subject>` MUST be the one requested by the client, but may be casefolded; unless it would be an invalid parameter, in which case it MUST be `*`.

{% numericheader ERR_INVALIDKEY %}

    "<client> <target chan> :Key is not well-formed"

Indicates the value of a key channel mode change (`+k`) was rejected.

Not to be confused with [`ERR_BADCHANNELKEY`](#errbadchannelkey-475), which is returned when someone tries to join a channel.

{% numericheader RPL_STARTTLS %}

      "<client> :STARTTLS successful, proceed with TLS handshake"

This numeric is used by the IRCv3 [`tls`](http://ircv3.net/specs/extensions/tls-3.1.html) extension and indicates that the client may begin a TLS handshake. For more information on this numeric, see the linked IRCv3 specification.

The text used in the last param of this message varies wildly.

{% numericheader RPL_WHOISSECURE %}

      "<client> <nick> :is using a secure connection"

Sent as a reply to the {% command WHOIS %} command, this numeric shows the client is connecting to the server in a way the server considers reasonably safe from eavesdropping (e.g. connecting from localhost, using TLS, using Tor).

{% numericheader ERR_STARTTLS %}

      "<client> :STARTTLS failed (Wrong moon phase)"

This numeric is used by the IRCv3 [`tls`](http://ircv3.net/specs/extensions/tls-3.1.html) extension and indicates that a server-side error occured and the `STARTTLS` command failed. For more information on this numeric, see the linked IRCv3 specification.

The text used in the last param of this message varies wildly.

{% numericheader ERR_INVALIDMODEPARAM %}

    "<client> <target chan/user> <mode char> <parameter> :<description>"

Indicates that there was a problem with a mode parameter. Replaces various implementation-specific mode-specific numerics.

{% numericheader RPL_HELPSTART %}

    "<client> <subject> :<first line of help section>"

Indicates the start of a reply to a {% command HELP %} command.
The text used in the last parameter of this message may vary, and SHOULD be displayed as-is by IRC clients to their users; possibly emphasized as the title of the help section.

The `<subject>` MUST be the one requested by the client, but may be casefolded; unless it would be an invalid parameter, in which case it MUST be `*`.

{% numericheader RPL_HELPTXT %}

    "<client> <subject> :<line of help text>"

Returns a line of {% command HELP %} text to the client. Lines MAY be wrapped to a certain line length by the server. Note that the final line MUST be a {% numeric RPL_ENDOFHELP %} numeric.

The `<subject>` MUST be the one requested by the client, but may be casefolded; unless it would be an invalid parameter, in which case it MUST be `*`.

{% numericheader RPL_ENDOFHELP %}

    "<client> <subject> :<last line of help text>"

Returns the final {% command HELP %} line to the client.

The `<subject>` MUST be the one requested by the client, but may be casefolded; unless it would be an invalid parameter, in which case it MUST be `*`.

{% numericheader ERR_NOPRIVS %}

      "<client> <priv> :Insufficient oper privileges."

Sent by a server to alert an IRC [operator](#operators) that they they do not have the specific operator privilege required by this server/network to perform the command or action they requested. The text used in the last param of this message may vary.

`<priv>` is a string that has meaning in the server software, and allows an operator the privileges to perform certain commands or actions. These strings are server-defined and may refer to one or multiple commands or actions that may be performed by IRC operators.

Examples of the sorts of privilege strings used by server software today include: `kline`, `dline`, `unkline`, `kill`, `kill:remote`, `die`, `remoteban`, `connect`, `connect:remote`, `rehash`.

{% numericheader RPL_LOGGEDIN %}

      "<client> <nick>!<user>@<host> <account> :You are now logged in as <username>"

This numeric indicates that the client was logged into the specified account (whether by [SASL authentication](#authenticate-message) or otherwise). For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

{% numericheader RPL_LOGGEDOUT %}

      "<client> <nick>!<user>@<host> :You are now logged out"

This numeric indicates that the client was logged out of their account. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

{% numericheader ERR_NICKLOCKED %}

      "<client> :You must use a nick assigned to you"

This numeric indicates that [SASL authentication](#authenticate-message) failed because the account is currently locked out, held, or otherwise administratively made unavailable. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

{% numericheader RPL_SASLSUCCESS %}

      "<client> :SASL authentication successful"

This numeric indicates that [SASL authentication](#authenticate-message) was completed successfully, and is normally sent along with {% numeric RPL_LOGGEDIN %}. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

{% numericheader ERR_SASLFAIL %}

      "<client> :SASL authentication failed"

This numeric indicates that [SASL authentication](#authenticate-message) failed because of invalid credentials or other errors not explicitly mentioned by other numerics. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

{% numericheader ERR_SASLTOOLONG %}

      "<client> :SASL message too long"

This numeric indicates that [SASL authentication](#authenticate-message) failed because the {% message AUTHENTICATE %} command sent by the client was too long (i.e. the parameter was longer than 400 bytes). For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

{% numericheader ERR_SASLABORTED %}

      "<client> :SASL authentication aborted"

This numeric indicates that [SASL authentication](#authenticate-message) failed because the client sent an {% message AUTHENTICATE %} command with the parameter `('*', 0x2A)`. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

{% numericheader ERR_SASLALREADY %}

      "<client> :You have already authenticated using SASL"

This numeric indicates that [SASL authentication](#authenticate-message) failed because the client has already authenticated using SASL and reauthentication is not available or has been administratively disabled. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) and [`sasl-3.2`](http://ircv3.net/specs/extensions/sasl-3.2.html) extensions.

The text used in the last param of this message varies wildly.

{% numericheader RPL_SASLMECHS %}

      "<client> <mechanisms> :are available SASL mechanisms"

This numeric specifies the mechanisms supported for [SASL authentication](#authenticate-message). `<mechanisms>` is a list of SASL mechanisms, delimited by a comma `(',', 0x2C)`. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

IRCv3.2 also specifies this information in the `sasl` client capability value. For more information on this, see the IRCv3 [`sasl-3.2`](http://ircv3.net/specs/extensions/sasl-3.2.html#mechanism-list-in-cap-ls) extension.

The text used in the last param of this message varies wildly.


---


{% h1 rplisupport-parameters %}`RPL_ISUPPORT` Parameters{% endh1 %}

Used to [advertise features](#feature-advertisement) to clients, the {% numeric RPL_ISUPPORT %} numeric lists parameters that let the client know which features are active and their value, if any.

The parameters listed here are standardised and/or widely-advertised by IRC servers today and do not include deprecated parameters. Servers SHOULD support at least the following parameters where appropriate, and may advertise any others. For a more extensive list of parameters advertised by this numeric, see the `irc-defs` [`RPL_ISUPPORT` list](https://defs.ircdocs.horse/defs/isupport.html).

Certain parameters described here may not be standardised nor widely-advertised. These parameters are noted with the descriptor `"Status: Proposed"`. However, we try to be conservative with the parameters we're proposing, both in terms of having a small number of them and them being fairly understandable extensions to the current widely-used parameters.

If a 'default value' is listed for a parameter, this is the assumed value of the parameter until and unless it is advertised by the server. This is primarily to interoperate with servers that don't advertise particular well-known and well-used parameters. If an 'empty value' is listed for a parameter, this is the assumed value of the parameter if it is advertised without a value.

{% isupportheader AWAYLEN %}

      Format: AWAYLEN=<number>

The `AWAYLEN` parameter indicates the maximum length for the `<reason>` of an {% message AWAY %} command. If an {% message AWAY %} `<reason>` has more characters than this parameter, it may be silently truncated by the server before being passed on to other clients. Clients MAY receive an {% message AWAY %} `<reason>` that has more characters than this parameter.

The value MUST be specified and MUST be a positive integer.

Examples:

      AWAYLEN=200

      AWAYLEN=307

{% isupportheader CASEMAPPING %}

      Format: CASEMAPPING=<casemap>

The `CASEMAPPING` parameter indicates what method the server uses to compare equality of case-insensitive strings (such as channel names and nicks).

The value MUST be specified and MUST be a string representing the method that the server uses.

The specified casemappings are as follows:

* **`ascii`**: Defines the characters `a` to `z` to be considered the lower-case equivalents of the characters `A` to `Z` only.
* **`rfc1459`**: Same as `'ascii'`, with the addition of the characters `'{'`, `'}'`, `'|'`, and `'^'` being considered the lower-case equivalents of the characters `'['`, `']'`, `'\'`, and `'~'` respectively.
* **`rfc1459-strict`**: Same casemapping as `'ascii'`, with the characters `'{'`, `'}'`, and `'|'` being the lower-case equivalents of `'['`, `']'`, and `'\'`, respectively. Note that the difference between this and `rfc1459` above is that in rfc1459-strict, `'^'` and `'~'` are not casefolded.
* **`rfc7613`**: Proposed casemapping which defines a method based on PRECIS, allowing additional Unicode characters to be correctly casemapped <sup><a href="https://github.com/ircv3/ircv3-specifications/pull/272">[link]</a></sup>.

The value MUST be specified and is a string. Servers MAY advertise alternate casemappings to those above, but clients MAY NOT be able to understand or perform them.

Servers SHOULD AVOID using the `rfc1459` casemapping unless explicitly required for compatibility reasons or for linking with servers using it. The equivalency of the extra characters is not necessary nor useful today, and issues such as incorrect implementations and a conflict between matching masks exists.

Examples:

      CASEMAPPING=ascii

      CASEMAPPING=rfc1459

{% isupportheader CHANLIMIT %}

      Format: CHANLIMIT=<prefixes>:[limit]{,<prefixes>:[limit]}

The `CHANLIMIT` parameter indicates the number of channels a client may join.

The value MUST be specified and is a list of `"<prefixes>:<limit>"` pairs, delimited by a comma `(',', 0x2C)`. `<prefixes>` is a list of channel prefix characters as defined in the {% isupport CHANTYPES %} parameter. `<limit>` is OPTIONAL and if specified is a positive integer indicating the maximum number of these types of channels a client may join. If there is no limit to the number of these channels a client may join, `<limit>` will not be specified.

Clients should not assume other clients are limited to what is specified in the `CHANLIMIT` parameter.

Examples:

      CHANLIMIT=#:25           ; indicates that clients may join 25 '#' channels

      CHANLIMIT=#&:50          ; indicates that clients may join 50 '#' and 50 '&' channels

      CHANLIMIT=#:70,&:        ; indicates that clients may join 70 '#' channels and any
                               number of '&' channels

{% isupportheader CHANMODES %}

      Format: CHANMODES=A,B,C,D[,X,Y...]

The `CHANMODES` parameter specifies the channel modes available and which types of arguments they do or do not take when using them with the {% message MODE %} command.

The value lists the channel mode letters of **Type A**, **B**, **C**, and **D**, respectively, delimited by a comma `(',', 0x2C)`. The channel mode types are defined in the the {% message MODE %} message description.

To allow for future extensions, a server MAY send additional types, delimited by a comma `(',', 0x2C)`. However, server authors SHOULD NOT extend this parameter without good reason, and SHOULD CONSIDER whether their mode would work as one of the existing types instead. The behaviour of any additional types is undefined.

Server MUST NOT list modes in this parameter that are also advertised in the {% isupport PREFIX %} parameter. However, modes within the {% isupport PREFIX %} parameter may be treated as type B modes.

Examples:

      CHANMODES=b,k,l,imnpst

      CHANMODES=beI,k,l,BCMNORScimnpstz

      CHANMODES=beI,kfL,lj,psmntirRcOAQKVCuzNSMTGZ

{% isupportheader CHANNELLEN %}

      Format: CHANNELLEN=<string>

The `CHANNELLEN` parameter specifies the maximum length of a channel name that a client may join. A client elsewhere on the network MAY join a channel with a larger name, but network administrators should take care to ensure this value stays consistent across the network.

The value MUST be specified and MUST be a positive integer.

Examples:

      CHANNELLEN=32

      CHANNELLEN=50

      CHANNELLEN=64

{% isupportheader CHANTYPES %}

       Format: CHANTYPES=[string]
      Default: CHANTYPES=#

The `CHANTYPES` parameter indicates the channel prefix characters that are available on the current server. Common channel types are listed in the [Channel Types](#channel-types) section.

The value is OPTIONAL; if it is not present, it indicates that no channel types are supported. If the parameter is not published by the server at all, clients SHOULD assume `CHANTYPES=#&`, corresponding to the RFC1459 behavior.

Examples:

      CHANTYPES=#

      CHANTYPES=&#

      CHANTYPES=#&

{% isupportheader ELIST %}

      Format: ELIST=<string>

The `ELIST` parameter indicates that the server supports search extensions to the {% message LIST %} command.

The value MUST be specified, and is a non-delimited list of letters, each of which denote an extension. The letters MUST be treated as being case-insensitive.

The following search extensions are defined:

* **C**: Searching based on channel creation time, via the `"C<val"` and `"C>val"` modifiers to search for a channel that was created either less than `val` minutes ago, or more than `val` minutes ago, respectively
* **M**: Searching based on a mask.
* **N**: Searching based on a non-matching !mask. i.e., the opposite of `M`.
* **T**: Searching based on topic set time, via the `"T<val"` and `"T>val"` modifiers to search for a topic time that was set less than `val` minutes ago, or more than `val` minutes ago, respectively.
* **U**: Searching based on user count within the channel, via the `"<val"` and `">val"` modifiers to search for a channel that has less or more than `val` users, respectively.

Examples:

      ELIST=MNUCT

      ELIST=MU

      ELIST=CMNTU

<div class="warning">
    <p>A widespread bug in existing implementations is to swap the semantics of <code>"C<val"</code> with <code>"C>val"</code>, and/or <code>"T<val"</code> with <code>"T>val"</code>, due to ambiguous legacy specifications. You should check the server you are using implements them as expected.</p>
</div>


{% isupportheader EXCEPTS %}

      Format: EXCEPTS=[character]
       Empty: e

The `EXCEPTS` parameter indicates that the server supports ban exceptions, as specified in the [ban exception](#ban-exception-channel-mode) channel mode section.

The value is OPTIONAL and when not specified indicates that the letter `"e"` is used as the channel mode for ban exceptions. If the value is specified, the character indicates the letter which is used for ban exceptions.

Examples:

      EXCEPTS

      EXCEPTS=e

{% isupportheader EXTBAN %}

      Format: EXTBAN=[<prefix>],<types>

The `EXTBAN` parameter indicates the types of "extended ban masks" that the server supports.

`<prefix>` denotes the character that indicates an extban to the server and `<types>` is a list of characters indicating the types of extended bans the server supports. If `<prefix>` does not exist then the server does not require a prefix for extbans, and they should be sent with no prefix.

Extbans may allow clients to issue bans based on account name, SSL certificate fingerprints and other attributes, based on what the server supports.

Extban masks SHOULD also be supported for the [ban exception](#ban-exception-channel-mode) and [invite exception](#invite-exception-channel-mode) modes.

<div class="warning">
    <p>Ensure that extban masks are actually typically supported in ban exception and invite exception modes.</p>

    <p>We should include a list of 'typical' extban characters and their associated meaning, but make sure we specify that these are not standardised and may change based on server software. See also the irc-defs <a href="https://defs.ircdocs.horse/defs/extbans.html"><code>EXTBAN</code> list</a>.</p>
</div>

Examples:

      EXTBAN=~,cqnr

      EXTBAN=~,qjncrRa

      EXTBAN=,ABCNOQRSTUcjmprsz

{% isupportheader HOSTLEN %}

      Format: HOSTLEN=<number>
      Status: Proposed

The `HOSTLEN` parameter indicates the maximum length that a hostname may be on the server (whether cloaked, spoofed, or a looked-up domain name). Networks SHOULD be consistent with this value across different servers.

If a looked-up domain name is longer than this length, the server SHOULD opt to use the IP address instead, so that the hostname is underneath this length.

The value MUST be specified and MUST be a positive integer.

Examples:

      HOSTLEN=63
      HOSTLEN=64

{% isupportheader INVEX %}

      Format: INVEX=[character]
       Empty: I

The `INVEX` parameter indicates that the server supports invite exceptions, as specified in the [invite exception](#invite-exception-channel-mode) channel mode section.

The value is OPTIONAL and when not specified indicates that the letter `"I"` is used as the channel mode for invite exceptions. If the value is specified, the character indicates the letter which is used for invite exceptions.

Examples:

      INVEX

      INVEX=I

{% isupportheader KICKLEN %}

      Format: KICKLEN=<length>

The `KICKLEN` parameter indicates the maximum length for the `<reason>` of a {% message KICK %} command. If a {% message KICK %} `<reason>` has more characters than this parameter, it may be silently truncated by the server before being passed on to other clients. Clients MAY receive a {% message KICK %} `<reason>` that has more characters than this parameter.

The value MUST be specified and MUST be a positive integer.

Examples:

      KICKLEN=255

      KICKLEN=307

{% isupportheader MAXLIST %}

      Format: MAXLIST=<modes>:<limit>{,<modes>:<limit>}

The `MAXLIST` parameter specifies how many "variable" modes of type A that have been defined in the {% isupport CHANMODES %} parameter that a client may set in total on a channel.

The value MUST be specified and is a list of `<modes>:<limit>` pairs, delimited by a comma `(',', 0x2C)`. `<modes>` is a list of type A modes defined in {% isupport CHANMODES %}. `<limit>` is a positive integer specifying the maximum number of entries that all of the modes in `<modes>`, combined, may set on a channel.

A client MUST NOT make any assumptions on how many mode entries may actually exist on any given channel. This limit only applies to the client setting new modes of the given types, and other clients may have different limits.

Examples:

      MAXLIST=beI:25           ; indicates that a client may set up to a total of 25 of a
                               combination of "b", "e", and "I" modes.

      MAXLIST=b:60,e:60,I:60   ; indicates that a client may set up to 60 "b" modes,
                               "e" modes, and 60 "I" modes.

      MAXLIST=beI:100,q:50     ; indicates that a client may set up to a total of 100 of
                               a combination of "b", "e", and "I" modes, and that they
                               may set up to 50 "q" modes.

{% isupportheader MAXTARGETS %}

      Format: MAXTARGETS=[number]

The `MAXTARGETS` parameter specifies the maximum number of targets a {% message PRIVMSG %} or {% message NOTICE %} command may have, and may apply to other commands based on server software.

The value is OPTIONAL and if specified, `[number]` is a positive integer representing the maximum number of targets those commands may have. If there is no limit, then `[number]` MAY not be specified.

The {% isupport TARGMAX %} parameter SHOULD be advertised instead of or in addition to this parameter. {% isupport TARGMAX %} is intended to replace `MAXTARGETS` as that parameter is more clear about which commands limits apply to.

Examples:

      MAXTARGETS=4

      MAXTARGETS=20

{% isupportheader MODES %}

      Format: MODES=[number]

The `MODES` parameter specifies how many 'variable' modes may be set on a channel by a single {% message MODE %} command from a client. A 'variable' mode is defined as being a type A, B or C mode as defined in the {% isupport CHANMODES %} parameter, or in the channel modes specified in the {% isupport PREFIX %} parameter.

A client SHOULD NOT issue more 'variable' modes than this in a single {% message MODE %} command. A server MAY however issue more 'variable' modes than this in a single {% message MODE %} message. The value is OPTIONAL and when not specified indicates that there is no limit to the number of 'variable' modes that may be set in a single client {% message MODE %} command.

If the value is specified, it MUST be a positive integer.

Examples:

      MODES=4

      MODES=12

      MODES=20

{% isupportheader NETWORK %}

      Format: NETWORK=<string>

The `NETWORK` parameter indicates the name of the IRC network that the client is connected to. This parameter is advertised for INFORMATIONAL PURPOSES ONLY. Clients SHOULD NOT use this value to make assumptions about supported features on the server as networks may change server software and configuration at any time.

Examples:

      NETWORK=EFNet

      NETWORK=Rizon

      NETWORK=Example\x20Network

{% isupportheader NICKLEN %}

       Format: NICKLEN=<number>

The `NICKLEN` parameter indicates the maximum length of a nickname that a client may set. Clients on the network MAY have longer nicks than this.

The value MUST be specified and MUST be a positive integer. `30` or `31` are typical values for this parameter advertised by servers today.

Examples:

      NICKLEN=9

      NICKLEN=30

      NICKLEN=31

{% isupportheader PREFIX %}

       Format: PREFIX=[(modes)prefixes]
      Default: PREFIX=(ov)@+

Within channels, clients can have different statuses, denoted by single-character prefixes. The `PREFIX` parameter specifies these prefixes and the channel mode characters that they are mapped to. There is a one-to-one mapping between prefixes and channel modes. The prefixes in this parameter are in descending order, from the prefix that gives the most privileges to the prefix that gives the least.

The typical prefixes advertised in this parameter are listed in the [Channel Membership Prefixes](#channel-membership-prefixes) section.

The value is OPTIONAL and when it is not specified indicates that no prefixes are supported.

Examples:

      PREFIX=(ov)@+

      PREFIX=(ohv)@%+

      PREFIX=(qaohv)~&@%+

{% isupportheader SAFELIST %}

      Format: SAFELIST

If `SAFELIST` parameter is advertised, the server ensures that a client may perform the {% message LIST %} command without being disconnected due to the large volume of data the {% message LIST %} command generates.

The `SAFELIST` parameter MUST NOT be specified with a value.

Examples:

      SAFELIST

{% isupportheader SILENCE %}

      Format: SILENCE[=<limit>]

The `SILENCE` parameter indicates the maximum number of entries a client can have in their silence list.

The value is OPTIONAL and if specified is a positive integer. If the value is not specified, the server does not support the {% message SILENCE %} command.

Most IRC clients also include client-side filter/ignore lists as an alternative to this command.

Examples:

      SILENCE

      SILENCE=15

      SILENCE=32

{% isupportheader STATUSMSG %}

      Format: STATUSMSG=<string>

The `STATUSMSG` parameter indicates that the server supports a method for clients to send a message via the {% message PRIVMSG %} / {% message NOTICE %} commands to those people on a channel with (one of) the specified [channel membership prefixes](#channel-membership-prefixes).

The value MUST be specified and MUST be a list of prefixes as specified in the {% isupport PREFIX %} parameter. Most servers today advertise every prefix in their {% isupport PREFIX %} parameter in `STATUSMSG`.

Examples:

      STATUSMSG=@+

      STATUSMSG=@%+

      STATUSMSG=~&@%+

{% isupportheader TARGMAX %}

      Format: TARGMAX=[<command>:[limit]{,<command>:[limit]}]

Certain client commands MAY contain multiple targets, delimited by a comma `(',', 0x2C)`. The `TARGMAX` parameter defines the maximum number of targets allowed for commands which accept multiple targets. If this parameter is not advertised or a value is not sent then a client SHOULD assume that no commands except the `JOIN` and `PART` commands accept multiple parameters.

The value is OPTIONAL and is a set of `<command>:<limit>` pairs, delimited by a comma `(',', 0x2C)`. `<command>` is the name of a client command. `<limit>` is the maximum number of targets which that command accepts. If `<limit>` is specified, it is a positive integer. If `<limit>` is not specified, then there is no maximum number of targets for that command. Clients MUST treat `<command>` as case-insensitive.

Examples:

      TARGMAX=PRIVMSG:3,WHOIS:1,JOIN:

      TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR:

      TARGMAX=ACCEPT:,KICK:1,LIST:1,NAMES:1,NOTICE:4,PRIVMSG:4,WHOIS:1

{% isupportheader TOPICLEN %}

      Format: TOPICLEN=<number>

The `TOPICLEN` parameter indicates the maximum length of a topic that a client may set on a channel. Channels on the network MAY have topics with longer lengths than this.

The value MUST be specified and MUST be a positive integer. `307` is the typical value for this parameter advertised by servers today.

Examples:

      TOPICLEN=307

      TOPICLEN=390

{% isupportheader USERLEN %}

      Format: USERLEN=<number>
      Status: Proposed

The `USERLEN` parameter indicates the maximum length that a username may be on the server. Networks SHOULD be consistent with this value across different servers. As noted in the {% message USER %} message, the tilde prefix (`"~"`), if it exists, contributes to the length of the username and would be included in this parameter.

The value MUST be specified and MUST be a positive integer.

Examples:

      USERLEN=12
      USERLEN=18


---


# Current Architectural Problems

There are a number of recognized problems with the IRC protocol. This section only addresses the problems related to the architecture of the protocol.


## Scalability

It is widely recognized that this protocol may not scale sufficiently well when used in a very large arena. The main problem comes from the requirement that all servers know about all other servers, clients, and channels, and that information regarding them be updated as soon as it changes.

Server-to-server protocols can attempt to alleviate this by, for example, only sending 'necessary' state information to leaf servers. These sort of optimisations are implementation-specific and are not covered in this document. However, server authors should take great care in their protocols to ensure race conditions and other network instability does not result from these attempts to improve the scalability of their protocol.


## Reliability

As the only network configuration used for IRC servers is that of a spanning tree, each link between two servers is an obvious and serious point of failure.

Software authors are and have been experimenting with alternative topologies such as mesh networks. However, there is not yet a production implementation or specification of any topology other than spanning-tree.


---


# Implementation Notes

The IRC protocol is reasonably complex. When writing software that interacts with it, there are certain choices that are implementation-defined, as well as certain areas that are commonly incorrectly implemented.

This section raises discussion, questions, and recommendations intended to help implementors. In particular, the advice/discussion here may be sloppy compared to the above, and the questions may be less well-defined or without strict answers, but regardless should help you when writing software that interacts with the IRC protocol.


## Character Encodings

Character encodings in IRC are hard. [UTF-8](http://tools.ietf.org/html/rfc3629) is recommended, the mess of [Latin-1/ISO-8859-1(5)/CP1252](https://en.wikipedia.org/wiki/Windows-1252) also seems common, but all sorts of other encodings are also used in practice. Particularly on networks that support other languages, and were created before UTF-8 became as widespread as it has.

When sending, we always recommend UTF-8. When decoding, we generally recommend trying UTF-8 and falling back to Latin-1 (what has been called the Hybrid encoding).

For clients, this is fine. Even if they incorrectly decode a private message, the user should see that the message has been decoded incorrectly and be able to resolve the issue (hopefully by telling the sending user to use UTF-8).

However, servers are in a trickier position (especially for PRIVMSG/NOTICE or any other command that takes arbitrary user input such as USER, TOPIC, etc). Servers should simply treat this input from the user as a character array they accept and then spit out again, no trouble.

Servers implemented in languages with first-class Unicode strings may wish to treat IRC lines and messages as Unicode text internally. For servers to treat messages in this way, they need to decode lines as they're received and later encode the lines before they're sent out.

This presents an issue. What if the line from the user is decoded incorrectly, modified (eg. by casefolding), and then sent out? (see also: [Mojibake](https://en.wikipedia.org/wiki/Mojibake)). What these servers may instead do is either:

1. follow the lead of the majority of existing servers and treat these parameters as byte arrays not to be parsed or decoded in any way.
2. attempt to decode all incoming lines as UTF-8 (possibly using Hybrid encoding like clients do) and if the line cannot be decoded it is ignored or returns an error. The [IRCv3 `UTF8ONLY` specification](https://ircv3.net/specs/extensions/utf8-only) allows them to signal this to clients.

The former ensures all messages are sent correctly, and the latter simplifies server implementations and allows clients to disable decoding heuristics.


## Message Parsing and Assembly

Message parsing/assembly is one area where implementations can differ wildly, and is a common vector for both security issues and general runtime problems.

Message Parsing is turning raw IRC messages into the various message parts (tags, prefix, command, parameters). Message Assembly is the opposite – taking the various message parts and creating an IRC line to be sent over the wire.

Implementors should ensure that their message parsing and assembly responds in expected ways, by running their software through test cases. I recommend these public-domain [irc-parser-tests](https://github.com/DanielOaks/irc-parser-tests), which are reasonably extensive.

### Trailing

Trailing is _a completely normal parameter_, except for the fact that it can contain spaces. When parsing messages, the 'normal params' and trailing should be appended and returned as a single list containing all the message params.

This is an example of an incorrect parser, that specifically separates normal params and trailing. When returning messages after parsing, **don't return a struct/object containing these variables:**

      Message
          .Tags
          .Source
          .Verb
          .Params (containing all but the trailing param)
          .Trailing (containing just the trailing param)

Trailing _is a normal parameter_. Separating the parameter types in this way _will cause many breakages and weird issues_, as logic code will depend on the final param being in either `.Params` or `.Trailing`, when the simple fact is that it can be in either. Make sure that your message parser instead outputs parsed messages more like this:

      Message
          .Tags
          .Source
          .Verb
          .Params (including all normal params, and the trailing param if it exists)

This will make sure that you don't run into silly trailing parameter errors.

### Direct String Comparisons on IRC Lines

Some software decides that the best way to process incoming lines is with something along the lines of this:

      Line = NewIRCLineFromSocket()
      If Line.StartsWith("PART") {
          Part(...etc...)
      } Else If Line.StartsWith("QUIT") {
          Quit(...etc...)
      }

This is bad. This will break. Here's why: _Any IRC message can choose to include or not include the `source`_.

If you directly compare the beginning of lines like this, then you will break when servers decide to start including sources on messages (for example, some newer IRCds decide to include the source on all messages that they output). This results in clients that don't correctly parse incoming messages and break as a result.

Instead, you should make sure that you send incoming lines through a message parser, and then do things based on what's output by that parser. For instance:

      Message = IRCMessageParser(Line)
      If Message.Verb == "PART" {
            Part(...etc...)
      } Else If Message.Verb == "QUIT" {
            Quit(...etc...)
      }

This will ensure that your software doesn't break when clients or servers send extra, or omit unnecessary, message elements.

Something to keep in mind is that the message verb is always case insensitive, so you should casemap it appropriately before doing comparisons similar to the above. In my own IRC libraries, I convert the verb to uppercase before returning the message.


## Casemapping

Casemapping, at least right now, is a topic where implementations differ greatly.

### Servers

* Does your server use `"rfc1459"` or `"rfc1459-strict"` casemapping? If so, can you use a casemapping with less ambiguity such as `"ascii"`?
* Does your server store state using nicks/channel names as keys? If so, is your server written in such a way that keys are casefolded automatically, or that ensures keys are casefolded before using them in this way?

### Clients

* Does your client store state using nicks/channel names as keys, and if so do you casefold those keys appropriately?
* Does your client discover the casemapping to use from the {% isupport CASEMAPPING %} `RPL_ISUPPORT` parameter on connection? If so, does your client use the appropriate casemapping based on it?


---

# Obsolete Commands and Numerics

## Obsolete Commands

* [`SUMMON`](https://datatracker.ietf.org/doc/html/rfc2812#section-4.5):
  was used to request people to connect to the network, by writing to their TTY.
  This only made sense back when users had shells on the same server as the IRC daemon.
* [`TRACE`](https://datatracker.ietf.org/doc/html/rfc2812#section-3.4.8):
  showed a path in the server graph, between the user and a target.
  Nowadays, many servers either don't implement it, or return redacted data.
* [`ISON`](https://datatracker.ietf.org/doc/html/rfc2812#section-4.9):
  replaced by the [IRCv3 Monitor](https://ircv3.net/specs/extensions/monitor.html) specification
* [`WATCH`](https://github.com/grawity/irc-docs/blob/master/client/draft-meglio-irc-watch-00.txt):
  was never formally specified, and is also replaced by [IRCv3 Monitor](https://ircv3.net/specs/extensions/monitor.html).

## Obsolete Numerics

These are numerics contained in [RFC1459](https://tools.ietf.org/html/rfc1459) and [RFC2812](https://tools.ietf.org/html/rfc2812) that are not contained in this document or that should be considered obsolete.

* **`RPL_BOUNCE (005)`**: `005` is now used for {% numeric RPL_ISUPPORT %}. {% numeric RPL_BOUNCE %} was moved to `010`
* **`RPL_SUMMONING (342)`**: Was a reply to the deprecated `SUMMON` command.
