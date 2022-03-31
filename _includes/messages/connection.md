
### CAP message

         Command: CAP
      Parameters: <subcommand> [:<capabilities>]

The `CAP` command is used for capability negotiation between a server and a client.

The `CAP` message may be sent from the server to the client.

For the exact semantics of the `CAP` command and subcommands, please see the [Capability Negotiation specification](https://ircv3.net/specs/extensions/capability-negotiation.html).

### AUTHENTICATE message

         Command: AUTHENTICATE

The `AUTHENTICATE` command is used for SASL authentication between a server and a client. The client must support and successfully negotiate the `"sasl"` client capability (as listed below in the SASL specifications) before using this command.

The `AUTHENTICATE` message may be sent from the server to the client.

For the exact semantics of the `AUTHENTICATE` command and negotiating support for the `"sasl"` client capability, please see the [IRCv3.1](http://ircv3.net/specs/extensions/sasl-3.1.html) and [IRCv3.2](http://ircv3.net/specs/extensions/sasl-3.2.html) SASL Authentication specifications.

### PASS message

         Command: PASS
      Parameters: <password>

The `PASS` command is used to set a 'connection password'. If set, the password must be set before any attempt to register the connection is made. This requires that clients send a `PASS` command before sending the `NICK` / `USER` combination.

The password supplied must match the one defined in the server configuration. It is possible to send multiple `PASS` commands before registering but only the last one sent is used for verification and it may not be changed once the client has been registered.

If the password supplied does not match the password expected by the server, then the server SHOULD send {% numeric ERR_PASSWDMISMATCH %} and MAY then close the connection with {% message ERROR %}. Servers MUST send at least one of these two messages.

Servers may also consider requiring [SASL authentication](#authenticate-message) upon connection as an alternative to this, when more information or an alternate form of identity verification is desired.

Numeric replies:

* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_ALREADYREGISTERED %}
* {% numeric ERR_PASSWDMISMATCH %}

Command Example:

      PASS secretpasswordhere

### NICK message

         Command: NICK
      Parameters: <nickname>

The `NICK` command is used to give the client a nickname or change the previous one.

If the server receives a `NICK` command from a client where the desired nickname is already in use on the network, it should issue an `ERR_NICKNAMEINUSE` numeric and ignore the `NICK` command.

If the server does not accept the new nickname supplied by the client as valid (for instance, due to containing invalid characters), it should issue an `ERR_ERRONEUSNICKNAME` numeric and ignore the `NICK` command.

If the server does not receive the `<nickname>` parameter with the `NICK` command, it should issue an `ERR_NONICKNAMEGIVEN` numeric and ignore the `NICK` command.

The `NICK` message may be sent from the server to clients to acknowledge their `NICK` command was successful, and to inform other clients about the change of nickname. In these cases, the `<source>` of the message will be the old `nickname [ [ "!" user ] "@" host ]` of the user who is changing their nickname.

Numeric Replies:

* {% numeric ERR_NONICKNAMEGIVEN %}
* {% numeric ERR_ERRONEUSNICKNAME %}
* {% numeric ERR_NICKNAMEINUSE %}
* {% numeric ERR_NICKCOLLISION %}

Command Example:

      NICK Wiz                  ; Requesting the new nick "Wiz".

Message Examples:

      :WiZ NICK Kilroy          ; WiZ changed his nickname to Kilroy.

      :dan-!d@localhost NICK Mamoped
                                ; dan- changed his nickname to Mamoped.

### USER message

         Command: USER
      Parameters: <username> 0 * <realname>

The `USER` command is used at the beginning of a connection to specify the username and realname of a new user.

It must be noted that `<realname>` must be the last parameter because it may contain SPACE `(' ',` `0x20)` characters, and should be prefixed with a colon (`:`) if required.

Servers MAY use the [Ident Protocol](http://tools.ietf.org/html/rfc1413) to look up the 'real username' of clients. If username lookups are enabled and a client does not have an Identity Server enabled, the username provided by the client SHOULD be prefixed by a tilde `('~', 0x7E)` to show that this value is user-set.

The maximum length of `<username>` may be specified by the {% isupport USERLEN %} `RPL_ISUPPORT` parameter. If this length is advertised, the username MUST be silently truncated to the given length before being used.
The minimum length of `<username>` is 1, ie. it MUST not be empty. If it is empty, the server SHOULD reject the command with [`ERR_NEEDMOREPARAMS`](#errneedmoreparams-461) (even if an empty parameter is provided); otherwise it MUST use a default value instead.

The second and third parameters of this command SHOULD be sent as one zero `('0', 0x30)` and one asterisk character `('*', 0x2A)` by the client, as the meaning of these two parameters varies between different versions of the IRC protocol.

If a client tries to send the `USER` command after they have already completed registration with the server, the `ERR_ALREADYREGISTERED` reply should be sent and the attempt should fail.

If the client sends a `USER` command after the server has successfully received a username using the Ident Protocol, the `<username>` parameter from this command should be ignored in favour of the one received from the identity server.

Numeric Replies:

* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_ALREADYREGISTERED %}

Command Examples:

      USER guest 0 * :Ronnie Reagan
                                  ; No ident server
                                  ; User gets registered with username
                                  "~guest" and real name "Ronnie Reagan"

      USER guest 0 * :Ronnie Reagan
                                  ; Ident server gets contacted and
                                  returns the name "danp"
                                  ; User gets registered with username
                                  "danp" and real name "Ronnie Reagan"


### PING message

         Command: PING
      Parameters: <token>

The `PING` command is sent by either clients or servers to check the other side of the connection is still connected and/or to check for connection latency, at the application layer.

The `<token>` may be any non-empty string.

When receiving a `PING` message, clients or servers must reply to it with a {% message PONG %} message with the same `<token>` value. This allows either to match `PONG` with the `PING` they reply to, for example to compute latency.

Clients should not send `PING` during connection registration, though servers may accept it.
Servers may send `PING` during connection registration and clients must reply to them.

Older versions of the protocol gave specific semantics to the `<token>` and allowed an extra parameter; but these features are not consistently implemented and should not be relied on. Instead, the `<token>` should be treated as an opaque value by the receiver.

Numeric Replies:

* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOORIGIN %}

Deprecated Numeric Reply:

* {% numeric ERR_NOSUCHSERVER %}


### PONG message

         Command: PONG
      Parameters: [<server>] <token>

The `PONG` command is used as a reply to {% message PING %} commands, by both clients and servers.
The `<token>` should be the same as the one in the `PING` message that triggered this `PONG`.

Servers MUST send a `<server>` parameter, and clients SHOULD ignore it. It exists for historical reasons, and indicates the name of the server sending the PONG.
Clients MUST NOT send a `<server>` parameter.

Numeric Replies:

* None


### OPER message

         Command: OPER
      Parameters: <name> <password>

The `OPER` command is used by a normal user to obtain IRC operator privileges. Both parameters are required for the command to be successful.

If the client does not send the correct password for the given name, the server replies with an `ERR_PASSWDMISMATCH` message and the request is not successful.

If the client is not connecting from a valid host for the given name, the server replies with an `ERR_NOOPERHOST` message and the request is not successful.

If the supplied name and password are both correct, and the user is connecting from a valid host, the `RPL_YOUREOPER` message is sent to the user. The user will also receive a {% command MODE %} message indicating their new user modes, and other messages may be sent.

The `<name>` specified by this command is separate to the accounts specified by SASL authentication, and is generally stored in the IRCd configuration.

Numeric Replies:

* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_PASSWDMISMATCH %}
* {% numeric ERR_NOOPERHOST %}
* {% numeric RPL_YOUREOPER %}

Command Example:

      OPER foo bar                ; Attempt to register as an operator
                                  using a name of "foo" and the password "bar".

### QUIT message

        Command: QUIT
     Parameters: [<reason>]

The `QUIT` command is used to terminate a client's connection to the server. The server acknowledges this by replying with an {% command ERROR %} message and closing the connection to the client.

This message may also be sent from the server to a client to show that a client has exited from the network. This is typically only dispatched to clients that share a channel with the exiting user. When the `QUIT` message is sent to clients, `<source>` represents the client that has exited the network.

When connections are terminated by a client-sent `QUIT` command, servers SHOULD prepend `<reason>` with the ASCII string `"Quit: "` when sending `QUIT` messages to other clients, to represent that this user terminated the connection themselves. This applies even if `<reason>` is empty, in which case the reason sent to other clients SHOULD be just this `"Quit: "` string. However, clients SHOULD NOT change behaviour based on the prefix of `QUIT` message reasons, as this is not required behaviour from servers.

When a netsplit (the disconnecting of two servers) occurs, a `QUIT` message is generated for each client that has exited the network, distributed in the same way as ordinary `QUIT` messages. The `<reason>` on these `QUIT` messages SHOULD be composed of the names of the two servers involved, separated by a SPACE `(' ', 0x20)`. The first name is that of the server which is still connected and the second name is that of the server which has become disconnected. If servers wish to hide or obscure the names of the servers involved, the `<reason>` on these messages MAY also be the literal ASCII string `"*.net *.split"` (i.e. the two server names are replaced with `"*.net"` and `"*.split"`). Software that implements the IRCv3 [`batch` Extension](http://ircv3.net/specs/extensions/batch-3.2.html) should also look at the [`netsplit` and `netjoin`](http://ircv3.net/specs/extensions/batch/netsplit-3.2.html) batch types.

If a client connection is closed without the client issuing a `QUIT` command to the server, the server MUST distribute a `QUIT` message to other clients informing them of this, distributed in the same was an ordinary `QUIT` message. Servers MUST fill `<reason>` with a message reflecting the nature of the event which caused it to happen. For instance, `"Ping timeout: 120 seconds"`, `"Excess Flood"`, and `"Too many connections from this IP"` are examples of relevant reasons for closing or for a connection with a client to have been closed.

Numeric Replies:

* None

Command Example:

      QUIT :Gone to have lunch         ; Client exiting from the network

Message Example:

      :dan-!d@localhost QUIT :Quit: Bye for now!
                                       ; dan- is exiting the network with
                                       the message: "Quit: Bye for now!"


### ERROR message

        Command: ERROR
     Parameters: <reason>

This message is sent from a server to a client to report a fatal error, before terminating the client's connection.

This MUST only be used to report fatal errors. Regular errors should use the appropriate numerics or the IRCv3 [standard replies](https://ircv3.net/specs/extensions/standard-replies) framework.

Numeric Replies:

* None

Command Example:

      ERROR :Connection timeout        ; Server closing a client connection because it
                                       is unresponsive.
