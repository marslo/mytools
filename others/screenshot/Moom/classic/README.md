
## read plist
```bash
$ defaults read com.manytricks.Moom.plist  | grep 'Visual Representation'
                "Visual Representation" = "\\U2325\\U2318\\U2193";
                "Visual Representation" = "\\U2325\\U2318\\U2191";
                "Visual Representation" = "\\U21e7\\U2318L";
                "Visual Representation" = "\\U21e7\\U2318H";
                "Visual Representation" = "\\U21e7\\U2318J";
                "Visual Representation" = "\\U21e7\\U2318K";
                "Visual Representation" = "\\U2325\\U2191";
                "Visual Representation" = "\\U2325\\U2193";
                "Visual Representation" = "\\U2325\\U2192";
                "Visual Representation" = "\\U2325\\U2190";
```

## unicode

|  UNICODE | KEY | COMMENTS    |
|:--------:|:---:|-------------|
| `\U2325` |  ⌥  | option      |
| `\U2318` |  ⌘  | command     |
| `\U21e7` |  ⇧  | shift       |
| `\U2190` |  ←  | left arrow  |
| `\U2192` |  →  | right arrow |
| `\U2191` |  ↑  | up arrow    |
| `\U2193` |  ↓  | down arrow  |
