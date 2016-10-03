Simple Python Completion Source for Auto-Complete
=================================================
This file provides a completion source for Auto-Complete:
http://www.emacswiki.org/emacs/AutoComplete
It is derived from the excellent ac-python by Chris Poole, downloadable from
http://chrispoole.com/downloads/ac-python.el

Keywords: vc tools

Package: ac-python-async

Package-Requires: ((auto-complete "1.5.0") (deferred "20150309.2052"))

Installation
------------

Setup Auto-Complete in the usual fashion, and make sure it gets loaded for
python buffers. Then, place this file in your load-path, and add

    (require 'ac-python-async)

to your .emacs file (after loading Auto-Complete).

Improves upon the original ac-python by evaluating the auto-complete string
asynchronously, using the deferred library to run the completion in a separate emacs
process.  This substantially reduces lag as the editor constantly attempts
auto-complete as the cursor moves around the buffer.

Usage
-----

Python symbols will be completed by Auto-Complete, once Emacs learns about
these symbols. This is the short-coming of the plugin, but it's a small
price to pay.

To teach Emacs about symbols in imported modules, Emacs needs to execute
the Python source. This can be accomplished with `python-send-buffer` for
example, often bound to `C-c C-c`. If a python process is already running,
this is essentially instantaneous.

Version: 20150925

License: MIT

Author: Jason Bell  <jbellthor@gmail.com>

Based on ac-python by Chris Poole:

<chris@chrispoole.com>

More information: http://chrispoole.com/project/emacs/ac-python/
