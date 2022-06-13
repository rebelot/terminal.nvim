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

Default: `{ open_cmd = "botright new"}`

`layout.open_cmd`:

Vim command used to create the new buffer and window.

Float Layout:
When `open_cmd = "float"`, `layout.height` and `layout.width`
are used to determine the height and width of the floating
window. Values `<= 1` are interpreted as percentage of
screen space.

#### config.cmd

Default command for new terminals

Type: `table|string` passed to `termopen` (`:h jobstart()`)

Default: `{ vim.o.shell }`

#### config.autoclose

Automatically close terminal window when the process exits (on `TermClose`).

Type: `bool`

Default: `false`

## Functions

#### setup()

Signature: `setup(config)`

params:

- `config` (`table`): user configuration

Set up the plugin with user `config`.
A call to this function is always required.

#### set_target()

Signature: `set_target(index)`

Set the `index` terminal as the target for other actions.

params:

- `index` (`integer`): Terminal index.

#### cycle()

Signature: `cycle(step)`

params:

-`step` (`integer`): Increment number for cycling.

Cycle between active terminals.

#### run()

Signature: `run(cmd?, opts?)`

params:

- `cmd` (`table|string`): command to be executed by the terminal.
- `opts` (`table`): options to be passed to `termopen`

Run a command in terminal with given options. If no command
is provided, user will be prompted to insert one;
If `cmd` is an empty string, `config.cmd` will be used.

#### open()

Signature: `open(index, layout, force)`

params:

-`index`(`integer`): terminal index -`layout` (`table`): layout spec -`force` (`bool`): Force opening the terminal window even if it already visible in the current tab.

Open a terminal with given layout.

#### close()

Signature: `close(index)`

params:

- `index`(`integer`): terminal index

Close a terminal window.

#### kill()

Signature: `kill(index)`

params:

- `index`(`integer`): terminal index

Kill a terminal job and close its window.

#### toggle()

Signature: `toggle(index, layout, force)`

params:

- `index`(`integer`): terminal index
- `layout` (`table`): layout spec
- `force` (`bool`): Force opening the terminal window even if it already visible in the current tab.

Open a terminal with given layout, or close its window
if it's visible in the current tab (unless `force` is `true`).

#### send()

Signature: `send(index, data)`

params:

- `index`(`integer`): terminal index
- `data` (`table|string`): Text to be sent to the terminal via `chansend()`

## Commands

#### TermRun

:TermRun[!] [command]

Run [command] in terminal. If command is empty, user will be prompted
to enter one, falling back to `config.cmd`. With [!] the new terminal window
will replace the current buffer.

#### TermOpen

:TermOpen[!] [count]

Open terminal with [count] index. With [!], a new window will be
created even if the terminal is already displayed in the current tab.

#### TermClose

#### TermToggle

#### TermKill

#### TermSend

#### TermSetTarget

## Named Terminals

## Donate

Buy me coffee and support my work ;)

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/donate/?business=VNQPHGW4JEM3S&no_recurring=0&item_name=Buy+me+coffee+and+support+my+work+%3B%29&currency_code=EUR)
