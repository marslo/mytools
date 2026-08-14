set runtimepath+=~/.vim/plugged/lexima.vim
let g:lexima_enable_basic_rules = 1
runtime plugin/lexima.vim
let s:suppress_regex = '\%#\%(\\["''`]\)\@![^ \t)}\]>"''`,;:!?/]'
for s:char in ['"', "'", '`', '<'] | call lexima#add_rule({ 'char': s:char, 'at': s:suppress_regex, 'priority': 1 }) | endfor
let s:bracket_suppress = '\%#[^ \t)}\]>"''`,;:!?/]'
for s:char in ['(', '[', '{'] | call lexima#add_rule({ 'char': s:char, 'at': s:bracket_suppress, 'priority': 1 }) | endfor
call lexima#add_rule({ 'char': '"', 'at': '\\\%#\%(\s\|$\)', 'input_after': '\"', 'priority': 3 })
call lexima#add_rule({ 'char': "'", 'at': "\\\\\\%#\\%(\\s\\|$\\)", 'input_after': "\\'", 'priority': 3 })
call lexima#add_rule({ 'char': '`', 'at': '\\\%#\%(\s\|$\)', 'input_after': '\`', 'priority': 3 })
function! T(before, keys) abort
  %delete _
  call setline(1, a:before)
  call feedkeys('A' . a:keys . "\<Esc>", 'tx')
  return '[' . a:before . '|] + ' . a:keys . '  ->  ' . getline(1)
endfunction
let r = []
call add(r, T('', '('))
call add(r, T('', '"'))
call add(r, T('\', '"'))
call add(r, T('\', '['))
call add(r, T('\', '`'))
call add(r, T('foo', '{'))
call writefile(r, expand('./output-3.txt'))
