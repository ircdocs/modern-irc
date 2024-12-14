---
title: IRC Formatting
layout: default
copyrights:
  -
    name: "Daniel Oaks"
    org: "ircdocs"
    org_link: "http://ircdocs.horse/"
    email: "daniel@danieloaks.net"
    editor: true
toc: true
---

{% include copyrights.html %}

<div class="note">
    <p>This document describes what I consider to be almost universally understood formatting. It is a <a href="./about.html#living-specification">living specification</a> which is updated in response to feedback and implementations as they change.</p>
    <p>If I've missed out on some formatting character or method which is understood by a majority of IRC software in use today, or have made a mistake in this document, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a> or <a href="mailto:daniel@danieloaks.net">contact me</a>.</p>
</div>

---


# Introduction

IRC clients today understand a number of special formatting characters. These characters allow IRC software to send and receive colors and formatting codes such as bold, italics, underline and others.

Over the years, many clients have attempted to create their own methods of formatting and there have been variations and extensions of almost every method. However, the characters and codes described in this document are understood fairly consistently across clients today.

Following what's described in this document should let your software send and interpret formatting in a fairly sane way, consistent with how most other IRC software out there does. Using formatting characters and methods not described in this document is possible, but it should be assumed they will not work across most clients (unless there is some way to fall back to what's defined here).

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).


<!--toc-->

---


# Formatting Uses

Formatting is widely used in IRC. In this section, we outline the places where formatting is traditionally used by clients and allowed by servers. This is not an expansive list nor does it note everywhere formatting is used, just some of the most common places.


## Messages / Numerics

Formatting characters can be used in lots of IRC messages and numerics. This is not a complete list, just some of the messages formatting codes are used with most often.

These are some of the messages and features formatting codes are normally used with:

