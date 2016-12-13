---
title: Direct Client-to-Client Protocol (DCC)
layout: default
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
    <p>This document intends to be a useful overview and reference of DCC as it is implemented today. It is a <a href="./about.html#living-specification">living specification</a> which is updated in response to feedback and implementations as they change. This document describes existing behaviour and what we consider best practices for new software.</p>
    <p>If something written in here isn't interoperable with an IRC client you know of, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a>.</p>
</div>

<div id="printable-toc" style="display: none"></div>


---


# Introduction

The Direct Client-to-Client Protocol (DCC) has been the primary method of establishing connections directly between IRC clients for a long time now. Once established, DCC connections bypass the IRC network and allow for all sorts of data to be transferred between clients including files and direct chat sessions.

There have been many extensions to DCC through the years. This document intends to describe DCC as it works today, and provide a specification for new client authors implementing this feature.
