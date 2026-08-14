# lexima config

> [!NOTE]
> vimrc : [https://github.com/marslo/dotfiles/blob/main/.marslo/vimrc.d/extension#L245-L311](https://github.com/marslo/dotfiles/blob/main/.marslo/vimrc.d/extension#L245-L311)

```vim
" cohama/lexima.vim
let g:lexima_enable_basic_rules = 1
" suppress auto-pair before word content or `.`; still pair before whitespace, closing bracket/quote, punctuation `,;:!?`, path `/`, or EOL (priority 1)
let s:suppress_regex = '\%#\%(\\["''`]\)\@![^ \t)}\]>"''`,;:!?/]'
for s:char in ['"', "'", '`', '<']
  call lexima#add_rule({ 'char': s:char, 'at': s:suppress_regex, 'priority': 1 })
endfor
" brackets suppress before word content or `.`; still pair before whitespace, quote, path `/`, closing bracket, punctuation `,;:!?`, or EOL
let s:bracket_suppress = '\%#[^ \t)}\]>"''`,;:!?/]'
for s:char in ['(', '[', '{']
  call lexima#add_rule({ 'char': s:char, 'at': s:bracket_suppress, 'priority': 1 })
endfor
" suppress auto-pair for quotes when odd number on line (priority 1)
for s:char in ['"', "'", '`']
  let s:regex = '^\([^' . s:char . ']*' . s:char . '[^' . s:char . ']*' . s:char . '\)*[^' . s:char . ']*' . s:char . '[^' . s:char . ']*\%#\(' . s:char . '\)\@!'
  call lexima#add_rule({ 'char': s:char, 'at': s:regex, 'priority': 1 })
endfor
" leave matching quote — priority 2 beats suppress
call lexima#add_rule({ 'char': '"', 'at': '\%#"',  'leave': 1, 'priority': 2 })
call lexima#add_rule({ 'char': "'", 'at': "\\%#'", 'leave': 1, 'priority': 2 })
call lexima#add_rule({ 'char': '`', 'at': '\%#`',  'leave': 1, 'priority': 2 })
" \%# : after-cursor position
" - < rule
call lexima#add_rule({ 'char': '<', 'input_after': '>', 'at': '\%#\%(\w\|\s\|$\|)\|}\|]\|"\|''\|`\)' })
" - << rule: typing < right after an auto-paired <> drops the > (e.g. left-shift `<<`) => `<<|`
call lexima#add_rule({ 'char': '<', 'at': '<\%#>', 'input': '<', 'delete': 1, 'priority': 2 })
" - > rule
call lexima#add_rule({ 'char': '>', 'at': '\%#>', 'leave': 1 })
" " "><"/ ">>><<<"
" call lexima#add_rule({ 'char': '>', 'input_after': '<', 'at': '\("\|''\)\%#' })
" call lexima#add_rule({ 'char': '>', 'input_after': '<', 'at': '\("\|''\)>\+\%#' })
" - " rule - \%(\s\|$\) : space or eof
call lexima#add_rule({ 'char': '"', 'input_after': '"', 'at': '\%#\%(\s\|$\)' })
" triple quotes — priority 3 beats leave and suppress
call lexima#add_rule({ 'char': '"', 'at': '""\%#\%(\s\|$\)',      'input_after': '"""', 'priority': 3 })
call lexima#add_rule({ 'char': '"', 'at': '""\%#"',               'input_after': '""',  'priority': 3 })
call lexima#add_rule({ 'char': "'", 'at': "''\\%#\\%(\\s\\|$\\)", 'input_after': "'''", 'priority': 3 })
call lexima#add_rule({ 'char': "'", 'at': "''\\%#'",              'input_after': "''",  'priority': 3 })
call lexima#add_rule({ 'char': '`', 'at': '``\%#\%(\s\|$\)',      'input_after': '```', 'priority': 3 })
call lexima#add_rule({ 'char': '`', 'at': '``\%#`',               'input_after': '``',  'priority': 3 })
" escaped quote pairs \" \' \` — priority 3
call lexima#add_rule({ 'char': '"', 'at': '\\\%#\%(\s\|$\)',          'input_after': '\"',  'priority': 3 })
call lexima#add_rule({ 'char': "'", 'at': "\\\\\\%#\\%(\\s\\|$\\)",   'input_after': "\\'", 'priority': 3 })
call lexima#add_rule({ 'char': '`', 'at': '\\\%#\%(\s\|$\)',          'input_after': '\`',  'priority': 3 })
call lexima#add_rule({ 'char': '\', 'at': '\%#\\"',  'leave': 1, 'priority': 3 })
call lexima#add_rule({ 'char': '\', 'at': '\%#\\''', 'leave': 1, 'priority': 3 })
call lexima#add_rule({ 'char': '\', 'at': '\%#\\`',  'leave': 1, 'priority': 3 })
function! s:EscapedQuoteBS() abort
  let l = getline('.')
  let c = col('.') - 1
  if c >= 2
    let after = c + 2 <= len(l) ? l[c : c+1] : ''
    for q in ['"', "'", '`']
      if l[c-2 : c-1] ==# '\' . q && after ==# '\' . q
        return repeat("\<Del>", 2) . repeat("\<BS>", 2)
      endif
    endfor
  endif
  return lexima#expand('<BS>', 'i')
