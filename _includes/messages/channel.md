This group of messages is concerned with manipulating channels, their properties (channel modes), and their contents (typically clients).

These commands may be requests to the server, in which case the server will or will not grant the request. If a 'request' is granted, it will be acknowledged by the server sending a message containing the same information back to the client. This is to tell the user that the request was successful. These sort of 'request' commands will be noted in the message information.

In implementing these messages, race conditions are inevitable when clients at opposing ends of a network send commands which will ultimately clash. Server-to-server protocols should be aware of this and make sure their protocol ensures consistent state across the entire network.

### JOIN message

         Command: JOIN
      Parameters: <channel>{,<channel>} [<key>{,<key>}]
      Alt Params: 0

The `JOIN` command indicates that the client wants to join the given channel(s), each channel using the given key for it. The server receiving the command checks whether or not the client can join the given channel, and processes the request. Servers MUST process the parameters of this command as lists on incoming commands from clients, with the first `<key>` being used for the first `<channel>`, the second `<key>` being used for the second `<channel>`, etc.

While a client is joined to a channel, they receive all relevant information about that channel including the `JOIN`, `PART`, `KICK`, and `MODE` messages affecting the channel. They receive all `PRIVMSG` and `NOTICE` messages sent to the channel, and they also receive `QUIT` messages from other clients joined to the same channel (to let them know those users have left the channel and the network). This allows them to keep track of other channel members and channel modes.

If a client's `JOIN` command to the server is successful, the server MUST send, in this order:

1. A `JOIN` message with the client as the message `<source>` and the channel they have joined as the first parameter of the message.
2. The channel's topic (with {% numeric RPL_TOPIC %} and optionally {% numeric RPL_TOPICWHOTIME %}), and no message if the channel does not have a topic.
3. A list of users currently joined to the channel (with one or more {% numeric RPL_NAMREPLY %} numerics followed by a single {% numeric RPL_ENDOFNAMES %} numeric). These `RPL_NAMREPLY` messages sent by the server MUST include the requesting client that has just joined the channel.

The [key](#key-channel-mode), [client limit](#client-limit-channel-mode) , [ban](#ban-channel-mode) - [exemption](#ban-exemption-channel-mode), [invite-only](#invite-only-channel-mode) - [exemption](#invite-exemption-channel-mode), and other (depending on server software) channel modes affect whether or not a given client may join a channel. More information on each of these modes and how they affect the `JOIN` command is available in their respective sections.

Servers MAY restrict the number of channels a client may be joined to at one time. This limit SHOULD be defined in the {% isupport CHANLIMIT %} `RPL_ISUPPORT` parameter. If the client cannot join this channel because they would be over their limit, they will receive an {% numeric ERR_TOOMANYCHANNELS %} reply and the command will fail.

Note that this command also accepts the special argument of `("0", 0x30)` instead of any of the usual parameters, which requests that the sending client leave all channels they are currently connected to. The server will process this command as though the client had sent a {% command PART %} command for each channel they are a member of.

This message may be sent from a server to a client to notify the client that someone has joined a channel. In this case, the message `<source>` will be the client who is joining, and `<channel>` will be the channel which that client has joined. Servers SHOULD NOT send multiple channels in this message to clients, and SHOULD distribute these multiple-channel `JOIN` messages as a series of messages with a single channel name on each.

Numeric Replies:

* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOSUCHCHANNEL %}
* {% numeric ERR_TOOMANYCHANNELS %}
* {% numeric ERR_BADCHANNELKEY %}
* {% numeric ERR_BANNEDFROMCHAN %}
* {% numeric ERR_CHANNELISFULL %}
* {% numeric ERR_INVITEONLYCHAN %}
* {% numeric RPL_TOPIC %}
* {% numeric RPL_TOPICWHOTIME %}
* {% numeric RPL_NAMREPLY %}
* {% numeric RPL_ENDOFNAMES %}

Command Examples:

      JOIN #foobar                    ; join channel #foobar.

      JOIN &foo fubar                 ; join channel &foo using key "fubar".

      JOIN #foo,&bar fubar            ; join channel #foo using key "fubar"
                                      and &bar using no key.

      JOIN #foo,#bar fubar,foobar     ; join channel #foo using key "fubar".
                                      and channel #bar using key "foobar".

      JOIN #foo,#bar                  ; join channels #foo and #bar.

Message Examples:

      :WiZ JOIN #Twilight_zone        ; WiZ is joining the channel
                                      #Twilight_zone

      :dan-!d@localhost JOIN #test    ; dan- is joining the channel #test

### PART message

         Command: PART
      Parameters: <channel>{,<channel>} [<reason>]

