" Tmux integration for Vim
" Maintainer Esa-Matti Suuronen <esa-matti@suuronen.org>
" License: MIT. See LICENSE.txt




let s:retry_send = ""

function! g:_SlimuxPickPaneFromBuf()

    " Get current line under the cursor
    let line = getline(".")

    " Hide (and destroy) the scratch buffer
    hide

    " Parse target pane
    let b:target_pane = matchlist(line, '\([^ ]\+\)\: ')[1]

    if len(s:retry_send) != 0
        call g:SlimuxSend(s:retry_send)
        let s:retry_send = ""
    endif

endfunction

function! g:SlimuxSelectPane()

    " Create new buffer in a horizontal split
    belowright new

    " Put tmux panes in the buffer. Must use cat here because tmux might fail
    " here due to some libevent bug in linux.
    " Try 'tmux list-panes -a > panes.txt' to see if it is fixed
    %!tmux list-panes -a | cat

    " bufhidden=wipe deletes the buffer when it is hidden
    setlocal bufhidden=wipe buftype=nofile
    setlocal nobuflisted nomodifiable noswapfile nowrap

    " Hide buffer on q and <ESC>
    nnoremap <buffer> <silent> q :hide<CR>
    nnoremap <buffer> <silent> <ESC> :hide<CR>

    " Use enter key to pick tmux pane
    nnoremap <buffer> <Enter> :call g:_SlimuxPickPaneFromBuf()<CR>

    " Use h key to display pane index hints
    nnoremap <buffer> <silent> d :call system("tmux display-panes")<CR>

endfunction


function! g:SlimuxSend(text)


    " Pane not selected! Save text and open selection dialog
    if !exists('b:target_pane')
        let s:retry_send = a:text
        return g:SlimuxSelectPane()
    endif

    call s:ExecFileTypeFn("SlimuxPre_", [b:target_pane])

    let escaped_text = s:ExecFileTypeFn("SlimuxEscape_", [a:text])
    let escaped_text = s:EscapeText(escaped_text)

    call system("tmux set-buffer " . escaped_text)
    call system("tmux paste-buffer -t " . b:target_pane)

    call s:ExecFileTypeFn("SlimuxPost_", [b:target_pane])

endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:EscapeText(text)
  return substitute(shellescape(a:text), "\\\\\\n", "\n", "g")
endfunction

function! s:ExecFileTypeFn(fn_name, args)
  let result = a:args[0]

  if exists("&filetype")
    let fullname = a:fn_name . &filetype
    if exists("*" . fullname)
      let result = call(fullname, a:args)
    end
  end

  return result
endfunction


" Thanks to http://vim.1045645.n5.nabble.com/Is-there-any-way-to-get-visual-selected-text-in-VIM-script-td1171241.html#a1171243
function! s:GetVisual() range
    let reg_save = getreg('"')
    let regtype_save = getregtype('"')
    let cb_save = &clipboard
    set clipboard&
    silent normal! ""gvy
    let selection = getreg('"')
    call setreg('"', reg_save, regtype_save)
    let &clipboard = cb_save
    return selection
endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Public interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" TODO: How we can use single command for both cases?
command! -range=% -bar -nargs=* SlimuxSendSelection call g:SlimuxSend(s:GetVisual())
command! -range=% -bar -nargs=* SlimuxSendLine call g:SlimuxSend(getline(".") . "\n")

command! -range=% -bar -nargs=* SlimuxConfigure call g:SlimuxSelectPane()


map <Leader>d :SlimuxSendLine<CR>
vmap <Leader>d :SlimuxSendSelection<CR>