endfunction
inoremap <silent><expr> <BS> <SID>EscapedQuoteBS()
" rule for html tags
let s:html_tags = ['div', 'font', 'span', 'code', 'pre', 'table', 'tbody', 'thread', 'th', 'td', 'kbd', 'a', 'p', 'u', 'i']
for s:tag in s:html_tags
  call lexima#add_rule({ 'char': '>', 'at': '<' . s:tag . '\%#>', 'leave': 1, 'input_after': '</' . s:tag . '>', 'filetype': ['markdown', 'html', 'groovy', 'Jenkinsfile'] })
  call lexima#add_rule({ 'char': '>', 'at': '<' . s:tag . '\%#\%(\s\|$\|<\)', 'input_after': '</' . s:tag . '>', 'filetype': ['markdown', 'html', 'groovy', 'Jenkinsfile'] })
endfor
```

# lexima.vim behavior reference

> Cursor is shown as `│`. Rules come from the lexima config in [`.marslo/vimrc.d/extension`](https://github.com/marslo/dotfiles/blob/main/.marslo/vimrc.d/extension#L245-L311).
> "Allowed position" = space / end of line / `) ] } >` / `" ' ` `` ` `` / `/` / `, ; : ! ?`.

## 1. Basic pairing — cursor is followed by an "allowed position"

