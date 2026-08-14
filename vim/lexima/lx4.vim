set runtimepath+=~/.vim/plugged/lexima.vim
let g:lexima_enable_basic_rules = 1
runtime plugin/lexima.vim
let s:suppress_regex = '\%#\%(\\["''`]\)\@![^ \t)}\]>"''`,;:!?/]'
for s:char in ['"', "'", '`', '<'] | call lexima#add_rule({ 'char': s:char, 'at': s:suppress_regex, 'priority': 1 }) | endfor
let s:bracket_suppress = '\%#[^ \t)}\]>"''`,;:!?/]'
for s:char in ['(', '[', '{'] | call lexima#add_rule({ 'char': s:char, 'at': s:bracket_suppress, 'priority': 1 }) | endfor
call lexima#add_rule({ 'char': '"', 'at': '\\\%#\%(\s\|$\)', 'input_after': '\"', 'priority': 3 })

" mid-cursor test: use '#' to mark cursor, then remove & position
function! M(line_with_bar, keys) abort
  %delete _
  let col = stridx(a:line_with_bar, '#') + 1
  call setline(1, substitute(a:line_with_bar, '#', '', ''))
  call cursor(1, col)
  " enter insert BEFORE current char (i), type, leave
  call feedkeys('i' . a:keys . "\<Esc>", 'tx')
  let res = getline(1)
  " show cursor pos by inserting a probe? just report line + col
  return printf('%-14s + %-4s ->  %s   (col=%d)', a:line_with_bar, a:keys, res, col('$'))
endfunction
function! E(line, keys) abort
  %delete _
  call setline(1, a:line)
  call feedkeys('A' . a:keys . "\<Esc>", 'tx')
  return printf('%-10s|  + %-4s ->  %s', a:line, a:keys, getline(1))
endfunction
let r = []
call add(r, '--- suppress before char-after-cursor ---')
call add(r, M('#foo', '('))
call add(r, M('#foo', '"'))
call add(r, M('#.bar', '{'))
call add(r, M('#/x', '('))
call add(r, '--- leave over ---')
call add(r, M('(#)', ')'))
call add(r, M('"#"', '"'))
call add(r, M('[#]', ']'))
call add(r, '--- << and word-apostrophe (EOL) ---')
call add(r, E('<>', '<'))
call add(r, E('I', "'"))
call add(r, E('don', "'"))
call add(r, '--- BS delete pair ---')
call add(r, M('(#)', "\<BS>"))
call add(r, M('"#"', "\<BS>"))
call writefile(r, expand('./output-4.txt'))
