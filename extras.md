---
title: Other Not-Uncommon IRC Features And Commands
layout: default
wip: true
copyrights:
  -
    name: "Daniel Oaks"
    org: "ircdocs"
    org_link: "http://ircdocs.horse/"
    email: "daniel@danieloaks.net"
    editor: true
---

{% include copyrights.html %}

<div class="note">
    <p>This document describes a subset of IRC functionality out there which I think is important for client and server authors to think about. It's a collection of different commands and functions that help make IRC what it is. This document is a <a href="./about.html#living-specification">living specification</a> which is updated in response to feedback and implementations as they change.</p>
    <p>If there's something you think should be added here, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a> or <a href="mailto:daniel@danieloaks.net">contact me</a>.</p>
</div>

<div class="warning">
    <p>NOTE: This document is a heavy work-in-progress right now, and you shouldn't blindly implement everything in here. The features and commands in this section <strong>are not standard</strong> and you should evaluate them closely by looking at the ecosystem as a whole.</p>
    <p>You can contribute by sending pull requests to our <a href="https://github.com/ircdocs/modern-irc">Github repository</a>!</p>
</div>

<div id="printable-toc" style="display: none"></div>

---


# Introduction

There are a lot of IRC commands and features out there that simply aren't documented, aren't entirely standardised, but are used on a fair number of servers out there. This document intends to outline a subset of those which I think deserve to be looked into closely by server developers, and possibly standardised in the future.

Due to what this document talks about, it's not structured like a standard specification on this site. Each major section discusses a new command or feature.


---


# IRC Ban 'Lines'

Being able to easily ban clients from your server, or your whole network, can be very useful. These days, most servers out there support dynamically banning clients, or even entire IP addresses / networks. This is done through ban lines.

Particularly if you've been an oper, you've probably seen people talk about k-lines, g-lines, and all other sorts of 'lines'. Each of these types of 'lines' bans users in different ways, and using different information.

Here are some examples of which attributes can be evaluated to ban clients:

- Connecting from a given IP address or network.
- Matching a given nickmask after connection registration has completed.
- Having a given realname (GECOS) field.

As well, clients can either be banned only on the local server, or across the entire network.

Because of the combination of these different requirements, and the different scopes that they can be applied for, servers have made new letters for many of these.

Here are some *line types referred to often and what they mean:

- **D-Line**: IP address / net banning of clients, usually on a single server.
- **K-Line**: Nickmask banning of clients, usually on a single server.
- **X-Line**: Any type of line. Usually used in configuration and when talking about lines in general.

They're named lines because older versions of the IRC server used a plaintext configuration file where every single line was a different directive. For instance, K-Lines represented masks to ban from the server, and all types of other lines existed. This is also why being an IRC Operator is sometimes called having an O-Line.


## Command Format

This section is not yet written.
