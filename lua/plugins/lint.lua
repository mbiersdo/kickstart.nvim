return {
  {
    'mfussenegger/nvim-lint',
    event = { 'BufReadPre', 'BufNewFile' },
    config = function()
      local lint = require 'lint'
      lint.linters_by_ft = {
        css = { 'biomejs' },
        scss = { 'biomejs' },
        html = { 'htmlhint' },
        javascript = { 'biomejs' },
        markdown = { 'markdownlint' },
        php = { 'phpcs' },
      }
      lint.linters.phpcs = {
        name = 'phpcs',
        cmd = '/Users/mbiersdo/.composer/vendor/bin/phpcs',
        args = {
          '--standard=WordPress',
          '--report=json',
          '-q',
          function()
            return '--stdin-path=' .. vim.api.nvim_buf_get_name(0)
          end,
          '-',
        },
        stdin = true,
        ignore_exitcode = true, -- Allow non-zero exit codes to reach parser
        parser = function(output, bufnr)
          local diagnostics = {}
          -- Check if output is empty or invalid
          if not output or output == '' then
            vim.notify('phpcs returned no output, exit code likely 2', vim.log.levels.WARN)
            return diagnostics
          end
          local ok, decoded = pcall(vim.fn.json_decode, output)
          if not ok or not decoded or not decoded.files then
            vim.notify('phpcs parsing failed: ' .. (output or 'nil'), vim.log.levels.WARN)
            return diagnostics
          end
          for file_path, data in pairs(decoded.files) do
            for _, error in ipairs(data.messages or {}) do
              table.insert(diagnostics, {
                lnum = error.line - 1,
                col = error.column - 1,
                message = error.message or error.source or 'Unknown PHPCS error',
                severity = error.type == 'ERROR' and vim.diagnostic.severity.ERROR or vim.diagnostic.severity.WARN,
                source = 'phpcs',
                code = error.source,
              })
            end
          end
          return diagnostics
        end,
      }
      -- To allow other plugins to add linters to require('lint').linters_by_ft,
      -- instead set linters_by_ft like this:
      -- lint.linters_by_ft = lint.linters_by_ft or {}
      -- lint.linters_by_ft['markdown'] = { 'markdownlint' }
      --
      -- However, note that this will enable a set of default linters,
      -- which will cause errors unless these tools are available:
      -- {
      --   clojure = { "clj-kondo" },
      --   dockerfile = { "hadolint" },
      --   inko = { "inko" },
      --   janet = { "janet" },
      --   json = { "jsonlint" },
      --   markdown = { "vale" },
      --   rst = { "vale" },
      --   ruby = { "ruby" },
      --   terraform = { "tflint" },
      --   text = { "vale" }
      -- }
      --
      -- You can disable the default linters by setting their filetypes to nil:
      -- lint.linters_by_ft['clojure'] = nil
      -- lint.linters_by_ft['dockerfile'] = nil
      -- lint.linters_by_ft['inko'] = nil
      -- lint.linters_by_ft['janet'] = nil
      -- lint.linters_by_ft['json'] = nil
      -- lint.linters_by_ft['markdown'] = nil
      -- lint.linters_by_ft['rst'] = nil
      -- lint.linters_by_ft['ruby'] = nil
      -- lint.linters_by_ft['terraform'] = nil
      -- lint.linters_by_ft['text'] = nil

      -- Create autocommand which carries out the actual linting
      -- on the specified events.
      local lint_augroup = vim.api.nvim_create_augroup('lint', { clear = true })
      vim.api.nvim_create_autocmd({ 'BufEnter', 'BufWritePost', 'InsertLeave' }, {
        group = lint_augroup,
        callback = function()
          -- Only run the linter in buffers that you can modify in order to
          -- avoid superfluous noise, notably within the handy LSP pop-ups that
          -- describe the hovered symbol using Markdown.
          if vim.opt_local.modifiable:get() then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
