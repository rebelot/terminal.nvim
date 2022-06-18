<!-- panvimdoc-ignore-start -->

<p align="center">
  <h2 align="center">terminal.nvim</h2>
</p>
<p align="center">
  <img src="assets/terminal.png" width="600" >
</p>
<p align="center">The Neovim Terminal Manager</p>

<!-- panvimdoc-ignore-end -->

# Terminal.nvim

## Installation

```lua
use({
    'rebelot/terminal.nvim',
    config = function()
        require("terminal").setup()
    end
})
```

---

## Config

Default config

```lua
{
    layout = { open_cmd = "botright new" },
    cmd = { vim.o.shell },
    autoclose = false,
}
```

#### config.layout

Specify the layout of the terminal window.

Type: `table`

Default: `{ open_cmd = "botright new" }`

##### config.layout.open_cmd:

Vim command used to create the new buffer and window.

##### Float Layout:

When `open_cmd = "float"`, `layout.height` and `layout.width`
are used to determine the height (lines) and width (columns)
of the floating window.
Values `<= 1` are interpreted as percentage of screen space.

#### config.cmd

Default command for new terminals

Type: `table|string` passed to `termopen` (`:h jobstart()`)

Default: `{ vim.o.shell }`

#### config.autoclose

Automatically close terminal window when the process exits (on `TermClose`).

Type: `bool`

Default: `false`

---

## Functions

#### setup()

`setup(config)`

Params:

- `config` (`table`): user configuration

Set up the plugin with user `config`.
A call to this function is always required.

#### set_target()

`set_target(index)`

Params:

- `index` (`integer`): Terminal index.

Set the `index` terminal as the target for other actions.

#### cycle()

`cycle(step)`

Params:

- `step` (`integer`): Increment number for cycling.

Cycle between active terminals.

#### run()

`run(cmd?, opts?)`

Params:

- `cmd` (`table|string`): command to be executed by the terminal.
- `opts` (`table`): options to be passed to `termopen`

Run a command in terminal with given options. If no command
is provided, user will be prompted to insert one;
If `cmd` is an empty string, `config.cmd` will be used.

#### open()

`open(index, layout, force)`

Params:

- `index`(`integer`): terminal index
- `layout` (`table`): layout spec
- `force` (`bool`): Force opening the terminal window even if it already visible in the current tab.

Open a terminal with given layout.

#### close()

`close(index)`

Params:

- `index`(`integer`): terminal index

Close a terminal window.

#### kill()

`kill(index)`

Params:

- `index`(`integer`): terminal index

Kill a terminal job and close its window.

#### toggle()

`toggle(index, layout, force)`

Params:

- `index`(`integer`): terminal index
- `layout` (`table`): layout spec
- `force` (`bool`): Force opening the terminal window even if it already visible in the current tab.

Open a terminal with given layout, or close its window
if it's visible in the current tab (unless `force` is `true`).

#### send()

`send(index, data)`

Params:

- `index`(`integer`): terminal index
- `data` (`table|string`): Text to be sent to the terminal via `chansend()`

#### current_term_index()

`current_term_index()`

Get the index of the terminal in the current window.

#### current_term()

`get_current_term()`

Get the terminal object displayed in the current window.

---

## Keymaps

Keymaps can be set up using the API defined in `terminal.mappings.`
When called with parameters, each keymap API function returns a
pre-loaded function with given parameters. Otherwise, the corresponding
terminal function will be called with default arguments.

##### Example mappings

```lua
local term_map = require("terminal.mappings")
vim.keymap.set({ "n", "x" }, "<leader>ts", term_map.operator_send, { expr = true })
vim.keymap.set("n", "<leader>to", term_map.toggle)
vim.keymap.set("n", "<leader>tO", term_map.toggle({ open_cmd = "enew" }))
vim.keymap.set("n", "<leader>tr", term_map.run)
vim.keymap.set("n", "<leader>tR", term_map.run(nil, { layout = { open_cmd = "enew" } }))
vim.keymap.set("n", "<leader>tk", term_map.kill)
vim.keymap.set("n", "<leader>t]", term_map.cycle_next)
vim.keymap.set("n", "<leader>t[", term_map.cycle_prev)
```

---

## Commands

#### TermRun

:TermRun[!] [command]

Run [command] in terminal. If command is empty, user will be prompted
to enter one, falling back to `config.cmd`. With [!] the new terminal window
will replace the current buffer.

#### TermOpen

:[count]TermOpen[!]

Open terminal with [count] index. With [!], a new window will be
created even if the terminal is already displayed in the current tab.

#### TermClose

