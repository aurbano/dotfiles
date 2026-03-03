local opt = vim.opt

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Tabs & indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Line wrapping
opt.wrap = false

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true

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
opt.laststatus = 2

-- Clipboard
opt.clipboard = "unnamedplus"

-- Undo
opt.undofile = true

-- Mouse
opt.mouse = "a"

-- Misc
opt.hidden = true
opt.encoding = "utf-8"
opt.history = 1000
