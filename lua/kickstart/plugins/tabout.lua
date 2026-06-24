-- tabout.nvim
-- https://github.com/abecodes/tabout.nvim
--
-- Lets <Tab> jump out of (), [], {}, '', "", `` instead of needing
-- arrow keys or <Esc>+l to step past a closing pair.
--
-- We're on blink.cmp, not nvim-cmp/LuaSnip's own <Tab> mapping, so we
-- use tabout's documented escape hatch: set tabkey = '' to disable its
-- automatic keymap entirely, then define <Tab> ourselves as an expr
-- mapping that defers to blink.cmp when its popup/snippet logic should
-- win, and falls back to <Plug>(Tabout) otherwise.

vim.pack.add { 'https://github.com/abecodes/tabout.nvim' }

require('tabout').setup {
  tabkey = '', -- we define <Tab> ourselves below
  backwards_tabkey = '<S-Tab>',
  act_as_tab = true,
  act_as_shift_tab = false,
  default_tab = '<C-t>',
  default_shift_tab = '<C-d>',
  enable_backwards = true,
  completion = true, -- blink owns the completion popup, not tabout
  tabouts = {
    { open = "'", close = "'" },
    { open = '"', close = '"' },
    { open = '`', close = '`' },
    { open = '(', close = ')' },
    { open = '[', close = ']' },
    { open = '{', close = '}' },
  },
  ignore_beginning = false,
  exclude = {},
}

-- Capture blink.cmp's original <Tab> (an expr-mapping: snippet-forward,
-- else literal tab) before we override it.
local blink_tab = vim.fn.maparg('<Tab>', 'i', false, true)

vim.keymap.set('i', '<Tab>', function()
  -- If blink's popup is visible, let blink handle it (select next item etc).
  if package.loaded['blink.cmp'] and require('blink.cmp').is_visible() then
    if blink_tab and blink_tab.callback then return blink_tab.callback() end
  end

  -- If a snippet is actively expandable/jumpable, let blink handle it too.
  local ok, active = pcall(function() return vim.snippet and vim.snippet.active { direction = 1 } end)
  if ok and active then
    if blink_tab and blink_tab.callback then return blink_tab.callback() end
  end

  -- Otherwise: dispatch tabout's <Plug> mapping.
  --
  -- BUG WE HIT: manually calling nvim_replace_termcodes() and then passing
  -- the result to feedkeys() double-encodes the K_SPECIAL escape bytes --
  -- that's literally what the "<80>...ys" garbage text in the buffer was:
  -- a mangled, double-escaped byte sequence inserted as literal characters
  -- instead of being interpreted as a keypress.
  --
  -- The fix: this mapping already has replace_keycodes = true (see the
  -- opts table below), which tells Neovim's *own* expr-mapping evaluator
  -- to do the keycode replacement exactly once, correctly, on whatever
  -- string we `return`. So we just return the raw, un-escaped <Plug>
  -- string directly -- no manual termcode/feedkeys juggling needed.
  return '<Plug>(Tabout)'
end, { expr = true, replace_keycodes = true, desc = 'Tabout, else blink.cmp <Tab>' })
