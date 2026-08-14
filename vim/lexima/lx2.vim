let cls = '[^ \t)}\]>"''`,;:!?/]'
let r = []
for c in ['a','Z','0','_','.', '@','-','#','$','&','*','+','=', ' ',')',']','}','>','/',',',';',':','!','?','"',"'",'`']
  call add(r, printf('%-3s -> %s', c, (match(c,'^'.cls)>=0 ? 'SUPPRESS' : 'pair')))
endfor
call writefile(r, expand('./output-2.txt'))
