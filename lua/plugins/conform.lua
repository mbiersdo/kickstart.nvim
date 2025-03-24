return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },
    config = function()
      require('conform').setup {
        notify_on_error = false,
        format_on_save = function(bufnr)
          local disable_filetypes = { c = true, cpp = true }
          local lsp_format_opt = disable_filetypes[vim.bo[bufnr].filetype] and 'never' or 'fallback'
          return { timeout_ms = 500, lsp_format = lsp_format_opt }
        end,
        formatters_by_ft = {
          css = { 'biome' },
          html = { 'prettier' },
          javascript = { 'biome' },
          lua = { 'stylua' },
          php = { 'phpcbf' },
        },
        formatters = {
          biome = {
            meta = { url = 'https://github.com/biomejs/biome', description = 'A toolchain for web projects.' },
            command = 'biome', -- Static string, relies on PATH
            stdin = true,
            args = { 'format', '--stdin-file-path', '$FILENAME', '--indent-style', 'space', '--indent-width', '2' },
            cwd = require('conform.util').root_file { 'biome.json', 'biome.jsonc' },
          },
          phpcbf = {
            meta = {
              url = 'https://phpqa.io/projects/phpcbf.html',
              description = 'PHP Code Beautifier and Fixer fixes violations of a defined coding standard.',
            },
            command = require('conform.util').find_executable({
              '/Users/mbiersdo/.composer/vendor/bin/phpcbf',
            }, 'phpcbf'),
            args = {
              '--standard=WordPress',
              '$FILENAME',
            },
            stdin = false,
            -- phpcbf ignores hidden files, so we have to override the default here
            tmpfile_format = 'conform.$RANDOM.$FILENAME',
            exit_codes = { 0, 1, 2 },
          },
        },
      }
    end,
  },
}
