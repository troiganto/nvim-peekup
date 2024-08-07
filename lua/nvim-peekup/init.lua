--[[ this module exposes the interface to open the peekup
window containing the registers content. Moreover it
sets the corresponding buffer options and commands on keystroke ]]
local peekup = require('nvim-peekup.peekup')
local config = require('nvim-peekup.config')

local function set_peekup_opts(buf, paste_where)
  vim.api.nvim_set_option_value('filetype', 'peek', { buf = buf })
  vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  vim.api.nvim_set_option_value('readonly', true, { buf = buf })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<ESC>', ':q<CR>',
    { nowait = true, noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<C-j>', '<C-e>',
    { nowait = true, noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<C-k>', '<C-y>',
    { nowait = true, noremap = true, silent = true })

  -- setting markers
  vim.api.nvim_exec2(
    [[
   function! SetMarks() abort
      execute 'keeppatterns /^Numerical'
      execute 'mark n'
      execute 'keeppatterns /^Literal'
      execute 'mark l'
      execute 'keeppatterns /^Special'
      execute 'mark s'
      execute 'normal! gg0'
   endfunction

   call SetMarks()
   ]],
    { output = false }
  )

  -- setting peekup keymaps
  for _, v in ipairs(config.reg_chars) do
    vim.api.nvim_buf_set_keymap(
      buf,
      'n',
      v,
      ':lua require"nvim-peekup.peekup".on_keystroke("' ..
      v .. '","' .. paste_where .. '")<cr>',
      {
        nowait = true,
        noremap = true,
        silent = true,
      }
    )
  end
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Down>', ']`',
    { nowait = true, noremap = true, silent = true })
  vim.api.nvim_buf_set_keymap(buf, 'n', '<Up>', '[`',
    { nowait = true, noremap = true, silent = true })

  vim.api.nvim_create_augroup('PeekAutoClose', {})
  vim.api.nvim_create_autocmd('WinLeave', {
    group = 'PeekAutoClose',
    buffer = buf,
    callback = function()
      vim.api.nvim_win_close(0, false)
    end
  })
end

local function peekup_open(paste_where)
  -- avoid opening nested peekup
  if vim.bo.filetype == 'peek' then
    return nil
  end

  local lines = peekup.reg2t(paste_where)
  local peekup_buf = peekup.floating_window(config.geometry)
  table.insert(lines, 1, peekup.centre_string(config.geometry.title))
  table.insert(lines, 2, '')

  if paste_where == nil then
    paste_where = ''
  end

  vim.api.nvim_buf_set_lines(peekup_buf, 0, -1, true, lines)
  set_peekup_opts(peekup_buf, paste_where)
end

return { peekup_open = peekup_open }
