# Slimux

Slimux is an [tmux][] integration plugin for Vim. It makes it easy to interact
with different tmux panes directly from Vim. It has two styles for interacting
with panes. REPL and Shell styles.

REPL commands are designed to work with various Read Eval Print Loops such as
`python`, `irb` (Ruby), `node` (Javascript), `coffee` (CoffeeScript) etc.
Shell commands are designed to work with normal shells such as `bash`.

Main difference between these is pane configuration visibility. Each buffer has
own configuration for REPL, but for Shell there is only one global
configuration. The configuration is prompted from user when the commands are
used for the first time. The configuration happens interactively. You will see
list of available tmux panes and you can choose one by hitting enter on top of
one.

Also REPL commands can have custom pre, post and escape hooks. These allow
interaction with some more complex REPLs such as the CoffeeScript REPL.

This plugin borrows ideas and some code from [vim-slime][].


## Installation

Use [pahtogen][] and put files to
`$HOME/.vim/bundle/slimux/`


## REPL Commands

### SlimuxREPLSendLine

Send current line to configured pane.

### SlimuxREPLSendSelection

Send last visually selected text to configured pane.

### SlimuxREPLConfigure

Prompt pane configuration for current buffer.


## Shell Commands

### SlimuxShellPromt

Promt for a shell command and send it to configured tmux pane.

### SlimuxShellLast

Rerun last shell command.

### SlimuxShellConfigure

Prompt global pane configuration for the shell commands.


## Keyboard Shortcuts

Slimux does not force shortcuts on your Vim, but here's something you
can put to your `.vimrc`

    map <Leader>s :SlimuxREPLSendLine<CR>
    vmap <Leader>s :SlimuxREPLSendSelection<CR>
    map <Leader>a :SlimuxShellLast<CR>


You may also add shortcuts to other commands too.

[tmux]: http://tmux.sourceforge.net/
[pahtogen]: https://github.com/tpope/vim-pathogen
[vim-slime]: https://github.com/jpalardy/vim-slime



