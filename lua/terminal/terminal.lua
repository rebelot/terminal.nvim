-- Create a Terminal object to manage a terminal emulator instance
-- spawned by neovim.

-- Once spawned, Termianl objects are stored in `active_terminals` table.
-- Once the terminal is closed (the process is terminated),
-- it is removed from the table.

local utils = require("terminal.utils")
local ui = require("terminal.ui")

local defaults = {
    layout = { style = "split" },
    cmd = vim.o.shell,
}

---@type table {jobid: number = terminal: Terminal}
local active_terminals = {}

---@class Terminal
---@field cmd string
---@field layout table
---@field clear_env boolean
---@field env table
---@field on_exit function
---@field on_stdout function
---@field on_stderr function
---@field bufnr number
---@field job_id number
---@return Terminal
local Terminal = {}

function Terminal:new(term)
    term = term or {}
    term.layout = term.layout or defaults.layout
    term.cmd = term.cmd or defaults.cmd
    setmetatable(term, { __index = self })
    return term
end

---spawn a new terminal: assign a jobid and append to active_terminals
---@return boolean
function Terminal:_spawn()
    local cmd = self.cmd
    local opts = {
        detach = 1,
        cwd = self.cwd,
        clear_env = self.clear_env,
        env = self.env,
        on_exit = self.on_exit,
        on_stdout = self.on_stdout,
        on_stderr = self.on_stderr,
    }
    local jobid = vim.fn.termopen(cmd, opts)
    if jobid > 0 then
        self.jobid = jobid
        active_terminals[jobid] = self
        return true
    end
    return false
end

---Return true if the terminal was spawned (has a jobid and bufnr)
---@return boolean
function Terminal:is_attached()
    if not (self.bufnr and self.jobid) then
        return false
    end
    return true
end

---Get the ids of windows displaying the terminal
---@return table window_ids
function Terminal:get_windows()
    if self.bufnr then
        return vim.fn.win_findbuf(self.bufnr)
    end
    return {}
end

---Get the ids of window displaying the terminal in the current tab
---@return table window_ids
--WARN: method is coupled with get_windows
function Terminal:get_current_tab_windows()
    local windows = {}
    for _, winid in ipairs(self:get_windows()) do
        if utils.win_is_in_current_tab(winid) then
            table.insert(windows, winid)
        end
    end
    return windows
end

---Display the terminal in the current tab
---if the terminal was not spawned, it will be spawned
---if the terminal is already displayed, the first window containing it will be focused
---if |force| is true, a new window for the terminal will always be displayed.
---@param force boolean
function Terminal:open(force)
    local winid = self:get_current_tab_windows()[1]
    if winid and not force then
        vim.api.nvim_set_current_win(winid)
        return
    end

    local bufnr, new_winid = ui.make_buf_and_win(self.layout)

    if not self:is_attached() then
        self:_spawn()
        self.bufnr = bufnr
    else
        vim.api.nvim_win_set_buf(new_winid, self.bufnr)
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end

    if not self:is_attached() then
        print("something went wrong!")
        vim.api.nvim_win_close(new_winid, true)
        vim.api.nvim_buf_delete(bufnr, { force = true })
    end
end

---Close the (first) terminal window in the current tab
function Terminal:close()
    local winid = self:get_current_tab_windows()[1]
    if not winid then
        return
    end
    vim.api.nvim_win_close(winid, true)
    self.winid = nil
end

---Toggle terminal window
function Terminal:toggle()
    if next(self:get_current_tab_windows()) then
        self:close()
    else
        self:open()
    end
end

---Close terminal window and kill the process
function Terminal:kill()
    if not self:is_attached() then
        return
    end
    self:close()
    vim.fn.jobstop(self.jobid)
    vim.api.nvim_buf_delete(self.bufnr, {force = true})
    -- on_term_close will handle cleanup
end

--- autocommand to intercept opened terminals
--- that were not instances of Terminal
function Terminal:on_term_open(bufnr)
    local jobid = vim.b[bufnr].terminal_job_id
    if active_terminals[jobid] then
        return
    end
    local cmd = vim.b.term_title:gsub(".-/%d*:(.*)", "%1")
    -- TODO: setting cmd using term_title could be risky
    -- get window layout
    active_terminals[jobid] = self:new({
        jobid = jobid,
        cmd = cmd,
        bufnr = bufnr,
    })
end

--- autocommand to ensure closed terminals are always removed from active_terminals
function Terminal.on_term_close(bufnr)
    local jobid = vim.b[bufnr].terminal_job_id
    local term = active_terminals[jobid]
    term.bufnr = nil
    term.jobid = nil
    active_terminals[jobid] = nil
end

function Terminal.get_sorted_active_terminals()
    local terminals = {}
    local keys = vim.tbl_keys(active_terminals)
    table.sort(keys)
    for _, key in ipairs(keys) do
        table.insert(terminals, active_terminals[key])
    end
    return terminals
end

function Terminal.get_active_terminals()
    return active_terminals
end

function Terminal.get_current_buf_terminal()
    local jobid = vim.b.terminal_job_id
    if not jobid then
        return
    end
    return active_terminals[jobid]
    -- local bufnr = vim.api.nvim_get_current_buf()
    -- for _, term in ipairs(active_terminals) do
    --     if term.bufnr == bufnr then
    --         return term
    --     end
    -- end
end

---Filter sorted active_terminals for the ones displayed in the current tab
---@return table Terminal
function Terminal:get_current_tab_terminals()
    return vim.tbl_filter(function(terminal)
        return next(terminal:get_current_tab_windows()) ~= nil
    end, self.get_sorted_active_terminals())
end

return Terminal
