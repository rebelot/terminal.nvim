---@class active_terminals
local mt = {}

---@type active_terminals
local active_terminals = {}

---Return a list of Terminal objects sorted by their job_id
---@return table<Terminal>
function mt:get_sorted_terminals()
    local terminals = {}
    local keys = vim.tbl_keys(self)
    table.sort(keys)
    for _, key in ipairs(keys) do
        table.insert(terminals, active_terminals[key])
    end
    return terminals
end

---Get the terminal object in the current buffer
---@return Terminal | nil
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

---Get the index of a given terminal within the sorted active_terminals list
---@param term Terminal
---@return integer|nil
function mt:get_term_index(term)
    local terminals = self:get_sorted_terminals()
    for i, t in ipairs(terminals) do
        if t.jobid == term.jobid then
            return i
        end
    end
end

---Get the length of the active_terminals list
---@return integer
function mt:len()
    return #vim.tbl_keys(self)
end

---Filter sorted active_terminals for the ones displayed in the current tab
---@return Terminal
function mt:get_current_tab_terminals()
    return vim.tbl_filter(function(terminal)
        return next(terminal:get_current_tab_windows()) ~= nil
    end, self:get_sorted_terminals())
end

setmetatable(active_terminals, { __index = mt })

return active_terminals
