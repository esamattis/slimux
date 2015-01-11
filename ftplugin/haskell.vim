let s:not_prefixable_keywords = [ "import", "data", "instance", "class", "{-#", "type", "case", "do", "let", "default", "foreign", "--"]
let s:spaces = repeat(" ", 4)
let s:tab = "	"

function! Process_Lines(lines)
	let l:lines = a:lines
	" skip empty lines
	let l:first_line = 0
	while l:lines[l:first_line] == ""
		let first_line += 1
	endwhile

	let l:word = split(l:lines[l:first_line], " ")[0]

	if index(s:not_prefixable_keywords, l:word) < 0
		" prepend let in the first line
		let l:lines[l:first_line] = "let " . l:lines[l:first_line]

		" indent the remaining lines
		let l:i = l:first_line + 1
		while l:i < len(l:lines)
			if l:lines[l:i] != ""
				let l:lines[l:i] = s:spaces . l:lines[l:i]
			endif

			let l:i += 1
		endwhile
		return l:lines
	else
		return l:lines
	endif
endfunction

function! SlimuxEscape_haskell(text)
	let l:text = substitute(a:text, s:tab, s:spaces, "g")
	let l:lines = split(l:text, "\n")
	let l:lines = Process_Lines(l:lines)
	let l:lines = [":{"] + l:lines + [":}"]

	return join(l:lines, "\n") . "\n"
endfunction
