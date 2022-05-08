local M = {}

---Check if the current window is displayed in the current tab
---@return boolean
function M.win_is_in_current_tab(winid)
    return vim.fn.win_id2win(winid) ~= 0
end

---Check if the current buffer is a terminal
---@return boolean
function M.cur_buf_is_term()
    return vim.b.terminal_job_id ~= nil
end


return M
