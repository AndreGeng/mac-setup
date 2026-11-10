" Load the shared Vim/Rex navigator from the checkout or installed Rex config.
let s:navigation = fnamemodify(resolve(expand('<sfile>:p')), ':h:h:h:h') . '/rex/vim-navigation.vim'
if !filereadable(s:navigation)
  let s:navigation = expand('~/.config/rex/vim-navigation.vim')
endif
if filereadable(s:navigation)
  execute 'source ' . fnameescape(s:navigation)
endif
