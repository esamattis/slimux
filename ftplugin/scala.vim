function! SlimuxPre_scala(target_pane)
    call system("tmux send-keys -t " . a:target_pane . " :paste C-m")
endfunction

function! SlimuxPost_scala(target_pane)
    call system("tmux send-keys -t " . a:target_pane . " C-d")
endfunction
