let s:not_prefixable_keywords = [ "import", "data", "instance", "class", "{-#", "type", "case", "do", "let", "default", "foreign", "--"]
let s:spaces = repeat(" ", 4)
let s:tab = "	"

function! ProcessLines(lines)
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

function! StripComments(lines)
	let l:lines = a:lines
	let l:ret = []
	let l:i = 0
	while l:i < len(l:lines)
		let l:stripped_spaces = substitute(l:lines[l:i], "^ *", "", "")
		if strpart(l:stripped_spaces, 0, 2) != "--"
			call add(l:ret, l:lines[l:i])
		endif

		let l:i += 1
	endwhile
	return l:ret
endfunction

function! SlimuxEscape_haskell(text)
	let l:text = substitute(a:text, s:tab, s:spaces, "g")
	let l:lines = split(l:text, "\n")
	let l:lines = StripComments(l:lines)
	let l:lines = ProcessLines(l:lines)
	let l:lines = [":{"] + l:lines + [":}"]

	return join(l:lines, "\n") . "\n"
endfunction
