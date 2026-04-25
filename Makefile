DEPS_DIR := tests/.deps
PLENARY_DIR := $(DEPS_DIR)/plenary.nvim
TELESCOPE_DIR := $(DEPS_DIR)/telescope.nvim

.PHONY: test test-deps test-unit test-integration

test: test-unit test-integration

test-deps:
	@mkdir -p "$(DEPS_DIR)"
	@if [ ! -d "$(PLENARY_DIR)/.git" ]; then git clone https://github.com/nvim-lua/plenary.nvim "$(PLENARY_DIR)"; else git -C "$(PLENARY_DIR)" pull --ff-only; fi
	@if [ ! -d "$(TELESCOPE_DIR)/.git" ]; then git clone https://github.com/nvim-telescope/telescope.nvim "$(TELESCOPE_DIR)"; else git -C "$(TELESCOPE_DIR)" pull --ff-only; fi

test-unit: test-deps
	nvim --headless -u tests/minimal_init.lua -c "runtime plugin/plenary.vim | PlenaryBustedDirectory tests/unit/recent_files { minimal_init = 'tests/minimal_init.lua' }"

test-integration: test-deps
	nvim --headless -u tests/minimal_init.lua -c "runtime plugin/plenary.vim | PlenaryBustedDirectory tests/integration { minimal_init = 'tests/minimal_init.lua' }"
