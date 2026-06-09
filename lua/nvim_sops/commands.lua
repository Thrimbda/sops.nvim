local utils = require('nvim_sops.utils')
local debug = utils.debug
local sops = require('nvim_sops.sops')


local M = {}

local function notify_error(message)
  vim.api.nvim_echo({ { 'sops.nvim: ' .. message, 'ErrorMsg' } }, true, {})
end

local function notify_info(message)
  vim.api.nvim_echo({ { 'sops.nvim: ' .. message, 'None' } }, true, {})
end

local function set_secret_buffer_options()
  vim.opt_local.swapfile = false
  vim.opt_local.undofile = false
  pcall(function()
    vim.opt_local.backup = false
  end)
  pcall(function()
    vim.opt_local.writebackup = false
  end)
end

local function temp_path_for(path)
  local dir = vim.fn.fnamemodify(path, ':h')
  local name = vim.fn.fnamemodify(path, ':t')
  local pid = vim.fn.getpid()
  local uv = vim.uv or vim.loop
  local nonce = uv and tostring(uv.hrtime()) or tostring(vim.fn.reltimefloat(vim.fn.reltime()))

  for index = 1, 100 do
    local candidate = dir .. '/.' .. name .. '.sops.nvim-' .. pid .. '-' .. nonce .. '-' .. index .. '.tmp'
    if vim.fn.getftype(candidate) == '' then
      return candidate
    end
  end
end

local function write_encrypted_file(path, encrypted_text)
  local temp_path = temp_path_for(path)
  if not temp_path then
    return false, 'Unable to create temporary encrypted output path'
  end

  local write_code, write_err = utils.write_text_file_exclusive(temp_path, encrypted_text)
  if write_code ~= 0 then
    vim.fn.delete(temp_path)
    return false, 'Unable to write encrypted temporary file: ' .. temp_path .. (write_err and ('\n' .. write_err) or '')
  end

  local permissions = vim.fn.getfperm(path)
  if permissions ~= '' then
    vim.fn.setfperm(temp_path, permissions)
  end

  local ok, err = os.rename(temp_path, path)
  if not ok then
    vim.fn.delete(temp_path)
    return false, err or 'Unable to replace target file'
  end

  return true
end

local function write_new_encrypted_file(path, encrypted_text)
  if vim.fn.getftype(path) ~= '' then
    return false, 'Refusing to overwrite existing file: ' .. path
  end

  local write_code, write_err = utils.write_text_file_exclusive(path, encrypted_text)
  if write_code ~= 0 then
    return false, 'Unable to write encrypted file: ' .. path .. (write_err and ('\n' .. write_err) or '')
  end

  return true
end

local function current_file_path(path)
  return vim.fn.fnamemodify(path or vim.fn.expand('%:p'), ':p')
end

local function current_buffer_file_path()
  local path = vim.fn.expand('%:p')
  if path == '' then
    return
  end

  return vim.fn.fnamemodify(path, ':p')
end

local function path_join(dir, name)
  local separator = '/'
  if dir:sub(-1) == '/' then
    separator = ''
  end

  return dir .. separator .. name
end

local source_suffixes = {
  { suffix = '.env', encrypted_suffix = '.enc.env' },
  { suffix = '.json', encrypted_suffix = '.enc.json' },
  { suffix = '.yaml', encrypted_suffix = '.enc.yaml' },
}

