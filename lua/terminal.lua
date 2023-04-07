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

local default_config = {
    layout = { open_cmd = "botright new" },
    cmd = { vim.o.shell },
    autoclose = false,
}

function M.setup(config)
    M.config = vim.tbl_deep_extend("force", default_config, config or {})
    require("terminal.commands")

    init_autocmds()
end

---Check validity of index
---@param index integer
---@return boolean
local function is_valid_index(index)
    if index > active_terminals:len() then
        vim.notify("Terminal: invalid terminal index " .. index, vim.log.levels.ERROR)
        return false
    end
    return true
end

---Set the index of the terminal to use as the target for terminal actions
---@param index integer
function M.set_target(index)
    if is_valid_index(index) then
        M.target_term = index
    end
end

---Logic to pick the terminal to use as the target for terminal actions
---If index is given, use that
---if taget_term is set, use that
---if current buffer is a terminal and cur_buf is true, use that
---if current tab contains a terminal, use that (first window)
---if tab_only is false, fallback to last terminal in active_terminals
---@param index? integer
---@param cur_buf boolean
---@param tab_only boolean
---@return Terminal|nil
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

---Cycle through step terminal buffers
---@param step? integer
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

---Run cmd in a terminal with given opts
---@param cmd? string | table
---@param opts? table
function M.run(cmd, opts)
    opts = opts or {}
    if not cmd then
        local ok, input = pcall(vim.fn.input, "Command: ", "", "shellcmd")
        if not ok then
            return
        end
        cmd = vim.fn.expandcmd(input)
    end
    opts.cmd = cmd ~= "" and cmd or nil
    terminal:new(opts):open()
end

---Open a terminal with given layout.
---If no terminal exists, create one.
---if index is given, use that
---if target_term is set, use that
---if tab contains a terminal, switch to that (first window)
---else, fallback to last terminal in active_terminals
---@param index? integer
---@param layout? table
---@param force? boolean
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

---Close a terminal window
---if index is given or target_term is set, close that terminal window.
---if current buffer is a terminal, close it
---else, close the first terminal in tab
---@param index? integer
function M.close(index)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, true, true)

    if term then
        term:close()
    end
end

---Kill a terminal job
---if index is given or target_term is set, kill that terminal.
---if current buffer is a terminal, kill it
---if current tab contains a terminal, kill the first terminal in tab
---else, kill the last terminal in active_terminals
---@param index? integer
function M.kill(index)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, true, false)

    if term then
        term:kill()
    end
end

---Toggle a terminal window.
---If no terminal exists, create one.
---if index is given or target_term is set, toggle that terminal.
---if current buffer is a terminal, toggle (close) it
---if current tab contains a terminal, toggle (close) the first terminal in tab
---else, toggle the last terminal in active_terminals
---@param index? integer
---@param layout? table
---@param force? boolean
function M.toggle(index, layout, force)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, true, false)

    if term then
        term:toggle(layout, force)
    else
        M.run(nil, { layout = layout })
    end
end

---Send text to a terminal
---@param index? integer
---@param data string | table
function M.send(index, data)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, true, true)

    if term then
        term:send(data)
    end
end

---Get the index of the current terminal
---@return integer|nil
function M.current_term_index()
    local term = active_terminals:get_current_buf_terminal()
    if term then
        return term:get_index()
    end
end

---Get the current buffer terminal
---@return Terminal|nil
function M.get_current_term()
    local term = active_terminals:get_current_buf_terminal()
    return term
end

---Change the layout of the selected terminal
---@param index? integer 
---@param layout table 
function M.move(index, layout)
    index = (index and index ~= 0) and index or nil
    local term = get_target_terminal(index, true, false)
    if term then
        term.layout = layout
        term:close()
        term:open()
    end
end

return M