The `PART` command removes the client from the given channel(s). On sending a successful `PART` command, the user will receive a `PART` message from the server for each channel they have been removed from. `<reason>` is the reason that the client has left the channel(s).

For each channel in the parameter of this command, if the channel exists and the client is not joined to it, they will receive an {% numeric ERR_NOTONCHANNEL %} reply and that channel will be ignored. If the channel does not exist, the client will receive an {% numeric ERR_NOSUCHCHANNEL %} reply and that channel will be ignored.

This message may be sent from a server to a client to notify the client that someone has been removed from a channel. In this case, the message `<source>` will be the client who is being removed, and `<channel>` will be the channel which that client has been removed from. Servers SHOULD NOT send multiple channels in this message to clients, and SHOULD distribute these multiple-channel `PART` messages as a series of messages with a single channel name on each. If a `PART` message is distributed in this way, `<reason>` (if it exists) should be on each of these messages.

Numeric Replies:

* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOSUCHCHANNEL %}
* {% numeric ERR_NOTONCHANNEL %}

Command Examples:

      PART #twilight_zone             ; leave channel "#twilight_zone"

      PART #oz-ops,&group5            ; leave both channels "&group5" and
                                      "#oz-ops".

Message Examples:

      :dan-!d@localhost PART #test    ; dan- is leaving the channel #test

### TOPIC message

         Command: TOPIC
      Parameters: <channel> [<topic>]

The `TOPIC` command is used to change or view the topic of the given channel. If `<topic>` is not given, either `RPL_TOPIC` or `RPL_NOTOPIC` is returned specifying the current channel topic or lack of one. If `<topic>` is an empty string, the topic for the channel will be cleared.

If the client sending this command is not joined to the given channel, and tries to view its' topic, the server MAY return the {% numeric ERR_NOTONCHANNEL %} numeric and have the command fail.

If `RPL_TOPIC` is returned to the client sending this command, `RPL_TOPICWHOTIME` SHOULD also be sent to that client.

If the [protected topic](#protected-topic-mode) mode is set on a channel, then clients MUST have appropriate channel permissions to modify the topic of that channel. If a client does not have appropriate channel permissions and tries to change the topic, the {% numeric ERR_CHANOPRIVSNEEDED %} numeric is returned and the command will fail.

If the topic of a channel is changed or cleared, every client in that channel (including the author of the topic change) will receive a `TOPIC` command with the new topic as argument (or an empty argument if the topic was cleared) alerting them to how the topic has changed.

Clients joining the channel in the future will receive a `RPL_TOPIC` numeric (or lack thereof) accordingly.

Numeric Replies:

* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOSUCHCHANNEL %}
* {% numeric ERR_NOTONCHANNEL %}
* {% numeric ERR_CHANOPRIVSNEEDED %}
* {% numeric RPL_NOTOPIC %}
* {% numeric RPL_TOPIC %}
* {% numeric RPL_TOPICWHOTIME %}

Command Examples:

      TOPIC #test :New topic          ; Setting the topic on "#test" to
                                      "New topic".

      TOPIC #test :                   ; Clearing the topic on "#test"

      TOPIC #test                     ; Checking the topic for "#test"

### NAMES message

         Command: NAMES
      Parameters: [<channel>{,<channel>}]

