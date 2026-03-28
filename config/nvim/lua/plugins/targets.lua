return {
  {
    -- cusom textobj
    'kana/vim-textobj-user'
  },
  {
    -- dae
    'kana/vim-textobj-entire',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  {
    -- dal
    'kana/vim-textobj-line',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  {
    -- dai
    'kana/vim-textobj-indent',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  {
    -- da/
    'kana/vim-textobj-lastpat',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  {
    -- dac
    'glts/vim-textobj-comment',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  {
    -- da, delete function parameter
    'sgur/vim-textobj-parameter',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
  {
    -- dax, delete xml attr
    'whatyouhide/vim-textobj-xmlattr',
    dependencies = {
      'kana/vim-textobj-user',
    }
  },
}
