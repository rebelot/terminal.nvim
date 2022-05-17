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

function M.add_newline(data)
    if type(data) == "table" then
        if data[#data] ~= "" then
            table.insert(data, "")
        end
    elseif type(data) == "string" then
        if data:sub(-1) ~= "\n" then
            data = data .. "\n"
        end
    end
    return data
end

function M.skip_blank_lines(data)
    if type(data) == "string" then
        data = vim.fn.split(data, "\n")
    end
    return vim.tbl_filter(function(line)
        return line ~= ""
    end, data)
end

function M.unindent(data)
    if type(data) == "string" then
        data = vim.fn.split(data, "\n")
    end
    return vim.tbl_map(vim.fn.trim, data)
end


return M