local function target_name_for_source(path)
  local name = vim.fn.fnamemodify(path, ':t')

  for _, item in ipairs(source_suffixes) do
    if name:sub(-#item.encrypted_suffix) == item.encrypted_suffix then
      return
    end

    if name:sub(-#item.suffix) == item.suffix then
      return name:sub(1, #name - #item.suffix) .. item.encrypted_suffix
    end
  end

  if name:sub(-#'.enc') == '.enc' then
    return
  end

  return name .. '.enc'
end

local function target_dir_for(arg, source_file)
  if not arg or arg == '' then
    return vim.fn.fnamemodify(source_file, ':h')
  end

  local dir = vim.fn.fnamemodify(vim.fn.expand(arg), ':p')
  if vim.fn.getftype(dir) ~= 'dir' then
    return nil, 'Target path is not a directory: ' .. arg
  end

  return dir
end

local function clear_buffer_state()
  vim.b.nvim_sops_managed = false
  vim.b.nvim_sops_path = nil
  vim.b.nvim_sops_endofline = nil
end

M.read_encrypted = function(path)
  local input_file = current_file_path(path)
  debug('decrypting into buffer', input_file)

  local result = sops.decrypt_file(input_file)
  if not result.ok then
    clear_buffer_state()
    vim.bo.modified = false
    vim.bo.readonly = true
    vim.bo.modifiable = false
    notify_error('Error decrypting file: ' .. input_file .. '\n' .. result.output)
    return
  end

  vim.bo.modifiable = true
  vim.bo.readonly = false
  set_secret_buffer_options()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, utils.split_lines(result.output))
  vim.b.nvim_sops_managed = true
  vim.b.nvim_sops_path = input_file
  vim.b.nvim_sops_endofline = result.output:sub(-1) == '\n'
  vim.bo.modified = false
end

M.write_encrypted = function(path)
  local output_file = current_file_path(path or vim.b.nvim_sops_path)

  if not vim.b.nvim_sops_managed or vim.b.nvim_sops_path ~= output_file then
    notify_error('Refusing to write SOPS file that was not successfully decrypted: ' .. output_file)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local endofline = vim.b.nvim_sops_endofline
  if endofline == nil then
    endofline = vim.bo.endofline
  end
  local plaintext = utils.join_lines(lines, endofline)
  local result = sops.encrypt_text(output_file, plaintext)

  if not result.ok then
    notify_error('Error encrypting file: ' .. output_file .. '\n' .. result.output)
    return
  end

  local ok, err = write_encrypted_file(output_file, result.output)
  if not ok then
    notify_error('Error writing encrypted file: ' .. output_file .. '\n' .. err)
    return
  end

  vim.bo.modified = false
  notify_info('Encrypted file written: ' .. output_file)
end

M.create_encrypted = function(target_dir_arg)
  local source_file = current_buffer_file_path()
  if not source_file then
    notify_error('Current buffer does not have a file path')
    return
  end

  local target_name = target_name_for_source(source_file)
  if not target_name then
    notify_error('Unsupported plaintext file type: ' .. source_file)
    return
  end

  local target_dir, dir_err = target_dir_for(target_dir_arg, source_file)
  if not target_dir then
    notify_error(dir_err)
    return
  end

  local output_file = path_join(target_dir, target_name)
  if vim.fn.getftype(output_file) ~= '' then
    notify_error('Refusing to overwrite existing file: ' .. output_file)
    return
  end

  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local plaintext = utils.join_lines(lines, vim.bo.endofline)
  local result = sops.encrypt_new_text(output_file, plaintext)

  if not result.ok then
    notify_error('Error creating encrypted file: ' .. output_file .. '\n' .. result.output)
    return
  end

  local ok, err = write_new_encrypted_file(output_file, result.output)
  if not ok then
    notify_error(err)
    return
  end

  notify_info('Encrypted file created: ' .. output_file)
end

M.setup_user_commands = function()
  if vim.g.nvim_sops_enabled == false then
    return
  end

  vim.api.nvim_create_user_command('Wsops', function(args)
    M.create_encrypted(args.args)
  end, {
    nargs = '?',
    complete = 'dir',
    desc = 'Create a SOPS encrypted .enc file from the current plaintext buffer',
    force = true,
  })

  vim.cmd([[silent! cunabbrev wsops]])
  vim.cmd([[cnoreabbrev <expr> wsops getcmdtype() ==# ':' && getcmdline() =~# '^\s*wsops$' ? 'Wsops' : 'wsops']])
end

M.setup_autocmds = function()
  local group = vim.api.nvim_create_augroup('nvim_sops', { clear = true })

  if vim.g.nvim_sops_enabled == false then
    return
  end

  M.setup_user_commands()

  vim.api.nvim_create_autocmd('BufReadCmd', {
    group = group,
    pattern = sops.supported_patterns,
    callback = function(args)
      M.read_encrypted(args.match)
    end,
  })

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    group = group,
    pattern = sops.supported_patterns,
    callback = function(args)
      M.write_encrypted(args.match)
    end,
  })
end

return M