The `NAMES` command is used to view the nicknames joined to a channel and their [channel membership prefixes](#channel-membership-prefixes). The param of this command is a list of channel names, delimited by a comma `(",", 0x2C)` character.

The channel names are evaluated one-by-one. For each channel that exists and they are able to see the users in, the server returns one of more `RPL_NAMREPLY` numerics containing the users joined to the channel and a single `RPL_ENDOFNAMES` numeric. If the channel name is invalid or the channel does not exist, one `RPL_ENDOFNAMES` numeric containing the given channel name should be returned. If the given channel has the [secret](#secret-channel-mode) channel mode set and the user is not joined to that channel, one `RPL_ENDOFNAMES` numeric is returned. Users with the [invisible](#invisible-user-mode) user mode set are not shown in channel responses unless the requesting client is also joined to that channel.

Servers MAY only return information about the first `<channel>` and silently ignore the others. This seems to be an attempt to reduce possible abuse. Due to this, clients SHOULD only query information about one channel when using the `NAMES` command.

If no parameter is given for this command, servers SHOULD return one `RPL_ENDOFNAMES` numeric with the `<channel>` parameter set to an asterisk character `('*', 0x2A)`. Servers MAY also choose to return information about every single channel and every single user on the network in response to this command being given without a parameter, but most servers these days return nothing.

Numeric Replies:

* {% numeric RPL_NAMREPLY %}
* {% numeric RPL_ENDOFNAMES %}

Command Examples:

      NAMES #twilight_zone,#42        ; List all visible users on
                                      "#twilight_zone" and "#42".

      NAMES                           ; Attempt to list all visible users on
                                      the network, which SHOULD be responded to
                                      as specified above.

### LIST message

         Command: LIST
      Parameters: [<channel>{,<channel>}] [<elistcond>{,<elistcond>}]

The `LIST` command is used to get a list of channels along with some information about each channel. Both parameters to this command are optional as they have different syntaxes.

The first possible parameter to this command is a list of channel names, delimited by a comma `(",", 0x2C)` character. If this parameter is given, the information for only the given channels is returned. If this parameter is not given, the information about all visible channels (those not hidden by the [secret](#secret-channel-mode) channel mode rules) is returned.

The second possible parameter to this command is a list of conditions as defined in the {% isupport ELIST %} `RPL_ISUPPORT` parameter, delimited by a comma `(",", 0x2C)` character. Clients MUST NOT submit an `ELIST` condition unless the server has explicitly defined support for that condition with the `ELIST` token. If this parameter is supplied, the server filters the returned list of channels with the given conditions as specified in the {% isupport ELIST %} documentation.

In response to a successful `LIST` command, the server MAY send one `RPL_LISTSTART` numeric, MUST send back zero or more `RPL_LIST` numerics, and MUST send back one `RPL_LISTEND` numeric.

Numeric Replies:

* {% numeric RPL_LISTSTART %}
* {% numeric RPL_LIST %}
* {% numeric RPL_LISTEND %}

Command Examples:

      LIST                            ; Command to list all channels

      LIST #twilight_zone,#42         ; Command to list the channels
                                      "#twilight_zone" and "#42".

      LIST >3                         ; Command to list all channels with
                                      more than three users.

### INVITE message

         Command: INVITE
      Parameters: <nickname> <channel>
      Alt Params: 0

The `INVITE` command is used to invite a user to a channel.  The parameter `<nickname>` is the nickname of the person to be invited to the target channel `<channel>`.

The target channel SHOULD exist (at least one user is on it).  Otherwise, the server SHOULD reject the command with the `ERR_NOSUCHCHANNEL` numeric.

Only members of the channel are allowed to invite other users.  Otherwise, the server MUST reject the command with the `ERR_NOTONCHANNEL` numeric.

Servers MAY reject the command with the `ERR_CHANOPRIVSNEEDED` numeric. In particular, they SHOULD reject it when the channel has [invite-only](#invite-only-channel-mode) mode set, and the user is not a channel operator.

If the user is already on the target channel, the server MUST reject the command with the `ERR_USERONCHANNEL` numeric.

When the invite is successful, the server MUST send a `RPL_INVITING` numeric to the command issuer, and an `INVITE` message, with the issuer as `<source>`, to the target user.  Other channel members SHOULD NOT be notified.

Numeric Replies:

* {% numeric RPL_INVITING %}
* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOSUCHCHANNEL %}
* {% numeric ERR_NOTONCHANNEL %}
* {% numeric ERR_CHANOPRIVSNEEDED %}
* {% numeric ERR_USERONCHANNEL %}

Command Examples:

      INVITE Wiz #foo_bar    ; Invite Wiz to #foo_bar

Message Examples:

      :dan-!d@localhost INVITE Wiz #test    ; dan- has invited Wiz
                                            to the channel #test

### KICK message

          Command: KICK
       Parameters: <channel> <user> *( "," <user> ) [<comment>]

The KICK command can be used to request the forced removal of a user from a channel.
It causes the `<user>` to be removed from the `<channel>` by force.
If no comment is given, the server SHOULD use a default message instead.

The server MUST NOT send KICK messages with multiple users to clients.
This is necessary to maintain backward compatibility with existing client software.

Servers MAY limit the number of target users per `KICK` command via the [`TARGMAX` parameter of `RPL_ISUPPORT`](#targmax-parameter), and silently drop targets if the number of targets exceeds the limit.

Numeric Replies:

* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOSUCHCHANNEL %}
* {% numeric ERR_CHANOPRIVSNEEDED %}
* {% numeric ERR_USERNOTINCHANNEL %}
* {% numeric ERR_NOTONCHANNEL %}

Deprecated Numeric Reply:

* {% numeric ERR_BADCHANMASK %}

Examples:

       KICK #Finnish Matthew           ; Command to kick Matthew from
                                       #Finnish

       KICK &Melbourne Matthew         ; Command to kick Matthew from
                                       &Melbourne

       KICK #Finnish John :Speaking English
                                       ; Command to kick John from #Finnish
                                       using "Speaking English" as the
                                       reason (comment).

       :WiZ!jto@tolsun.oulu.fi KICK #Finnish John
                                       ; KICK message on channel #Finnish
                                       from WiZ to remove John from channel

