"=============================================================================
" README.
" 1. What is this plugin?
"   This plugin add simple REPL support for racket.
"
"   Like slime for emacs or slimv for vim except that this is much simpler and
"   comunicate via slimux instead of swank connection.
"
" 2. Default Key bindings.
"   Note: This leader is Slimux_racket specific, the same to g:mapleader by
"   default.
"
"   <Leader>d -- evaluate the top block which the cursor is in.
"   <Leader>b -- evaluate the whole buffer
"   <Leader>p -- Prompt for input and send it directly to the REPL.
"   <Leader>q -- Send 'C-c' to the REPL
"   <Leader>k -- Prompt for a key and send it.
"
"   If you have enabled xrepl, we have the following addtional key bindings:
"
"   <leader>t -- Return to the 'top-level' anamespace
"   <leader>w -- search documentation for the word under curser
"
" 3. Configurations.
"   a) To disable this plugin
"       add `let g:slimux_racket_loaded=1` to your vimrc
"
"   b) To enable default keybindings (recommended)
"       let g:slimux_racket_keybindings=1
"       let g:slimux_racket_xrepl = 1    " set this if you have xrepl enabled.
"
"   c) To change the default leader, want to change it to ';' for example.
"       let g:slimux_racket_leader=';'
"=============================================================================

" Settings {{{1
" Whether to load this plugin or not.
if exists("g:slimux_racket_loaded")
    finish
endif
let g:slimux_racket_loaded= 1

" set Custom <Leader> for the slimux_racket plugin
if !exists('g:slimux_racket_leader')
    if exists( 'mapleader' ) && mapleader != ' '
        let g:slimux_racket_leader = mapleader
    else
        let g:slimux_racket_leader = ','
    endif
endif

" slimux_racket keybinding set (0 = no keybindings)
if !exists('g:slimux_racket_keybindings')
    let g:slimux_racket_keybindings = 0
endif

" slimux_racket_xrepl (0 = no xrepl support)
if !exists('g:slimux_racket_xrepl')
    let g:slimux_racket_xrepl = 0
else
    let g:slimux_racket_xrepl = 1
endif

" Add racket support for normal SlimuxSendSelection {{{1

function! SlimuxEscape_racket(text)
    " if text does not end with newline, add one
    if a:text !~ "\n$"
        let str_ret = a:text . '\n'
    else
        let str_ret = a:text
    endif

    return str_ret
endfunction


" Function Definitions {{{1

" Evaluate a racket 'define' statement
function! Slimux_racket_eval_defun()
    let pos = getpos(".")
    let regContent = @"
    let s:skip_sc = 'synIDattr(synID(line("."), col("."), 0), "name") =~ "[Ss]tring\\|[Cc]omment"'
    let [lhead, chead] = searchpairpos( '(', '', ')', 'bW', s:skip_sc)
    call cursor(lhead, chead)
    silent! exec "normal! 99[(yab"
    if getline('.')[0] == '('
        call SlimuxSendCode(@" . "\n")
    else
        call SlimuxSendCode(getline('.') . "\n")
    endif
    " restore contents
    let @" = regContent
    call setpos('.', pos)
endfunction

" Evaluate the entire buffer
function! Slimux_racket_eval_buffer()
    if g:slimux_racket_xrepl
        call SlimuxSendCode(',enter (file "' . expand('%:p') . '")' . "\n")
    else
        call SlimuxSendCode(join(getline(1, '$'), "\n") . "\n")
    endif
endfunction

" return to top-level namespace
function! Slimux_racket_top()
    if g:slimux_racket_xrepl
        call SlimuxSendCode(',top' . "\n")
    endif
endfunction

" lookup word in the online doc
function! Slimux_racket_doc(...)
    if g:slimux_racket_xrepl
        echomsg a:0
        if a:0 <= 0
            let s:word = expand("<cword>")
        else
            let s:word = a:1
        endif
        call SlimuxSendCode(',doc ' . s:word . "\n")
    endif
endfunction

" Send User break
function! Slimux_racket_break()
    call SlimuxSendKeys('C-c enter')
endfunction

" Change functions to commands {{{1
command! SlimuxRacketEvalDefun call Slimux_racket_eval_defun()
command! SlimuxRacketEvalBuffer call Slimux_racket_eval_buffer()
command! SlimuxRacketTop call Slimux_racket_top()
command! -nargs=? SlimuxRacketDoc call Slimux_racket_doc(<f-args>)
command! SlimuxRacketBreak call Slimux_racket_break()

" Set keybindings {{{1
if g:slimux_racket_keybindings == 1
    execute 'noremap <buffer> <silent> ' . g:slimux_racket_leader.'d :SlimuxRacketEvalDefun<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_racket_leader.'b :SlimuxRacketEvalBuffer<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_racket_leader.'p :SlimuxShellPrompt<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_racket_leader.'k :SlimuxSendKeysPrompt<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_racket_leader.'t :SlimuxRacketTop<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_racket_leader.'w :SlimuxRacketDoc<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_racket_leader.'q :SlimuxRacketBreak<CR>'
endif
