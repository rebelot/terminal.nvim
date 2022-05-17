local M = {}

local function percentbbox(h, w)
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

local function make_buf_and_float_win(layout)
    local bufnr = vim.api.nvim_create_buf(true, false)
    local row, col, height, width = percentbbox(layout.height, layout.width)

    local win_opts = {
        relative = "editor",
        row = row,
        col = col,
        width = width,
        height = height,
        focusable = true,
        style = "minimal",
        border = layout.border or "none",
    }
    local winid = vim.api.nvim_open_win(bufnr, true, win_opts)
    return bufnr, winid
end

---Create buffer and window for the terminal
---@param layout table
---@return number bufnr
---@return number winid
function M.make_buf_and_win(layout)
    if layout.open_cmd == "float" then
        return make_buf_and_float_win(layout)
    end
    vim.cmd(layout.open_cmd)
    local winid = vim.fn.win_getid()
    local bufnr = vim.api.nvim_get_current_buf()
    return bufnr, winid
end

return M
