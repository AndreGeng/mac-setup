#!/bin/bash
realpath_osx() {
  echo $(cd $(dirname "$0"); pwd -P)
}
