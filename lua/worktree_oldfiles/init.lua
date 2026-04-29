---@class WorktreeOldfilesPickerOpts
---@field mappings? table<string, table<string, fun(prompt_bufnr: number)>> Telescope-style per-mode mapping overrides for a single picker invocation.

---@class WorktreeOldfilesState
---@field loaded boolean
---@field setup_done boolean
---@field records table<string, WorktreeOldfilesRecord>
---@field stale table<string, integer>
---@field config WorktreeOldfilesConfig
---@field compiled WorktreeOldfilesCompiledConfig

---@class WorktreeOldfilesModule
---@field open_picker fun(opts?: WorktreeOldfilesPickerOpts)
---@field setup fun(opts?: WorktreeOldfilesConfig)

---@type WorktreeOldfilesModule
local M = {}

local config_mod = require("worktree_oldfiles.config")
local logic = require("worktree_oldfiles.logic")
local path = require("worktree_oldfiles.path")
local git_mod = require("worktree_oldfiles.git")
local store_mod = require("worktree_oldfiles.store")
local tracker_mod = require("worktree_oldfiles.tracker")
local picker_mod = require("worktree_oldfiles.picker")

---@type WorktreeOldfilesState
local state = {
    loaded = false,
    setup_done = false,
    records = {},
    stale = {},
    config = config_mod.defaults(),
    compiled = config_mod.compile(config_mod.defaults(), logic),
}

local store_dir = vim.fs.joinpath(vim.fn.stdpath("data"), "worktree-oldfiles.nvim")
local store_path = vim.fs.joinpath(store_dir, "worktree_oldfiles.json")
local legacy_store_path = vim.fs.joinpath(vim.fn.stdpath("data"), "recent-files.nvim", "recent_files.json")

local store = store_mod.new({
    state = state,
    logic = logic,
    normalize_path = path.normalize,
    path_exists = path.exists,
    store_dir = store_dir,
    store_path = store_path,
    legacy_store_path = legacy_store_path,
})

local git = git_mod.new({
    state = state,
    logic = logic,
    normalize_path = path.normalize,
    path_exists = path.exists,
    mark_stale = store.mark_stale,
})

local tracker = tracker_mod.new({
    state = state,
    logic = logic,
    normalize_path = path.normalize,
    path_exists = path.exists,
    get_git_info = git.get_git_info,
    load_records = store.load_records,
})

local picker = picker_mod.new({
    logic = logic,
    load_records = store.load_records,
    sorted_records = store.sorted_records,
    current_context = git.current_context,
    resolve_record_target = git.resolve_record_target,
    should_ignore_record = tracker.should_ignore_record,
    normalize_path = path.normalize,
    get_config = function()
        return state.config
    end,
})

---@param opts? WorktreeOldfilesPickerOpts
function M.open_picker(opts)
    return picker.open_picker(opts)
end

---@param opts? WorktreeOldfilesConfig
function M.setup(opts)
    state.config = config_mod.merge(state.config, opts)
    state.compiled = config_mod.compile(state.config, logic)

    if state.setup_done then
        return
    end

    store.load_records()

    local group = vim.api.nvim_create_augroup("worktree_oldfiles_nvim", { clear = true })
    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
        group = group,
        callback = tracker.record_current_buffer,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            store.save_records()
        end,
    })

    state.setup_done = true
end

return M
