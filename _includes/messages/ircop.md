The following messages are typically reserved to server operators.

### KILL message

         Command: KILL
      Parameters: <nickname> <comment>

The `KILL` command is used to close the connection between a given client and the server they are connected to. `KILL` is a privileged command and is available only to IRC Operators. `<nickname>` represents the user to be 'killed', and `<comment>` is shown to all users and to the user themselves upon being killed.

When a `KILL` command is used, the client being killed receives the `KILL` message, and the `<source>` of the message SHOULD be the operator who performed the command. The user being killed and every user sharing a channel with them receives a {% command QUIT %} message representing that they are leaving the network. The `<reason>` on this `QUIT` message typically has the form: `"Killed (<killer> (<reason>))"` where `<killer>` is the nickname of the user who performed the `KILL`. The user being killed then receives the {% command ERROR %} message, typically containing a `<reason>` of `"Closing Link: <servername> (Killed (<killer> (<reason>)))"`. After this, their connection is closed.

If a `KILL` message is received by a client, it means that the user specified by `<nickname>` is being killed. With certain servers, users may elect to receive `KILL` messages created for other users to keep an eye on the network. This behavior may also be restricted to operators.

Clients can rejoin instantly after this command is performed on them. However, it can serve as a warning to a user to stop their activity. As it breaks the flow of data from the user, it can also be used to stop large amounts of 'flooding' from abusive users or due to accidents. Abusive users may not care and promptly reconnect and resume their abusive behaviour. In these cases, opers may look at the KLINE command to keep them from rejoining the network for a longer time.

As nicknames across an IRC network MUST be unique, if duplicates are found when servers join, one or both of the clients MAY be `KILL`ed and removed from the network. Servers may also handle this case in alternate ways that don't involve removing users from the network.

Servers MAY restrict whether specific operators can remove users on other servers (remote users). If the operator tries to remove a remote user but is not privileged to, they should receive the {% numeric ERR_NOPRIVS %} numeric.

`<comment>` SHOULD reflect why the `KILL` was performed. For user-generated `KILL`s, it is up to the user to provide an adequate reason.

Numeric Replies:

* {% numeric ERR_NOSUCHSERVER %}
* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOPRIVILEGES %}
* {% numeric ERR_NOPRIVS %}

<div class="warning">
    <p>NOTE: The <tt>KILL</tt> message is weird, and I need to look at it more closely, add some examples, etc.</p>
</div>

### REHASH message

         Command: REHASH
      Parameters: None

The `REHASH` command is an administrative command which can be used by an operator to force the local server to re-read and process its configuration file.
This may include other data, such as modules or TLS certificates.

Servers MAY accept, as an optional argument, the name of a remote server that should be rehashed instead of the current one.

Numeric replies:

* {% numeric RPL_REHASHING %}
* {% numeric ERR_NOPRIVILEGES %}

Example:

     REHASH                          ; message from user with operator
                                     status to server asking it to reread
                                     its configuration file.

### RESTART message

         Command: RESTART
      Parameters: None

An operator can use the restart command to force the server to restart itself.
This message is optional since it may be viewed as a risk to allow arbitrary people to connect to a server as an operator and execute this command, causing (at least) a disruption to service.

Numeric replies:

* {% numeric ERR_NOPRIVILEGES %}

Example:

     RESTART                         ; no parameters required.

### SQUIT message

         Command: SQUIT
      Parameters: <server> <comment>

The `SQUIT` command disconnects a server from the network. `SQUIT` is a privileged command and is only available to IRC Operators. `<comment>` is the reason why the server link is being disconnected.

In a traditional spanning-tree topology, the command gets forwarded to the specified server. And the link between the specified server and the last server to propagate the command gets broken.

Numeric replies:

* {% numeric ERR_NOSUCHSERVER %}
* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOPRIVILEGES %}
* {% numeric ERR_NOPRIVS %}

Examples:

     SQUIT tolsun.oulu.fi :Bad Link ?  ; Command to uplink of the server
                                     tolson.oulu.fi to terminate its
                                     connection with comment "Bad Link".

