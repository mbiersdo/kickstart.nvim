return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    priority = 1000,
    config = function()
      require('catppuccin').setup {
        flavour = 'mocha',
        styles = {
          comments = { 'italic' },
          keywords = { 'bold' },
        },
        integrations = {
          telescope = true,
        },
      }
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
