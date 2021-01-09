使用:
clone项目
1. 运行./ss.sh
2. 手动配置ss代理
3. 运行根目录下的./setup.sh脚本
4. 安装dropbox, [sync alfred setting](https://www.alfredapp.com/help/advanced/sync/)(brew cask install dropbox总是出错)
ps: dropbox要设代理才能访问
5. Alfred设置同步文件夹
  "Advanced" -> "set preference folder"
6. 修改iterm2字体为"hack-nerd-font"
  Preference -> Profiles -> Text -> Font

目前仍需手动配置项
1. 设置dock位置
  System Preference -> Dock -> Position on Screen
2. key repeat rate
  System Preference -> Keyboard -> Keyboard tab
  两项都调至fast
  defaults write -g ApplePressAndHoldEnabled -bool false
3. touchpad开启'tap to click'
  System Preference -> TrackPad
3. 使用tab去控制dialog上的button
  System Preference -> Keyboard -> Shortcuts -> Full Keyboard Access, 打开All controls
4. 输入法切快捷键
  System Preference -> Keyboard -> Shortcuts -> InputSource