:[count]TermClose

Close terminal with [count] index.

#### TermToggle

:[count]TermToggle[!] [open_cmd]

Toggle terminal with [count] index and layout specified by [open_cmd].
With [!], a new window will be created even if the terminal is already displayed in the current tab.

#### TermKill

:[count]TermKill

Kill terminal with [count] index.

#### TermSend

:[count]TermSend [text]

Send [text] to terminal with [count] index.

#### TermSetTarget

:[count]TermSetTarget

Set terminal with [count] index as target for terminal actions.

---

## Terminal objects

#### terminal:new()

`terminal:new(opts)`

Params:

- `opts` (`table`):
  - layout (`table`): layout spec
  - cmd (`table|string`): command to be executed by the terminal
  - autoclose (`bool`): automatically close terminal window when the process exits
  - cwd (`string|function->string|nil`): CWD of the terminal job.
  - Other fields passed to `jobstart`:
    - clear_env
    - env
    - on_exit
    - on_stdout
    - on_stderr

#### terminal:open()

`terminal:open(layout, force)`

Params:

- `layout` (`table`): layout spec
- `force` (`bool`): Force opening the terminal window even if it already visible in the current tab.

Open the terminal with given layout.

#### terminal:close()

`terminal:close()`

Close the terminal window in the current tab.

#### terminal:toggle()

`terminal:toggle(layout, force)`

Params:

- `layout` (`table`): layout spec
- `force` (`bool`): Force opening the terminal window even if it already visible in the current tab.

Open the terminal with given layout, or close its window
if it's visible in the current tab (unless `force` is `true`).

#### terminal:kill()

`terminal:kill()`

Kill a terminal job and close its window.

#### terminal:send()

`terminal:send(data)`

Params:

- `data` (`table|string`): Text to be sent to the terminal via `chansend()`

Send text to terminal.

### Named Terminals

##### IPython:

```lua
local ipython = require("terminal").terminal:new({
    layout = { open_cmd = "botright vertical new" },
    cmd = { "ipython" },
    autoclose = true,
})

vim.api.nvim_create_user_command("IPython", function()
    ipython:toggle(nil, true)
    local bufnr = vim.api.nvim_get_current_buf()
    vim.keymap.set(
        "x",
        "<leader>ts",
        function()
            vim.api.nvim_feedkeys('"+y', 'n', false)
            ipython:send("%paste")
        end,
        { buffer = bufnr }
    )
    vim.keymap.set("n", "<leader>t?", function()
        ipython:send(vim.fn.expand("<cexpr>") .. "?")
    end, { buffer = bufnr })
end, {})
```

##### Lazygit:

```lua
local lazygit = require("terminal").terminal:new({
    layout = { open_cmd = "float", height = 0.9, width = 0.9 },
    cmd = { "lazygit" },
    autoclose = true,
})
vim.env["GIT_EDITOR"] = "nvr -cc close -cc split --remote-wait +'set bufhidden=wipe'"
vim.api.nvim_create_user_command("Lazygit", function(args)
    lazygit.cwd = args.args and vim.fn.expand(args.args)
    lazygit:toggle(nil, true)
end, { nargs = "?" })
```

##### Htop:

```lua
local htop = require("terminal").terminal:new({
    layout = { open_cmd = "float" },
    cmd = { "htop" },
    autoclose = true,
})
vim.api.nvim_create_user_command("Htop", function()
    htop:toggle(nil, true)
end, { nargs = "?" })
```

---

## Tips

##### Useful terminal mappings

```vim
tnoremap <c-\><c-\> <c-\><c-n>
tnoremap <c-h> <c-\><c-n><c-w>h
tnoremap <c-j> <c-\><c-n><c-w>j
tnoremap <c-k> <c-\><c-n><c-w>k
tnoremap <c-l> <c-\><c-n><c-w>l
```

##### Auto insert mode

```lua
vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter", "TermOpen" }, {
    callback = function(args)
        if vim.startswith(vim.api.nvim_buf_get_name(args.buf), "term://") then
            vim.cmd("startinsert")
        end
    end,
})
```

##### terminal window highlight

```lua
vim.api.nvim_create_autocmd("TermOpen", {
    command = [[setlocal nonumber norelativenumber winhl=Normal:NormalFloat]]
})
```

##### Statusline integration

Use `terminal.current_term_index()` to get the current terminal index and display it within the statusline.

## Donate

Buy me coffee and support my work ;)

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/donate/?business=VNQPHGW4JEM3S&no_recurring=0&item_name=Buy+me+coffee+and+support+my+work+%3B%29&currency_code=EUR)
