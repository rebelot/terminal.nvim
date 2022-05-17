local terminal = require("terminal.terminal")
local active_terminals = require("terminal.active_terminals")

local M = {}

M.terminal = terminal

-- TODO: lock terminal windows?

M.target_term = 0 -- use 0 as "smart target"

local function init_autocmds()
    local au_id = vim.api.nvim_create_augroup("terminal_nvim", { clear = true })
    vim.api.nvim_create_autocmd({ "TermOpen" }, {
        callback = function(params)
            terminal:on_term_open(params.buf)
        end,
        group = au_id,
        desc = "on_term_open",
    })
    vim.api.nvim_create_autocmd({ "TermClose" }, {
        callback = function(params)
            terminal:on_term_close(params.buf)
            vim.cmd("let &stl = &stl") -- redrawstatus | redrawtabline
        end,
        group = au_id,
        desc = "on_term_close",
    })
end

--TODO: finish implementing options
local default_config = {
    layout = { open_cmd = "botright new" },
    cmd = { vim.o.shell },
    autoclose = false,
}

local _config = {}

function M.get_config()
    return vim.tbl_deep_extend("force", _config, {})
end

function M.setup(config)
    _config = vim.tbl_deep_extend("force", default_config, config or {})

    init_autocmds()
end

local function is_valid_index(index)
    vim.pretty_print(index, active_terminals:len())
    if index > active_terminals:len() then
        vim.notify("Terminal: invalid terminal index " .. index, vim.log.levels.ERROR)
        return false
    end
    return true
end

function M.set_target(index)
    if is_valid_index(index) then
        M.target_term = index
    end
end

local function get_target_terminal(index, cur_buf, tab_only)
    local terminals = active_terminals:get_sorted_terminals()
    if not terminals then
        return
    end
    if index then
        if is_valid_index(index) then
            return terminals[index]
        else
            return
        end
    end
    if M.target_term ~= 0 then -- lower precedence than explicit index
        return terminals[M.target_term]
    end

    if cur_buf then
        local buf_term = active_terminals:get_current_buf_terminal()
        if buf_term then
            return buf_term
        end
    end

    local tab_terminals = active_terminals:get_current_tab_terminals()
    if next(tab_terminals) then
        return tab_terminals[1]
    end

    if not tab_only then
        return terminals[#terminals]
    end
end

function M.cycle(step)
    step = (step and step ~= 0) and step or 1

    local term = get_target_terminal(nil, true, true)
    if not term then
        return
    end
    local terminals = active_terminals:get_sorted_terminals()
    local index = (term:get_index() + step - 1) % #terminals + 1
    local winid = term:get_current_tab_windows()[1]
    vim.api.nvim_win_set_buf(winid, terminals[index].bufnr)
end

function M.run(cmd, opts)
    opts = opts or {}
    cmd = cmd or vim.fn.expandcmd(vim.fn.input("Command: ", "", "shellcmd"))
    opts.cmd = cmd ~= "" and cmd or nil
    terminal:new({ cmd = opts.cmd }):open(opts.layout)
end

-- if no active terminals, start a new one
-- if index is given, open (or focus) the terminal at the given index
-- else, if tab has terminals, open (focus) the first one
-- else, open the last terminal
function M.open(index, layout, force)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, false, false)

    if not term then
        -- if no active terminals, start a new one
        M.run(nil, { layout = layout })
    else
        term:open(layout, force)
    end
end

--- if no active terminals in tab, return
--- if index is given, close the terminal at the given index
--- else, if current buffer is a terminal, close it
--- else, close the first terminal in tab
function M.close(index)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, true, true)

    if term then
        term:close()
    end
end

function M.kill(index)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, true, false)

    if term then
        term:kill()
    end
end

function M.toggle(index, layout, force)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, true, false)

    if term then
        term:toggle(layout, force)
    else
        M.run(nil, { layout = layout })
    end
end

function M.send(index, data)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, true, true)

    if term then
        term:send(data)
    end
end

function M.current_term_index()
    local term = active_terminals:get_current_buf_terminal()
    if term then
        return term:get_index()
    end
end

return M
