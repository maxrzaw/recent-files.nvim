local assert = require("luassert")

describe("recent_files Telescope integration", function()
    local function reset_recent_files_modules()
        for name, _ in pairs(package.loaded) do
            if name == "recent_files" or name:match("^recent_files%.") or name == "telescope._extensions.recent_files" then
                package.loaded[name] = nil
            end
        end

        require("telescope").extensions.recent_files = nil
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
        reset_recent_files_modules()

        local telescope = require("telescope")
        telescope.setup({
            extensions = {
                recent_files = {
                    ignore_patterns = { "first.lua" },
                },
            },
        })
        telescope.load_extension("recent_files")
    end)

    after_each(function()
        cleanup_windows()
        vim.cmd("silent! %bwipeout!")
        clear_store()
    end)

    it("loads the extension export", function()
        local telescope = require("telescope")

        assert.is_table(telescope.extensions.recent_files)
        assert.is_function(telescope.extensions.recent_files.recent_files)
    end)

    it("opens through Telescope and applies configured picker filtering", function()
        local temp_dir = vim.fn.tempname()
        local first = vim.fs.joinpath(temp_dir, "first.lua")
        local second = vim.fs.joinpath(temp_dir, "second.lua")

        write_file(first, { "return 1" })
        write_file(second, { "return 2" })

        vim.cmd.edit(vim.fn.fnameescape(first))
        vim.cmd.edit(vim.fn.fnameescape(second))

        vim.cmd("Telescope recent_files")

        local opened = vim.wait(1000, function()
            return vim.bo[vim.api.nvim_get_current_buf()].filetype == "TelescopePrompt"
        end)

        assert.is_true(opened)

        local prompt_bufnr = vim.api.nvim_get_current_buf()
        local picker = require("telescope.actions.state").get_current_picker(prompt_bufnr)

        assert.is_not_nil(picker)
        assert.are.equal("Recent Files", picker.prompt_title)
        assert.are.equal(0, #picker.finder.results)
    end)
end)
