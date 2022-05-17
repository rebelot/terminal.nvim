local terminal = require("terminal")
local M = {}

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
            vim.o.operatorfunc = "v:lua.require'terminal.mappings'.send_opfunc"
            return "g@"
        end
        local marks = mode == "V" and { "'<", "'>" } or { "'[", "']" }
        local data = get_marked_text(unpack(marks))
        terminal.send(index, data)
    end

    return M.send_opfunc()
end

function M.register_send(reg, data)
    return function()
        local index = vim.v.count ~= 0 and vim.v.count or nil
        reg = reg or "t"

        function M.send_opfunc(motion)
            if not motion then
                vim.o.operatorfunc = "v:lua.require'terminal.mappings'.send_opfunc"
                return "g@"
            end
            vim.api.nvim_command('normal! `["' .. reg .. "y`]")
            terminal.send(index, data or vim.fn.getreg(reg))
        end

        return M.send_opfunc()
    end
end

local function with_count(func)
    local count = vim.v.count
    count = count ~= 0 and count or nil
    func(count)
end

function M.cycle_next()
    with_count(function(count)
        count = count or 1
        terminal.cycle(math.abs(count))
    end)
end

function M.cycle_prev()
    with_count(function(count)
        count = count or 1
        terminal.cycle(-math.abs(count))
    end)
end

function M.toggle(layout, force)
    if layout then
        return function()
            with_count(function(count)
                terminal.toggle(count, layout, force)
            end)
        end
    end
    with_count(terminal.toggle)
end

function M.open(layout, force)
    if layout then
        return function()
            with_count(function(count)
                terminal.open(count, layout, force)
            end)
        end
    end
    with_count(terminal.open)
end

function M.close()
    with_count(terminal.close)
end

function M.kill()
    with_count(terminal.kill)
end

function M.run(cmd, opts)
    if cmd or opts then
        return function()
            terminal.run(cmd, opts)
        end
    end
    terminal.run()
end

function M.send(data)
    return function()
        with_count(function(count)
            terminal.send(count, data)
        end)
    end
end

return M
