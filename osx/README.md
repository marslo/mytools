
## backup brew packages
```bash
$ brew bundle dump --file=./brewfile --describe
```

## restore brew packages
```bash
$ brew bundle --file=./brewfile
```

## cleanup brew packages
```bash
$ brew bundle cleanup --file=./brewfile
```

## mas list
### HNWH3C04CX
```bash
$ mas list
1611347086  iShot Pro  (2.6.7)
 409203825  Numbers    (14.5)
1516950324  Overlap    (2.3.1)
 520993579  pwSafe     (12.0.4)
```

### iMarsloPro
```bash
1551531632  AutoSwitchInput Pro     (2.3.4)
1630034110  Bob                     (1.19.0)
1562503375  Caps Lock Tone          (2.05)
 523620159  CleanMyDrive 2          (2.2.3)
1545870783  Color Picker            (2.2.0)
 682658836  GarageBand              (10.4.13)
1081413713  GIF Brewery 3           (3.9.5)
 408981434  iMovie                  (10.4.4)
1611347086  iShot Pro               (2.6.7)
 409183694  Keynote                 (14.5)
 784801555  Microsoft OneNote       (16.106.2)
 419330170  Moom Classic            (3.2.28)
6455304581  OpenChat                (1.9)
1516950324  Overlap                 (2.3.1)
 429449079  Patterns                (1.3)
1572202501  Plain Text Editor       (1.8.4)
 520993579  pwSafe                  (12.0.4)
 451108668  QQ                      (6.9.89)
 595615424  QQMusic                 (11.1.1)
1340697163  Record It Pro           (1.7.7)
 498370702  RegExRX                 (1.9.2)
1295053131  ShadowsocksX            (2.16)
 803453959  Slack                   (4.48.95)
1153157709  Speedtest               (1.27)
 978980906  Visualize               (1.1)
 836500024  WeChat                  (4.1.7)
6502579523  Week Number             (1.3.0)
1455463454  WiFi Speed Test         (1.6.6)
1295203466  Windows App             (11.3.2)
1443749478  WPS Office              (12.1.25201)
 497799835  Xcode                   (26.3)
 876336838  喜马拉雅                (4.0.6)
1442745175  快帆                    (3.2.0)
 491854842  网易有道翻译            (11.2.15)
1231336508  腾讯视频                (2.156.1)
```

### upgrade
```bash
# list outdated apps
$ mas outdated

$ mas upgrade
# or
$ mas upgrade 1611347086 409203825 1516950324 520993579
```
