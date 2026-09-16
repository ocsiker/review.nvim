local M = {}

local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local dates = require("review.dates")

local function shorten_path(path)
	local home = vim.fn.expand("~")

	if path:sub(1, #home) == home then
		return "~" .. path:sub(#home + 1)
	end

	return path
end

local function status_width(status)
	return #status
end

local function format_entry(item)
	local status = item.status

	local label

	if status == "MISSING" then
		label = "[MISSING]"
	elseif status == "OVERDUE" then
		label = "[OVERDUE]"
	elseif status == "TODAY" then
		label = "[TODAY]"
	elseif status == "TOMORROW" then
		label = "[TOMORROW]"
	elseif status == "NEXT 7 DAYS" then
		label = "[NEXT 7 DAYS]"
	else
		label = "[FUTURE]"
	end

	return string.format(
		"%-13s  %s  #%d  %s",
		label,
		item.review.next_review or "--------",
		item.review.review_count or 0,
		shorten_path(item.path)
	)
end

local function collect(database)
	local items = {}

	for path, review in pairs(database) do
		local status

		if vim.fn.filereadable(path) == 1 then
			status = dates.status(review)
		else
			status = "MISSING"
		end

		table.insert(items, {
			path = path,
			review = review,
			status = status,
			search = table.concat({
				status,
				review.next_review or "",
				path,
			}, " "),
		})
	end

	local order = {
		OVERDUE = 1,
		TODAY = 2,
		TOMORROW = 3,
		["NEXT 7 DAYS"] = 4,
		FUTURE = 5,
		MISSING = 6,
	}

	table.sort(items, function(a, b)
		local oa = order[a.status] or 99
		local ob = order[b.status] or 99

		if oa ~= ob then
			return oa < ob
		end

		return a.path < b.path
	end)

	return items
end

local function open_entry(entry)
	if not entry then
		return
	end

	if vim.fn.filereadable(entry.path) ~= 1 then
		vim.notify("File không tồn tại:\n" .. entry.path, vim.log.levels.WARN, { title = "Review" })

		return
	end

	vim.cmd("edit " .. vim.fn.fnameescape(entry.path))
end

function M.open(database, callbacks)
	local items = collect(database)

	if #items == 0 then
		vim.notify("Review database đang trống.", vim.log.levels.INFO, { title = "Review" })

		return
	end

	pickers
		.new({}, {
			prompt_title = "Review",

			finder = finders.new_table({
				results = items,

				entry_maker = function(item)
					return {
						path = item.path,
						value = item,
						ordinal = item.search,
						display = format_entry(item),
					}
				end,
			}),

			sorter = conf.generic_sorter({}),

			previewer = conf.file_previewer({}),

			attach_mappings = function(prompt_bufnr, map)
				local function get_selection()
					return action_state.get_selected_entry()
				end

				local function close_and_refresh()
					actions.close(prompt_bufnr)

					vim.schedule(function()
						M.open(database, callbacks)
					end)
				end

				local function complete()
					local selection = get_selection()

					if not selection then
						return
					end

					callbacks.complete(selection.path)

					close_and_refresh()
				end

				local function postpone()
					local selection = get_selection()

					if not selection then
						return
					end

					callbacks.postpone(selection.path)

					close_and_refresh()
				end

				local function remove()
					local selection = get_selection()

					if not selection then
						return
					end

					callbacks.remove(selection.path)

					close_and_refresh()
				end

				map("i", "<C-c>", complete)
				map("n", "<C-c>", complete)

				map("i", "<C-p>", postpone)
				map("n", "<C-p>", postpone)

				map("i", "<C-d>", remove)
				map("n", "<C-d>", remove)

				actions.select_default:replace(function()
					local selection = get_selection()

					actions.close(prompt_bufnr)

					if selection then
						open_entry(selection)
					end
				end)

				return true
			end,
		})
		:find()
end

return M
