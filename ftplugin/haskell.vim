let s:not_prefixable_keywords = [ "import", "data", "instance", "class", "{-#", "type", "case", "do", "let", "default", "foreign", "--"]

function! Process_Lines(lines)
	let l:lines = a:lines
	" skip empty lines
	while 1
		let l:splitted = split(l:lines[0], " ")
		if len(l:splitted) > 0
			break
		endif
	endwhile

	let l:word = l:splitted[0]

	if index(s:not_prefixable_keywords, l:word) < 0
		let l:lines[0] = "let " . l:lines[0]
		let l:i = 1
		while l:i < len(l:lines)
			if l:lines[l:i] != ""
				let l:lines[l:i] = "    " . l:lines[l:i]
			endif

			let l:i += 1
		endwhile
		return l:lines
	else
		return l:lines
	endif
endfunction

function! SlimuxEscape_haskell(text)
	let l:text = substitute(a:text, "	", "    ", "g")
	let l:lines = split(l:text, "\n")
	let l:lines = Process_Lines(l:lines)
	let l:lines = [":{"] + l:lines + [":}"]

	return join(l:lines, "\n") . "\n"
endfunction
