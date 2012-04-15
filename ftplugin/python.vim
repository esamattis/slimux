

" TODO: Add one extra line break to multiline code chunks
function! SlimuxEscape_python(text)
  let no_empty_lines = substitute(a:text, '\n\s*\ze\n', "", "g")
  return substitute(no_empty_lines, "\n", "", "g")
endfunction

