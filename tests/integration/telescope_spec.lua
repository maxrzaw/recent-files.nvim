local assert = require("luassert")

describe("worktree_oldfiles Telescope integration", function()
    local function configure_telescope()
        local telescope = require("telescope")
        telescope.setup({
            extensions = {
                worktree_oldfiles = {
                    ignore_patterns = { "first.lua" },
                    picker = {
                        prompt_title = "My Worktree Oldfiles",
                    },
                },
            },
        })
        telescope.load_extension("worktree_oldfiles")
    end

    local function reset_worktree_oldfiles_modules()
        for name, _ in pairs(package.loaded) do
            if name == "worktree_oldfiles" or name:match("^worktree_oldfiles%.") or name == "telescope._extensions.worktree_oldfiles" then
                package.loaded[name] = nil
            end
        end

        require("telescope").extensions.worktree_oldfiles = nil
    end

    local function cleanup_windows()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            if vim.api.nvim_win_is_valid(win) then
                local buf = vim.api.nvim_win_get_buf(win)
                local filetype = vim.bo[buf].filetype
                if filetype == "TelescopePrompt" or filetype == "TelescopeResults" or filetype == "TelescopePreview" then
                    pcall(vim.api.nvim_win_close, win, true)
                end
            end
        end
    end

    local function clear_store()
        vim.fn.delete(vim.fs.joinpath(vim.fn.stdpath("data"), "worktree-oldfiles.nvim"), "rf")
        vim.fn.delete(vim.fs.joinpath(vim.fn.stdpath("data"), "recent-files.nvim"), "rf")
    end

    local function write_file(path, lines)
        vim.fn.mkdir(vim.fs.dirname(path), "p")
        vim.fn.writefile(lines, path)
    end

    before_each(function()
        cleanup_windows()
        vim.cmd("silent! %bwipeout!")
        clear_store()
        reset_worktree_oldfiles_modules()
        configure_telescope()
    end)

    after_each(function()
        cleanup_windows()
        vim.cmd("silent! %bwipeout!")
        clear_store()
    end)

    it("loads the extension export", function()
        local telescope = require("telescope")

        assert.is_table(telescope.extensions.worktree_oldfiles)
        assert.is_function(telescope.extensions.worktree_oldfiles.worktree_oldfiles)
    end)

    it("opens through Telescope and applies configured picker filtering", function()
        local temp_dir = vim.fn.tempname()
        local first = vim.fs.joinpath(temp_dir, "first.lua")
        local second = vim.fs.joinpath(temp_dir, "second.lua")

        write_file(first, { "return 1" })
        write_file(second, { "return 2" })

        vim.cmd.edit(vim.fn.fnameescape(first))
        vim.cmd.edit(vim.fn.fnameescape(second))

        vim.cmd("Telescope worktree_oldfiles")

        local opened = vim.wait(1000, function()
            return vim.bo[vim.api.nvim_get_current_buf()].filetype == "TelescopePrompt"
        end)

        assert.is_true(opened)

        local prompt_bufnr = vim.api.nvim_get_current_buf()
        local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)

        assert.is_not_nil(picker)
        assert.are.equal("My Worktree Oldfiles", picker.prompt_title)
        assert.are.equal(0, #picker.finder.results)
    end)

    it("migrates records from the legacy recent-files store", function()
        local temp_dir = vim.fn.tempname()
        local legacy_file = vim.fs.joinpath(temp_dir, "legacy.lua")
        local legacy_store = vim.fs.joinpath(vim.fn.stdpath("data"), "recent-files.nvim", "recent_files.json")
        local new_store = vim.fs.joinpath(vim.fn.stdpath("data"), "worktree-oldfiles.nvim", "worktree_oldfiles.json")

        clear_store()
        reset_worktree_oldfiles_modules()

        write_file(legacy_file, { "return 1" })
        write_file(legacy_store, { vim.json.encode({ { file = legacy_file, last_accessed = 1 } }) })

        configure_telescope()
        vim.cmd("Telescope worktree_oldfiles")

        local opened = vim.wait(1000, function()
            return vim.bo[vim.api.nvim_get_current_buf()].filetype == "TelescopePrompt"
        end)

        assert.is_true(opened)

        local prompt_bufnr = vim.api.nvim_get_current_buf()
        local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)

        assert.is_not_nil(picker)
        assert.are.equal(1, #picker.finder.results)
        assert.are.equal(legacy_file, picker.finder.results[1].filename)
        assert.is_true(vim.uv.fs_stat(new_store) ~= nil)
    end)
end)
