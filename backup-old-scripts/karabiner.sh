find /usr/local/Caskroom/karabiner-elements -type f -iname '*.pkg' | head -n 1 | xargs -I {} sudo installer -pkg {} -target /

