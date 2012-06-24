# Slimux

This is a SLIME inspired tmux integration plugin for Vim. It makes it easy to interact
with different tmux panes directly from Vim. It has two styles for interacting
with panes. REPL and Shell styles.

REPL commands are designed to work with various Read Eval Print Loops such as
`python`, `irb` (Ruby), `node` (Javascript), `coffee` (CoffeeScript) etc.
This is loosely modelled after [SLIME for Emacs][SLIME]. Shell commands are designed
to work with normal shells such as `bash`. These are useful for running tests for
example.

Main difference between these is pane configuration visibility. Each buffer has
own configuration for REPL, but for Shell there is only one global
configuration. The configuration is prompted from user when the commands are
used for the first time. The configuration happens interactively. You will see
list of available tmux panes and you can choose one by hitting enter on top of
one.

Also REPL commands can have custom pre, post and escape hooks. These allows
interaction with some more complex REPLs such as the CoffeeScript REPL.

This plugin borrows ideas and some code from [vim-slime][].


Blog post

http://esa-matti.suuronen.org/blog/2012/04/19/slimux-tmux-plugin-for-vim/

Ascii.io screencast

http://ascii.io/a/409


## Installation

Use [pathogen][] and put files to
`$HOME/.vim/bundle/slimux/`

Slimux requires fairly recent tmux version. Be sure you have 1.5.x or later.

## REPL Commands

### SlimuxREPLSendLine

Send current line to configured pane.

### SlimuxREPLSendSelection

Send last visually selected text to configured pane.

### SlimuxREPLConfigure

Prompt pane configuration for current buffer.


## Shell Commands

### SlimuxShellPrompt

Prompt for a shell command and send it to configured tmux pane.

### SlimuxShellLast

Rerun last shell command.

### SlimuxShellRun

Specify a shell command to run directly, without the prompt:

    :SlimuxShellRun rspec spec/foo_spec.rb

Suitable for mapping and other automation.

Note that you need to double any escapes intended for the shell using this command.
E.g. to list files with actual asterisks in their name:

    :SlimuxShellRun ls \\*

### SlimuxShellConfigure

Prompt global pane configuration for the shell commands.


## Keyboard Shortcuts

Slimux does not force any shortcuts on your Vim, but here's something you can
put to your `.vimrc`

    map <Leader>s :SlimuxREPLSendLine<CR>
    vmap <Leader>s :SlimuxREPLSendSelection<CR>
    map <Leader>a :SlimuxShellLast<CR>

Or if you like something more Emacs Slime style try something like this:

    map <C-c><C-c> :SlimuxREPLSendLine<CR>
    vmap <C-c><C-c> :SlimuxREPLSendSelection<CR>

You may also add shortcuts to other commands too.


## Adding support for new languages

Usually new there is no need to do anything. For example Ruby and Node.js REPLs
works just fine out of box, but for some languages you have to do some preprocessing
before the code can be sent. There are three hooks you can specify for
each language.

Custom escaping function

    function SlimuxEscape_<filetype>(text)
        return a:text
    endfunction

Pre send hook

    function SlimuxPre_<filetype>(target_pane)
    endfunction

Post send hook

    function SlimuxPost_<filetype>(target_pane)
    endfunction

Just add these to ftplugin directory contained within this plugin (and sent a pull request on Github!).
You can use [Python][] and [CoffeeScript][] hooks as examples.




## Other Vim Slime plugins

Before I created this plugin I tried several others, but non of them satisfied me. They where too
complicated or just didn't support the languages I needed. So if Slimux isn't your cup of tea,
maybe one of these is:

  * <https://github.com/jpalardy/vim-slime>
  * <https://github.com/benmills/vimux>
  * <https://github.com/kikijump/tslime.vim>
  * <https://github.com/jgdavey/vim-turbux>
  * <http://www.vim.org/scripts/script.php?script_id=2531>
  * <https://github.com/ervandew/screen>



[tmux]: http://tmux.sourceforge.net/
[pathogen]: https://github.com/tpope/vim-pathogen
[vim-slime]: https://github.com/jpalardy/vim-slime
[SLIME]: http://common-lisp.net/project/slime/

[Python]: https://github.com/epeli/slimux/blob/master/ftplugin/python.vim
[CoffeeScript]: https://github.com/epeli/slimux/blob/master/ftplugin/coffee.vim
