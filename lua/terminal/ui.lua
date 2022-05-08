local M = {}

---@param layout table
function M.make_buf_and_win(layout)
    if layout.style == "split" then
        vim.cmd("botright " .. (layout.height or "") .. "new")
    elseif layout.style == "vertical" then
        vim.cmd("botright vertical " .. (layout.width or "") .. "new")
    end
    local winid = vim.fn.win_getid()
    local bufnr = vim.api.nvim_get_current_buf()
    return bufnr, winid
end

function M.open_with_layout(term, layout)
    if layout then
        term.layout = layout
        term:open(true)
    else
        term:open()
    end
end

return M
