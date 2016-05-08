# Numerics

As mentioned in the [numeric replies](#numeric-replies) section, the first parameter of most numerics is the target of that numeric (the nickname of the client that is receiving it). Underneath the name and numeric of each reply, we list the parameters sent by this message.

Clients MUST not fail because the number of parameters on a given incoming numeric is larger than the number of parameters we list for that numeric here. Most IRC servers extends some of these numerics with their own special additions. For example, if a message is listed here as having 2 parameters, and your client receives it with 5 parameters, your client should not fail to parse or handle that message correctly because of the extra parameters.

Optional parameters are surrounded with the standard square brackets `([<optional>])` -- this means clients MUST NOT assume they will receive this parameter from all servers, and that servers SHOULD send this parameter unless otherwise specified in the numeric description. Parameters and parts of parameters surrounded with curly brackets `({ <repeating>})` may be repeated zero or more times.

Server authors that wish to extend one of the numerics listed here SHOULD make their extension into a [client capability](#capability-negotiation). If your extension would be useful to other client and server software, you should consider submitting it to the [IRCv3 Working Group](http://ircv3.net/) for standardisation.

Note that for numerics with "human-readable" informational strings for the last parameter which are not designed to be parsed, such as in `RPL_WELCOME`, servers commonly change this last-param text. Clients SHOULD NOT rely on these sort of parameters to have exactly the same human-readable string as described in this document. Clients that rely on the format of these human-readable final informational strings may fail.
We do try to note numerics where this is the case with a message like *"The text used in the last param of this message varies wildly"*.

### `RPL_WELCOME (001)`

      "<client> :Welcome to the <networkname> Network, <nick>[!<user>@<host>]"

The first message sent after client registration, this message introduces the client to the network. The text used in the last param of this message varies wildly.

Servers that implement spoofed hostmasks in any capacity SHOULD NOT include the extended (complete) hostmask in the last parameter of this reply, either for all clients or for those whose hostnames have been spoofed. This is because some clients try to extract the hostname from this final parameter of this message and resolve this hostname, in order to discover their 'local IP address'.

Clients MUST NOT try to extract the hostname from the final parameter of this message and then attempt to resolve this hostname. This method of operation WILL BREAK and will cause issues when the server returns a spoofed hostname.

### `RPL_YOURHOST (002)`

      "<client> :Your host is <servername>, running version <version>"

Part of the post-registration greeting, this numeric returns the name and software/version of the server the client is currently connected to. The text used in the last param of this message varies wildly.

### `RPL_CREATED (003)`

      "<client> :This server was created <datetime>"

Part of the post-registration greeting, this numeric returns a human-readable date/time that the server was started or created. The text used in the last param of this message varies wildly.

### `RPL_MYINFO (004)`

      "<client> <servername> <version> <available user modes>
      <available channel modes> [<channel modes with a parameter>]"

Part of the post-registration greeting. Clients SHOULD discover available features using `RPL_ISUPPORT` tokens rather than the mode letters listed in this reply.

### `RPL_ISUPPORT (005)`

      "<client> <1-13 tokens> :are supported by this server"

The ABNF representation for an `RPL_ISUPPORT` token is:

      token      =  parameter *1( "=" value )
      parameter  =  1*20 letter
      value      =  * letpun
      letter     =  ALPHA / DIGIT
      punct      =  %d33-47 / %d58-64 / %d91-96 / %d123-126
      letpun     =  letter / punct

As the maximum number of parameters to any reply is 15, the maximum number of   `RPL_ISUPPORT` tokens that can be advertised is 13. To counter this, a server MAY issue multiple `RPL_ISUPPORT` numerics. A server MUST issue at least one `RPL_ISUPPORT` numeric after client registration has completed. It MUST be issued before further commands from the client are processed.

As with other local numerics, when `RPL_ISUPPORT` is delivered remotely, it MUST be converted into a `105` numeric before delivery to the client.

A token is of the form `PARAMETER` or `PARAMETER=VALUE`. A server MAY send an empty value field, and a parameter MAY have a default value. A server MUST send the parameter as upper-case text. Unless otherwise stated, when a parameter contains a value, the value MUST be treated as being case sensitive. The value MAY contain multiple fields, if this is the case the fields MUST be delimited with a comma character (`,`).

See the [Feature Advertisement](#feature-advertisement) section for more details on this numeric. A list of `RPL_ISUPPORT` parameters is available in the [`RPL_ISUPPORT` Parameters](#rplisupport-parameters) section.

### `RPL_BOUNCE (010)`

      "<client> <hostname> <port> :<info>"

Sent to the client to redirect it to another server. The `<info>` text varies between server software and reasons for the redirection.

Because this numeric does not specify whether to enable SSL and is not interpreted correctly by all clients, it is recommended that this not be used.

This numeric is also known as `RPL_REDIR` by some software.

### `RPL_UMODEIS (221)`

      "<client> <user modes>"

Sent to a client to inform that client of their currently-set user modes.

### `RPL_LUSERCLIENT (251)`

      "<client> :There are <u> users and <i> invisible on <s> servers"

Sent as a reply to the [`LUSER`](#luser-message) command. `<u>`, `<i>`, and `<s>` are non-negative integers, and represent the number of total users, invisible users, and other servers connected to this server.

### `RPL_LUSEROP (252)`

      "<client> <ops> :operator(s) online"

Sent as a reply to the [`LUSER`](#luser-message) command. `<ops>` is a positive integer and represents the number of [IRC operators](#operators) connected to this server. The text used in the last param of this message may vary.

### `RPL_LUSERUNKNOWN (253)`

      "<client> <connections> :unknown connection(s)"

Sent as a reply to the [`LUSER`](#luser-message) command. `<connections>` is a positive integer and represents the number of connections to this server that are currently in an unknown state. The text used in the last param of this message may vary.

### `RPL_LUSERCHANNELS (254)`

      "<client> <channels> :channels formed"

Sent as a reply to the [`LUSER`](#luser-message) command. `<channels>` is a positive integer and represents the number of channels that currently exist on this server. The text used in the last param of this message may vary.

### `RPL_LUSERME (255)`

      "<client> :I have <c> clients and <s> servers"

Sent as a reply to the [`LUSER`](#luser-message) command. `<c>` and `<s>` are non-negative integers and represent the number of clients and other servers connected to this server, respectively.

### `RPL_ADMINME (256)`

      "<client> <server> :Administrative info"

Sent as a reply to an [`ADMIN`](#admin-message) command, this numeric establishes the name of the server whose administrative info is being provided. The text used in the last param of this message may vary.

### `RPL_ADMINLOC1 (257)`

      "<client> :<info>"

Sent as a reply to an [`ADMIN`](#admin-message) command, `<info>` is a string intended to provide information about the location of the server (i.e. city, state and country). The text used in the last param of this message varies wildly.

### `RPL_ADMINLOC2 (258)`

      "<client> :<info>"

Sent as a reply to an [`ADMIN`](#admin-message) command, `<info>` is a string intended to provide information about whoever runs the server (i.e. details of the institution hosting it). The text used in the last param of this message varies wildly.

### `RPL_ADMINEMAIL (259)`

      "<client> :<info>"

Sent as a reply to an [`ADMIN`](#admin-message) command, `<info>` MUST contain the email address to contact the administrator(s) of the server. The text used in the last param of this message varies wildly.

### `RPL_TRYAGAIN (263)`

      "<client> <command> :Please wait a while and try again."

When a server drops a command without processing it, this numeric MUST be sent to inform the client. The text used in the last param of this message varies wildly, and commonly provides the client with more information about why the command could not be processed (i.e., due to rate-limiting).

### `RPL_LOCALUSERS (265)`

      "<client> [<u> <m>] :Current local users <u>, max <m>"

Sent as a reply to the [`LUSER`](#luser-message) command. `<u>` and `<m>` are non-negative integers and represent the number of clients currently and the maximum number of clients that have been connected directly to this server at one time, respectively.

The two optional parameters SHOULD be supplied to allow clients to better extract these numbers.

### `RPL_GLOBALUSERS (266)`

      "<client> [<u> <m>] :Current global users <u>, max <m>"

Sent as a reply to the [`LUSER`](#luser-message) command. `<u>` and `<m>` are non-negative integers. `<u>` represents the number of clients currently connected to this server, globally (directly and through other server links). `<m>` represents the maximum number of clients that have been connected to this server at one time, globally.

The two optional parameters SHOULD be supplied to allow clients to better extract these numbers.

### `RPL_WHOISCERTFP (276)`

      "<client> <nick> :has client certificate fingerprint <fingerprint>"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric shows the SSL/TLS certificate fingerprint used by the client with the nickname `<nick>`. Clients MUST only be sent this numeric if they are either using the `WHOIS` command on themselves or they are an [operator](#operators).

### `RPL_NONE (300)`

      Undefined format

`RPL_NONE` is a dummy numeric. It does not have a defined use nor format.

### `RPL_AWAY (301)`

      "<client> <nick> :<message>"

Indicates that the user with the nickname `<nick>` is currently away and sends the away message that they set.

### `RPL_USERHOST (302)`

      "<client> :[<reply>{ <reply>}]"

Sent as a reply to the [`USERHOST`](#userhost-message) command, this numeric lists nicknames and the information associated with them. The last parameter of this numeric (if there are any results) is a list of `<reply>` values, delimited by a SPACE character `(' ', 0x20)`.

The ABNF representation for `<reply>` is:

      reply   =  nickname [ isop ] "=" isaway hostname
      isop    =  "*"
      isaway  =  ( "+" / "-" )

`<isop>` is included if the user with the nickname of `<nickname>` has registered as an [operator](#operators). `<isaway>` represents whether that user has set an [away] message. `"+"` represents that the user is not away, and `"-"` represents that the user is away.

### `RPL_ISON (303)`

      "<client> :[<nickname>{ <nickname>}]"

Sent as a reply to the [`ISON`](#ison-message) command, this numeric lists the nicks that are present on the network. The last parameter of this numeric (if there are any results) is a list of nicknames, delimited by a SPACE character `(' ', 0x20)`.

### `RPL_UNAWAY (305)`

      "<client> :You are no longer marked as being away"

Sent as a reply to the [`AWAY`](#away-message) command, this lets the client know that they are no longer set as being away. The text used in the last param of this message may vary.

### `RPL_NOWAWAY (306)`

      "<client> :You have been marked as being away"

Sent as a reply to the [`AWAY`](#away-message) command, this lets the client know that they are set as being away. The text used in the last param of this message may vary.

### `RPL_WHOISUSER (311)`

      "<client> <nick> <username> <host> * :<realname>"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric shows details about the client with the nickname `<nick>`. `<username>` and `<realname>` represent the names set by the [`USER`](#user-message) command (though `<username>` may be set by the server in other ways). `<host>` represents the host used for the client in nickmasks (which may or may not be a real hostname or IP address). The second-last parameter is a literal asterix character `('*', 0x2A)` and does not mean anything.

### `RPL_WHOISSERVER (312)`

      "<client> <nick> <server> :<server info>"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric shows which server the client with the nickname `<nick>` is connected to. `<server>` is the name of the server (as used in message prefixes). `<server info>` is a string containing a description of that server.

### `RPL_WHOISOPERATOR (313)`

      "<client> <nick> :is an IRC operator"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric indicates that the client with the nickname `<nick>` is an [operator](#operators). This command MAY also indicate what type or level of operator the client is by changing the text in the last parameter of this numeric. The text used in the last param of this message varies wildly, and SHOULD be displayed as-is by IRC clients to their users.

### `RPL_WHOWASUSER (314)`

      "<client> <nick> <username> <host> * :<realname>"

Sent as a reply to the [`WHOWAS`](#whowas-message) command, this numeric shows details about the last client that used the nickname `<nick>`. The purpose of each argument is the same as with the [`RPL_WHOISUSER`](#rplwhoisuser-311) numeric.

### `RPL_WHOISIDLE (317)`

      "<client> <nick> <secs> [<signon>] :seconds idle, signon time

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric indicates how long the client with the nickname `<nick>` has been idle. `<secs>` is the number of seconds since the client has been active. Servers generally denote specific commands (for instance, perhaps [`JOIN`](#join-message), [`PRIVMSG`](#privmsg-message), [`NOTICE`](#notice-message), etc) as updating the 'idle time', and calculate this off when the idle time was last updated. `<signon>` is a unix timestamp representing when the user joined the network. The text used in the last param of this message may vary.

### `RPL_ENDOFWHOIS (318)`

      "<client> <nick> :End of /WHOIS list"

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric indicates the end of a `WHOIS` response for the client with the nickname `<nick>`. This numeric is sent after all other `WHOIS` response numerics have been sent to the client.

### `RPL_WHOISCHANNELS (319)`

      "<client> <nick> :[prefix]<channel>{ [prefix]<channel>}

Sent as a reply to the [`WHOIS`](#whois-message) command, this numeric lists the channels that the client with the nickname `<nick>` is joined to and their status in these channels. `<prefix>` is the highest [channel membership prefix](#channel-membership-prefixes) that the client has in that channel, if the client has one. `<channel>` is the name of a channel that the client is joined to. The last parameter of this numeric is a list of `[prefix]<channel>` pairs, delimited by a SPACE character `(' ', 0x20)`.

The channels in this response are affected by the [secret](#secret-channel-mode) channel mode and the [invisible](#invisible-user-mode) user mode, and may be affected by other modes depending on server software and configuration.

### `RPL_LISTSTART (321)`

      "<client> Channel :Users  Name"

Sent as a reply to the [`LIST`](#list-message) command, this numeric marks the start of a channel list. As noted in the command description, this numeric MAY be skipped by the server so clients MUST NOT depend on receiving it.

### `RPL_LIST (322)`

      "<client> <channel> <visible clients> :<topic>"

Sent as a reply to the [`LIST`](#list-message) command, this numeric sends information about a channel to the client. `<channel>` is the name of the channel. `<visible clients>` is an integer indicating how many clients are joined to that channel. `<topic>` is the channel's topic (as set by the [`TOPIC`](#topic-message) command).

### `RPL_LISTEND (323)`

      "<client> :End of /LIST"

Sent as a reply to the [`LIST`](#list-message) command, this numeric indicates the end of a `LIST` response.

### `RPL_CHANNELMODEIS (324)`

      "<client> <channel> <modestring> <mode arguments>..."

Sent to a client to inform them of the currently-set modes of a channel. `<channel>` is the name of the channel. `<modestring>` and `<mode arguments>` are a mode string and the mode arguments (delimited as separate parameters) as defined in the [`MODE`](#mode-message) message description.

### `RPL_NOTOPIC (331)`

      "<client> <channel> :No topic is set"

Sent as a reply to the [`TOPIC`](#topic-message) command, this numeric indicates that the channel with the name `<channel>` does not have any topic set.

### `RPL_TOPIC (332)`

      "<client> <channel> :<topic>"

Sent to a client to inform them of the current [topic](#topic-message) of the channel.

### `RPL_INVITING (341)`

      "<client> <channel> <nick>"

Sent as a reply to the [`INVITE`](#invite-message) command to indicate that the attempt was successful and the client with the nickname `<nick>` has been invited to `<channel>`.

### `RPL_VERSION (351)`

      "<client> <version> <server> :<comments>"

Sent as a reply to the [`VERSION`](#version-message) command, this numeric indicates information about the desired server. `<version>` is the name and version of the software being used (including any revision information). `<server>` is the name of the server. `<comments>` may contain any further comments or details about the specific version of the server.

### `RPL_NAMREPLY (353)`

      "<client> <channel> :[prefix]<nick>{ [prefix]<nick>}

Sent as a reply to the [`NAMES`](#names-message) command, this numeric lists the clients that are joined to `<channel>` and their status in that channel. `<nick>` is the nickname of a client joined to that channel, and `<prefix>` is the highest [channel membership prefix](#channel-membership-prefixes) that client has in that channel, if they have one. The last parameter of this numeric is a list of `[prefix]<nick>` pairs, delimited by a SPACE character `(' ', 0x20)`.

### `RPL_ENDOFNAMES (366)`

      "<client> <channel> :End of /NAMES list"

Sent as a reply to the [`NAMES`](#names-message) command, this numeric specifies the end of a list of channel member names.

### `RPL_ENDOFWHOWAS (369)`

      "<client> <nick> :End of WHOWAS"

Sent as a reply to the [`WHOWAS`](#whowas-message) command, this numeric indicates the end of a `WHOWAS` reponse for the nickname `<nick>`. This numeric is sent after all other `WHOWAS` response numerics have been sent to the client.

### `RPL_MOTDSTART (375)`

      "<client> :- <server> Message of the day - "

Indicates the start of the [Message of the Day](#motd-message) to the client. The text used in the last param of this message may vary, and SHOULD be displayed as-is by IRC clients to their users.

### `RPL_MOTD (372)`

      "<client> :<line of the motd>"

When sending the [`Message of the Day`](#motd-message) to the client, servers reply with each line of the `MOTD` as this numeric. `MOTD` lines MAY be wrapped to 80 characters by the server.

### `RPL_ENDOFMOTD (376)`

      "<client> :End of /MOTD command."

Indicates the end of the [Message of the Day](#motd-message) to the client. The text used in the last param of this message may vary.

### `RPL_YOUREOPER (381)`

      "<client> :You are now an IRC operator"

Sent to a client which has just successfully issued an [`OPER`](#oper-message) command and gained [operator](#operators) status. The text used in the last param of this message varies wildly.

### `RPL_REHASHING (382)`

      "<client> <config file> :Rehashing"

Sent to an [operator](#operators) which has just successfully issued a [`REHASH`](#rehash-message) command. The text used in the last param of this message may vary.

### `ERR_NOSUCHNICK (401)`

      "<client> <nickname> :No such nick/channel"

Indicates that no client can be found for the supplied nickname. The text used in the last param of this message may vary.

### `ERR_NOSUCHSERVER (402)`

      "<client> <server name> :No such server"

Indicates that the given server name does not exist. The text used in the last param of this message may vary.

### `ERR_NOSUCHCHANNEL (403)`

      "<client> <channel> :No such channel"

Indicates that no channel can be found for the supplied channel name. The text used in the last param of this message may vary.

### `ERR_CANNOTSENDTOCHAN (404)`

      "<client> <channel> :Cannot send to channel"

Indicates that the `PRIVMSG` / `NOTICE` could not be delivered to `<channel>`. The text used in the last param of this message may vary.

This is generally sent in response to channel modes, such as a channel being [moderated](#moderated-channel-mode) and the client not having permission to speak on the channel, or not being joined to a channel with the [no external messages](#no-external-messages-mode) mode set.

### `ERR_TOOMANYCHANNELS (405)`

      "<client> <channel> :You have joined too many channels"

Indicates that the `JOIN` command failed because the client has joined their maximum number of channels. The text used in the last param of this message may vary.

### `ERR_UNKNOWNCOMMAND (421)`

      "<client> <command> :Unknown command"

Sent to a registered client to indicate that the command they sent isn't known by the server. The text used in the last param of this message may vary.

### `ERR_NOMOTD (422)`

      "<client> :MOTD File is missing"

Indicates that the [Message of the Day](#motd-message) file does not exist or could not be found. The text used in the last param of this message may vary.

### `ERR_ERRONEUSNICKNAME (432)`

      "<client> <nick> :Erroneus nickname"

Returned when a [`NICK`](#nick-message) command cannot be successfully completed as the desired nickname contains characters that are disallowed by the server. See the [wire format](#wire-format-in-abnf) section for more information on characters which are allowed in various IRC servers. The text used in the last param of this message may vary.

### `ERR_NICKNAMEINUSE (433)`

      "<client> <nick> :Nickname is already in use"

Returned when a [`NICK`](#nick-message) command cannot be successfully completed as the desired nickname is already in use on the network. The text used in the last param of this message may vary.

### `ERR_NOTREGISTERED (451)`

      "<client> :You have not registered"

Returned when a client command cannot be parsed as they are not yet registered. Servers offer only a limited subset of commands until clients are properly registered to the server. The text used in the last param of this message may vary.

### `ERR_NEEDMOREPARAMS (461)`

      "<client> <command> :Not enough parameters"

Returned when a client command cannot be parsed because not enough parameters were supplied. The text used in the last param of this message may vary.

### `ERR_ALREADYREGISTERED (462)`

      "<client> :You may not reregister"

Returned when a client tries to change a detail that can only be set during registration (such as resending the [`PASS`](#pass-command) or [`USER`](#user-command) after registration). The text used in the last param of this message varies.

### `ERR_PASSWDMISMATCH (464)`

      "<client> :Password incorrect"

Returned to indicate that the connection could not be registered as the [password](#pass-message) was either incorrect or not supplied. The text used in the last param of this message may vary.

### `ERR_YOUREBANNEDCREEP (465)`

      "<client> :You are banned from this server."

Returned to indicate that the server has been configured to explicitly deny connections from this client. The text used in the last param of this message varies wildly and typically also contains the reason for the ban and/or ban details, and SHOULD be displayed as-is by IRC clients to their users.

### `ERR_CHANNELISFULL (471)`

      "<client> <channel> :Cannot join channel (+l)"

Returned to indicate that a [`JOIN`](#join-message) command failed because the [client limit](#client-limit-channel-mode) mode has been set and the maximum number of users are already joined to the channel. The text used in the last param of this message may vary.

### `ERR_UNKNOWNMODE (472)`

      "<client> <modechar> :is unknown mode char to me"

Indicates that a mode character used by a client is not recognized by the server. The text used in the last param of this message may vary.

### `ERR_INVITEONLYCHAN (473)`

      "<client> <channel> :Cannot join channel (+i)"

Returned to indicate that a [`JOIN`](#join-message) command failed because the channel is set to [invite-only] mode and the client has not been [invited](#invite-message) to the channel or had an [invite exemption](#invite-exemption-channel-mode) set for them. The text used in the last param of this message may vary.

### `ERR_BANNEDFROMCHAN (474)`

      "<client> <channel> :Cannot join channel (+b)"

Returned to indicate that a [`JOIN`](#join-message) command failed because the client has been [banned](#ban-channel-mode) from the channel and has not had a [ban exemption](#ban-exemption-channel-mode) set for them. The text used in the last param of this message may vary.

### `ERR_BADCHANNELKEY (475)`

      "<client> <channel> :Cannot join channel (+k)"

Returned to indicate that a [`JOIN`](#join-message) command failed because the channel requires a [key](#key-channel-mode) and the key was either incorrect or not supplied. The text used in the last param of this message may vary.

### `ERR_NOPRIVILEGES (481)`

      "<client> :Permission Denied- You're not an IRC operator"

Indicates that the command failed because the user is not an [IRC operator](#operators). The text used in the last param of this message may vary.

### `ERR_CHANOPRIVSNEEDED (482)`

      "<client> <channel> :You're not channel operator"

Indicates that a command failed because the client does not have the appropriate [channel priveleges](#channel-operators). This numeric can apply for different prefixes such as [halfop](#halfop-prefix), [operator](#operator-prefix), etc. The text used in the last param of this message may vary.

### `ERR_CANTKILLSERVER (483)`

      "<client> :You cant kill a server!"

Indicates that a [`KILL`](#kill-message) command failed because the user tried to kill a server. The text used in the last param of this message may vary.

### `ERR_NOOPERHOST (491)`

      "<client> :No O-lines for your host"

Indicates that an [`OPER`](#oper-message) command failed because the server has not been configured to allow connections from this client's host to become an operator. The text used in the last param of this message may vary.

### `ERR_UMODEUNKNOWNFLAG (501)`

      "<client> :Unknown MODE flag"

Indicates that a [`MODE`](#mode-message) command affecting a user contained a `MODE` letter that was not recognized. The text used in the last param of this message may vary.

### `ERR_USERSDONTMATCH (502)`

      "<client> :Cant change mode for other users"

Indicates that a [`MODE`](#mode-message) command affecting a user failed because they were trying to set or view modes for other users. The text used in the last param of this message varies, for instance when trying to view modes for another user, a server may send: `"Can't view modes for other users"`.

### `RPL_STARTTLS (670)`

      "<client> :STARTTLS successful, proceed with TLS handshake"

This numeric is used by the IRCv3 [`tls`](http://ircv3.net/specs/extensions/tls-3.1.html) extension and indicates that the client may begin a TLS handshake. For more information on this numeric, see the linked IRCv3 specification.

The text used in the last param of this message varies wildly.

### `ERR_STARTTLS (691)`

      "<client> :STARTTLS failed (Wrong moon phase)"

This numeric is used by the IRCv3 [`tls`](http://ircv3.net/specs/extensions/tls-3.1.html) extension and indicates that a server-side error occured and the `STARTTLS` command failed. For more information on this numeric, see the linked IRCv3 specification.

The text used in the last param of this message varies wildly.

### `ERR_NOPRIVS (723)`

      "<client> <priv> :Insufficient oper privileges."

Sent by a server to alert an IRC [operator](#operators) that they they do not have the specific operator privilege required by this server/network to perform the command or action they requested. The text used in the last param of this message may vary.

`<priv>` is a string that has meaning in the server software, and allows an operator the privileges to perform certain commands or actions. These strings are server-defined and may refer to one or multiple commands or actions that may be performed by IRC operators.

Examples of the sorts of privilege strings used by server software today include: `kline`, `dline`, `unkline`, `kill`, `kill:remote`, `die`, `remoteban`, `connect`, `connect:remote`, `rehash`.

### `RPL_LOGGEDIN (900)`

      "<client> <nick>!<user>@<host> <account> :You are now logged in as <username>"

This numeric indicates that the client was logged into the specified account (whether by [SASL authentication](#authenticate-message) or otherwise). For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

### `RPL_LOGGEDOUT (901)`

      "<client> <nick>!<user>@<host> :You are now logged out"

This numeric indicates that the client was logged out of their account. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

### `ERR_NICKLOCKED (902)`

      "<client> :You must use a nick assigned to you"

This numeric indicates that [SASL authentication](#authenticate-message) failed because the account is currently locked out, held, or otherwise administratively made unavailable. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

### `RPL_SASLSUCCESS (903)`

      "<client> :SASL authentication successful"

This numeric indicates that [SASL authentication](#authenticate-message) was completed successfully, and is normally sent along with [`RPL_LOGGEDIN`](#rplloggedin-900). For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

### `ERR_SASLFAIL (904)`

      "<client> :SASL authentication failed"

This numeric indicates that [SASL authentication](#authenticate-message) failed because of invalid credentials or other errors not explicitly mentioned by other numerics. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

### `ERR_SASLTOOLONG (905)`

      "<client> :SASL message too long"

This numeric indicates that [SASL authentication](#authenticate-message) failed because the [`AUTHENTICATE`](#authenticate-message) command sent by the client was too long (i.e. the parameter was longer than 400 bytes). For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

### `ERR_SASLABORTED (906)`

      "<client> :SASL authentication aborted"

This numeric indicates that [SASL authentication](#authenticate-message) failed because the client sent an [`AUTHENTICATE`](#authenticate-message) command with the parameter `('*', 0x2A)`. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

The text used in the last param of this message varies wildly.

### `ERR_SASLALREADY (907)`

      "<client> :You have already authenticated using SASL"

This numeric indicates that [SASL authentication](#authenticate-message) failed because the client has already authenticated using SASL and reauthentication is not available or has been administratively disabled. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) and [`sasl-3.2`](http://ircv3.net/specs/extensions/sasl-3.2.html) extensions.

The text used in the last param of this message varies wildly.

### `RPL_SASLMECHS (908)`

      "<client> <mechanisms> :are available SASL mechanisms"

This numeric specifies the mechanisms supported for [SASL authentication](#authenticate-message). `<mechanisms>` is a list of SASL mechanisms, delimited by a comma `(',', 0x2C)`. For more information on this numeric, see the IRCv3 [`sasl-3.1`](http://ircv3.net/specs/extensions/sasl-3.1.html) extension.

IRCv3.2 also specifies this information in the `sasl` client capability value. For more information on this, see the IRCv3 [`sasl-3.2`](http://ircv3.net/specs/extensions/sasl-3.2.html#mechanism-list-in-cap-ls) extension.

The text used in the last param of this message varies wildly.


---


# `RPL_ISUPPORT` Parameters

Used to [advertise features](#feature-advertisement) to clients, the [`RPL_ISUPPORT`](#rplisupport-005) numeric lists parameters that let the client know which features are active and their value, if any.

The parameters listed here are standardised and/or widely-advertised by IRC servers today and do not include deprecated parameters. Servers SHOULD support at least the following parameters where appropriate, and may advertise any others. For a more extensive list of parameters advertised by this numeric, see the `irc-defs` [`RPL_ISUPPORT` list](http://defs.ircdocs.horse/defs/isupport.html).

If a 'default value' is listed for a parameter, this is the assumed value of the parameter until and unless it is advertised by the server. This is primarily to interoperate with servers that don't advertise particular well-known and well-used parameters. If an 'empty value' is listed for a parameter, this is the assumed value of the parameter if it is advertised without a value.

### `AWAYLEN` Parameter

      Format: AWAYLEN=<number>

The `AWAYLEN` parameter indicates the maximum length for the `<reason>` of an [`AWAY`](#away-message) command. If an [`AWAY`](#away-message) `<reason>` has more characters than this parameter, it may be silently truncated by the server before being passed on to other clients. Clients MAY receive an [`AWAY`](#away-message) `<reason>` that has more characters than this parameter.

The value MUST be specified and MUST be a positive integer.

Examples:

      AWAYLEN=200

      AWAYLEN=307

### `CASEMAPPING` Parameter

      Format: CASEMAPPING=<casemap>

The `CASEMAPPING` parameter indicates what method the server uses to compare equality of case-insensitive strings (such as channel names and nicks).

The value MUST be specified and MUST be a string representing the method that the server uses.

The specified casemappings are as follows:

* **`ascii`**: Defines the characters `a` to be considered the lower-case equivalents of the characters `A` to `Z` only.
* **`rfc1459`**: Defines the same casemapping as `'ascii'`, with the addition of the characters `'{'`, `'}'`, and `'|'` being considered the lower-case equivalents of the characters `'['`, `']'`, and `'\'` respectively.
* **`rfc3454`**: Proposed casemapping which defines that strings are to be compared using the `nameprep` method described in [`RFC3454`](http://tools.ietf.org/html/rfc3454) and [`RFC3491`](https://tools.ietf.org/html/rfc3491) (NOTE: An alternate unicode-based casemapping is being created, and this entry will be replaced with that one when it comes about).

The value MUST be specified and is a string. Servers MAY advertise alternate casemappings to those above, but clients MAY NOT be able to understand or perform them.

Servers SHOULD NOT use the `rfc1459` casemapping unless explicitly required for compatibility reasons or for linking with servers using it. There are issues with it as described below, and the equivalency of the extra characters is not necessary with the global usage of the IRC protocol today.

<div class="warning">
    <p>Some implementations of **`rfc1459`** casemapping consider the `'~'` character to be treated as the lower-case equivalent of the `'^'` character, and some do not. Implementations that follow this rule consider the exact casemapping rules as specified above to belong to the **`rfc1459-strict`** casemapping instead, and for implementations following the rule in this bubble to be considered **`rfc1459`**.</p>

    <p>This is a fault with **`rfc1459`** casemapping, and is one reason it should not be used by new installations.</p>
</div>

Examples:

      CASEMAPPING=ascii

      CASEMAPPING=rfc1459

### `CHANLIMIT` Parameter

      Format: CHANLIMIT=<prefixes>:[limit]{,<prefixes>:[limit]}

The `CHANLIMIT` parameter indicates the number of channels a client may join.

The value MUST be specified and is a list of `"<prefixes>:<limit>"` pairs, delimited by a comma `(',',` `0x2C)`. `<prefixes>` is a list of channel prefix characters as defined in the [`CHANTYPES`](#chantypes-parameter) parameter. `<limit>` is OPTIONAL and if specified is a positive integer indicating the maximum number of these types of channels a client may join. If there is no limit to the number of these channels a client may join, `<limit>` will not be specified.

Clients should not assume other clients are limited to what is specified in the `CHANLIMIT` parameter.

Examples:

      CHANLIMIT=#:25           ; indicates that clients may join 25 '#' channels

      CHANLIMIT=#&:50          ; indicates that clients may join 50 '#' and 50 '&' channels

      CHANLIMIT=#:70,&:        ; indicates that clients may join 70 '#' channels and any
                               number of '&' channels

### `CHANMODES` Parameter

      Format: CHANMODES=A,B,C,D[,X,Y...]

The `CHANMODES` parameter specifies the channel modes available and which types of arguments they do or do not take when using them with the [`MODE`](#mode-message) command.

The value lists the channel mode letters of **Type A**, **B**, **C**, and **D**, respectively, delimited by a comma `(',',` `0x2C)`. The channel mode types are defined in the the [`MODE`](#mode-message) message description.

To allow for future extensions, a server MAY send additional types, delimited by a comma `(',',` `0x2C)`. However, server authors SHOULD NOT extend this parameter without good reason, and SHOULD CONSIDER whether their mode would work as one of the existing types instead. The behaviour of any additional types is undefined.

Server MUST NOT list modes in this parameter that are also advertised in the [`PREFIX`](#prefix-parameter) parameter. However, modes within the [`PREFIX`](#prefix-parameter) parameter may be treated as type B modes.

Examples:

      CHANMODES=b,k,l,imnpst

      CHANMODES=beI,k,l,BCMNORScimnpstz

      CHANMODES=beI,kfL,lj,psmntirRcOAQKVCuzNSMTGZ

### `CHANNELLEN` Parameter

      Format: CHANNELLEN=<string>

The `CHANNELLEN` parameter specifies the maximum length of a channel name that a client may join. A client elsewhere on the network MAY join a channel with a larger name, but network administrators should take care to ensure this value stays consistent across the network.

The value MUST be specified and MUST be a positive integer.

Examples:

      CHANNELLEN=32

      CHANNELLEN=50

      CHANNELLEN=64

### `CHANTYPES` Parameter

       Format: CHANTYPES=[string]
      Default: CHANTYPES=#

The `CHANTYPES` parameter indicates the channel prefix characters that are available on the current server. Common channel types are listed in the [Channel Types](#channel-types) section.

The value is OPTIONAL and if not specified indicates that no channel types are supported.

Examples:

      CHANTYPES=#

      CHANTYPES=&#

      CHANTYPES=#&

### `ELIST` Parameter

      Format: ELIST=<string>

The `ELIST` parameter indicates that the server supports search extensions to the [`LIST`](#list-message) command.

The value MUST be specified, and is a non-delimited list of letters, each of which denote an extension. The letters MUST be treated as being case-insensitive.

The following search extensions are defined:

* **C**: Searching based on channel creation time, via the `"C<val"` and `"C>val"` modifiers to search for a channel creation time that is higher or lower than `val`.
* **M**: Searching based on a mask.
* **N**: Searching based on a non-matching mask. i.e., the opposite of `M`.
* **T**: Searching based on topic set time, via the `"T<val"` and `"T>val"` modifiers to search for a topic time that is higher or lower than `val`.
* **U**: Searching based on user count within the channel, via the `"U<val"` and `"U>val"` modifiers to search for a channel that has less or more user than `val`.

Examples:

      ELIST=MNUCT

      ELIST=MU

      ELIST=CMNTU

### `EXCEPTS` Parameter

      Format: EXCEPTS=[character]
       Empty: e

The `EXCEPTS` parameter indicates that the server supports ban exceptions, as specified in the [ban exemption](#ban-exemption-channel-mode) channel mode section.

The value is OPTIONAL and when not specified indicates that the letter `"e"` is used as the channel mode for ban exceptions. If the value is specified, the character indicates the letter which is used for ban exceptions.

Examples:

      EXCEPTS

      EXCEPTS=e

### `EXTBAN` Parameter

      Format: EXTBAN=<prefix>,<types>

The `EXTBAN` parameter indicates the types of "extended ban masks" that the server supports.

`<prefix>` denotes the character that indicates an extban to the server and `<types>` is a list of characters indicating the types of extended bans the server supports.

Extbans may allow clients to issue bans based on account name, SSL certificate fingerprints and other attributes, based on what the server supports.

Extban masks SHOULD also be supported for the [ban exemption](#ban-exemption-channel-mode) and [invite exemption](#invite-exemption-channel-mode) modes.

<div class="warning">
    <p>Ensure that extban masks are actually typically supported in ban exemption and invite exemption modes.</p>

    <p>We should include a list of 'typical' extban characters and their associated meaning, but make sure we specify that these are not standardised and may change based on server software. See also: <a href="https://github.com/ircdocs/irc-defs/issues/9"><code>irc-defs#9</code></a></p>
</div>

Examples:

      EXTBAN=~,cqnr

      EXTBAN=~,qjncrRa

### `INVEX` Parameter

      Format: INVEX=[character]
       Empty: I

The `INVEX` parameter indicates that the server supports invite exceptions, as specified in the [invite exemption](#invite-exemption-channel-mode) channel mode section.

The value is OPTIONAL and when not specified indicates that the letter `"I"` is used as the channel mode for invite exceptions. If the value is specified, the character indicates the letter which is used for invite exceptions.

Examples:

      INVEX

      INVEX=I

### `KICKLEN` Parameter

The `KICKLEN` parameter indicates the maximum length for the `<reason>` of a [`KICK`](#kick-message) command. If a [`KICK`](#kick-message) `<reason>` has more characters than this parameter, it may be silently truncated by the server before being passed on to other clients. Clients MAY receive a [`KICK`](#kick-message) `<reason>` that has more characters than this parameter.

The value MUST be specified and MUST be a positive integer.

Examples:

      KICKLEN=255

      KICKLEN=307

### `MAXLIST` Parameter

      Format: MAXLIST=<modes>:<limit>{,<modes>:<limit>}

The `MAXLIST` parameter specifies how many "variable" modes of type A that have been defined in the [`CHANMODES`](#chanmodes-parameter) parameter that a client may set in total on a channel.

The value MUST be specified and is a list of `<modes>:<limit>` pairs, delimited by a comma `(',',` `0x2C)`. `<modes>` is a list of type A modes defined in [`CHANMODES`](#chanmodes-parameter). `<limit>` is a positive integer specifying the maximum number of entries that all of the modes in `<modes>`, combined, may set on a channel.

A client MUST NOT make any assumptions on how many mode entries may actually exist on any given channel. This limit only applies to the client setting new modes of the given types, and other clients may have different limits.

Examples:

      MAXLIST=beI:25           ; indicates that a client may set up to a total of 25 of a
                               combination of "b", "e", and "I" modes.

      MAXLIST=b:60,e:60,I:60   ; indicates that a client may set up to 60 "b" modes,
                               "e" modes, and 60 "I" modes.

      MAXLIST=beI:100,q:50     ; indicates that a client may set up to a total of 100 of
                               a combination of "b", "e", and "I" modes, and that they
                               may set up to 50 "q" modes.

### `MAXTARGETS` Parameter

      Format: MAXTARGETS=[number]

The `MAXTARGETS` parameter specifies the maximum number of targets a [`PRIVMSG`](#privmsg-message) or [`NOTICE`](#notice-message) command may have, and may apply to other commands based on server software.

The value is OPTIONAL and if specified, `[number]` is a positive integer representing the maximum number of targets those commands may have. If there is no limit, then `[number]` MAY not be specified.

The [`TARGMAX`](#targmax-parameter) parameter SHOULD be advertised instead of or in addition to this parameter. [`TARGMAX`](#targmax-parameter) is intended to replace `MAXTARGETS` as that parameter is more clear about which commands limits apply to.

Examples:

      MAXTARGETS=4

      MAXTARGETS=20

### `MODES` Parameter

      Format: MODES=[number]

The `MODES` parameter specifies how many 'variable' modes may be set on a channel by a single [`MODE`](#mode-message) command from a client. A 'variable' mode is defined as being a type A, B or C mode as defined in the [`CHANMODES`](#chanmodes-parameter) parameter, or in the channel modes specified in the [`PREFIX`](#prefix-parameter) parameter.

A client SHOULD NOT issue more 'variable' modes than this in a single [`MODE`](#mode-message) command. A server MAY however issue more 'variable' modes than this in a single [`MODE`](#mode-message) message. The value is OPTIONAL and when not specified indicates that there is no limit to the number of 'variable' modes that may be set in a single client [`MODE`](#mode-message) command.

If the value is specified, it MUST be a positive integer.

Examples:

      MODES=4

      MODES=12

      MODES=20

### `NETWORK` Parameter

      Format: NETWORK=<string>

The `NETWORK` parameter indicates the name of the IRC network that the client is connected to. This parameter is advertised for INFORMATIONAL PURPOSES ONLY. Clients SHOULD NOT use this value to make assumptions about supported features on the server as networks may change server software and configuration at any time.

Examples:

      NETWORK=EFNet

      NETWORK=Rizon

### `NICKLEN` Parameter

       Format: NICKLEN=<number>

The `NICKLEN` parameter indicates the maximum length of a nickname that a client may set. Clients on the network MAY have longer nicks than this.

The value MUST be specified and MUST be a positive integer. `30` or `31` are typical values for this parameter advertised by servers today.

Examples:

      NICKLEN=9

      NICKLEN=30

      NICKLEN=31

### `PREFIX` Parameter

       Format: PREFIX=[(modes)prefixes]
      Default: PREFIX=(ov)@+

Within channels, clients can have different statuses, denoted by single-character prefixes. The `PREFIX` parameter specifies these prefixes and the channel mode characters that they are mapped to. There is a one-to-one mapping between prefixes and channel modes. The prefixes in this parameter are in descending order, from the prefix that gives the most privileges to the prefix that gives the least.

The typical prefixes advertised in this parameter are listed in the [Channel Membership Prefixes](#channel-membership-prefixes) section.

The value is OPTIONAL and when it is not specified indicates that no prefixes are supported.

Examples:

      PREFIX=(ov)@+

      PREFIX=(ohv)@%+

      PREFIX=(qaohv)~&@%+

### `SAFELIST` Parameter

      Format: SAFELIST

If `SAFELIST` parameter is advertised, the server ensures that a client may perform the [`LIST`](#list-message) command without being disconnected due to the large volume of data the [`LIST`](#list-message) command generates.

The `SAFELIST` parameter MUST NOT be specified with a value.

Examples:

      SAFELIST

### `SILENCE` Parameter

      Format: SILENCE[=<limit>]

The `SILENCE` parameter indicates the maximum number of entries a client can have in their silence list.

The value is OPTIONAL and if specified is a positive integer. If the value is not specified, the server does not support the [`SILENCE`](#silence-message) command.

Most IRC clients also include client-side filter/ignore lists as an alternative to this command.

Examples:

      SILENCE

      SILENCE=15

      SILENCE=32

### `STATUSMSG` Parameter

      Format: STATUSMSG=<string>

The `STAUSMSG` parameter indicates that the server supports a method for clients to send a message via the [`PRIVMSG`](#privmsg-message) / [`NOTICE`](#notice-message) commands to those people on a channel with (one of) the specified [channel membership prefixes](#channel-membership-prefixes).

The value MUST be specified and MUST be a list of prefixes as specified in the [`PREFIX`](#prefix-parameter) parameter. Most servers today advertise every prefix in their [`PREFIX`](#prefix-parameter) parameter in `STATUSMSG`.

Examples:

      STATUSMSG=@+

      STATUSMSG=@%+

      STATUSMSG=~&@%+

### `TARGMAX` Parameter

      Format: TARGMAX=[<command>:[limit]{,<command>:[limit]}]

Certain client commands MAY contain multiple targets, delimited by a comma `(',', 0x2C)`. The `TARGMAX` parameter defines the maximum number of targets allowed for commands which accept multiple targets.

The value is OPTIONAL and is a set of `<command>:<limit>` pairs, delimited by a comma `(',', 0x2C)`. `<command>` is the name of a client command. `<limit>` is the maximum number of targets which that command accepts. If `<limit>` is specified, it is a positive integer. If `<limit>` is not specified, then there is no maximum number of targets for that command. Clients MUST treat `<command>` as case-insensitive.

Examples:

      TARGMAX=PRIVMSG:3,WHOIS:1,JOIN:

      TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR:

      TARGMAX=ACCEPT:,KICK:1,LIST:1,NAMES:1,NOTICE:4,PRIVMSG:4,WHOIS:1

### `TOPICLEN` Parameter

      Format: TOPICLEN=<number>

The `TOPICLEN` parameter indicates the maximum length of a topic that a client may set on a channel. Channels on the network MAY have topics with longer lengths than this.

The value MUST be specified and MUST be a positive integer. `307` is the typical value for this parameter advertised by servers today.

Examples:

      TOPICLEN=307

      TOPICLEN=390


---


# Obsolete Numerics

These are numerics contained in [RFC1459](https://tools.ietf.org/html/rfc1459) and [RFC2812](https://tools.ietf.org/html/rfc2812) that are not contained in this document or that should be considered obsolete.

* **`RPL_BOUNCE (005)`**: `005` is now used for [`RPL_ISUPPORT`](#rplisupport-005). `RPL_BOUNCE` was moved to [`010`](#rplbounce-010).
