set runtimepath+=~/.vim/plugged/lexima.vim
let g:lexima_enable_basic_rules = 1
let g:lexima_no_default_rules = 0
runtime plugin/lexima.vim
" --- user rules (from extension) ---
let s:suppress_regex = '\%#\%(\\["''`]\)\@![^ \t)}\]>"''`,;:!?/]'
for s:char in ['"', "'", '`', '<'] | call lexima#add_rule({ 'char': s:char, 'at': s:suppress_regex, 'priority': 1 }) | endfor
let s:bracket_suppress = '\%#[^ \t)}\]>"''`,;:!?/]'
for s:char in ['(', '[', '{'] | call lexima#add_rule({ 'char': s:char, 'at': s:bracket_suppress, 'priority': 1 }) | endfor
call lexima#add_rule({ 'char': '"', 'at': '\\\%#\%(\s\|$\)', 'input_after': '\"', 'priority': 3 })
call lexima#add_rule({ 'char': "'", 'at': "\\\\\\%#\\%(\\s\\|$\\)", 'input_after': "\\'", 'priority': 3 })
call lexima#add_rule({ 'char': '`', 'at': '\\\%#\%(\s\|$\)', 'input_after': '\`', 'priority': 3 })
call lexima#add_rule({ 'char': '"', 'at': '\%#"', 'leave': 1, 'priority': 2 })

function! Try(before, keys) abort
  %delete _
  call setline(1, a:before)
  " place cursor at the '|' marker position: use a real marker approach
  let col = stridx(a:before, '@') + 1
  call setline(1, substitute(a:before, '@', '', ''))
  call cursor(1, col)
  call feedkeys('i' . a:keys . "\<Esc>", 'tx')
  return getline(1)
endfunction

let r = []
call add(r, 'before=\@   input="  -> ' . Try('\@', '"'))
call add(r, 'before=\@   input=[  -> ' . Try('\@', '['))
call add(r, 'before=@    input=(  -> ' . Try('@', '('))
call add(r, 'before=@    input="  -> ' . Try('@', '"'))
call writefile(r, expand('./output-6.txt'))
