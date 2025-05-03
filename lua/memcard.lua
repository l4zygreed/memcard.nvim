local api, fn, fs = vim.api, vim.fn, vim.fs
local plugin = {}

local session_list = function()
  return vim.split(fn.globpath(plugin.opt.dir, '*.vim'), '\n')
end

local fullname = function(name)
  return fs.joinpath(plugin.opt.dir, name .. '.vim')
end

local completion = function(arg, _, _)
  local list = session_list()

  list = vim.tbl_map(function(v)
    return fs.basename(v):gsub("%..*$", "")
  end, list)
  list = vim.tbl_filter(function(v)
    return v:find(arg)
  end, list)
  return list
end

local default = function()
  return {
    dir = fs.joinpath(fn.stdpath('cache'), 'memcard'),
    auto_save_on_exit = false,
    root_markers = {},
  }
end


--- @private
--- @return string cwd return root related cwd
function plugin:getcwd()
  local marks = vim.tbl_extend(
    'force',
    { '.git', },
    plugin.root_markers or {}
  )
  local cwd = fs.root(0, marks)

  if cwd ~= nil then
    return fs.basename(cwd)
  else
    return fs.basename(fn.getcwd())
  end
end

--- @return string default_name cwd based name forr session
function plugin:default_name()
  local cwd = plugin:getcwd()
  local tbl = vim.split(cwd, '/', { trimempty = true })

  tbl = vim.tbl_map(function(item)
    if item:find('%p') then
      item = item:gsub('%p', '_')
    end
    return item
  end, tbl)
  cwd = table.concat(tbl, '_')
  cwd = fn.substitute(cwd, [[^\.]], '', '')

  return cwd
end

--- @param name? string save current state with specified name or default_name()
function plugin:save(name)
  local filename, filepath

  if not name or #name == 0 and vim.v.this_session then
    filepath = vim.v.this_session
    filename = fs.basename(filepath):gsub("%..*$", "")
  else
    filename = (not name or #name == 0) and plugin:default_name() or name
    filepath = fs.joinpath(self.opt.dir, filename .. '.vim')
  end

  api.nvim_cmd({
    cmd = 'mksession',
    bang = true,
    args = { fn.fnameescape(filepath) },
  }, {})
  vim.v.this_session = filepath

  vim.notify('[memcard] Saved ' .. filename)
end

--- @param name? string load session with specified name or default_name()
function plugin:load(name)
  local path

  if not name or #name == 0 then
    local list = session_list()
    local sname = plugin:default_name()

    for _, item in ipairs(list) do
      if item:find(sname) then
        path = item
        break
      end
    end
  else
    path = fullname(name)
  end

  if fn.filereadable(path) == 1 then
    local curbuf = vim.api.nvim_get_current_buf()

    if vim.bo[curbuf].modified then
      vim.cmd.write()
    end
    vim.cmd([[noautocmd silent! %bwipeout!]])
    api.nvim_command('silent! source ' .. path)
    vim.notify('[memcard] Loaded ' .. name)
    return
  end

  vim.notify('[memcard] load failed ' .. name, vim.log.levels.ERROR)
end

--- @param name? string delete session with specified name
function plugin:delete(name)
  if not name then
    vim.notify('[memcard] please give a session name to delete', vim.log.levels.WARN)
    return
  end

  local path = fullname(name)

  if fn.filereadable(path) == 1 then
    fn.delete(path)
    vim.notify('[memcard] Deleted ' .. name)
    return
  end

  vim.notify('[memcard] deletion failed ' .. name, vim.log.levels.ERROR)
end

--- @private
function plugin:commands()
  if self.opt.auto_save_on_exit then
    api.nvim_create_autocmd('VimLeavePre', {
      group = api.nvim_create_augroup('memcard_auto_save', { clear = true }),
      callback = function()
        plugin:save()
      end,
    })
  end

  api.nvim_create_user_command('CardSave', function(args)
    plugin:save(args.args)
  end, {
    nargs = '?',
    complete = completion,
  })

  api.nvim_create_user_command('CardLoad', function(args)
    plugin:load(args.args)
  end, {
    nargs = '?',
    complete = completion,
  })

  api.nvim_create_user_command('CardDelete', function(args)
    plugin:delete(args.args)
  end, {
    nargs = '?',
    complete = completion,
  })
end

function plugin.setup(opt)
  plugin.opt = vim.tbl_extend('force', default(), opt or {})
  plugin.opt.dir = fs.normalize(plugin.opt.dir)

  if fn.isdirectory(plugin.opt.dir) == 0 then
    fn.mkdir(plugin.opt.dir, 'p')
  end

  plugin:commands()
end

return plugin
