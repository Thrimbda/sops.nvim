local debug = require("nvim_sops.utils").debug
local M = {}

local stdin_file = '__NVIM_SOPS_STDIN_FILE__'

M.supported_patterns = {
  '*.enc.env',
  '*.enc.json',
  '*.enc.yaml',
}

local supported_types = {
  { pattern = '%.enc%.env$', type = 'dotenv' },
  { pattern = '%.enc%.json$', type = 'json' },
  { pattern = '%.enc%.yaml$', type = 'yaml' },
}

M.file_type_for_path = function(path)
  for _, candidate in ipairs(supported_types) do
    if path:match(candidate.pattern) then
      return candidate.type
    end
  end
end

M.get_sops_general_options = function()
  local awsProfile = vim.g.nvim_sops_defaults_aws_profile
  local gcpCredentialsPath = vim.g.nvim_sops_defaults_gcp_credentials_path
  local ageKeyFile = vim.g.nvim_sops_defaults_age_key_file

  local sopsGeneralEnvVars = {}

  if awsProfile then
    sopsGeneralEnvVars.AWS_PROFILE = awsProfile
  end

  if gcpCredentialsPath then
    sopsGeneralEnvVars.GOOGLE_APPLICATION_CREDENTIALS = gcpCredentialsPath
  end

  if ageKeyFile then
    sopsGeneralEnvVars.SOPS_AGE_KEY_FILE = ageKeyFile
  end

  for key, _ in pairs(sopsGeneralEnvVars) do
    debug('sops option configured: ' .. key)
  end

  return {
    sopsGeneralEnvVars = sopsGeneralEnvVars
  }
end

local function restore_env(previous)
  for key, value in pairs(previous) do
    if value == vim.NIL then
      vim.fn.setenv(key, nil)
    else
      vim.fn.setenv(key, value)
    end
  end
end

local function with_sops_env(fn)
  local env = M.get_sops_general_options().sopsGeneralEnvVars
  local previous = {}

  for key, value in pairs(env) do
    previous[key] = vim.fn.getenv(key)
    vim.fn.setenv(key, tostring(value))
  end

  local ok, output, code = pcall(fn)
  restore_env(previous)

  if not ok then
    error(output)
  end

  return output, code
end

local function command_to_string(command)
  return table.concat(command, ' ')
end

local function filename_override_dir(command)
  for index, arg in ipairs(command) do
    if arg == '--filename-override' and command[index + 1] then
      return vim.fn.fnamemodify(command[index + 1], ':h')
    end
  end

  return vim.fn.getcwd()
end

local function temp_fifo_for(command)
  local dir = filename_override_dir(command)
  local pid = vim.fn.getpid()

  for index = 1, 100 do
    local candidate = dir .. '/.nvim-sops-stdin-' .. pid .. '-' .. index .. '.fifo'
    if vim.fn.getftype(candidate) == '' then
      return candidate
    end
  end
end

local function replace_stdin_file(command, fifo)
  local replaced = {}

  for index, arg in ipairs(command) do
    if arg == stdin_file then
      replaced[index] = fifo
    else
      replaced[index] = arg
    end
  end

  return replaced
end

local function command_uses_stdin_file(command)
  for _, arg in ipairs(command) do
    if arg == stdin_file then
      return true
    end
  end

  return false
end

local function command_output(result)
  local output = result.stdout or ''

  if result.code ~= 0 and result.stderr and result.stderr ~= '' then
    output = output .. result.stderr
  end

  return output
end

local function run_with_fifo(command, input)
  if not vim.system then
    return 'nvim-sops requires vim.system for stdin encryption', -1
  end

  local fifo = temp_fifo_for(command)
  if not fifo then
    return 'Unable to create SOPS stdin FIFO path', -1
  end

  local mkfifo_result = vim.system({ 'mkfifo', fifo }, { text = true }):wait()
  if mkfifo_result.code ~= 0 then
    return command_output(mkfifo_result), mkfifo_result.code
  end

  local sops_job = vim.system(replace_stdin_file(command, fifo), { text = true })
  local writer_job = vim.system({ 'sh', '-c', 'cat > "$1"', 'nvim-sops-writer', fifo }, {
    stdin = input,
    text = true,
  })

  local sops_result = sops_job:wait(30000)
  if sops_result.code == nil then
    sops_job:kill(15)
    writer_job:kill(15)
    vim.fn.delete(fifo)
    return 'Timed out while running SOPS', -1
  end

  if sops_result.code ~= 0 then
    writer_job:kill(15)
    writer_job:wait(1000)
    vim.fn.delete(fifo)
    return command_output(sops_result), sops_result.code
  end

  local writer_result = writer_job:wait(30000)
  if writer_result.code == nil then
    writer_job:kill(15)
    vim.fn.delete(fifo)
    return 'Timed out while writing plaintext to SOPS FIFO', -1
  end

  vim.fn.delete(fifo)

  if writer_result.code ~= 0 and sops_result.code == 0 then
    return command_output(writer_result), writer_result.code
  end

  return command_output(sops_result), sops_result.code
end

local function run_command(command, input)
  if input ~= nil and command_uses_stdin_file(command) then
    return run_with_fifo(command, input)
  end

  if vim.system then
    local result = vim.system(command, {
      stdin = input,
      text = true,
    }):wait()
    return command_output(result), result.code
  end

  local output
  if input ~= nil then
    output = vim.fn.system(command, input)
  else
    output = vim.fn.system(command)
  end

  return output, vim.v.shell_error
end

M.run = function(args, input)
  local command = { vim.g.nvim_sops_bin_path or 'sops' }
  for _, arg in ipairs(args) do
    table.insert(command, arg)
  end

  debug('sops command: ' .. command_to_string(command))

  local ok, output, code = pcall(function()
    return with_sops_env(function()
      return run_command(command, input)
    end)
  end)

  if not ok then
    return {
      ok = false,
      code = -1,
      output = output,
      command = command,
    }
  end

  return {
    ok = code == 0,
    code = code,
    output = output,
    command = command,
  }
end

M.decrypt_file = function(path)
  local file_type = M.file_type_for_path(path)
  if not file_type then
    return {
      ok = false,
      code = -1,
      output = 'Unsupported SOPS file type: ' .. path,
    }
  end

  return M.run({
    '--decrypt',
    '--input-type', file_type,
    '--output-type', file_type,
    path,
  })
end

M.encrypt_text = function(path, text)
  local file_type = M.file_type_for_path(path)
  if not file_type then
    return {
      ok = false,
      code = -1,
      output = 'Unsupported SOPS file type: ' .. path,
    }
  end

  return M.run({
    '--encrypt',
    '--input-type', file_type,
    '--output-type', file_type,
    '--filename-override', path,
    stdin_file,
  }, text)
end

return M
