local terminal = require("terminal")
local command = vim.api.nvim_create_user_command

command("TermOpen", function(args)
    local layout = args.args ~= "" and { open_cmd = args.args }
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
    bang = true,
    desc = "Terminal: Kill terminal {N}",
})

command("TermToggle", function(args)
    local layout = args.args ~= "" and { open_cmd = args.args }
    terminal.toggle(args.count, layout, args.bang)
end, {
    count = true,
    nargs = "*",
    bang = true,
    desc = "Terminal: Toggle terminal {N}",
})

command("TermRun", function(args)
    local opts
    if args.bang then
        opts = {
            layout = { open_cmd = "enew" },
        }
    end
    local cmd = args.args ~= "" and vim.fn.expand(args.args)
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
