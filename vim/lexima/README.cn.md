# lexima 配置

> [!NOTE]
> 查看 vimrc 的配置: [https://github.com/marslo/dotfiles/blob/main/.marslo/vimrc.d/extension#L245-L311](https://github.com/marslo/dotfiles/blob/main/.marslo/vimrc.d/extension#L245-L311)

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

# lexima.vim 行为总表

> 光标用 `│` 表示。规则来自 `~/.marslo/vimrc.d/extension` 的 lexima 配置。
> 「允许位」= 空格 / 行尾 / `) ] } >` / `" ' ` `` ` `` / `/` / `, ; : ! ?`。

## 1. 基础成对 — 光标后是「允许位」

| Before | Input | After | 说明 |
|---|---|---|---|
| `│` | `(` | `(│)` | 成对 |
| `│` | `[` | `[│]` | 成对 |
| `│` | `{` | `{│}` | 成对 |
| `│` | `"` | `"│"` | 成对 |
| `│` | `'` | `'│'` | 成对 |
| `│` | `` ` `` | `` `│` `` | 成对 |
| `│` | `<` | `<│>` | 成对 |
| `foo│` | `{` | `foo{│}` | 光标后是行尾 → 允许 |
| `│/x` | `(` | `(│)/x` | 光标后是 `/` → 允许 |

## 2. 抑制成对 — 光标后是 单词字符 / `.` / `@` 等(非允许位)

| Before | Input | After | 说明 |
|---|---|---|---|
| `│foo` | `(` | `(│foo` | 后面是字母 → 只插左符号,不补右 |
| `│foo` | `"` | `"│foo` | 同上 |
| `│.bar` | `{` | `{│.bar` | 后面是 `.` → 抑制 |

## 3. 缩写/连词的单引号 — 单词后紧跟 `'`

| Before | Input | After | 说明 |
|---|---|---|---|
| `I│` | `'` | `I'│` | lexima 默认:字母后 `'` 不成对(`I'm` / `don't`) |
| `don│` | `'` | `don'│` | 同上 |

## 4. 跳过右符号(leave-over)— 光标已在右符号前

| Before | Input | After | 说明 |
|---|---|---|---|
| `(│)` | `)` | `()│` | 不插入,直接跳过 |
| `"│"` | `"` | `""│` | 跳过 |
| `'│'` | `'` | `''│` | 跳过 |
| `<│>` | `>` | `<>│` | 跳过 |

## 5. `<<`(第二个 `<`)

| Before | Input | After | 说明 |
|---|---|---|---|
| `<│>` | `<` | `<<│` | 第二个 `<` → 变 `<<`,不再当成对 |

## 6. 转义符 `\` 之后

| Before | Input | After | 说明 |
|---|---|---|---|
| `\│` | `"` | `\"│\"` | `\`+引号 → 转义引号成对 |
| `\│` | `'` | `\'│\'` | 同上 |
| `` \│ `` | `` ` `` | `` \`│\` `` | 转义 backtick 成对 |
| `\│` | `[` | `\[│` | `\`+括号 → 转义,不成对(lexima 默认) |

## 7. 三连引号(markdown / docstring)

| Before | Input | After | 说明 |
|---|---|---|---|
| `""│` | `"` | `"""│"""` | 第三个引号 → 三连成对 |
| `''│` | `'` | `'''│'''` | 同上 |
| `` ``│ `` | `` ` `` | `` ```│``` `` | 同上 |

## 8. 退格删整对

| Before | Input | After | 说明 |
|---|---|---|---|
| `(│)` | `<BS>` | `│` | 删左符号 → 右符号一起删 |
| `"│"` | `<BS>` | `│` | 同上 |

---

> [!NOTE]
> 第 1、2、3、6、8 组为 `feedkeys` 无头 nvim 实测结果;
> 第 4(leave)、5(`<<`)、7(三连)取自 lexima 标准行为 + 截图确认。

# debug 脚本的结果

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
