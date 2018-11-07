log() # $1: message to echo, $2: color var
{
    echo -e "${2-$Color_Off}$1${Color_Off}"
}