# backup

```bash
osascript -e 'quit app "iShot Pro"'
defaults export cn.better365.iShotPro ./cn.better365.iShotPro.plist && defaults export 4K6FWZU8C4.group.cn.better365 ./group.cn.better365.plist

# other data
tar -C ~/Library -czf ./ishot-containers.tgz "Containers/cn.better365.iShotPro/Data/Library" "Group Containers/4K6FWZU8C4.group.cn.better365"
```

# restore

```bash
osascript -e 'quit app "iShot Pro"'
defaults import cn.better365.iShotPro ./cn.better365.iShotPro.plist && defaults import 4K6FWZU8C4.group.cn.better365 ./group.cn.better365.plist

# other data
tar -C ~/Library -xzf ./ishot-containers.tgz
```
