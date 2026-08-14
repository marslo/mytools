set runtimepath+=~/.vim/plugged/lexima.vim
let g:lexima_enable_basic_rules = 1
runtime plugin/lexima.vim
let s:suppress_regex = '\%#\%(\\["''`]\)\@![^ \t)}\]>"''`,;:!?/]'
for s:char in ['"', "'", '`', '<'] | call lexima#add_rule({ 'char': s:char, 'at': s:suppress_regex, 'priority': 1 }) | endfor
let s:bracket_suppress = '\%#[^ \t)}\]>"''`,;:!?/]'
for s:char in ['(', '[', '{'] | call lexima#add_rule({ 'char': s:char, 'at': s:bracket_suppress, 'priority': 1 }) | endfor
function! M(mk, keys) abort
  %delete _
  let col = stridx(a:mk, '#') + 1
  call setline(1, substitute(a:mk, '#', '', ''))
  call cursor(1, col)
  call feedkeys('i' . a:keys . "\<Esc>", 'tx')
  return printf('%-12s + %-6s ->  %s', a:mk, strtrans(a:keys), getline(1))
endfunction
let r = []
call add(r, M('#foo', '('))
call add(r, M('#foo', '"'))
call add(r, M('#.bar', '{'))
call add(r, M('#/x', '('))
call add(r, '--- leave ---')
call add(r, M('(#)', ')'))
call add(r, M('"#"', '"'))
call add(r, M('[#]', ']'))
call add(r, '--- << ---')
call add(r, M('<#>', '<'))
call add(r, '--- BS ---')
call add(r, M('(#)', "\<BS>"))
call add(r, M('"#"', "\<BS>"))
call writefile(r, expand('./output-5.txt'))
