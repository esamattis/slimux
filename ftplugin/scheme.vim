"=============================================================================
" README.
" 1. What is this plugin?
"   This plugin add simple REPL support for scheme.
"
"   Like slime for emacs or slimv for vim except that this is much simpler and
"   comunicate via slimux instead of swank connection.
"
" 2. Default Key bindings.
"   Note: This leader is Slimux_Scheme specific, the same to g:mapleader by
"   default.
"
"   <Leader>d -- evaluate the top block which the cursor is in.
"   <Leader>p -- Prompt for input and send it directly to the REPL.
"   <Leader>k -- Prompt for a key and send it.
"   <Leader>q -- quit debug. => (RESTART 1)
"   <Leader>1..9 -- send (RESTART <1..9>) to the REPL.
"
" 3. Configurations.
"   a) To disable this plugin
"       add `let g:slimux_scheme_loaded=1` to your vimrc
"
"   b) To enable default keybindings (recommended)
"       let g:slimux_scheme_keybindings=1
"
"   c) To change the default leader, want to change it to ';' for example.
"       let g:slimux_scheme_leader=';'
"=============================================================================

" Settings {{{1
" Whether to load this plugin or not.
if exists("g:slimux_scheme_loaded")
    finish
endif
let g:slimux_scheme_loaded= 1

" set Custom <Leader> for the slimux_scheme plugin
if !exists('g:slimux_scheme_leader')
    if exists( 'mapleader' ) && mapleader != ' '
        let g:slimux_scheme_leader = mapleader
    else
        let g:slimux_scheme_leader = ','
    endif
endif

" slimux_scheme keybinding set (0 = no keybindings)
if !exists('g:slimux_scheme_keybindings')
    let g:slimux_scheme_keybindings = 0
endif

" Add scheme support for normal SlimuxSendSelection {{{1

function! SlimuxEscape_scheme(text)
    " if text does not end with newline, add one
    if a:text !~ "\n$"
        let str_ret = a:text . '\n'
    else
        let str_ret = a:text
    endif

    return str_ret
endfunction


" Function Definitions {{{1

" Evaluate a scheme 'define' statement
function! Slimux_scheme_eval_defun()
    let pos = getpos(".")
    silent! exec "normal! 99[(yab"
    call SlimuxSendCode(@" . "\n")
    call setpos('.', pos)
endfunction

" Evaluate the entire buffer
function! Slimux_scheme_eval_buffer()
    call SlimuxSendCode(join(getline(1, '$'), "\n") . "\n")
endfunction

" invoke restart by number
function! Slimux_scheme_restart_by_number(num)
    let sent_text="(restart ". a:num .")\n"
    call SlimuxSendCode(sent_text)
endfunction

" Change functions to commands {{{1
command! SlimuxSchemeEvalDefun call Slimux_scheme_eval_defun()
command! SlimuxSchemeEvalBuffer call Slimux_scheme_eval_buffer()
command! -nargs=1 SlimuxSchemeRestartByNum call Slimux_scheme_restart_by_number(<args>)

" Set keybindings {{{1
if g:slimux_scheme_keybindings == 1
    execute 'noremap <buffer> <silent> ' . g:slimux_scheme_leader.'d :SlimuxSchemeEvalDefun<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_scheme_leader.'b :SlimuxSchemeEvalBuffer<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_scheme_leader.'p :SlimuxShellPrompt<CR>'
    execute 'noremap <buffer> <silent> ' . g:slimux_scheme_leader.'k :SlimuxSendKeysPrompt<CR>'

    " bind keys for restart.
    for i in range(10)
        execute 'noremap <buffer> <silent> ' . g:slimux_scheme_leader . i . ' :SlimuxSchemeRestartByNum ' . i . '<CR>'
    endfor
    execute 'noremap <buffer> <silent> ' . g:slimux_scheme_leader . 'q :SlimuxSchemeRestartByNum 1<CR>'
endif
