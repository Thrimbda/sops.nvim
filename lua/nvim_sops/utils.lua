local M = {}
local uv = vim.uv or vim.loop

M.first_not_nil = function(...)
    for i = 1, select("#", ...) do
        local value = select(i, ...)
        if value ~= nil then
            return value
        end
    end
end

M.debug = function(...)
  if vim.g.nvim_sops_debug then
    print('DEBUG: ', ... )
  end
end

M.split_lines = function(text)
  if text == '' then
    return { '' }
  end

  local lines = vim.split(text, '\n', { plain = true })
  if text:sub(-1) == '\n' then
    table.remove(lines)
  end

  if #lines == 0 then
    return { '' }
  end

  return lines
end

M.join_lines = function(lines, endofline)
  local text = table.concat(lines, '\n')
  if endofline then
    text = text .. '\n'
  end
  return text
end

M.write_text_file = function(path, text)
  local lines = vim.split(text, '\n', { plain = true })
  return vim.fn.writefile(lines, path, 'b')
end

M.write_text_file_exclusive = function(path, text)
  if not uv then
    if vim.fn.getftype(path) ~= '' then
      return -1, 'temporary file already exists'
    end

    return M.write_text_file(path, text)
  end

  local fd, open_err = uv.fs_open(path, 'wx', 384)
  if not fd then
    return -1, open_err
  end

  local offset = 0
  while offset < #text do
    local written, write_err = uv.fs_write(fd, text:sub(offset + 1), offset)
    if not written then
      uv.fs_close(fd)
      vim.fn.delete(path)
      return -1, write_err
    end

    offset = offset + written
  end

  local close_ok, close_err = uv.fs_close(fd)
  if not close_ok then
    vim.fn.delete(path)
    return -1, close_err
  end

  return 0
end

return M
