local M = {}

function M.make_float(layout) end

---@param layout table
function M.make_buf_and_win(layout)
    local winid, bufnr
    if layout.open_cmd ~= "float" then
        vim.cmd(layout.open_cmd)
        winid = vim.fn.win_getid()
        bufnr = vim.api.nvim_get_current_buf()
    else
        winid, bufnr = M.make_float(layout)
    end
    return bufnr, winid
end

return M
