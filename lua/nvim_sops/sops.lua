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

local key_flag_order = {
  { metadata_key = 'kms', flag = '--kms' },
  { metadata_key = 'gcp_kms', flag = '--gcp-kms' },
  { metadata_key = 'azure_kv', flag = '--azure-kv' },
  { metadata_key = 'hc_vault', flag = '--hc-vault-transit' },
  { metadata_key = 'age', flag = '--age' },
  { metadata_key = 'pgp', flag = '--pgp' },
}

local rule_flag_order = {
  { metadata_key = 'unencrypted_suffix', flag = '--unencrypted-suffix' },
  { metadata_key = 'encrypted_suffix', flag = '--encrypted-suffix' },
  { metadata_key = 'unencrypted_regex', flag = '--unencrypted-regex' },
  { metadata_key = 'encrypted_regex', flag = '--encrypted-regex' },
  { metadata_key = 'unencrypted_comment_regex', flag = '--unencrypted-comment-regex' },
  { metadata_key = 'encrypted_comment_regex', flag = '--encrypted-comment-regex' },
  { metadata_key = 'shamir_threshold', flag = '--shamir-secret-sharing-threshold' },
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

local function strip_value(value)
  value = tostring(value or ''):gsub('^%s+', ''):gsub('%s+$', '')

  if (value:sub(1, 1) == '"' and value:sub(-1) == '"') or (value:sub(1, 1) == "'" and value:sub(-1) == "'") then
    value = value:sub(2, -2)
  end

  return value
end

local function add_unique(values, value)
  value = strip_value(value)
  if value == '' then
    return
  end

  for _, existing in ipairs(values) do
    if existing == value then
      return
    end
  end

  table.insert(values, value)
end

local function set_rule(keys, key, value)
  value = strip_value(value)
  if value ~= '' then
    keys.rules[key] = value
  end
end

local function set_bool_rule(keys, key, value)
  if value == true or strip_value(value) == 'true' then
    keys.rules[key] = true
  end
end

local function table_has_values(value)
  return type(value) == 'table' and next(value) ~= nil
end

local function empty_keys()
  return {
    kms = {},
    gcp_kms = {},
    azure_kv = {},
    hc_vault = {},
    age = {},
    pgp = {},
    rules = {},
  }
end

local function azure_kv_url(key)
  if not key or not key.vault_url or not key.name then
    return
  end

  local url = strip_value(key.vault_url):gsub('/+$', '') .. '/keys/' .. strip_value(key.name)
  if key.version and strip_value(key.version) ~= '' then
    url = url .. '/' .. strip_value(key.version)
  end

  return url
end

local function hc_vault_uri(key)
  if not key or not key.vault_address or not key.engine_path or not key.key_name then
    return
  end

  return strip_value(key.vault_address):gsub('/+$', '') .. '/v1/' .. strip_value(key.engine_path):gsub('^/+', ''):gsub('/+$', '') .. '/keys/' .. strip_value(key.key_name)
end

local function collect_metadata_keys(metadata, keys)
  if table_has_values(metadata.key_groups) then
    return false, 'SOPS key_groups metadata cannot be represented safely as flat encryption flags'
  end

  for _, item in ipairs(rule_flag_order) do
    set_rule(keys, item.metadata_key, metadata[item.metadata_key])
  end
  set_bool_rule(keys, 'mac_only_encrypted', metadata.mac_only_encrypted)

  for _, key in ipairs(metadata.kms or {}) do
    if key.context ~= nil and (type(key.context) ~= 'table' or next(key.context) ~= nil) then
      return false, 'SOPS KMS encryption context metadata cannot be represented safely as flat encryption flags'
    end
    add_unique(keys.kms, key.arn)
  end
  for _, key in ipairs(metadata.gcp_kms or {}) do
    add_unique(keys.gcp_kms, key.resource_id)
  end
  for _, key in ipairs(metadata.azure_kv or {}) do
    add_unique(keys.azure_kv, azure_kv_url(key))
  end
  for _, key in ipairs(metadata.hc_vault or {}) do
    add_unique(keys.hc_vault, hc_vault_uri(key))
  end
  for _, key in ipairs(metadata.age or {}) do
    add_unique(keys.age, key.recipient)
  end
  for _, key in ipairs(metadata.pgp or {}) do
    add_unique(keys.pgp, key.fp)
  end

  return true
end

local function keys_to_args(keys)
  local args = {}

  for _, item in ipairs(key_flag_order) do
    local values = keys[item.metadata_key]
    if values and #values > 0 then
      table.insert(args, item.flag)
      table.insert(args, table.concat(values, ','))
    end
  end

  for _, item in ipairs(rule_flag_order) do
    local value = keys.rules[item.metadata_key]
    if value then
      table.insert(args, item.flag)
      table.insert(args, tostring(value))
    end
  end

  if keys.rules.mac_only_encrypted then
    table.insert(args, '--mac-only-encrypted')
  end

  return args
end

local function has_reusable_keys(keys)
  for _, item in ipairs(key_flag_order) do
    local values = keys[item.metadata_key]
    if values and #values > 0 then
      return true
    end
  end

  return false
end

local function read_text_file(path)
  local ok, lines = pcall(vim.fn.readfile, path, 'b')
  if not ok then
    return nil, lines
  end

  return table.concat(lines, '\n')
end

local function metadata_from_json(text)
  local ok, document = pcall(vim.json.decode, text)
  if not ok or type(document) ~= 'table' or type(document.sops) ~= 'table' then
    return nil, 'Unable to parse SOPS JSON metadata'
  end

  return document.sops
end

local function sops_yaml_block(text)
  local block = {}
  local in_block = false
  local base_indent

  for line in (text .. '\n'):gmatch('([^\n]*)\n') do
    local indent, content = line:match('^(%s*)(.*)$')
    if not in_block and content == 'sops:' then
      in_block = true
      base_indent = #indent
    elseif in_block then
      if content ~= '' and #indent <= base_indent then
        break
      end
      table.insert(block, line)
    end
  end

  if #block == 0 then
    return nil
  end

  return table.concat(block, '\n')
end

local function metadata_keys_from_yaml(text)
  local block = sops_yaml_block(text)
  if not block then
    return nil, 'Unable to find SOPS YAML metadata'
  end
  if block:match('^%s*key_groups:%s*$') or block:match('\n%s*key_groups:%s*$') then
    return nil, 'SOPS key_groups metadata cannot be represented safely as flat encryption flags'
  end
  if block:match('^%s*context:%s*$') or block:match('\n%s*context:%s*$') then
    return nil, 'SOPS KMS encryption context metadata cannot be represented safely as flat encryption flags'
  end

  local keys = empty_keys()
  local current_list
  local current_item

  local function flush_item()
    if not current_list or not current_item then
      return
    end

    if current_list == 'kms' then
      add_unique(keys.kms, current_item.arn)
    elseif current_list == 'gcp_kms' then
      add_unique(keys.gcp_kms, current_item.resource_id)
    elseif current_list == 'azure_kv' then
      add_unique(keys.azure_kv, azure_kv_url(current_item))
    elseif current_list == 'hc_vault' then
      add_unique(keys.hc_vault, hc_vault_uri(current_item))
    elseif current_list == 'age' then
      add_unique(keys.age, current_item.recipient)
    elseif current_list == 'pgp' then
      add_unique(keys.pgp, current_item.fp)
    end
  end

  for line in (block .. '\n'):gmatch('([^\n]*)\n') do
    local scalar_key, scalar_value = line:match('^%s*(unencrypted_suffix):%s*(.-)%s*$')
    if not scalar_key then
      scalar_key, scalar_value = line:match('^%s*(encrypted_suffix):%s*(.-)%s*$')
    end
    if not scalar_key then
      scalar_key, scalar_value = line:match('^%s*(unencrypted_regex):%s*(.-)%s*$')
    end
    if not scalar_key then
      scalar_key, scalar_value = line:match('^%s*(encrypted_regex):%s*(.-)%s*$')
    end
    if not scalar_key then
      scalar_key, scalar_value = line:match('^%s*(unencrypted_comment_regex):%s*(.-)%s*$')
    end
    if not scalar_key then
      scalar_key, scalar_value = line:match('^%s*(encrypted_comment_regex):%s*(.-)%s*$')
    end
    if not scalar_key then
      scalar_key, scalar_value = line:match('^%s*(shamir_threshold):%s*(.-)%s*$')
    end
    if not scalar_key then
      scalar_key, scalar_value = line:match('^%s*(mac_only_encrypted):%s*(.-)%s*$')
    end

    if scalar_key then
      flush_item()
      current_item = nil
      if scalar_key == 'mac_only_encrypted' then
        set_bool_rule(keys, scalar_key, scalar_value)
      else
        set_rule(keys, scalar_key, scalar_value)
      end
    else
      local list = line:match('^%s*(%w[%w_]*):%s*$')
      if list then
        flush_item()
        current_list = list
        current_item = nil
      else
        local item_key, item_value = line:match('^%s*%-%s+(%w[%w_]*):%s*(.-)%s*$')
        if item_key then
          flush_item()
          current_item = {}
          current_item[item_key] = strip_value(item_value)
        elseif current_item then
          local key, value = line:match('^%s+(%w[%w_]*):%s*(.-)%s*$')
          if key and value ~= '|' and value ~= '>' then
            current_item[key] = strip_value(value)
          end
        end
      end
    end
  end

  flush_item()
  return keys
end

local function metadata_keys_from_dotenv(text)
  if text:match('^sops_key_groups') or text:match('\nsops_key_groups') then
    return nil, 'SOPS key_groups metadata cannot be represented safely as flat encryption flags'
  end

  local keys = empty_keys()
  local azure = {}
  local hc_vault = {}

  for line in (text .. '\n'):gmatch('([^\n]*)\n') do
    local key, value = line:match('^([^=]+)=(.*)$')
    if key then
      if key:match('^sops_age__list_%d+__map_recipient$') then
        add_unique(keys.age, value)
      elseif key:match('^sops_pgp__list_%d+__map_fp$') then
        add_unique(keys.pgp, value)
      elseif key:match('^sops_kms__list_%d+__map_arn$') then
        add_unique(keys.kms, value)
      elseif key:match('^sops_gcp_kms__list_%d+__map_resource_id$') then
        add_unique(keys.gcp_kms, value)
      elseif key:match('^sops_kms__list_%d+__map_context') then
        return nil, 'SOPS KMS encryption context metadata cannot be represented safely as flat encryption flags'
      elseif key == 'sops_unencrypted_suffix' then
        set_rule(keys, 'unencrypted_suffix', value)
      elseif key == 'sops_encrypted_suffix' then
        set_rule(keys, 'encrypted_suffix', value)
      elseif key == 'sops_unencrypted_regex' then
        set_rule(keys, 'unencrypted_regex', value)
      elseif key == 'sops_encrypted_regex' then
        set_rule(keys, 'encrypted_regex', value)
      elseif key == 'sops_unencrypted_comment_regex' then
        set_rule(keys, 'unencrypted_comment_regex', value)
      elseif key == 'sops_encrypted_comment_regex' then
        set_rule(keys, 'encrypted_comment_regex', value)
      elseif key == 'sops_shamir_threshold' then
        set_rule(keys, 'shamir_threshold', value)
      elseif key == 'sops_mac_only_encrypted' then
        set_bool_rule(keys, 'mac_only_encrypted', value)
      else
        local azure_index, azure_field = key:match('^sops_azure_kv__list_(%d+)__map_(%w[%w_]*)$')
        if azure_index then
          azure[azure_index] = azure[azure_index] or {}
          azure[azure_index][azure_field] = value
        end

        local vault_index, vault_field = key:match('^sops_hc_vault__list_(%d+)__map_(%w[%w_]*)$')
        if vault_index then
          hc_vault[vault_index] = hc_vault[vault_index] or {}
          hc_vault[vault_index][vault_field] = value
        end
      end
    end
  end

  for _, key in pairs(azure) do
    add_unique(keys.azure_kv, azure_kv_url(key))
  end
  for _, key in pairs(hc_vault) do
    add_unique(keys.hc_vault, hc_vault_uri(key))
  end

  return keys
end

local function metadata_key_args(path, file_type)
  local text, err = read_text_file(path)
  if not text then
    return nil, 'Unable to read encrypted file metadata: ' .. tostring(err)
  end

  local keys
  if file_type == 'json' then
    local metadata
    metadata, err = metadata_from_json(text)
    if metadata then
      keys = empty_keys()
      local ok
      ok, err = collect_metadata_keys(metadata, keys)
      if not ok then
        return nil, err
      end
    end
  elseif file_type == 'yaml' then
    keys, err = metadata_keys_from_yaml(text)
  elseif file_type == 'dotenv' then
    keys, err = metadata_keys_from_dotenv(text)
  end

  if not keys then
    return nil, err or 'Unable to parse SOPS metadata'
  end

  if not has_reusable_keys(keys) then
    return nil, 'SOPS metadata does not contain reusable encryption keys'
  end

  return keys_to_args(keys)
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

  local key_args, key_err = metadata_key_args(path, file_type)
  if not key_args then
    return {
      ok = false,
      code = -1,
      output = key_err,
    }
  end

  local args = {
    '--encrypt',
    '--input-type', file_type,
    '--output-type', file_type,
    '--filename-override', path,
  }

  for _, arg in ipairs(key_args) do
    table.insert(args, arg)
  end

  table.insert(args, stdin_file)

  return M.run(args, text)
end

return M