| BEFORE | INPUT   | AFTER     | NOTE                             |
| ------ | ------- | --------- | -------------------------------- |
| `│`    | `(`     | `(│)`     | paired                           |
| `│`    | `[`     | `[│]`     | paired                           |
| `│`    | `{`     | `{│}`     | paired                           |
| `│`    | `"`     | `"│"`     | paired                           |
| `│`    | `'`     | `'│'`     | paired                           |
| `│`    | `` ` `` | `` `│` `` | paired                           |
| `│`    | `<`     | `<│>`     | paired                           |
| `foo│` | `{`     | `foo{│}`  | cursor at end of line → allowed  |
| `│/x`  | `(`     | `(│)/x`   | cursor followed by `/` → allowed |

## 2. Pairing suppressed — cursor is followed by a word char / `.` / `@` etc. (not an allowed position)

| BEFORE  | INPUT | AFTER    | NOTE                                                                 |
| ------- | ----- | -------- | -------------------------------------------------------------------- |
| `│foo`  | `(`   | `(│foo`  | followed by a letter → only the opening char is inserted, no closing |
| `│foo`  | `"`   | `"│foo`  | same as above                                                        |
| `│.bar` | `{`   | `{│.bar` | followed by `.` → suppressed                                         |

## 3. Apostrophe in contractions/words — `'` right after a word

| Before | Input | After | Note |
|---|---|---|---|
| `I│` | `'` | `I'│` | lexima default: `'` after a letter is not paired (`I'm` / `don't`) |
| `don│` | `'` | `don'│` | same as above |

## 4. Skip over the closing char (leave-over) — cursor already before the closing char

| BEFORE | INPUT | AFTER | NOTE                             |
| ------ | ----- | ----- | -------------------------------- |
| `(│)`  | `)`   | `()│` | nothing inserted, just skip over |
| `"│"`  | `"`   | `""│` | skip over                        |
| `'│'`  | `'`   | `''│` | skip over                        |
| `<│>`  | `>`   | `<>│` | skip over                        |

## 5. `<<` (second `<`)

| BEFORE | INPUT | AFTER | NOTE                                                   |
| ------ | ----- | ----- | ------------------------------------------------------ |
| `<│>`  | `<`   | `<<│` | second `<` → becomes `<<`, no longer treated as a pair |

## 6. After the escape char `\`

| BEFORE   | INPUT   | AFTER       | NOTE                                               |
| -------- | ------- | ----------- | -------------------------------------------------- |
| `\│`     | `"`     | `\"│\"`     | `\`+quote → escaped quote, paired                  |
| `\│`     | `'`     | `\'│\'`     | same as above                                      |
| `` \│ `` | `` ` `` | `` \`│\` `` | escaped backtick, paired                           |
| `\│`     | `[`     | `\[│`       | `\`+bracket → escaped, not paired (lexima default) |

## 7. Triple quotes (markdown / docstring)

| BEFORE    | INPUT   | AFTER         | NOTE                      |
| --------- | ------- | ------------- | ------------------------- |
| `""│`     | `"`     | `"""│"""`     | third quote → triple pair |
| `''│`     | `'`     | `'''│'''`     | same as above             |
| `` ``│ `` | `` ` `` | `` ```│``` `` | same as above             |

## 8. Backspace deletes the whole pair

| BEFORE | INPUT  | AFTER | NOTE                                                  |
| ------ | ------ | ----- | ----------------------------------------------------- |
| `(│)`  | `<BS>` | `│`   | delete the opening char → closing char is removed too |
| `"│"`  | `<BS>` | `│`   | same as above                                         |

---

> [!NOTE]
> Groups 1, 2, 3, 6, 8 are actual results measured with `feedkeys` in headless nvim;
> groups 4 (leave), 5 (`<<`), 7 (triple) are from lexima's standard behavior + screenshot confirmation.

# debug output

```bash
$ bash debug.sh
──────────────────────────────────────── 1 ───────────────────────────────────────
next | bracket_class(suppress?) | <-pair-rule(match?)
a    | SUPPRESS | yes
.    | SUPPRESS | no
     | pair     | yes
)    | pair     | yes
]    | pair     | yes
}    | pair     | yes
>    | pair     | no
/    | pair     | no
,    | pair     | no
;    | pair     | no
:    | pair     | no
"    | pair     | yes
'    | pair     | yes
`    | pair     | yes

──────────────────────────────────────── 2 ───────────────────────────────────────
a   -> SUPPRESS
Z   -> SUPPRESS
0   -> SUPPRESS
_   -> SUPPRESS
.   -> SUPPRESS
@   -> SUPPRESS
-   -> SUPPRESS
#   -> SUPPRESS
$   -> SUPPRESS
&   -> SUPPRESS
*   -> SUPPRESS
+   -> SUPPRESS
=   -> SUPPRESS
    -> pair
)   -> pair
]   -> pair
}   -> pair
>   -> pair
/   -> pair
,   -> pair
;   -> pair
:   -> pair
!   -> pair
?   -> pair
"   -> pair
'   -> pair
`   -> pair

──────────────────────────────────────── 3 ───────────────────────────────────────
[|] + (  ->  ()
[|] + "  ->  ""
[\|] + "  ->  \"\"
[\|] + [  ->  \[
[\|] + `  ->  \`\`
[foo|] + {  ->  foo{}

──────────────────────────────────────── 4 ───────────────────────────────────────
--- suppress before char-after-cursor ---
#foo           + (    ->  (foo   (col=5)
#foo           + "    ->  "foo   (col=5)
#.bar          + {    ->  {.bar   (col=6)
#/x            + (    ->  ()/x   (col=5)
--- leave over ---
(#)            + )    ->  ())   (col=4)
"#"            + "    ->  """   (col=4)
[#]            + ]    ->  []]   (col=4)
--- << and word-apostrophe (EOL) ---
<>        |  + <    ->  <><
I         |  + '    ->  I'
don       |  + '    ->  don'
--- BS delete pair ---
(#)            + �kb  ->     (col=1)
"#"            + �kb  ->     (col=1)

──────────────────────────────────────── 5 ───────────────────────────────────────
#foo         + (      ->  (foo
#foo         + "      ->  "foo
#.bar        + {      ->  {.bar
#/x          + (      ->  ()/x
--- leave ---
(#)          + )      ->  ())
"#"          + "      ->  """
[#]          + ]      ->  []]
--- << ---
<#>          + <      ->  <<>
--- BS ---
(#)          + <80>kb ->
"#"          + <80>kb ->

──────────────────────────────────────── 6 ───────────────────────────────────────
before=\@   input="  -> "\
before=\@   input=[  -> [\
before=@    input=(  -> ()
before=@    input="  -> ""
```
