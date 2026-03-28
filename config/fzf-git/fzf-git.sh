# fbr - checkout git branch
# fbr() {
#   local branches branch
#   branches=$(git branch -vv) &&
#   branch=$(echo "$branches" | fzf +m) &&
#   git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
# }

# fbr - checkout git branch (including remote branches)
fco() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
  branch=$(echo "$branches" |
           fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# # fbr - checkout git branch (including remote branches), sorted by most recent commit, limit 30 last branches
# fbr() {
#   local branches branch
#   branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
#   branch=$(echo "$branches" |
#            fzf-tmux -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
#   git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
# }

# fco - checkout git branch/tag
# fco() {
#   local tags branches target
#   tags=$(
#     git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
#   branches=$(
#     git branch --all | grep -v HEAD             |
#     sed "s/.* //"    | sed "s#remotes/[^/]*/##" |
#     sort -u          | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
#   target=$(
#     (echo "$tags"; echo "$branches") |
#     fzf-tmux -l30 -- --no-hscroll --ansi +m -d "\t" -n 2) || return
#   git checkout $(echo "$target" | awk '{print $2}')
# }


# fco_preview - checkout git branch/tag, with a preview showing the commits between the tag/branch and HEAD
# fco_preview() {
#   local tags branches target
#   tags=$(
# git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}') || return
#   branches=$(
# git branch --all | grep -v HEAD |
# sed "s/.* //" | sed "s#remotes/[^/]*/##" |
# sort -u | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}') || return
#   target=$(
# (echo "$tags"; echo "$branches") |
#     fzf --no-hscroll --no-multi --delimiter="\t" -n 2 \
#         --ansi --preview="git log -200 --pretty=format:%s $(echo {+2..} |  sed 's/$/../' )" ) || return
#   git checkout $(echo "$target" | awk '{print $2}')
# }
