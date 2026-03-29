#!/bin/bash
for f in $(dirname "$0")/utils/*.sh; do
    source $f
done
curl -L https://github.com/jwilm/alacritty/releases/download/binaries/Alacritty.dmg >> ~/Downloads/Alacritty.dmg
hdiutil attach ~/Downloads/Alacritty.dmg
cp -R /Volumes/Alacritty/Alacritty.app /Applications/Alacritty.app
