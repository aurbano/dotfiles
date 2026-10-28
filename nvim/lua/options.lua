local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true

-- Line wrapping
opt.wrap = false

-- Search
opt.ignorecase = true
opt.smartcase = true

-- Cursor & scrolling
opt.cursorline = true
opt.scrolloff = 3
opt.sidescrolloff = 3

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Appearance
opt.termguicolors = true
opt.signcolumn = "yes"
opt.colorcolumn = "110"

-- Clipboard
opt.clipboard = "unnamedplus"

-- Undo
opt.undofile = true

-- Mouse
opt.mouse = "a"
