### MOTD message

         Command: MOTD
      Parameters: [<target>]

The `MOTD` command is used to get the "Message of the Day" of the given server. If `<target>` is not given, the MOTD of the server the client is connected to should be returned.

If `<target>` is a server, the MOTD for that server is requested. If `<target>` is given and a matching server cannot be found, the server will respond with the `ERR_NOSUCHSERVER` numeric and the command will fail.

If the MOTD can be found, one `RPL_MOTDSTART` numeric is returned, followed by one or more `RPL_MOTD` numeric, then one `RPL_ENDOFMOTD` numeric.

If the MOTD does not exist or could not be found, the `ERR_NOMOTD` numeric is returned.

Numeric Replies:

* {% numeric ERR_NOSUCHSERVER %}
* {% numeric ERR_NOMOTD %}
* {% numeric RPL_MOTDSTART %}
* {% numeric RPL_MOTD %}
* {% numeric RPL_ENDOFMOTD %}

{% messageheader VERSION %}

         Command: VERSION
      Parameters: [<target>]

The `VERSION` command is used to query the version of the software and the [`RPL_ISUPPORT` parameters](#rplisupport-parameters) of the given server. If `<target>` is not given, the information for the server the client is connected to should be returned.

If `<target>` is a server, the information for that server is requested. If `<target>` is a client, the information for the server that client is connected to is requested. If `<target>` is given and a matching server cannot be found, the server will respond with the `ERR_NOSUCHSERVER` numeric and the command will fail.

Wildcards are allowed in the `<target>` parameter.

Upon receiving a `VERSION` command, the given server SHOULD respond with one `RPL_VERSION` reply and one or more `RPL_ISUPPORT` replies.

Numeric Replies:

* {% numeric ERR_NOSUCHSERVER %}
* {% numeric RPL_ISUPPORT %}
* {% numeric RPL_VERSION %}

Command Examples:

      :Wiz VERSION *.se               ; message from Wiz to check the
                                      version of a server matching "*.se"

      VERSION tolsun.oulu.fi          ; check the version of server
                                      "tolsun.oulu.fi".

### ADMIN message

         Command: ADMIN
      Parameters: [<target>]

The `ADMIN` command is used to find the name of the administrator of the given server. If `<target>` is not given, the information for the server the client is connected to should be returned.

If `<target>` is a server, the information for that server is requested. If `<target>` is a client, the information for the server that client is connected to is requested. If `<target>` is given and a matching server cannot be found, the server will respond with the `ERR_NOSUCHSERVER` numeric and the command will fail.

Wildcards are allowed in the `<target>` parameter.

Upon receiving an `ADMIN` command, the given server SHOULD respond with the `RPL_ADMINME`, `RPL_ADMINLOC1`, `RPL_ADMINLOC2`, and `RPL_ADMINEMAIL` replies.

Numeric Replies:

* {% numeric ERR_NOSUCHSERVER %}
* {% numeric RPL_ADMINME %}
* [`RPL_ADMINLOC1`](#rpladminloc1-257) `(257)`
* [`RPL_ADMINLOC2`](#rpladminloc2-258) `(258)`
* {% numeric RPL_ADMINEMAIL %}

Command Examples:

      ADMIN tolsun.oulu.fi            ; request an ADMIN reply from
                                      tolsun.oulu.fi

      ADMIN syrk                      ; ADMIN request for the server to
                                      which the user syrk is connected

### CONNECT message

         Command: CONNECT
      Parameters: <target server> [<port> [<remote server>]]

The `CONNECT` command forces a server to try to establish a new connection to another server. `CONNECT` is a privileged command and is available only to IRC Operators. If a remote server is given, the connection is attempted by that remote server to `<target server>` using `<port>`.

Numeric Replies:

* {% numeric ERR_NOSUCHSERVER %}
* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOPRIVILEGES %}
* {% numeric ERR_NOPRIVS %}

Command Examples:

      CONNECT tolsun.oulu.fi
      ; Attempt to connect the current server to tololsun.oulu.fi

      CONNECT  eff.org 12765 csd.bu.edu
      ; Attempt to connect csu.bu.edu to eff.org on port 12765

### LINKS message

         Command: LUSERS
      Parameters: None

With LINKS, a user can list all servers which are known by the server answering the query, usually including the server itself.

In replying to the LINKS message, a server MUST send replies back using zero or more {% numeric RPL_LINKS %} messages and mark the end of the list using a {% numeric RPL_ENDOFLINKS %} message.

Servers MAY omit some or all servers on the network, including itself.

Numeric Replies:

* {% numeric ERR_UNKNOWNCOMMAND %}
* {% numeric RPL_LINKS %}
* {% numeric RPL_ENDOFLINKS %}

### LUSERS message

         Command: LUSERS
      Parameters: None

Returns statistics about local and global users, as numeric replies.

Servers MUST reply with `RPL_LUSERCLIENT` and `RPL_LUSERME`, and SHOULD also include
all those defined below.

Clients SHOULD NOT try to parse the free-form text in the trailing parameter,
and rely on specific parameters instead.

* {% numeric RPL_LUSERCLIENT %}
* {% numeric RPL_LUSEROP %}
* {% numeric RPL_LUSERUNKNOWN %}
* {% numeric RPL_LUSERCHANNELS %}
* {% numeric RPL_LUSERME %}
* {% numeric RPL_LOCALUSERS %}
* {% numeric RPL_GLOBALUSERS %}

### TIME message

         Command: TIME
      Parameters: [<server>]

The `TIME` command is used to query local time from the specified server. If the server parameter is not given, the server handling the command must reply to the query.

Numeric Replies:

* {% numeric ERR_NOSUCHSERVER %}
* {% numeric RPL_TIME %}

Command Examples:

      TIME tolsun.oulu.fi             ; check the time on the server
                                      "tolson.oulu.fi"

      :Angel TIME *.au                ; user angel checking the time on a
                                      server matching "*.au"

### STATS message

         Command: STATS
      Parameters: <query> [<server>]

The `STATS` command is used to query statistics of a certain server. The specific queries supported by this command depend on the server that replies, although the server must be able to supply information as described by the queries below (or similar).

A query may be given by any single letter which is only checked by the destination server and is otherwise passed on by intermediate servers, ignored and unaltered.

The following queries are those found in current IRC implementations and provide a large portion of the setup and runtime information for that server. All servers should be able to supply a valid reply to a `STATS` query which is consistent with the reply formats currently used and the purpose of the query.

The currently supported queries are:

* `c` - returns a list of servers which the server may connect to or allow connections from;
* `h` - returns a list of servers which are either forced to be treated as leaves or allowed to act as hubs;
* `i` - returns a list of hosts which the server allows a client to connect from;
* `k` - returns a list of banned username/hostname combinations for that server;
* `l` - returns a list of the server's connections, showing how long each connection has been established and the traffic over that connection in bytes and messages for each direction;
* `m` - returns a list of commands supported by the server and the usage count for each if the usage count is non zero;
* `o` - returns a list of hosts from which normal clients may become operators;
* `u` - returns a string showing how long the server has been up.
* `y` - show Y (Class) lines from server's configuration file;

<div class="warning">
    Need to give this a good look-over. It's probably quite incorrect.
</div>

Numeric Replies:

* {% numeric ERR_NOSUCHSERVER %}
* {% numeric ERR_NEEDMOREPARAMS %}
* {% numeric ERR_NOPRIVILEGES %}
* {% numeric ERR_NOPRIVS %}
* {% numeric RPL_STATSCLINE %}
* {% numeric RPL_STATSHLINE %}
* {% numeric RPL_STATSILINE %}
* {% numeric RPL_STATSKLINE %}
* {% numeric RPL_STATSLLINE %}
* {% numeric RPL_STATSOLINE %}
* {% numeric RPL_STATSLINKINFO %}
* {% numeric RPL_STATSUPTIME %}
* {% numeric RPL_STATSCOMMANDS %}
* {% numeric RPL_ENDOFSTATS %}

Command Examples:

      STATS m                         ; check the command usage for the
                                      server you are connected to

      :Wiz STATS c eff.org            ; request by WiZ for C/N line
                                      information from server eff.org

### HELP message

         Command: HELP
      Parameters: [<subject>]

The `HELP` command is used to return documentation about the IRC server and the IRC commands it implements.

When receiving a `HELP` command, servers MUST either: reply with a single {% numeric ERR_HELPNOTFOUND %} message; or reply with a single {% numeric RPL_HELPSTART %} message, then arbitrarily many {% numeric RPL_HELPTXT %} messages, then a single {% numeric RPL_ENDOFHELP %}. Servers MAY return the {% numeric RPL_HELPTXT %} form for unknown subjects, especially if their reply would not fit in a single line.

The {% numeric RPL_HELPSTART %} message SHOULD be some sort of title and the first {% numeric RPL_HELPTXT %} message SHOULD be empty. This is what most servers do today.

Servers MAY define any `<subject>` they want.
Servers typically have documentation for most of the IRC commands they support.

Clients SHOULD gracefully handle older servers that reply to `HELP` with a set of {% command NOTICE %} messages.
On these servers, the client may try sending the `HELPOP` command (with the same syntax specified here), which may return the numeric-based reply.

Clients SHOULD also gracefully handle servers that reply to `HELP` with a set of `290`/`291`/`292`/`293`/`294`/`295` numerics.

Numerics:

* {% numeric ERR_HELPNOTFOUND %}
* {% numeric RPL_HELPSTART %}
* {% numeric RPL_HELPTXT %}
* {% numeric RPL_ENDOFHELP %}

Command Examples:

      HELP                                                     ; request generic help
      :server 704 val * :** Help System **                     ; first line
      :server 705 val * :
      :server 705 val * :Try /HELP <command> for specific help,
      :server 705 val * :/HELP USERCMDS to list available
      :server 706 val * :commands, or join the #help channel   ; last line

      HELP PRIVMSG                                             ; request help on PRIVMSG
      :server 704 val PRIVMSG :** The PRIVMSG command **
      :server 705 val PRIVMSG :
      :server 705 val PRIVMSG :The /PRIVMSG command is the main way
      :server 706 val PRIVMSG :to send messages to other users.

      HELP :unknown subject                                    ; request help on "unknown subject"
      :server 524 val * :I do not know anything about this

      HELP :unknown subject
      :server 704 val * :** Help System **
      :server 705 val * :
      :server 705 val * :I do not know anything about this.
      :server 705 val * :
      :server 705 val * :Try /HELP USERCMDS to list available
      :server 706 val * :commands, or join the #help channel

### INFO message

         Command: INFO
      Parameters: None

The `INFO` command is used to return information which describes the server. This information usually includes the software name/version and its authors. Some other info that may be returned includes the patch level and compile date of the server, the copyright on the server software, and whatever miscellaneous information the server authors consider relevant.

Upon receiving an `INFO` command, the server will respond with zero or more `RPL_INFO` replies, followed by one `RPL_ENDOFINFO` numeric.

Numeric Replies:

* {% numeric RPL_INFO %}
* {% numeric RPL_ENDOFINFO %}

Command Examples:

     INFO                            ; request info from the server

### MODE message

         Command: MODE
      Parameters: <target> [<modestring> [<mode arguments>...]]

The `MODE` command is used to set or remove options (or *modes*) from a given target.

#### User mode

If `<target>` is a nickname that does not exist on the network, the {% numeric ERR_NOSUCHNICK %} numeric is returned. If `<target>` is a different nick than the user who sent the command, the {% numeric ERR_USERSDONTMATCH %} numeric is returned.

If `<modestring>` is not given, the {% numeric RPL_UMODEIS %} numeric is sent back containing the current modes of the target user.

If `<modestring>` is given, the supplied modes will be applied, and a `MODE` message will be sent to the user containing the changed modes. If one or more modes sent are not implemented on the server, the server MUST apply the modes that are implemented, and then send the {% numeric ERR_UMODEUNKNOWNFLAG %} in reply along with the `MODE` message.

#### Channel mode

If `<target>` is a channel that does not exist on the network, the {% numeric ERR_NOSUCHCHANNEL %} numeric is returned.

If `<modestring>` is not given, the {% numeric RPL_CHANNELMODEIS %} numeric is returned. Servers MAY choose to hide sensitive information such as channel keys when sending the current modes. Servers MAY also return the {% numeric RPL_CREATIONTIME %} numeric following `RPL_CHANNELMODEIS`.

If `<modestring>` is given, the user sending the command MUST have appropriate channel privileges on the target channel to change the modes given. If a user does not have appropriate privileges to change modes on the target channel, the server MUST not process the message, and {% numeric ERR_CHANOPRIVSNEEDED %} numeric is returned.
If the user has permission to change modes on the target, the supplied modes will be applied based on the type of the mode (see below).
For type A, B, and C modes, arguments will be sequentially obtained from `<mode arguments>`. If a type B or C mode does not have a parameter when being set, the server MUST ignore that mode.
If a type A mode has been sent without an argument, the contents of the list MUST be sent to the user, unless it contains sensitive information the user is not allowed to access.
When the server is done processing the modes, a `MODE` command is sent to all members of the channel containing the mode changes. Servers MAY choose to hide sensitive information when sending the mode changes.

---

`<modestring>` starts with a plus `('+',` `0x2B)` or minus `('-',` `0x2D)` character, and is made up of the following characters:

* **`'+'`**: Adds the following mode(s).
* **`'-'`**: Removes the following mode(s).
* **`'a-zA-Z'`**: Mode letters, indicating which modes are to be added/removed.

The ABNF representation for `<modestring>` is:

      modestring  =  1*( modeset )
      modeset     =  plusminus *( modechar )
      plusminus   =  %x2B / %x2D
                       ; + or -
      modechar    =  ALPHA

There are four categories of channel modes, defined as follows:

* **Type A**: Modes that add or remove an address to or from a list. These modes MUST always have a parameter when sent from the server to a client. A client MAY issue this type of mode without an argument to obtain the current contents of the list. The numerics used to retrieve contents of Type A modes depends on the specific mode. Also see the {% isupport EXTBAN %} parameter.
* **Type B**: Modes that change a setting on a channel. These modes MUST always have a parameter.
* **Type C**: Modes that change a setting on a channel. These modes MUST have a parameter when being set, and MUST NOT have a parameter when being unset.
* **Type D**: Modes that change a setting on a channel. These modes MUST NOT have a parameter.

Channel mode letters, along with their types, are defined in the {% isupport CHANMODES %} parameter. User mode letters are always **Type D** modes.

The meaning of standard (and/or well-used) channel and user mode letters can be found in the [Channel Modes](#channel-modes) and [User Modes](#user-modes) sections. The meaning of any mode letters not in this list are defined by the server software and configuration.

---

Type A modes are lists that can be viewed. The method of viewing these lists is not standardised across modes and different numerics are used for each. The specific numerics used for these are outlined here:

* **[Ban List `"+b"`](#ban-channel-mode)**: Ban lists are returned with zero or more {% numeric RPL_BANLIST %} numerics, followed by one {% numeric RPL_ENDOFBANLIST %} numeric.
* **[Exception List `"+e"`](#exception-channel-mode)**: Exception lists are returned with zero or more {% numeric RPL_EXCEPTLIST %} numerics, followed by one {% numeric RPL_ENDOFEXCEPTLIST %} numeric.
* **[Invite-Exception List `"+I"`](#invite-exception-channel-mode)**: Invite-exception lists are returned with zero or more {% numeric RPL_INVITELIST %} numerics, followed by one {% numeric RPL_ENDOFINVITELIST %} numeric.

After the initial `MODE` command is sent to the server, the client receives the above numerics detailing the entries that appear on the given list. Servers MAY choose to restrict the above information to channel operators, or to only those clients who have permissions to change the given list.

---

Command Examples:

      MODE dan +i                     ; Setting the "invisible" user mode on dan.

      MODE #foobar +mb *@127.0.0.1    ; Setting the "moderated" channel mode and
                                      adding the "*@127.0.0.1" mask to the ban
                                      list of the #foobar channel.

Message Examples:

      :dan!~h@localhost MODE #foobar -bl+i *@192.168.0.1
                                      ; dan unbanned the "*@192.168.0.1" mask,
                                      removed the client limit from, and set the
                                      #foobar channel to invite-only.

      :irc.example.com MODE #foobar +o bunny
                                      ; The irc.example.com server gave channel
                                      operator privileges to bunny on #foobar.

