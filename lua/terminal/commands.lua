local terminal = require("terminal")
local command = vim.api.nvim_create_user_command

local function parse_layout(args, ignore_args, bang)
    local split = args.smods.split
    local vert = args.smods.vertical

    local open_cmd
    if bang then
        open_cmd = "enew"
    elseif split ~= "" or vert then
        open_cmd = (split ~= "" and (split .. " ") or "") .. (vert and "vertical " or "") .. "new"
    elseif not ignore_args and args.args ~= "" then
        open_cmd = args.args
    end

    return open_cmd and { open_cmd = open_cmd } or nil
end

command("TermOpen", function(args)
    local layout = parse_layout(args)
    terminal.open(args.count, layout, args.bang)
end, {
    count = true,
    bang = true,
    nargs = "*",
    desc = "Terminal: Open terminal {N}",
})

command("TermClose", function(args)
    terminal.close(args.count)
end, {
    count = true,
    desc = "Terminal: Close terminal {N}",
})

command("TermKill", function(args)
    terminal.kill(args.count)
end, {
    count = true,
    desc = "Terminal: Kill terminal {N}",
})

command("TermToggle", function(args)
    local layout = parse_layout(args)
    terminal.toggle(args.count, layout, args.bang)
end, {
    count = true,
    nargs = "*",
    bang = true,
    desc = "Terminal: Toggle terminal {N}",
})

command("TermRun", function(args)
    local opts
    local layout = parse_layout(args, true, args.bang)
    if layout then
        opts = { layout = layout }
    end
    local cmd = args.args ~= "" and vim.fn.expandcmd(args.args) or nil
    terminal.run(cmd, opts)
end, {
    complete = "shellcmd",
    nargs = "*",
    bang = true,
    desc = "Terminal: Toggle terminal {N}",
})

command("TermSend", function(args)
    terminal.send(args.count, vim.fn.expandcmd(args.args))
end, {
    count = true,
    nargs = "*",
    desc = "Terminal: Send text to terminal",
})

command("TermSetTarget", function(args)
    terminal.set_target(args.count)
end, {
    count = true,
    desc = "Terminal: Set target terminal",
})

command("TermMove", function(args)
    terminal.move(args.count, { open_cmd = args.args })
end, {
    count = true,
    nargs = "?",
    desc = "Terminal: change terminal layout"
})
