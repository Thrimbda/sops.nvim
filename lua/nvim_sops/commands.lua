local utils = require('nvim_sops.utils')
local debug = utils.debug
local sops = require('nvim_sops.sops')


local M = {}

local function notify_error(message)
  vim.api.nvim_echo({ { 'nvim-sops: ' .. message, 'ErrorMsg' } }, true, {})
end

local function notify_info(message)
  vim.api.nvim_echo({ { 'nvim-sops: ' .. message, 'None' } }, true, {})
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
    local candidate = dir .. '/.' .. name .. '.nvim-sops-' .. pid .. '-' .. nonce .. '-' .. index .. '.tmp'
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

local function current_file_path(path)
  return vim.fn.fnamemodify(path or vim.fn.expand('%:p'), ':p')
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

M.setup_autocmds = function()
  local group = vim.api.nvim_create_augroup('nvim_sops', { clear = true })

  if vim.g.nvim_sops_enabled == false then
    return
  end

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
