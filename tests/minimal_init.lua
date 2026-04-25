local root = vim.fn.getcwd()
local deps_dir = vim.fs.joinpath(root, "tests", ".deps")

vim.env.XDG_DATA_HOME = vim.fs.joinpath(root, "tests", ".data")

vim.opt.runtimepath:append(root)

for _, dep in ipairs({ "plenary.nvim", "telescope.nvim" }) do
    local dep_path = vim.fs.joinpath(deps_dir, dep)
    if vim.uv.fs_stat(dep_path) then
        vim.opt.runtimepath:append(dep_path)
    end
end

pcall(vim.cmd.runtime, "plugin/telescope.lua")