* [`PRIVMSG`](/index.html#privmsg-message)
* [`NOTICE`](/index.html#notice-message)
* [`TOPIC`](/index.html#topic-message)
* [`AWAY`](/index.html#away-message)
* [`USER`](/index.html#user-message) (allowed in realnames, <strong>not</strong> in usernames)
* The [Message of the Day](/index.html#motd-message)

And the numerics containing content associated with these messages and features.


## Names

Formatting is allowed and commonly used in realnames (set with the [`USER`](/index.html#user-message) command when the client joins the network).

On some networks and with some server software, vhosts (vanity hostnames) may contain formatting characters and codes. Hostnames sent to clients MAY contain formatting, and clients SHOULD display them with this in mind.

The use of formatting MUST NOT be allowed in nicknames, user names or channel names. This is to avoid confusion and prevent issues, particularly with clients that have disabled the rendering of colors / formatting or cannot display certain types of formatting.

If a client sends a [`USER`](/index.html#user-message) command with any formatting codes in the first parameter (in the username) during registration, the server SHOULD send the client an [`ERROR`](/index.html#error-message) message and close the connection.


---


# Client Behaviour

This section is non-normative and outlines suggested behaviour for clients and client interfaces.


## Limitations

If an IRC client cannot display a specified type of formatting, the client should do one of the following:

* Simply not display the formatting.
* Display the formatting character in an obvious way, so users are aware that it was used.

One way some clients represent formatting characters they cannot display is using an uppercase letter which represents the specific formatting character, with their default foreground and background colors switched. For example, displaying an underline formatting character as <span class="reverse">U</span>.


## Preventing Display of Formatting

Clients may allow users to prevent all or just specified formatting from displaying. This can help users that are colorblind or are visually impaired, and should be considered by client authors.


## ANSI Escape Code Support

IRC clients supporting ANSI formatting was, historically, due to clients outputting messages via terminals that supported ANSI escape codes. Many IRC clients today do not display through an interface that natively supports ANSI escape codes, and so must implement this behaviour themselves if they wish to support it.

Clients can support or not support ANSI escape codes as they like. However, they should implement this feature with the knowledge that a large number of IRC clients today, even those using a terminal interface, do not support displaying text formatted using ANSI escape codes.


---


# Characters

There are a number of formatting characters that are parsed and understood by IRC software today.

Some formatting codes work as a toggle, i.e. with the first instance of the character, the specified formatting is enabled for the following text. After the next instance of that character, that formatting is disabled for the following characters. Formatting codes that work in this way are called 'togglable'.

These formatting characters are the ones all IRC clients should understand.

## Bold

    ASCII 0x02

This formatting character works as a toggle. It enables bold text (e.g. <strong>bold text</strong>).

## Italics

    ASCII 0x1D

This formatting character works as a toggle. It enables italicized text (e.g. <em>italicised text</em>).

## Underline

    ASCII 0x1F

This formatting character works as a toggle. It enables underlined text (e.g. <u>underlined text</u>).

## Strikethrough

    ASCII 0x1E

This formatting character works as a toggle. It enables strikethrough'd text (e.g. <span style="text-decoration: line-through">strokethrough text</span>).

This character is a relatively new addition, and was defined by Textual. As of right now, at least HexChat, IRCCloud, Konversation, The Lounge and Textual are known to support it.

## Monospace

    ASCII 0x11

This formatting character works as a toggle. It enables monospace'd text (e.g. <tt>monospace text</tt>).

This character is a relatively new addition, and was defined by IRCCloud. However, a number of other clients including TheLounge and Textual now support this as well, and it's now the defacto formatting character for monospace text.

## Color

    ASCII 0x03

This formatting character sets or resets colors on the following text.

With this formatting code, colors are represented as ASCII digits.

### Forms of Color Codes

In the following list, `<CODE>` represents the color formatting character `(0x03)`, `<COLOR>` represents one or two ASCII digits (either `0-9` or `00-99`).

The use of this code can take on the following forms:

* `<CODE>` - Reset foreground and background colors.
* `<CODE>,` - Reset foreground and background colors and display the `,` character as text.
* `<CODE><COLOR>` - Set the foreground color.
* `<CODE><COLOR>,` - Set the foreground color and display the `,` character as text.
* `<CODE><COLOR>,<COLOR>` - Set the foreground and background color.

The foreground color is the first `<COLOR>`, and the background color is the second `<COLOR>` (if sent).

If only the foreground color is set, the background color stays the same.

<div class="warning">
    <p>If there are two ASCII digits available where a <tt>&lt;COLOR&gt;</tt> is allowed, then two characters MUST always be read for it and displayed as described below.</p>
</div>

### Colors

The following colors are defined for use with this formatting character:

* <tt><span class="ircb-0">&nbsp;&nbsp;</span> - 00</tt> - White.
* <tt><span class="ircb-1">&nbsp;&nbsp;</span> - 01</tt> - Black.
* <tt><span class="ircb-2">&nbsp;&nbsp;</span> - 02</tt> - Blue.
* <tt><span class="ircb-3">&nbsp;&nbsp;</span> - 03</tt> - Green.
* <tt><span class="ircb-4">&nbsp;&nbsp;</span> - 04</tt> - Red.
* <tt><span class="ircb-5">&nbsp;&nbsp;</span> - 05</tt> - Brown.
* <tt><span class="ircb-6">&nbsp;&nbsp;</span> - 06</tt> - Magenta.
* <tt><span class="ircb-7">&nbsp;&nbsp;</span> - 07</tt> - Orange.
* <tt><span class="ircb-8">&nbsp;&nbsp;</span> - 08</tt> - Yellow.
* <tt><span class="ircb-9">&nbsp;&nbsp;</span> - 09</tt> - Light Green.
* <tt><span class="ircb-10">&nbsp;&nbsp;</span> - 10</tt> - Cyan.
* <tt><span class="ircb-11">&nbsp;&nbsp;</span> - 11</tt> - Light Cyan.
* <tt><span class="ircb-12">&nbsp;&nbsp;</span> - 12</tt> - Light Blue.
* <tt><span class="ircb-13">&nbsp;&nbsp;</span> - 13</tt> - Pink.
* <tt><span class="ircb-14">&nbsp;&nbsp;</span> - 14</tt> - Grey.
* <tt><span class="ircb-15">&nbsp;&nbsp;</span> - 15</tt> - Light Grey.
* <tt><span class="ircb-1">&nbsp;</span><span class="ircb-0">&nbsp;</span> - 99</tt> - Default Foreground/Background - Not universally supported.

In addition, the table below describes the commonly-used colors for codes 16-98.

<div class="note">
    NOTE: The colors displayed here are simply a guide. The actual RGB values used for these codes will depend on what the client author has defined, and are often defined by the terminal color scheme for terminal-based clients.
</div>


### Mistaken Eating of Text

When sending color codes `0-9`, clients may use either the one-digit `(3)` or two-digit `(03)` versions of it. However, since two digits are always used if available, if the text following the color code starts with a digit, the last `<COLOR>` MUST use the two-digit version to be displayed correctly. This ensures that the first character of the text does not get interpreted as part of the formatting code.

If the text immediately following a code setting a foreground color consists of something like `",13"`, it will get interpreted as setting the background rather than text. In this example, clients can put the color code either after the comma character or before the character in front of the comma character to avoid this. They can also put a different formatting code after the comma to ensure that the number does not get interpreted as part of the color code (for instance, two bold characters in a row, which will cancel each other out as they are toggles).


### 'Spoilers'

If the background and foreground colors are the same for a section of text, on 'hovering over' or selecting this text these colours should be replaced with readable alternatives. For example:

<style>
    .spoiler {
        background: #222;
        color: #222;
        font-size: 1.1em;
        padding: 0.2em 0.25em;
    }
    .spoiler:hover {
        color: #f7f7f7;
    }
</style>
<span class="spoiler"><tt>this is spoilered text</tt></span>


### Colors 16-98

When you receive the color codes 16-98, you should display them using the RGB values in this table:

<style>
    .colorcode {
        display: block;
        font-size: 1.1em;
    }
    .hexcode {
        font-size: 0.8em;
    }
    .rgb-table .hexcode::before {
        content: "#";
    }
    .ansi-table .hexcode::before {
        content: "ANSI ";
    }
    .ondark .hexcode::before {
        color: rgba(245, 245, 245, 0.73);
    }
    .onlight .hexcode::before {
        color: rgba(10, 10, 10, 0.73);
    }
    .ondark {
        color: #f7f7f7;
    }
    .onlight {
        color: #131313;
    }
    .color-table {
        text-align: center;
        width: 100%;
    }
    .color-table td {
        padding: 0.2em 0.6em;
    }
</style>

<table class="rgb-table color-table pure-table">
    <tr>
        <td class="ondark" style="background:#470000">
            <span class="colorcode">16</span>
            <span class="hexcode">470000</span>
        </td>
        <td class="ondark" style="background:#472100">
            <span class="colorcode">17</span>
            <span class="hexcode">472100</span>
        </td>
        <td class="ondark" style="background:#474700">
            <span class="colorcode">18</span>
            <span class="hexcode">474700</span>
        </td>
        <td class="ondark" style="background:#324700">
            <span class="colorcode">19</span>
            <span class="hexcode">324700</span>
        </td>
        <td class="ondark" style="background:#004700">
            <span class="colorcode">20</span>
            <span class="hexcode">004700</span>
        </td>
        <td class="ondark" style="background:#00472c">
            <span class="colorcode">21</span>
            <span class="hexcode">00472c</span>
        </td>
        <td class="ondark" style="background:#004747">
            <span class="colorcode">22</span>
            <span class="hexcode">004747</span>
        </td>
        <td class="ondark" style="background:#002747">
            <span class="colorcode">23</span>
            <span class="hexcode">002747</span>
        </td>
        <td class="ondark" style="background:#000047">
            <span class="colorcode">24</span>
            <span class="hexcode">000047</span>
        </td>
        <td class="ondark" style="background:#2e0047">
            <span class="colorcode">25</span>
            <span class="hexcode">2e0047</span>
        </td>
        <td class="ondark" style="background:#470047">
            <span class="colorcode">26</span>
            <span class="hexcode">470047</span>
        </td>
        <td class="ondark" style="background:#47002a">
            <span class="colorcode">27</span>
            <span class="hexcode">47002a</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#740000">
            <span class="colorcode">28</span>
            <span class="hexcode">740000</span>
        </td>
        <td class="ondark" style="background:#743a00">
            <span class="colorcode">29</span>
            <span class="hexcode">743a00</span>
        </td>
        <td class="ondark" style="background:#747400">
            <span class="colorcode">30</span>
            <span class="hexcode">747400</span>
        </td>
        <td class="ondark" style="background:#517400">
            <span class="colorcode">31</span>
            <span class="hexcode">517400</span>
        </td>
        <td class="ondark" style="background:#007400">
            <span class="colorcode">32</span>
            <span class="hexcode">007400</span>
        </td>
        <td class="ondark" style="background:#007449">
            <span class="colorcode">33</span>
            <span class="hexcode">007449</span>
        </td>
        <td class="ondark" style="background:#007474">
            <span class="colorcode">34</span>
            <span class="hexcode">007474</span>
        </td>
        <td class="ondark" style="background:#004074">
            <span class="colorcode">35</span>
            <span class="hexcode">004074</span>
        </td>
        <td class="ondark" style="background:#000074">
            <span class="colorcode">36</span>
            <span class="hexcode">000074</span>
        </td>
        <td class="ondark" style="background:#4b0074">
            <span class="colorcode">37</span>
            <span class="hexcode">4b0074</span>
        </td>
        <td class="ondark" style="background:#740074">
            <span class="colorcode">38</span>
            <span class="hexcode">740074</span>
        </td>
        <td class="ondark" style="background:#740045">
            <span class="colorcode">39</span>
            <span class="hexcode">740045</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#b50000">
            <span class="colorcode">40</span>
            <span class="hexcode">b50000</span>
        </td>
        <td class="ondark" style="background:#b56300">
            <span class="colorcode">41</span>
            <span class="hexcode">b56300</span>
        </td>
        <td class="ondark" style="background:#b5b500">
            <span class="colorcode">42</span>
            <span class="hexcode">b5b500</span>
        </td>
        <td class="ondark" style="background:#7db500">
            <span class="colorcode">43</span>
            <span class="hexcode">7db500</span>
        </td>
        <td class="ondark" style="background:#00b500">
            <span class="colorcode">44</span>
            <span class="hexcode">00b500</span>
        </td>
        <td class="ondark" style="background:#00b571">
            <span class="colorcode">45</span>
            <span class="hexcode">00b571</span>
        </td>
        <td class="ondark" style="background:#00b5b5">
            <span class="colorcode">46</span>
            <span class="hexcode">00b5b5</span>
        </td>
        <td class="ondark" style="background:#0063b5">
            <span class="colorcode">47</span>
            <span class="hexcode">0063b5</span>
        </td>
        <td class="ondark" style="background:#0000b5">
            <span class="colorcode">48</span>
            <span class="hexcode">0000b5</span>
        </td>
        <td class="ondark" style="background:#7500b5">
            <span class="colorcode">49</span>
            <span class="hexcode">7500b5</span>
        </td>
        <td class="ondark" style="background:#b500b5">
            <span class="colorcode">50</span>
            <span class="hexcode">b500b5</span>
        </td>
        <td class="ondark" style="background:#b5006b">
            <span class="colorcode">51</span>
            <span class="hexcode">b5006b</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#ff0000">
            <span class="colorcode">52</span>
            <span class="hexcode">ff0000</span>
        </td>
        <td class="ondark" style="background:#ff8c00">
            <span class="colorcode">53</span>
            <span class="hexcode">ff8c00</span>
        </td>
        <td class="onlight" style="background:#ffff00">
            <span class="colorcode">54</span>
            <span class="hexcode">ffff00</span>
        </td>
        <td class="onlight" style="background:#b2ff00">
            <span class="colorcode">55</span>
            <span class="hexcode">b2ff00</span>
        </td>
        <td class="onlight" style="background:#00ff00">
            <span class="colorcode">56</span>
            <span class="hexcode">00ff00</span>
        </td>
        <td class="onlight" style="background:#00ffa0">
            <span class="colorcode">57</span>
            <span class="hexcode">00ffa0</span>
        </td>
        <td class="onlight" style="background:#00ffff">
            <span class="colorcode">58</span>
            <span class="hexcode">00ffff</span>
        </td>
        <td class="ondark" style="background:#008cff">
            <span class="colorcode">59</span>
            <span class="hexcode">008cff</span>
        </td>
        <td class="ondark" style="background:#0000ff">
            <span class="colorcode">60</span>
            <span class="hexcode">0000ff</span>
        </td>
        <td class="ondark" style="background:#a500ff">
            <span class="colorcode">61</span>
            <span class="hexcode">a500ff</span>
        </td>
        <td class="ondark" style="background:#ff00ff">
            <span class="colorcode">62</span>
            <span class="hexcode">ff00ff</span>
        </td>
        <td class="ondark" style="background:#ff0098">
            <span class="colorcode">63</span>
            <span class="hexcode">ff0098</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#ff5959">
            <span class="colorcode">64</span>
            <span class="hexcode">ff5959</span>
        </td>
        <td class="onlight" style="background:#ffb459">
            <span class="colorcode">65</span>
            <span class="hexcode">ffb459</span>
        </td>
        <td class="onlight" style="background:#ffff71">
            <span class="colorcode">66</span>
            <span class="hexcode">ffff71</span>
        </td>
        <td class="onlight" style="background:#cfff60">
            <span class="colorcode">67</span>
            <span class="hexcode">cfff60</span>
        </td>
        <td class="onlight" style="background:#6fff6f">
            <span class="colorcode">68</span>
            <span class="hexcode">6fff6f</span>
        </td>
        <td class="onlight" style="background:#65ffc9">
            <span class="colorcode">69</span>
            <span class="hexcode">65ffc9</span>
        </td>
        <td class="onlight" style="background:#6dffff">
            <span class="colorcode">70</span>
            <span class="hexcode">6dffff</span>
        </td>
        <td class="onlight" style="background:#59b4ff">
            <span class="colorcode">71</span>
            <span class="hexcode">59b4ff</span>
        </td>
        <td class="ondark" style="background:#5959ff">
            <span class="colorcode">72</span>
            <span class="hexcode">5959ff</span>
        </td>
        <td class="ondark" style="background:#c459ff">
            <span class="colorcode">73</span>
            <span class="hexcode">c459ff</span>
        </td>
        <td class="ondark" style="background:#ff66ff">
            <span class="colorcode">74</span>
            <span class="hexcode">ff66ff</span>
        </td>
        <td class="ondark" style="background:#ff59bc">
            <span class="colorcode">75</span>
            <span class="hexcode">ff59bc</span>
        </td>
    </tr>
    <tr>
        <td class="onlight" style="background:#ff9c9c">
            <span class="colorcode">76</span>
            <span class="hexcode">ff9c9c</span>
        </td>
        <td class="onlight" style="background:#ffd39c">
            <span class="colorcode">77</span>
            <span class="hexcode">ffd39c</span>
        </td>
        <td class="onlight" style="background:#ffff9c">
            <span class="colorcode">78</span>
            <span class="hexcode">ffff9c</span>
        </td>
        <td class="onlight" style="background:#e2ff9c">
            <span class="colorcode">79</span>
            <span class="hexcode">e2ff9c</span>
        </td>
        <td class="onlight" style="background:#9cff9c">
            <span class="colorcode">80</span>
            <span class="hexcode">9cff9c</span>
        </td>
        <td class="onlight" style="background:#9cffdb">
            <span class="colorcode">81</span>
            <span class="hexcode">9cffdb</span>
        </td>
        <td class="onlight" style="background:#9cffff">
            <span class="colorcode">82</span>
            <span class="hexcode">9cffff</span>
        </td>
        <td class="onlight" style="background:#9cd3ff">
            <span class="colorcode">83</span>
            <span class="hexcode">9cd3ff</span>
        </td>
        <td class="onlight" style="background:#9c9cff">
            <span class="colorcode">84</span>
            <span class="hexcode">9c9cff</span>
        </td>
        <td class="onlight" style="background:#dc9cff">
            <span class="colorcode">85</span>
            <span class="hexcode">dc9cff</span>
        </td>
        <td class="onlight" style="background:#ff9cff">
            <span class="colorcode">86</span>
            <span class="hexcode">ff9cff</span>
        </td>
        <td class="onlight" style="background:#ff94d3">
            <span class="colorcode">87</span>
            <span class="hexcode">ff94d3</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#000000">
            <span class="colorcode">88</span>
            <span class="hexcode">000000</span>
        </td>
        <td class="ondark" style="background:#131313">
            <span class="colorcode">89</span>
            <span class="hexcode">131313</span>
        </td>
        <td class="ondark" style="background:#282828">
            <span class="colorcode">90</span>
            <span class="hexcode">282828</span>
        </td>
        <td class="ondark" style="background:#363636">
            <span class="colorcode">91</span>
            <span class="hexcode">363636</span>
        </td>
        <td class="ondark" style="background:#4d4d4d">
            <span class="colorcode">92</span>
            <span class="hexcode">4d4d4d</span>
        </td>
        <td class="ondark" style="background:#656565">
            <span class="colorcode">93</span>
            <span class="hexcode">656565</span>
        </td>
        <td class="ondark" style="background:#818181">
            <span class="colorcode">94</span>
            <span class="hexcode">818181</span>
        </td>
        <td class="ondark" style="background:#9f9f9f">
            <span class="colorcode">95</span>
            <span class="hexcode">9f9f9f</span>
        </td>
        <td class="onlight" style="background:#bcbcbc">
            <span class="colorcode">96</span>
            <span class="hexcode">bcbcbc</span>
        </td>
        <td class="onlight" style="background:#e2e2e2">
            <span class="colorcode">97</span>
            <span class="hexcode">e2e2e2</span>
        </td>
        <td class="onlight" style="background:#ffffff">
            <span class="colorcode">98</span>
            <span class="hexcode">ffffff</span>
        </td>
        <td></td>
    </tr>
</table>

If displaying this on an ANSI terminal, these ANSI color codes should be used:

<table class="ansi-table color-table pure-table">
    <tr>
        <td class="ondark" style="background:#470000">
            <span class="colorcode">16</span>
            <span class="hexcode">52</span>
        </td>
        <td class="ondark" style="background:#472100">
            <span class="colorcode">17</span>
            <span class="hexcode">94</span>
        </td>
        <td class="ondark" style="background:#474700">
            <span class="colorcode">18</span>
            <span class="hexcode">100</span>
        </td>
        <td class="ondark" style="background:#324700">
            <span class="colorcode">19</span>
            <span class="hexcode">58</span>
        </td>
        <td class="ondark" style="background:#004700">
            <span class="colorcode">20</span>
            <span class="hexcode">22</span>
        </td>
        <td class="ondark" style="background:#00472c">
            <span class="colorcode">21</span>
            <span class="hexcode">29</span>
        </td>
        <td class="ondark" style="background:#004747">
            <span class="colorcode">22</span>
            <span class="hexcode">23</span>
        </td>
        <td class="ondark" style="background:#002747">
            <span class="colorcode">23</span>
            <span class="hexcode">24</span>
        </td>
        <td class="ondark" style="background:#000047">
            <span class="colorcode">24</span>
            <span class="hexcode">17</span>
        </td>
        <td class="ondark" style="background:#2e0047">
            <span class="colorcode">25</span>
            <span class="hexcode">54</span>
        </td>
        <td class="ondark" style="background:#470047">
            <span class="colorcode">26</span>
            <span class="hexcode">53</span>
        </td>
        <td class="ondark" style="background:#47002a">
            <span class="colorcode">27</span>
            <span class="hexcode">89</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#740000">
            <span class="colorcode">28</span>
            <span class="hexcode">88</span>
        </td>
        <td class="ondark" style="background:#743a00">
            <span class="colorcode">29</span>
            <span class="hexcode">130</span>
        </td>
        <td class="ondark" style="background:#747400">
            <span class="colorcode">30</span>
            <span class="hexcode">142</span>
        </td>
        <td class="ondark" style="background:#517400">
            <span class="colorcode">31</span>
            <span class="hexcode">64</span>
        </td>
        <td class="ondark" style="background:#007400">
            <span class="colorcode">32</span>
            <span class="hexcode">28</span>
        </td>
        <td class="ondark" style="background:#007449">
            <span class="colorcode">33</span>
            <span class="hexcode">35</span>
        </td>
        <td class="ondark" style="background:#007474">
            <span class="colorcode">34</span>
            <span class="hexcode">30</span>
        </td>
        <td class="ondark" style="background:#004074">
            <span class="colorcode">35</span>
            <span class="hexcode">25</span>
        </td>
        <td class="ondark" style="background:#000074">
            <span class="colorcode">36</span>
            <span class="hexcode">18</span>
        </td>
        <td class="ondark" style="background:#4b0074">
            <span class="colorcode">37</span>
            <span class="hexcode">91</span>
        </td>
        <td class="ondark" style="background:#740074">
            <span class="colorcode">38</span>
            <span class="hexcode">90</span>
        </td>
        <td class="ondark" style="background:#740045">
            <span class="colorcode">39</span>
            <span class="hexcode">125</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#b50000">
            <span class="colorcode">40</span>
            <span class="hexcode">124</span>
        </td>
        <td class="ondark" style="background:#b56300">
            <span class="colorcode">41</span>
            <span class="hexcode">166</span>
        </td>
        <td class="ondark" style="background:#b5b500">
            <span class="colorcode">42</span>
            <span class="hexcode">184</span>
        </td>
        <td class="ondark" style="background:#7db500">
            <span class="colorcode">43</span>
            <span class="hexcode">106</span>
        </td>
        <td class="ondark" style="background:#00b500">
            <span class="colorcode">44</span>
            <span class="hexcode">34</span>
        </td>
        <td class="ondark" style="background:#00b571">
            <span class="colorcode">45</span>
            <span class="hexcode">49</span>
        </td>
        <td class="ondark" style="background:#00b5b5">
            <span class="colorcode">46</span>
            <span class="hexcode">37</span>
        </td>
        <td class="ondark" style="background:#0063b5">
            <span class="colorcode">47</span>
            <span class="hexcode">33</span>
        </td>
        <td class="ondark" style="background:#0000b5">
            <span class="colorcode">48</span>
            <span class="hexcode">19</span>
        </td>
        <td class="ondark" style="background:#7500b5">
            <span class="colorcode">49</span>
            <span class="hexcode">129</span>
        </td>
        <td class="ondark" style="background:#b500b5">
            <span class="colorcode">50</span>
            <span class="hexcode">127</span>
        </td>
        <td class="ondark" style="background:#b5006b">
            <span class="colorcode">51</span>
            <span class="hexcode">161</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#ff0000">
            <span class="colorcode">52</span>
            <span class="hexcode">196</span>
        </td>
        <td class="ondark" style="background:#ff8c00">
            <span class="colorcode">53</span>
            <span class="hexcode">208</span>
        </td>
        <td class="onlight" style="background:#ffff00">
            <span class="colorcode">54</span>
            <span class="hexcode">226</span>
        </td>
        <td class="onlight" style="background:#b2ff00">
            <span class="colorcode">55</span>
            <span class="hexcode">154</span>
        </td>
        <td class="onlight" style="background:#00ff00">
            <span class="colorcode">56</span>
            <span class="hexcode">46</span>
        </td>
        <td class="onlight" style="background:#00ffa0">
            <span class="colorcode">57</span>
            <span class="hexcode">86</span>
        </td>
        <td class="onlight" style="background:#00ffff">
            <span class="colorcode">58</span>
            <span class="hexcode">51</span>
        </td>
        <td class="ondark" style="background:#008cff">
            <span class="colorcode">59</span>
            <span class="hexcode">75</span>
        </td>
        <td class="ondark" style="background:#0000ff">
            <span class="colorcode">60</span>
            <span class="hexcode">21</span>
        </td>
        <td class="ondark" style="background:#a500ff">
            <span class="colorcode">61</span>
            <span class="hexcode">171</span>
        </td>
        <td class="ondark" style="background:#ff00ff">
            <span class="colorcode">62</span>
            <span class="hexcode">201</span>
        </td>
        <td class="ondark" style="background:#ff0098">
            <span class="colorcode">63</span>
            <span class="hexcode">198</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#ff5959">
            <span class="colorcode">64</span>
            <span class="hexcode">203</span>
        </td>
        <td class="onlight" style="background:#ffb459">
            <span class="colorcode">65</span>
            <span class="hexcode">215</span>
        </td>
        <td class="onlight" style="background:#ffff71">
            <span class="colorcode">66</span>
            <span class="hexcode">227</span>
        </td>
        <td class="onlight" style="background:#cfff60">
            <span class="colorcode">67</span>
            <span class="hexcode">191</span>
        </td>
        <td class="onlight" style="background:#6fff6f">
            <span class="colorcode">68</span>
            <span class="hexcode">83</span>
        </td>
        <td class="onlight" style="background:#65ffc9">
            <span class="colorcode">69</span>
            <span class="hexcode">122</span>
        </td>
        <td class="onlight" style="background:#6dffff">
            <span class="colorcode">70</span>
            <span class="hexcode">87</span>
        </td>
        <td class="onlight" style="background:#59b4ff">
            <span class="colorcode">71</span>
            <span class="hexcode">111</span>
        </td>
        <td class="ondark" style="background:#5959ff">
            <span class="colorcode">72</span>
            <span class="hexcode">63</span>
        </td>
        <td class="ondark" style="background:#c459ff">
            <span class="colorcode">73</span>
            <span class="hexcode">177</span>
        </td>
        <td class="ondark" style="background:#ff66ff">
            <span class="colorcode">74</span>
            <span class="hexcode">207</span>
        </td>
        <td class="ondark" style="background:#ff59bc">
            <span class="colorcode">75</span>
            <span class="hexcode">205</span>
        </td>
    </tr>
    <tr>
        <td class="onlight" style="background:#ff9c9c">
            <span class="colorcode">76</span>
            <span class="hexcode">217</span>
        </td>
        <td class="onlight" style="background:#ffd39c">
            <span class="colorcode">77</span>
            <span class="hexcode">223</span>
        </td>
        <td class="onlight" style="background:#ffff9c">
            <span class="colorcode">78</span>
            <span class="hexcode">229</span>
        </td>
        <td class="onlight" style="background:#e2ff9c">
            <span class="colorcode">79</span>
            <span class="hexcode">193</span>
        </td>
        <td class="onlight" style="background:#9cff9c">
            <span class="colorcode">80</span>
            <span class="hexcode">157</span>
        </td>
        <td class="onlight" style="background:#9cffdb">
            <span class="colorcode">81</span>
            <span class="hexcode">158</span>
        </td>
        <td class="onlight" style="background:#9cffff">
            <span class="colorcode">82</span>
            <span class="hexcode">159</span>
        </td>
        <td class="onlight" style="background:#9cd3ff">
            <span class="colorcode">83</span>
            <span class="hexcode">153</span>
        </td>
        <td class="onlight" style="background:#9c9cff">
            <span class="colorcode">84</span>
            <span class="hexcode">147</span>
        </td>
        <td class="onlight" style="background:#dc9cff">
            <span class="colorcode">85</span>
            <span class="hexcode">183</span>
        </td>
        <td class="onlight" style="background:#ff9cff">
            <span class="colorcode">86</span>
            <span class="hexcode">219</span>
        </td>
        <td class="onlight" style="background:#ff94d3">
            <span class="colorcode">87</span>
            <span class="hexcode">212</span>
        </td>
    </tr>
    <tr>
        <td class="ondark" style="background:#000000">
            <span class="colorcode">88</span>
            <span class="hexcode">16</span>
        </td>
        <td class="ondark" style="background:#131313">
            <span class="colorcode">89</span>
            <span class="hexcode">233</span>
        </td>
        <td class="ondark" style="background:#282828">
            <span class="colorcode">90</span>
            <span class="hexcode">235</span>
        </td>
        <td class="ondark" style="background:#363636">
            <span class="colorcode">91</span>
            <span class="hexcode">237</span>
        </td>
        <td class="ondark" style="background:#4d4d4d">
            <span class="colorcode">92</span>
            <span class="hexcode">239</span>
        </td>
        <td class="ondark" style="background:#656565">
            <span class="colorcode">93</span>
            <span class="hexcode">241</span>
        </td>
        <td class="ondark" style="background:#818181">
            <span class="colorcode">94</span>
            <span class="hexcode">244</span>
        </td>
        <td class="ondark" style="background:#9f9f9f">
            <span class="colorcode">95</span>
            <span class="hexcode">247</span>
        </td>
        <td class="onlight" style="background:#bcbcbc">
            <span class="colorcode">96</span>
            <span class="hexcode">250</span>
        </td>
        <td class="onlight" style="background:#e2e2e2">
            <span class="colorcode">97</span>
            <span class="hexcode">254</span>
        </td>
        <td class="onlight" style="background:#ffffff">
            <span class="colorcode">98</span>
            <span class="hexcode">231</span>
        </td>
        <td></td>
    </tr>
</table>


## Hex Color

    ASCII 0x04

Some clients support an alternate form of conveying colours using hex codes.

Following this character are six hex digits representing the Red, Green and Blue values of the colour to display (e.g. `FF0000` means <span style="color:#ff0000">bright red</span>).

Keep the [Forms of Color Codes](#forms-of-color-codes) section above in mind, as this method of formatting keeps these same rules – the exceptions being that `<CODE>` represents the hex color character `(0x04)` and `<COLOR>` represents a six-digit hex value as `RRGGBB`.

This method of formatting is not as widely-supported as the colors above, but clients are fine to parse them without any negative effects.


## Reverse Color

    ASCII 0x16

This formatting character works as a toggle. When reverse color is enabled, the foreground and background text colors are reversed. For instance, if you enable reverse color and then send the line "<span class="reverse">C</span>3,13Test!", you will end up with pink foreground text and green background text while the reverse color is in effect.

This code isn't super well-supported, and mIRC seems to always treat it as applying the reverse of the default foreground and background characters, rather than the current fore/background as set by prior mIRC color codes in the message.


## Reset

    ASCII 0x0F

This formatting character resets all formatting. It removes the bold, italics, and underline formatting, and sets the foreground and background colors back to the default for the client display. The text following this character will use or display no formatting, until other formatting characters are encountered.


---


# Examples

In this section, the color formatting character `(0x03)` is displayed as <span class="reverse">C</span>, the bold character `(0x02)` is displayed as <span class="reverse">B</span>, the italics character `(0x1D)` is displayed as <span class="reverse">I</span>, and the reset character `(0x0F)` is displayed as <span class="reverse">O</span>.

Each example displays both the raw IRC code sent, and then a formatted version of the output.

* <div><tt>Code: &nbsp; I love <span class="reverse">C</span>3IRC! <span class="reverse">C</span>It is the <span class="reverse">C</span>7best protocol ever!</tt><br/><tt>Output: I love <span class="ircf-3">IRC! </span>It is the <span class="ircf-7">best protocol ever!</span></tt></div>
* <div><tt>Code: &nbsp; This is a <span class="reverse">I</span><span class="reverse">C</span>13,9cool <span class="reverse">C</span>message</tt><br/><tt>Output: This is a <span class="irci"><span class="ircf-13 ircb-9">cool </span>message</span></tt></div>
* <div><tt>Code: &nbsp; IRC <span class="reverse">B</span>is <span class="reverse">C</span>4,12so <span class="reverse">C</span>great<span class="reverse">O</span>!</tt><br/><tt>Output: IRC <span class="ircb">is <span class="ircf-4 ircb-12">so </span>great</span>!</tt></div>
* <div><tt>Code: &nbsp; Rules: Don't spam 5<span class="reverse">C</span>13,8,6<span class="reverse">C</span>,7,8, and especially not <span class="reverse">B</span>9<span class="reverse">B</span><span class="reverse">I</span>!</tt><br/><tt>Output: Rules: Don't spam 5<span class="ircf-13 ircb-8">,6</span>,7,8, and especially not <span class="ircb">9</span><span class="irci">!</span></tt></div>


---


# Acknowledgements

Thanks to [Nei](http://anti.teamidiot.de/static/nei/*/extended_mirc_color_proposal.html) for some guidance on the extended color codes!
