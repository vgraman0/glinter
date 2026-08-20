if vim.g.loaded_glinter then
  return
end
vim.g.loaded_glinter = true

require("glinter").setup()
