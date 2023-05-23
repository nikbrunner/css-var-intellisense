local Path = require("plenary.path")
local scan_dir = require("plenary.scandir")
local cmp = require("cmp")

-- main module file
-- local module = require("plugin_name.module")

local M = {}

function M.parse_css_files()
  local properties = {}

  -- Scan the current working directory and all subdirectories for .css files
  local css_files =
    scan_dir.scan_dir(Path:new(vim.fn.getcwd()):absolute(), { hidden = true, search_pattern = "%.css$" })

  -- For each CSS file found...
  for _, file in ipairs(css_files) do
    -- Read the file
    local lines = Path:new(file):readlines()

    -- For each line in the file...
    for _, line in ipairs(lines) do
      -- If the line is a CSS custom property...
      if line:match("^%s*--") then
        -- Extract the property name and value
        local name, value = line:match("^%s*(--[^:]+):%s*(.+)%s*;$")

        if name and value then
          -- Trim whitespace and add the property to the list
          name = name:gsub("^%s*(.-)%s*$", "%1")
          value = value:gsub("^%s*(.-)%s*$", "%1")

          properties[name] = value
        end
      end
    end
  end

  return properties
end

function M.feed_to_autocomplete(properties)
  -- Use the nvim-cmp API to feed these properties to the autocomplete engine
  cmp.register_source("css_custom_properties", {
    complete = function(_, callback)
      local items = {}
      for k, v in pairs(properties) do
        table.insert(items, { label = k, detail = v })
      end
      callback(items)
    end,
  })
end

M.config = {
  -- default config
  opt = "Hello!",
}

-- setup is the public method to setup your plugin
function M.setup(args)
  -- you can define your setup function here. Usually configurations can be merged, accepting outside params and
  -- you can also put some validation here for those.
  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  -- Start a timer to parse the CSS files asynchronously
  vim.loop.new_timer():start(
    0,
    0,
    vim.schedule_wrap(function()
      local properties = M.parse_css_files()

      print(vim.inspect(properties))

      M.feed_to_autocomplete(properties)
    end)
  )
end

return M
