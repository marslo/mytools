" 共享抑制字符类(brackets & quotes 相同)
let cls = '[^ \t)}\]>"''`,;:!?/]'
" < 自己的配对规则 at(去掉 \%#): 允许 word/space/EOL/)}]/quote
let ltpair = '\%(\w\|\s\|$\|)\|}\|]\|"\|''\|`\)'
let r = ['next | bracket_class(suppress?) | <-pair-rule(match?)']
for c in ['a','.', ' ', ')', ']', '}', '>', '/', ',', ';', ':', '"', "'", '`']
  let sup = match(c, '^'.cls) >= 0 ? 'SUPPRESS' : 'pair'
  let lt  = match(c, '^'.ltpair) >= 0 ? 'yes' : 'no'
  call add(r, printf('%-4s | %-8s | %s', c, sup, lt))
endfor
call writefile(r, expand('./output-1.txt'))
