local M = {}

---@return number row
---@return number col
---@return number height
---@return number width
function M.percentbbox(h, w)
    h, w = h or 0.8, w or 0.8
    local row, col, height, width
    if h <= 1 then
        row = math.floor(vim.o.lines / 2 * (1 - h)) - 1
        height = math.floor(vim.o.lines * h)
    else
        row = math.floor(vim.o.lines / 2 - h / 2) - 1
        height = h
    end

    if w <= 1 then
        col = math.floor(vim.o.columns / 2 * (1 - w))
        width = math.floor(vim.o.columns * w)
    else
        col = math.floor(vim.o.columns / 2 - w / 2)
        width = w
    end
    return row, col, height, width
end

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
