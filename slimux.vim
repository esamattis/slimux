
let s:retry_send = ""

function! g:_SlimuxPickPaneFromBuf()
    let l:line = getline(".")
    hide
    let b:target_pane = matchlist(l:line, '\([^ ]\+\)\: ')[1]

    if len(s:retry_send) != 0
        call g:SlimuxSend(s:retry_send)
        let s:retry_send = ""
    endif

endfunction

function! g:SlimuxSelectPane()

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

    nnoremap <buffer> <Enter> :call g:_SlimuxPickPaneFromBuf()<CR>

    " Show pane index hints if Vim is in tmux
    if len($TMUX) != 0
        call system("tmux display-panes")
    endif

endfunction


function! g:SlimuxSend(text)

    " Pane not selected! Save text and open selection dialog
    if !exists('b:target_pane')
        let s:retry_send = a:text
        return g:SlimuxSelectPane()
    endif

    call s:ExecFileTypeFn("_PreSlimux_", [b:target_pane])

    let escaped_text = s:EscapeText(a:text)
    call system("tmux set-buffer " . escaped_text)
    call system("tmux paste-buffer -t " . b:target_pane)

    call s:ExecFileTypeFn("_PostSlimux_", [b:target_pane])

endfunction


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Helpers
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:EscapeText(text)
  let transformed_text = a:text

  if exists("&filetype")
    let custom_escape = "_EscapeText_" . &filetype
    if exists("*" . custom_escape)
        let transformed_text = call(custom_escape, [a:text])
    end
  end

  return substitute(shellescape(transformed_text), "\\\\\\n", "\n", "g")
endfunction

function! s:ExecFileTypeFn(fn_name, args)
  if exists("&filetype")
    let fullname = a:fn_name . &filetype
    if exists("*" . fullname)
      call call(fullname, a:args)
    end
  end
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


command! -range=% -bar -nargs=* SlimuxSendSelection call g:SlimuxSend(s:GetVisual())
command! -range=% -bar -nargs=* SlimuxSendLine call g:SlimuxSend(getline(".") . "\n")
command! -range=% -bar -nargs=* SlimuxConfigure call: g:SlimuxSelectPane()
