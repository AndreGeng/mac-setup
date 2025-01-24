-- Run your favorite search tool from Vim, with an enhanced results list.
return {
  'mileszs/ack.vim',
  init = function()
    local has_rg = vim.fn.executable('rg')

    -- Set global variable
    if has_rg then
      vim.g.ackprg = "rg --vimgrep"
    end
  end,
  keys = {
    { '<leader>a', ':Ack -i ', noremap = true },
  }
}
