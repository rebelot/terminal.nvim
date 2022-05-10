local terminal = require("terminal.terminal")
local active_terminals = require("terminal.active_terminals")
local utils = require("terminal.utils")
local ui = require("terminal.ui")

local M = {}

M.terminal = terminal

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
        end,
        group = au_id,
        desc = "on_term_close",
    })
end

function M.setup(config)
    init_autocmds()
end

local function get_current_term_index(terminals)
    local bufnr = vim.api.nvim_get_current_buf()
    for i, term in ipairs(terminals) do
        if term.bufnr == bufnr then
            return i
        end
    end
end

function M.cycle(step)
    step = step or 1
    local terminals = active_terminals:get_sorted_terminals()
    local term
    if not terminals then
        return
    else
        local buf_term = active_terminals:get_current_buf_terminal()
        if buf_term then
            term = buf_term
        else
            local tab_terminals = active_terminals:get_current_tab_terminals()
            if next(tab_terminals) then
                term = tab_terminals[1]
            end
        end
    end
    if not term then
        return
    end

    local index = (term:get_index() + step - 1) % #terminals + 1
    vim.api.nvim_win_set_buf(0, terminals[index].bufnr)
end

function M.run(cmd, opts)
    opts = opts or {}
    cmd = cmd or vim.fn.input("Command: ", "", "shellcmd")
    opts.cmd = cmd ~= "" and cmd or nil
    terminal:new(opts):open()
end

local function is_valid_index(index, max)
    if index == 0 or index > max then
        vim.notify("Terminal: invalid terminal index " .. index, vim.log.levels.ERROR)
        return false
    end
    return true
end

-- if no active terminals, start a new one
-- if index is given, open (or focus) the terminal at the given index
-- else, if tab has terminals, open (focus) the first one
-- else, open the last terminal
function M.open(index, layout)
    local terminals = active_terminals:get_sorted_terminals()

    if not next(terminals) then
        -- if no active terminals, start a new one
        M.run(nil, { layout = layout })
    else
        if index then
            if not is_valid_index(index, #terminals) then
                return
            end
            ui.open_with_layout(terminals[index], layout)
        else
            local tab_terminals = active_terminals:get_current_tab_terminals()
            if next(tab_terminals) then
                ui.open_with_layout(tab_terminals[1], layout)
            else
                ui.open_with_layout(terminals[#terminals], layout)
            end
        end
    end
end

--- if no active terminals in tab, return
--- if index is given, close the terminal at the given index
--- else, if current buffer is a terminal, close it
--- else, close the first terminal in tab
function M.close(index)
    local tab_terminals = active_terminals:get_current_tab_terminals()

    if not next(tab_terminals) then
        -- it would have no effect, since term:close() only closes current-tab windows
        return
    else
        if index then
            local terminals = active_terminals:get_sorted_terminals()
            if not is_valid_index(index, #terminals) then
                return
            end
            terminals[index]:close()
        else
            local buf_term = active_terminals:get_current_buf_terminal()
            if buf_term then
                buf_term:close()
            else
                tab_terminals[1]:close()
            end
        end
    end
end

function M.kill(index)
    local terminals = active_terminals:get_sorted_terminals()

    if not next(terminals) then
        return
    else
        if index then
            if not is_valid_index(index, #terminals) then
                return
            end
            terminals[index]:kill()
        else
            local buf_term = active_terminals:get_current_buf_terminal()
            if buf_term then
                buf_term:kill()
            else
                local tab_terminals = active_terminals:get_current_tab_terminals()
                if next(tab_terminals) then
                    tab_terminals[1]:kill()
                else
                    terminals[1]:kill()
                end
            end
        end
    end
end

function M.toggle(index)
    local terminals = active_terminals:get_sorted_terminals()
    if not next(terminals) then
        M.open()
    else
        if index then
            if not is_valid_index(index, #terminals) then
                return
            end
            terminals[index]:toggle()
        else
            local buf_term = active_terminals:get_current_buf_terminal()
            if buf_term then
                buf_term:toggle()
            else
                local tab_terminals = active_terminals:get_current_tab_terminals()
                if next(tab_terminals) then
                    tab_terminals[1]:toggle()
                else
                    terminals[1]:toggle()
                end
            end
        end
    end
end

function M.send(index, data)
    local terminals = active_terminals:get_sorted_terminals()
    if not next(terminals) then
        return
    else
        if index then
            if not is_valid_index(index, #terminals) then
                return
            end
            terminals[index]:send(data)
        else
            local _, target = next(active_terminals:get_current_tab_terminals())
            if target then
                target:send(data)
            end
        end
    end
end

--TODO: use BufWinLeave <buffer> + nvim_win_set_buf
--to freeze terminal buffer to window
return M
