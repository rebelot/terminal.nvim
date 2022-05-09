local utils = require("terminal.utils")

---@type table {jobid: number = terminal: Terminal}
local active_terminals = {}
local mt = {}

function mt:get_sorted_terminals()
    local terminals = {}
    local keys = vim.tbl_keys(self)
    table.sort(keys)
    for _, key in ipairs(keys) do
        table.insert(terminals, active_terminals[key])
    end
    return terminals
end

function mt:get_current_buf_terminal()
    local jobid = vim.b.terminal_job_id
    if not jobid then
        return
    end
    return self[jobid]
    -- local bufnr = vim.api.nvim_get_current_buf()
    -- for _, term in ipairs(active_terminals) do
    --     if term.bufnr == bufnr then
    --         return term
    --     end
    -- end
end

function mt:get_current_buf_index()
    local jobid = vim.b.terminal_job_id
    if not jobid then
        return
    end
    for i, term in ipairs(self:get_sorted_terminals()) do
        if term.jobid == jobid then
            return i
        end
    end
end


---Filter sorted active_terminals for the ones displayed in the current tab
---@return table Terminal
function mt:get_current_tab_terminals()
    return vim.tbl_filter(function(terminal)
        return next(terminal:get_current_tab_windows()) ~= nil
    end, self:get_sorted_terminals())
end


setmetatable(active_terminals, { __index = mt })

return active_terminals
