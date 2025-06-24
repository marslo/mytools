<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [create dmg](#create-dmg)
  - [via hdiutil](#via-hdiutil)
  - [via create-dmg](#via-create-dmg)
- [install dmg](#install-dmg)
- [tips](#tips)
  - [extract dmg](#extract-dmg)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## create dmg

> [!TIP]
> - [* iMarlso: osx tips: create image](https://marslo.github.io/ibook/osx/tricky.html#create-image)
> - [How do I create a nice-looking DMG for Mac OS X using command-line tools?](https://stackoverflow.com/a/1513578/2940319)

### via hdiutil
```bash
$ hdiutil create -srcfolder /Applications/Python3\ IDLE.app \
                 -volname 'Python3 IDLE' \
                 -fs HFS+ \
                 -fsargs "-c c=64,a=16,e=16" \
                 -format UDRW \
                 "Python3 IDLE.dmg"
```

### via create-dmg
```bash
$ brew install create-dmg
$ create-dmg --volname 'Python3 IDLE' \
             --volicon ./dmg-backgound/.idle.icns \
             --background ./dmg-backgound/.background.2.png \
             --icon 'Python3 IDLE.app' 225 275 \
             --app-drop-link 526 270 \
             --window-size 750 500 \
             --hide-extension "Python3 IDLE.app" \
             'Python3 IDLE.dmg' '/Applications/Python3 IDLE.app'
```

## install dmg

> [!NOTE]
> - [* iMarlso: osx: install dmg](https://marslo.github.io/ibook/osx/apps/apps.html#install-dmg)

- attach
  ```bash
  # Python3 IDLE
  $ hdiutil attach "Python3 IDLE.dmg" -noverify -mountpoint /Volumes/Python3
  $ cp /Volumes/Python3/Python3\ IDLE.app /Applications

  # groovyConsole
  $ hdiutil attach groovyConsole.dmg -noverify -mountpoint /Volumes/groovyConsole
  $ cp /Volumes/groovyConsole/groovyConsole.app /Applications
  ```

- deattach
  ```bash
  # Python3 IDLE
  $ hdiutil detach /Volumes/Python3

  # groovyConsole
  $ hdiutil detach /Volumes/groovyConsole
  ```

## tips
### extract dmg
```bash
$ 7z x "Python3 IDLE.dmg"

# or
$ 7z x -o"Python3 IDLE" "Python3 IDLE.dmg"
```
