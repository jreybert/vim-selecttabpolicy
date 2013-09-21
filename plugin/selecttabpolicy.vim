" selecttabpolicy.vim  -  Select the tabulation policy
"
" Copyright February 2012 by Jerome Reybert <jreybert@gmail.com>
"
" Distributed under the terms of the Vim license.  See ":help license".
"

if exists("g:loaded_select_tab_policy")
	finish
endif
let g:loaded_select_tab_policy = 1

if !exists("g:select_tab_policy_default_policy")
	let g:select_tab_policy_default_policy = 1
endif

if !exists("g:select_tab_policy_max_file_size")
	let g:select_tab_policy_max_file_size = 256000
endif

if !exists("g:select_tab_policy_look_nb_lines")
	" Default is all file
	let g:select_tab_policy_look_nb_lines = "$"
endif

if !exists("g:select_tab_policy_smart_nb_spaces")
	let g:select_tab_policy_smart_nb_spaces = 1
endif

if !exists("g:select_tab_policy_default_tabstop")
	let g:select_tab_policy_default_tabstop = 4
endif

if !exists("g:select_tab_policy_default_softtabstop")
	let g:select_tab_policy_default_softtabstop = 4
endif

if !exists("g:select_tab_policy_default_shiftwidth")
	let g:select_tab_policy_default_shiftwidth = 4
endif

function! SetTabPolicy(policy)
	if ( b:tabPolicyInit != 0 )
		if (a:policy == 0)
			let &l:shiftwidth=g:select_tab_policy_default_shiftwidth
			let &l:softtabstop=g:select_tab_policy_default_softtabstop
			let &l:tabstop=g:select_tab_policy_default_tabstop
			setlocal noexpandtab 
			let b:tabPolicy = 0
		elseif (a:policy == 1)
			let &l:shiftwidth=b:shiftNbSpaces " Nombre d'espace pour une tabulation
			let &l:softtabstop=b:shiftNbSpaces " if non-zero, number of spaces to insert for a <tab>
			let &l:tabstop=g:select_tab_policy_default_tabstop
			setlocal expandtab
			let b:tabPolicy = 1
		endif
	endif
endfunction

" Easy switch between policies
function! SwitchTabPolicy()
	if ( b:tabPolicyInit != 0 )
		if (b:tabPolicy == 0)
			call SetTabPolicy(1)
		elseif (b:tabPolicy == 1)
			call SetTabPolicy(0)
		endif
	endif
endfunction

" Get current policy (useful for statusline)
function! GetCurrentTabPolicy()
	if ( b:tabPolicyInit != 0 )
		if (b:tabPolicy == 0)
			return "T"
		elseif (b:tabPolicy == 1)
			return "S"
		endif
	endif
endfunction

function TabsOrSpaces()

	if ( &buftype == '' )
		let b:tabPolicyInit = 1
	else
		let b:tabPolicyInit = 0
	endif

	if !exists("b:tabPolicy")
		let b:shiftNbSpaces=g:select_tab_policy_default_shiftwidth
		" Determines whether to use spaces or tabs on the current buffer.
		if getfsize(bufname("%")) > g:select_tab_policy_max_file_size
			" File is very large, just use the default.
			call SetTabPolicy(g:select_tab_policy_default_policy)
			return
		endif

		let l:numLinesTab=len(filter(getbufline(bufname("%"), 1, g:select_tab_policy_look_nb_lines), 'v:val =~ "^\\t"'))
		let l:listLinesSpace=filter(getbufline(bufname("%"), 1, g:select_tab_policy_look_nb_lines), 'v:val =~ "^  "')
		let l:numLinesSpace=len(l:listLinesSpace)


		if ( l:numLinesTab == 0 && l:numLinesSpace == 0 ) || ( l:numLinesTab == l:numLinesSpace )
			let &l:tabstop=g:select_tab_policy_default_tabstop
			let &l:shiftwidth=g:select_tab_policy_default_shiftwidth
			let &l:softtabstop=g:select_tab_policy_default_softtabstop
			call SetTabPolicy(g:select_tab_policy_default_policy)
		elseif l:numLinesTab > l:numLinesSpace
			let &l:shiftwidth=g:select_tab_policy_default_shiftwidth
			let &l:softtabstop=g:select_tab_policy_default_softtabstop
			let &l:tabstop=g:select_tab_policy_default_tabstop
			call SetTabPolicy(0)
		else
			if ( g:select_tab_policy_smart_nb_spaces && l:numLinesSpace > 10 )
				let l:nbModulo2 = 0
				let l:nbModulo4 = 0
				let l:nbModulo8 = 0
				for l:lineSpace in l:listLinesSpace
					let l:nbSpaces = match(l:lineSpace, '[^ ]')
					if ( !(l:nbSpaces % 8) )
						let l:nbModulo8 += 1
					elseif ( !(l:nbSpaces % 4) )
						let l:nbModulo4 += 1
					elseif ( !(l:nbSpaces % 2) )
						let l:nbModulo2 += 1
					endif
				endfor

				if l:nbModulo8 >= l:nbModulo4
					let b:shiftNbSpaces=8
				elseif l:nbModulo4 >= l:nbModulo2
					let b:shiftNbSpaces=4
				else
					let b:shiftNbSpaces=2
				endif
				call SetTabPolicy(1)
			else
				call SetTabPolicy(0)
			endif
		endif
	else
		call SetTabPolicy(b:tabPolicy)
	endif

endfunction

" Call the function after opening a buffer
autocmd BufEnter,BufNew * call TabsOrSpaces()
nmap <silent> <Leader>st :execute SwitchTabPolicy()<CR>

