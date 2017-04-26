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
---

{% include copyrights.html %}

<div class="note">
    <p>This document describes what I consider to be almost universally understood formatting. It is a <a href="./about.html#living-specification">living specification</a> which is updated in response to feedback and implementations as they change.</p>
    <p>If I've missed out on some formatting character or method which is understood by a majority of IRC software in use today, or have made a mistake in this document, please <a href="https://github.com/ircdocs/modern-irc/issues">open an issue</a> or <a href="mailto:daniel@danieloaks.net">contact me</a>.</p>
</div>

<div id="printable-toc" style="display: none"></div>

---


# Introduction

IRC clients today understand a number of special formatting characters. These characters allow IRC software to send and receive colors and formatting codes such as bold, italics, underline and others.

Over the years, many clients have attempted to create their own methods of formatting and there have been variations and extensions of almost every method. However, the characters and codes described in this document are understood fairly consistently across clients today.

Following what's described in this document should let your software send and interpret formatting in a fairly sane way, consistent with how most other IRC software out there does. Using formatting characters and methods not described in this document is possible, but it should be assumed they will not work across most clients (unless there is some way to fall back to what's defined here).

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC2119](http://tools.ietf.org/html/rfc2119).


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

Clients may allow users to prevent all or just specified formatting from displaying. This can help users that are colorblind or are visually impared, and should be considered by client authors.


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

This formatting character works as a toggle. It enables bold text (i.e. <strong>bold text</strong>).

## Italics

    ASCII 0x1D

This formatting character works as a toggle. It enables italicized text (i.e. <em>italicised text</em>).

## Underline

    ASCII 0x1F

This formatting character works as a toggle. It enables underlined text (i.e. <u>underlined text</u>).

## Color

    ASCII 0x03

This formatting character sets or resets colors on the following text.

With this formatting code, colors are represented as ASCII digits.

### Forms of Color Codes

In the following list, `<CODE>` represents the color formatting character `(0x03)`, `<COLOR>` represents one or two ASCII digits (either `0-9` or `00-15`).

The use of this code can take on the following forms:

* `<CODE>` - Reset foreground and background colors.
* `<CODE>,` - Reset foreground and background colors and display the `,` character as text.
* `<CODE><COLOR>` - Set the foreground color.
* `<CODE><COLOR>,` - Set the foreground color and display the `,` character as text.
* `<CODE><COLOR>,<COLOR>` - Set the foreground and background color.

The foreground color is the first `<COLOR>`, and the background color is the second `<COLOR>` (if sent).

If only the foreground color is set, the background color stays the same.

<div class="warning">
    <p>If there are two ASCII digits available where a <tt>&lt;COLOR&gt;</tt> is allowed, if the two characters are in the range <tt>00-15</tt> then two characters MUST always be read for it. If they are in the range <tt>16-99</tt>, the client MAY unconditionally read and process the two characters, or the client MAY read just the first digit and display the second digit.</p>

    <p>Clients SHOULD NOT send the digits <tt>16-99</tt> where a <tt>&lt;COLOR&gt;</tt> is allowed, as clients will interpret it differently.</p>
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

<div class="note">
    NOTE: The colors displayed here are simply a guide. The actual RGB values used for these codes will depend on what the client author has defined, and are often defined by the terminal color scheme for terminal-based clients.
</div>

<div class="warning">
    WARNING: Clients SHOULD NOT send color codes <tt>16-99</tt>. As noted above, they will be interpreted different ways by different clients and we do not recommend using them.
</div>

### Mistaken Eating of Text

When sending color codes `0-9`, clients may use either the one-digit `(3)` or two-digit `(03)` versions of it. However, since two digits are always used if available, if the text following the color code starts with a digit, the last `<COLOR>` MUST use the two-digit version to be displayed correctly. This ensures that the first character of the text does not get interpreted as part of the formatting code.

If the text immediately following a code setting a foreground color consists of something like `",13"`, it will get interpreted as setting the background rather than text. In this example, clients can put the color code either after the comma character or before the character in front of the comma character to avoid this. They can also put a different formatting code after the comma to ensure that the number does not get interpreted as part of the color code (for instance, two bold characters in a row, which will cancel each other out as they are toggles).


## Hex Color

    ASCII 0x04

Some clients support an alternate form of conveying colours using hex codes.

Following this character are six hex digits representing the Red, Green and Blue values of the colour to display (e.g. `FF0000` means <span style="color:#ff0000">bright red</span>).

Keep the [Forms of Color Codes](#forms-of-color-codes) section above in mind, as this method of formatting keeps these same rules – the exceptions being that `<CODE>` represents the hex color character `(0x03)` and `<COLOR>` represents a six-digit hex value as `RRGGBB`.

This method of formatting is not as widely-supported as the colors above, but clients are fine to implement it without any issues.


## Reverse Color (/ or Italics)

    ASCII 0x16

This formatting character switches the foreground and background colors of the following text. It can act similarly to a toggle, in that every time it is used it switches the colors for the text following it.

<div class="warning">
    WARNING: As noted in the title of this section, <tt>(0x16)</tt> may also represent italics in some clients (those clients that do usually represent Reverse Color with the character <tt>(0x12)</tt> instead). Honestly, it's probably about half-half (two of the major clients I checked both handled this differently), so I'd recommend not using this code.
</div>


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
* <div><tt>Code: &nbsp; Rules: Don't spam 5<span class="reverse">C</span>13,8,6<span class="reverse">C</span>,7,8, and especially not <span class="reverse">B</span>9<span class="reverse">B</span><span class="reverse">I</span>!</tt><br/><tt>Output: Don't spam 5<span class="ircf-13 ircb-8">,6</span>,7,8, and especially not <span class="ircb">9</span><span class="irci">!</span></tt></div>

