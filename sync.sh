rm -rf ~/.hammerspoon
rm -rf ~/config/karabiner
rm -f ~/.zshrc
rm -f ~/.tmux.conf
rm -rf ~/.config/nvim
rm -rf ~/.config/alacritty
rm -rf ~/.tmuxinator
cp -R ./mac-config/.hammerspoon ~
cp -R ./mac-config/karabiner ~/.config
cp -R ./mac-config/.zshrc ~
cp -R ./mac-config/nvim ~/.config
cp -R ./mac-config/alacritty ~/.config
cp -R ./mac-config/.tmux.conf ~
cp -R ./mac-config/.tmuxinator ~
