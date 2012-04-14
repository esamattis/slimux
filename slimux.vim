
let b:select_pane_buf_num = -1

function! g:SlimuxPickPane()
    let l:line = getline(".")
    hide
    let l:pane = matchlist(l:line, '\([^ ]\+\)\: ')[1]
    echo l:pane
endfunction

function! g:SlimuxSelectPane()

    let b:select_pane_buf_num = bufnr('%')

    " Create new buffer in horizontal split
    belowright new

    " Put tmux panes in the buffer. Must you cat here because tmux might fail
    " here due to some libevent bug in linux.
    %!tmux list-panes -a | cat

    " bufhidden=wipe deletes the buffer when it is hidden
    setlocal bufhidden=wipe buftype=nofile
    setlocal nobuflisted nomodifiable noswapfile nowrap

    " Hide buffer on q and <ESC>
    nnoremap <buffer> <silent> q :hide<CR>
    nnoremap <buffer> <silent> <ESC> :hide<CR>

    nnoremap <buffer> <Enter> :call g:SlimuxPickPane()<CR>

endfunction
