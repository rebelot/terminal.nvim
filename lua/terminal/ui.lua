local M = {}

local function make_buf_and_float_win(layout)
    local bufnr = vim.api.nvim_create_buf(true, false)
    local row, col, height, width = M.percentbbox(layout.height, layout.width)

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
