files["lua/**/*.lua"] = {
    globals = { "vim" },
}

files["tests/**/*.lua"] = {
    globals = {
        "vim",
        "describe",
        "it",
        "before_each",
        "after_each",
    },
}

ignore = {
    "631", -- Allow long lines; stylua already governs formatting width for this repo.
}
