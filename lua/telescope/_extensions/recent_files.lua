return require("telescope").register_extension({
    setup = function(ext_config, _)
        require("recent_files").setup(ext_config)
    end,
    exports = {
        recent_files = require("recent_files").open_picker,
    },
})
