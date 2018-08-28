currentDir="$PWD"
mkdir -p ~/Documents/unremitting && cd $_
if [ ! -d ~/Documents/unremitting/MacConfig/.git ]; then
	git clone https://github.com/AndreGeng/MacConfig.git
	cd MacConfig
else
	cd MacConfig
	git pull
fi
./sync.sh
cd $currentDir
source ~/.zshrc
