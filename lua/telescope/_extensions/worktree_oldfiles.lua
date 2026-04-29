return require("telescope").register_extension({
    setup = function(ext_config, _)
        require("worktree_oldfiles").setup(ext_config)
    end,
    exports = {
        worktree_oldfiles = require("worktree_oldfiles").open_picker,
    },
})
