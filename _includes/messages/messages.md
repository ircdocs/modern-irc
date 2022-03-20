### PRIVMSG message

         Command: PRIVMSG
      Parameters: <target>{,<target>} <text to be sent>

The `PRIVMSG` command is used to send private messages between users, as well as to send messages to channels. `<target>` is the nickname of a client or the name of a channel.

If `<target>` is a channel name and the client is [banned](#ban-channel-mode) and not covered by a [ban exemption](#ban-exemption-channel-mode), the message will not be delivered and the command will silently fail. Channels with the [moderated](#moderated-channel-mode) mode active may block messages from certain users. Other channel modes may affect the delivery of the message or cause the message to be modified before delivery, and these modes are defined by the server software and configuration being used.

If a message cannot be delivered to a channel, the server SHOULD respond with an {% numeric ERR_CANNOTSENDTOCHAN %} numeric to let the user know that this message could not be delivered.

If `<target>` is a channel name, it may be prefixed with one or more [channel membership prefix character (`@`, `+`, etc)](#channel-membership-prefixes) and the message will be delivered only to the members of that channel with the given or higher status in the channel. Servers that support this feature will list the prefixes which this is supported for in the {% isupport STATUSMSG %} `RPL_ISUPPORT` parameter, and this SHOULD NOT be attempted by clients unless the prefix has been advertised in this token.

If `<target>` is a user and that user has been set as away, the server may reply with an {% numeric RPL_AWAY %} numeric and the command will continue.

The `PRIVMSG` message is sent from the server to client to deliver a message to that client. The `<source>` of the message represents the user or server that sent the message, and the `<target>` represents the target of that `PRIVMSG` (which may be the client, a channel, etc).

When the `PRIVMSG` message is sent from a server to a client and `<target>` starts with a dollar character `('$', 0x24)`, the message is a broadcast sent to all clients on one or multiple servers.

Numeric Replies:

* {% numeric ERR_NOSUCHNICK %}
* {% numeric ERR_NOSUCHSERVER %}
* {% numeric ERR_CANNOTSENDTOCHAN %}
* {% numeric ERR_TOOMANYTARGETS %}
* {% numeric ERR_NORECIPIENT %}
* {% numeric ERR_NOTEXTTOSEND %}
* {% numeric ERR_NOTOPLEVEL %}
* {% numeric ERR_WILDTOPLEVEL %}
* {% numeric RPL_AWAY %}

<div class="warning">
    There are strange "X@Y" target rules and such which are noted in the examples of the original PRIVMSG RFC section. We need to check to make sure modern servers actually process them properly, and if so then specify them.
</div>

Command Examples:

      PRIVMSG Angel :yes I'm receiving it !
                                      ; Command to send a message to Angel.

      PRIVMSG %#bunny :Hi! I have a problem!
                                      ; Command to send a message to halfops
                                      and chanops on #bunny.

      PRIVMSG @%#bunny :Hi! I have a problem!
                                      ; Command to send a message to halfops
                                      and chanops on #bunny. This command is
                                      functionally identical to the above
                                      command.

Message Examples:

      :Angel PRIVMSG Wiz :Hello are you receiving this message ?
                                      ; Message from Angel to Wiz.

      :dan!~h@localhost PRIVMSG #coolpeople :Hi everyone!
                                      ; Message from dan to the channel
                                      #coolpeople

### NOTICE message

         Command: NOTICE
      Parameters: <target>{,<target>} <text to be sent>

The `NOTICE` command is used to send notices between users, as well as to send notices to channels. `<target>` is interpreted the same way as it is for the {% command PRIVMSG %} command.

The `NOTICE` message is used similarly to {% command PRIVMSG %}. The difference between `NOTICE` and {% command PRIVMSG %} is that automatic replies must never be sent in response to a `NOTICE` message. This rule also applies to servers -- they must not send any error back to the client on receipt of a `NOTICE` command. The intention of this is to avoid loops between a client automatically sending something in response to something it received. This is typically used by 'bots' (a client with a program, and not a user, controlling their actions) and also for server messages to clients.

One thing for bot authors to note is that the `NOTICE` message may be interpreted differently by various clients. Some clients highlight or interpret any `NOTICE` sent to a channel in the same way that a `PRIVMSG` with their nickname gets interpreted. This means that users may be irritated by the use of `NOTICE` messages rather than `PRIVMSG` messages by clients or bots, and they are not commonly used by client bots for this reason.

