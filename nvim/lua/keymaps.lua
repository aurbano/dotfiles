local map = vim.keymap.set

vim.g.mapleader = ","

-- Better split navigation
map("n", "<C-h>", "<C-w>h", { desc = "Move to left split" })
map("n", "<C-j>", "<C-w>j", { desc = "Move to bottom split" })
map("n", "<C-k>", "<C-w>k", { desc = "Move to top split" })
map("n", "<C-l>", "<C-w>l", { desc = "Move to right split" })

-- Split resizing
map("n", "+", "<C-W>+", { desc = "Increase height" })
map("n", "-", "<C-W>-", { desc = "Decrease height" })

-- Faster scrolling
map("n", "<C-e>", "3<C-e>", { desc = "Scroll down faster" })
map("n", "<C-y>", "3<C-y>", { desc = "Scroll up faster" })

-- Better mark jumping (line + col)
map("n", "'", "`", { desc = "Jump to mark with column" })

-- Yank to end of line
map("n", "Y", "y$", { desc = "Yank to end of line" })

-- Clear search highlight
map("n", "<leader>qs", "<Esc>:noh<CR>", { silent = true, desc = "Clear search highlight" })

-- Sudo write
map("n", "<leader>W", ":w !sudo tee %<CR>", { desc = "Sudo write" })

-- Search and replace word under cursor
map("n", "<leader>*", ':%s/\\<<C-r><C-w>\\>//<Left>', { desc = "Replace word under cursor" })
map("v", "<leader>*", '"hy:%s/\\V<C-r>h//<left>', { desc = "Replace selection" })

-- Buffer navigation
map("n", "gb", ":bnext<CR>", { desc = "Next buffer" })
map("n", "gB", ":bprev<CR>", { desc = "Previous buffer" })
map("n", "<leader>x", ":bd<CR>", { desc = "Close buffer" })
map("n", "<leader>ls", ":buffers<CR>", { desc = "List buffers" })
map("n", "<leader>qq", ":cclose<CR>", { desc = "Close quickfix" })

-- File tree
map("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file tree" })
map("n", "<leader>E", "<cmd>NvimTreeFindFile<cr>", { desc = "Reveal current file in tree" })

-- Telescope
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })
map("n", "<leader>bs", "<cmd>Telescope buffers<cr>", { desc = "Buffer select" })
