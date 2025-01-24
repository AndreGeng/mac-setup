return {
  -- emmet-vim is a vim plug-in which provides support for expanding abbreviations similar to emmet.
  'mattn/emmet-vim',
  keys = {
    { '<tab>', '<plug>(emmet-expand-abbr)', mode = 'i', noremap = true }
  },
}
