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

function M.cycle_next()
    if not utils.cur_buf_is_term() then
        return
    end
    local terminals = active_terminals:get_sorted_terminals()
    local index = get_current_term_index(terminals)
    if index + 1 > #terminals then
        index = 0
    end
    vim.api.nvim_win_set_buf(0, terminals[index + 1].bufnr)
end

function M.cycle_prev()
    if not utils.cur_buf_is_term() then
        return
    end
    local terminals = active_terminals:get_sorted_terminals()
    local index = get_current_term_index(terminals)
    if index - 1 < 1 then
        index = #terminals + 1
    end
    vim.api.nvim_win_set_buf(0, terminals[index - 1].bufnr)
end

function M.run(cmd, opts)
    opts = opts or {}
    cmd = cmd or vim.fn.input("Command: ", "", "shellcmd")
    opts.cmd = cmd ~= "" and cmd or nil
    local term = terminal:new(opts)
    term:open()
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
    local tab_terminals = active_terminals:get_current_tab_terminals()
    if not next(tab_terminals) then
        M.open(index)
    else
        M.close(index)
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

local function get_marked_text(m1, m2)
    local _, srow, scol, _ = unpack(vim.fn.getpos(m1))
    local _, erow, ecol, _ = unpack(vim.fn.getpos(m2))

    local start_row, start_col, end_row, end_col
    if srow < erow or (srow == erow and scol <= ecol) then
        start_row, start_col, end_row, end_col = srow - 1, scol - 1, erow - 1, ecol
    else
        start_row, start_col, end_row, end_col = erow - 1, ecol - 1, srow - 1, scol
    end

    local max_col = 2147483646
    end_col = end_col <= max_col and end_col or max_col
    start_col = start_col >= 0 and start_col or 0

    return vim.api.nvim_buf_get_text(0, start_row, start_col, end_row, end_col, {})
end

-- this was tough.
function M.operator_send()
    local index = vim.v.count ~= 0 and vim.v.count or nil
    local mode = vim.fn.mode()

    function M.send_opfunc(motion)
        if not motion then
            vim.o.operatorfunc = "v:lua.require'terminal'.send_opfunc"
            return "g@"
        end
        local marks = mode == "V" and { "'<", "'>" } or { "'[", "']" }
        local data = get_marked_text(unpack(marks))
        M.send(index, data)
    end

    return M.send_opfunc()
end

vim.keymap.set({ "n", "x" }, "<leader>ts", M.operator_send, { expr = true })

--TODO: use BufWinLeave <buffer> + nvim_win_set_buf
--to freeze terminal buffer to window
return M
