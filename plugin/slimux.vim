" Tmux integration for Vim
" Maintainer Esa-Matti Suuronen <esa-matti@suuronen.org>
" License: MIT. See LICENSE




let s:retry_send = {}
let s:last_selected_pane = ""

function! g:_SlimuxPickPaneFromBuf(tmux_packet, test)

    " Get current line under the cursor
    let line = getline(".")

    " Parse target pane from current line
    let pane_match = matchlist(line, '\(^[^ ]\+\)\: ')

    if len(pane_match) == 0
      echo "Please select a pane with enter or exit with 'q'"
      return
    endif

    let target_pane = pane_match[1]

    " Test only. Do not send the real packet or configure anything. Instead
    " just send line break to see on which pane the cursor is on.
    if a:test
        return s:Send({ "target_pane": target_pane, "text": "\n", "type": "code" })
    endif

    " Hide (and destroy) the scratch buffer
    hide

    " Configure current packet
    let a:tmux_packet["target_pane"] = target_pane

    " Save last selected pane
    let s:last_selected_pane = target_pane

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

    " Set header for the menu buffer
    call setline(1, "# Enter: Select pane - Space: Test - Esc/q: Cancel")
    call setline(2, "")

    " Add last used pane as the first
    if len(s:last_selected_pane) != 0
      call setline(3, s:last_selected_pane . ": (last one used)")
    endif

    " List all tmux panes at the end
    normal G

    " Put tmux panes in the buffer. Must use cat here because tmux might fail
    " here due to some libevent bug in linux.
    " Try 'tmux list-panes -a > panes.txt' to see if it is fixed
    read !tmux list-panes -F '\#{pane_id}: \#{session_name}:\#{window_index}.\#{pane_index}: \#{window_name}: \#{pane_title} [\#{pane_width}x\#{pane_height}] \#{?pane_active,(active),}' -a | cat

    " Move cursor to first item
    call setpos(".", [0, 3, 0, 0])

    " bufhidden=wipe deletes the buffer when it is hidden
    setlocal bufhidden=wipe buftype=nofile
    setlocal nobuflisted nomodifiable noswapfile nowrap
    setlocal cursorline nocursorcolumn

    " Hide buffer on q and <ESC>
    nnoremap <buffer> <silent> q :hide<CR>
    nnoremap <buffer> <silent> <ESC> :hide<CR>

    " Use enter key to pick tmux pane
    nnoremap <buffer> <Enter> :call g:_SlimuxPickPaneFromBuf(g:SlimuxActiveConfigure, 0)<CR>

    nnoremap <buffer> <Space> :call g:_SlimuxPickPaneFromBuf(g:SlimuxActiveConfigure, 1)<CR>

    " Use d key to display pane index hints
    nnoremap <buffer> <silent> d :call system("tmux display-panes")<CR>

endfunction


function! s:Send(tmux_packet)

    " Pane not selected! Save text and open selection dialog
    if len(a:tmux_packet["target_pane"]) == 0
        let s:retry_send = a:tmux_packet
        return s:SelectPane(a:tmux_packet)
    endif

    let target = a:tmux_packet["target_pane"]
    let type = a:tmux_packet["type"]

    if type == "code" || type == "cmd"

      let text = a:tmux_packet["text"]

      if type == "code"
        call s:ExecFileTypeFn("SlimuxPre_", [target])
        let text = s:ExecFileTypeFn("SlimuxEscape_", [text])
      endif


      " The limit of text bytes tmux can send one time. 500 is a safe value.
      let s:sent_text_length_limit = 500

      " If the text is too long, split the text into pieces and send them one by one
      while text != ""
          let local_text = strpart(text, 0, s:sent_text_length_limit)
          let text = strpart(text, s:sent_text_length_limit)
          let local_text = s:EscapeText(local_text)
          call system("tmux set-buffer " . local_text)
          call system("tmux paste-buffer -t " . target)
      endwhile

      if type == "code"
        call s:ExecFileTypeFn("SlimuxPost_", [target])
      endif

    elseif type == 'keys'

      let keys = a:tmux_packet["keys"]
      call system("tmux send-keys -t " . target . " " . keys)

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

function! SlimuxSendCommand(cmd)

  let s:previous_cmd = a:cmd
  let s:cmd_packet["text"] = a:cmd . ""
  call s:Send(s:cmd_packet)

endfunction

command! -nargs=1 -complete=shellcmd SlimuxShellRun call SlimuxSendCommand("<args>")
command! SlimuxShellPrompt    call SlimuxSendCommand(input("CMD>", s:previous_cmd))
command! SlimuxShellLast      call SlimuxSendCommand(s:previous_cmd != "" ? s:previous_cmd : input("CMD>", s:previous_cmd))
command! SlimuxShellConfigure call s:SelectPane(s:cmd_packet)


"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Keys interface
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Send raw keys using the tmux 'send-keys' syntax.
" Works like the shell interface regarding configuration.
" Here's an example the stops the currently running server(ctrl+c) and starts it again:
" :SlimuxSendKeysPrompt
" KEYS>C-C 'make run-server' Enter)

let s:keys_packet = { "target_pane": "", "type": "keys" }
let s:previous_keys = ""

function! SlimuxSendKeys(keys)

  let s:previous_keys = a:keys
  let s:keys_packet["keys"] = a:keys
  call s:Send(s:keys_packet)

endfunction

command! SlimuxSendKeysPrompt    call SlimuxSendKeys(input('KEYS>', s:previous_keys))
command! SlimuxSendKeysLast      call SlimuxSendKeys(s:previous_keys != "" ? s:previous_keys : input('KEYS>'))
command! SlimuxSendKeysConfigure call s:SelectPane(s:keys_packet)
