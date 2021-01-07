#!/bin/bash

RVM_DIR="$HOME/.rvm"

if [ -d $RVM_DIR ]; then
  RVM_GLOBALS=(`find $HOME/.rvm/{bin,rubies/**/bin}/* -type l -o -type f -print0 | xargs -0 basename | sort | uniq`)
fi

load_rvm () {
  # Unset placeholder functions
  for cmd in "${RVM_GLOBALS[@]}"; do unset -f ${cmd} &>/dev/null; done

  # Load RVM
  [[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"

  export PATH="$PATH:$HOME/.rvm/bin"

  # Do not reload rvm again
  export RVM_LOADED=1
}

for cmd in "${RVM_GLOBALS[@]}"; do
  if ! which ${cmd} &>/dev/null; then
    eval "${cmd}() { unset -f ${cmd} &>/dev/null; [ -z \${RVM_LOADED+x} ] && load_rvm; ${cmd} \$@; }"
  fi
done
