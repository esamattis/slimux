


" CoffeeScript REPL enters multi-line mode with Ctrl+v
function! SlimuxPre_coffee(target_pane)
    call system("tmux send-keys -t " . a:target_pane . " C-v")
endfunction

" Exit multi-line REPL mode with Ctrl+d
function! SlimuxPost_coffee(target_pane)
    call system("tmux send-keys -t " . a:target_pane . " C-d")
endfunction
