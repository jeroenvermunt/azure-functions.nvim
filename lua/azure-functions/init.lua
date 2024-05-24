local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local M = {}

local function get_function_apps()
	local function_apps = {}
	local function_apps_cmd = "az functionapp list -o table"
	local handle = io.popen(function_apps_cmd)

	if handle == nil then
		return function_apps
	end

	-- set the columns as the first line
	local columns = handle:read("*line")

	for column in string.gmatch(columns, "[^%s]+") do
		-- print(column)
	end

	-- skip the second line and loop through the rest
	local _ = handle:read("*line")

	for function_app in handle:lines() do
		local split_values = {}

		for value in string.gmatch(function_app, "[^%s]+") do
			-- for value in string.gmatch(function_app, "%S+(?:%s%S+)*") do
			table.insert(split_values, value)
		end

		local parsed_app = {
			name = split_values[1],
			location = split_values[2] .. " " .. split_values[3],
			state = split_values[4],
			resource_group = split_values[5],
			default_host_name = split_values[6],
			app_service_plan = split_values[7],
		}

		-- print(parsed_app.name)
		-- print(parsed_app.location)
		-- print(parsed_app.state)
		-- print(parsed_app.resource_group)
		-- print(parsed_app.default_host_name)
		-- print(parsed_app.app_service_plan)

		table.insert(function_apps, parsed_app)
	end

	handle:close()
	return function_apps
end

local construct_deployment_command = function(app_name, resource_group)
	return "func azure functionapp publish " .. app_name .. " --resource-group " .. resource_group
end

local deploy_function_app = function(app_name, resource_group)
	local deploy_command = construct_deployment_command(app_name, resource_group)
	-- open a new terminal and run the command
	vim.cmd.terminal()
	vim.api.nvim_chan_send(vim.b.terminal_job_id, deploy_command .. "\n")
end

local endpoint_picker = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Endpoints",
			finder = finders.new_table({
				-- results = get_function_apps(),
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.default_host_name,
						ordinal = entry.default_host_name,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.cmd("func start --functions " .. selection.value.default_host_name)
				end)
				return true
			end,
		})
		:find()
end

local get_functions = function()
	local functions = {}
	local function_cmd = 'find . -type f -name "function.json" -printf "%h\n" | sed \'s|^\\.||\''

	print(function_cmd)
	local handle = io.popen(function_cmd)

	print(handle)

	if handle == nil then
		return functions
	end

	functions = handle:read("*all")
	print(functions)

	return functions
end

local function_app_picker = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Function Apps",
			finder = finders.new_table({
				results = get_function_apps(),
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.name,
						ordinal = entry.name,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					deploy_function_app(selection.value.name, selection.value.resource_group)
				end)
				return true
			end,
			--   map('i', '<CR>', select_function_app)
			--   map('n', '<CR>', select_function_app)
			--   return true
			-- end,
		})
		:find()
end

local start_function_app = function(app_name)
	local start_command = "func start --functions " .. app_name
	-- open a new terminal and run the command
	vim.cmd.terminal()
	vim.api.nvim_chan_send(vim.b.terminal_job_id, start_command .. "\n")
end

local endpoint_picker = function(opts)
	opts = opts or {}
	pickers
		.new(opts, {
			prompt_title = "Endpoints",
			finder = finders.new_table({
				results = get_functions(),
				entry_maker = function(entry)
					return {
						value = entry,
					}
				end,
			}),
			sorter = conf.generic_sorter({}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					start_function_app(selection.value)
				end)
				return true
			end,
		})
		:find()
end

M.deploy_app = function_app_picker
M.start_app = endpoint_picker

return M
