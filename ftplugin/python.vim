" These python keywords should not have extra newline at indentation level 0
let w:slimux_python_allowed_indent0 = ["elif", "else", "except", "finally"]


function! SlimuxEscape_python(text)
  "" Remove all empty lines and use soft linebreaks
  let no_empty_lines = substitute(a:text, '\n\s*\ze\n', "", "g")
  let no_empty_lines = substitute(no_empty_lines, "\n", "", "g")

  "" Process line by line and insert needed linebreaks
  let l:non_processed_lines = split(no_empty_lines,"")
  let l:processed_lines = [l:non_processed_lines[0]]
  " Only actually anything to do if more than one line
  if len(l:non_processed_lines) > 1
      " Check initial indent level
      let l:first_word = matchstr(l:processed_lines[0],'^[a-zA-Z\"]\+')
      if !(l:first_word == "")
          let l:at_indent0 = 1
      else
          let l:at_indent0 = 0
      endif
      " Go through remaining lines
      for cur_line in l:non_processed_lines[1:]
          let l:first_word = matchstr(cur_line,'^[a-zA-Z\"]\+')
          if !(l:first_word == "")
              if index(w:slimux_python_allowed_indent0, l:first_word) > 0
                  " Keyword allowed at indent level 0
                  let l:processed_lines = l:processed_lines + [cur_line]
              else
                  if l:at_indent0
                      " Do not insert another newline when we are already
                      " at indent level 0
                      let l:processed_lines = l:processed_lines + [cur_line]
                  else
                      " Back at indent level 0. We need newline
                      let l:at_indent0 = 1
                      let l:processed_lines = l:processed_lines + ["".cur_line]
                  endif
              endif
          else
              " Not at indent level 0. Do not touch
              let l:at_indent0 = 0
              let l:processed_lines = l:processed_lines + [cur_line]
          endif
      endfor
  endif

  "" Return the processed lines
  if !l:at_indent0
      " We ended at indentation. Finish with extra linebreak
      return join(l:processed_lines,"").""
  else
      return join(l:processed_lines,"").""
  endif
endfunction

