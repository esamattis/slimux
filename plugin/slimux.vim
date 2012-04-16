" Tmux integration for Vim
" Maintainer Esa-Matti Suuronen <esa-matti@suuronen.org>
" License: MIT. See LICENSE.txt




let s:retry_send = {}

function! g:_SlimuxPickPaneFromBuf(tmux_packet)

    let pos = getpos(".")[1]
    if pos < 3
      echo "select a pane"
      return
    end

    " Get current line under the cursor
    let line = getline(".")

    " Hide (and destroy) the scratch buffer
    hide

    " Parse target pane
    let a:tmux_packet["target_pane"] = matchlist(line, '\([^ ]\+\)\: ')[1]

    if !empty(s:retry_send)
        call s:Send(s:retry_send)
        let s:retry_send = {}
    endif

endfunction

function! s:SelectPane(tmux_packet)

    " Save config dict to global so that it can be accessed later
    let g:SlimuxActiveConfigure = a:tmux_packet

    " Create new buffer in a horizontal split
    belowright new

    " Put tmux panes in the buffer. Must use cat here because tmux might fail
    " here due to some libevent bug in linux.
    " Try 'tmux list-panes -a > panes.txt' to see if it is fixed

    " Set header for the menu buffer
    call setline(1, "Select tmux pane with Enter key")
    call setline(2, "")

    " Add last used pane as the first
    let last = a:tmux_packet["target_pane"]
    if len(last) != 0
      call setline(3, last . ": (previous)")
    endif

    " List all tmux panes at the end
    normal G
    read !tmux list-panes -a | cat

    " Move cursor to first item
    call setpos(".", [0, 3, 0, 0])

    " Hilight items we can select
    highlight TmuxPanes ctermbg=green guibg=green
    match TmuxPanes '^\([^ ]\+\)\:'

    " bufhidden=wipe deletes the buffer when it is hidden
    setlocal bufhidden=wipe buftype=nofile
    setlocal nobuflisted nomodifiable noswapfile nowrap
    setlocal cursorline nocursorcolumn

    " Hide buffer on q and <ESC>
    nnoremap <buffer> <silent> q :hide<CR>
    nnoremap <buffer> <silent> <ESC> :hide<CR>

    " Use enter key to pick tmux pane
    nnoremap <buffer> <Enter> :call g:_SlimuxPickPaneFromBuf(g:SlimuxActiveConfigure)<CR>

    " Use h key to display pane index hints
    nnoremap <buffer> <silent> d :call system("tmux display-panes")<CR>

endfunction


function! s:Send(tmux_packet)

    " Pane not selected! Save text and open selection dialog
    if len(a:tmux_packet["target_pane"]) == 0
        let s:retry_send = a:tmux_packet
        return s:SelectPane(a:tmux_packet)
    endif

    let target = a:tmux_packet["target_pane"]
    let text = a:tmux_packet["text"]

    if a:tmux_packet["type"] == "code"
      call s:ExecFileTypeFn("SlimuxPre_", [target])
      let text = s:ExecFileTypeFn("SlimuxEscape_", [text])
    endif

    let text = s:EscapeText(text)

    call system("tmux set-buffer " . text)
    call system("tmux paste-buffer -t " . target)

    if a:tmux_packet["type"] == "code"
      call s:ExecFileTypeFn("SlimuxPost_", [target])
    endif

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
" Code interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Code interface uses per buffer configuration

function! SlimuxConfigureCode()
  if !exists("b:code_packet")
    let b:code_packet = { "target_pane": "", "type": "code" }
  endif
  call s:SelectPane(b:code_packet)
endfunction

function! SlimuxSendCode(text)
  if !exists("b:code_packet")
    let b:code_packet = { "target_pane": "", "type": "code" }
  endif
  let b:code_packet["text"] = a:text
  call s:Send(b:code_packet)
endfunction

command! SlimuxREPLSendLine call SlimuxSendCode(getline(".") . "\n")
command! -range=% -bar -nargs=* SlimuxREPLSendSelection call SlimuxSendCode(s:GetVisual())
command! SlimuxREPLConfigure call SlimuxConfigureCode()



"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Shell interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Command interface has only one global configuration

let s:cmd_packet = { "target_pane": "", "type": "cmd" }
let s:previous_cmd = ""

function SlimuxSendCommand(cmd)

  let s:previous_cmd = a:cmd
  let s:cmd_packet["text"] = a:cmd . ""
  call s:Send(s:cmd_packet)

endfunction

command! SlimuxShellPromt call SlimuxSendCommand(input("CMD>", s:previous_cmd))
command! SlimuxShellLast call SlimuxSendCommand(s:previous_cmd)
command! SlimuxShellConfigure call s:SelectPane(s:cmd_packet)

