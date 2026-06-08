# sops.nvim

**sops.nvim** is a lua plugin for neovim that wraps the [SOPS](https://github.com/mozilla/sops) commandline tool.

It was partly inspired by [the vscode extension by signageos](https://github.com/signageos/vscode-sops). It does not implement realtime encryption while editing.

## Attribution

This project is derived from [`prismatic-koi/nvim-sops`](https://github.com/prismatic-koi/nvim-sops), originally created by Ben Sherman. The current automatic edit workflow and ongoing maintenance are by Siyuan Wang.

## Features

- Automatically decrypts supported encrypted files into the current buffer when opened with `:e`
- Automatically encrypts the current buffer back to the target file on `:w`
- Supports automatic editing for `.enc.env`, `.enc.json`, and `.enc.yaml`
- Creates `.enc.env`, `.enc.json`, and `.enc.yaml` files from plaintext `.env`, `.json`, and `.yaml` buffers with `:wsops`
- Allows overriding `AWS_PROFILE`, `SOPS_AGE_KEY_FILE`, or `GOOGLE_APPLICATION_CREDENTIALS` within neovim
- Includes a `debug` option for verbose command information

## Workflow

For files ending in `.enc.env`, `.enc.json`, or `.enc.yaml`, the plugin installs `BufReadCmd` and `BufWriteCmd` handlers.

```vim
:e secrets.enc.yaml
```

Opening the file runs SOPS decrypt and loads the plaintext into the current buffer. The buffer keeps the encrypted filename, but the target file on disk remains encrypted.

```vim
:w
```

Writing the buffer sends the current buffer text to SOPS through a same-directory FIFO, encrypts it with key information read from the existing encrypted file metadata, writes the encrypted output to a same-directory temporary file, and then replaces the target file.

The plugin avoids writing plaintext to the target file path or to a temporary plaintext file. Plaintext still exists in the Neovim process while the buffer is open.

To create a new encrypted file from a plaintext `.env`, `.json`, or `.yaml` buffer, run:

```vim
:wsops
```

The command creates a sibling file with an `.enc` infix, such as `secrets.enc.yaml` for `secrets.yaml` or `.enc.env` for `.env`. To create the encrypted file inside another existing directory, pass that directory:

```vim
:wsops ../encrypted
```

New encrypted file creation uses your SOPS creation rules for the target `.enc.*` filename and refuses to overwrite an existing target.

## Requirements
- The plugin expects you to have the `sops` commandline tool. You can get it here: https://github.com/mozilla/sops/releases
- It expects the binary to be on your `$PATH`, but you can set a custom path in the opts
- It expects your SOPS keys and configuration to be set up already
- Automatic writes support existing encrypted files. `:wsops` can create new encrypted files when SOPS creation rules or other SOPS-supported key configuration match the target encrypted filename

If you use Nix, this repository includes a development shell with `sops` and `age`:

```sh
nix-shell
```

## Installation

### [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'Thrimbda/sops.nvim',
  -- Required for automatic BufReadCmd handling on the first opened file.
  lazy = false,
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  }
}
```

The plugin must be loaded before opening supported encrypted files. Do not lazy-load this plugin on `BufReadPre`, `BufEnter`, or similar file events: that is too late for the first encrypted file because the `BufReadCmd` handlers need to exist before the read starts.

### [packer](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'Thrimbda/sops.nvim',
  config = function()
    require('nvim_sops').setup {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    }
  end
}
```

## Configuration

sops.nvim comes with the following defaults

```lua
{
  enabled = true,
  debug = false,
  binPath = 'sops', -- assumes it is on $PATH
  defaults = {
    awsProfile = nil,
    ageKeyFile = nil,
    gcpCredentialsPath = nil,
  },
}
```

If a value in `defaults` is not set, sops.nvim reads the matching environment variable from the current process:

| Option | Environment variable |
| --- | --- |
| `defaults.awsProfile` | `AWS_PROFILE` |
| `defaults.ageKeyFile` | `SOPS_AGE_KEY_FILE` |
| `defaults.gcpCredentialsPath` | `GOOGLE_APPLICATION_CREDENTIALS` |

## Keymaps
sops.nvim doesnt come with any default keybindings. The workflow is automatic for supported suffixes.
