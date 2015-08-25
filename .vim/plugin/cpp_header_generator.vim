" cpp_header_generator.vim - C++ header file generator.
"	Invoke :CppNewHeader command to print C++ hpp file skeleton to current
"	buffer.
"
" Maintainer : Povilas Balciunas<balciunas90@gmail.com>
" License : MIT

function Cpp_print_header_guard_skeleton()
	let header_guard_name = "HEADER_HPP"
	let str_header_guard = ["#ifndef " . header_guard_name,
		\"#define " . header_guard_name . " 1",
		\"",
		\"#endif /* " . header_guard_name . " */"]
	call setline(line("$"), str_header_guard)

	" Hihglights header guard name so that it could be substituted easily.
	call search(header_guard_name)
	call matchadd("Search", header_guard_name)
endfunction

command CppNewHeader :call Cpp_print_header_guard_skeleton()
