local M = {}

local database = require("review.database")
local dates = require("review.dates")
local telescope = require("review.telescope")

M.config = {
	intervals = {
		1,
		3,
		7,
		14,
		30,
		60,
	},

	keymaps = {
		add = "<leader>ra",
		dashboard = "<leader>rr",
		complete = "<leader>rc",
		postpone = "<leader>rp",
		remove = "<leader>rd",
		clean = "<leader>rC",
	},
}

M.state = {
	database = {},
}

local function current_file()
	local path = vim.api.nvim_buf_get_name(0)

	if path == "" then
		return nil
	end

	return vim.fn.fnamemodify(path, ":p")
end

local function file_exists(path)
	return vim.fn.filereadable(path) == 1
end

local function notify(message, level)
	vim.notify(message, level or vim.log.levels.INFO, { title = "Review" })
end

local function save()
	database.save(M.state.database)
end

function M.add(path)
	path = path or current_file()

	if not path then
		notify("Buffer hiện tại chưa có file.", vim.log.levels.WARN)
		return
	end

	if not file_exists(path) then
		notify("File không tồn tại:\n" .. path, vim.log.levels.WARN)
		return
	end

	path = vim.fn.fnamemodify(path, ":p")

	if M.state.database[path] then
		notify("File đã có trong review.", vim.log.levels.INFO)
		return
	end

	local today = dates.today()

	M.state.database[path] = {
		created_at = today,
		next_review = dates.add_days(today, M.config.intervals[1]),
		interval_index = 1,
		review_count = 0,
		postponed_count = 0,
	}

	save()

	notify("Đã thêm file vào review.")
end

function M.remove(path)
	path = path or current_file()

	if not path then
		return
	end

	path = vim.fn.fnamemodify(path, ":p")

	if not M.state.database[path] then
		notify("File này chưa có trong review.", vim.log.levels.INFO)
		return
	end

	M.state.database[path] = nil

	save()

	notify("Đã xóa file khỏi review.")
end

function M.complete(path)
	path = path or current_file()

	if not path then
		return
	end

	path = vim.fn.fnamemodify(path, ":p")

	local review = M.state.database[path]

	if not review then
		notify("File này chưa có trong review.", vim.log.levels.WARN)
		return
	end

	if not file_exists(path) then
		notify("File không tồn tại, không thể complete.", vim.log.levels.WARN)
		return
	end

	local current_index = review.interval_index or 1

	local next_index = math.min(current_index + 1, #M.config.intervals)

	review.interval_index = next_index
	review.review_count = (review.review_count or 0) + 1

	local days = M.config.intervals[next_index]

	review.next_review = dates.add_days(dates.today(), days)

	save()

	notify(string.format("Review tiếp theo sau %d ngày: %s", days, review.next_review))
end

function M.postpone(path, days)
	path = path or current_file()
	days = days or 1

	if not path then
		return
	end

	path = vim.fn.fnamemodify(path, ":p")

	local review = M.state.database[path]

	if not review then
		notify("File này chưa có trong review.", vim.log.levels.WARN)
		return
	end

	if not file_exists(path) then
		notify("File không tồn tại, không thể postpone.", vim.log.levels.WARN)
		return
	end

	local base_date = dates.today()

	review.next_review = dates.add_days(base_date, days)

	review.postponed_count = (review.postponed_count or 0) + 1

	save()

	notify(string.format("Đã postpone %d ngày → %s", days, review.next_review))
end

function M.clean_missing()
	local missing = database.missing(M.state.database, file_exists)

	if #missing == 0 then
		notify("Không có review nào bị missing.")
		return
	end

	local question = string.format("Xóa %d review có file không tồn tại?", #missing)

	local choice = vim.fn.confirm(question, "&Có\n&Không", 2)

	if choice ~= 1 then
		return
	end

	for _, item in ipairs(missing) do
		M.state.database[item.path] = nil
	end

	save()

	notify(string.format("Đã xóa %d review missing.", #missing))
end

function M.find()
	telescope.open(M.state.database, {
		complete = function(path)
			M.complete(path)
		end,

		postpone = function(path)
			M.postpone(path)
		end,

		remove = function(path)
			M.remove(path)
		end,
	})
end

local function map(mode, lhs, rhs, desc)
	if not lhs or lhs == "" then
		return
	end

	vim.keymap.set(mode, lhs, rhs, {
		desc = desc,
		silent = true,
	})
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	M.state.database = database.load()

	map("n", M.config.keymaps.add, function()
		M.add()
	end, "Review: add file")

	map("n", M.config.keymaps.dashboard, function()
		M.find()
	end, "Review: dashboard")

	map("n", M.config.keymaps.complete, function()
		M.complete()
	end, "Review: complete")

	map("n", M.config.keymaps.postpone, function()
		M.postpone()
	end, "Review: postpone")

	map("n", M.config.keymaps.remove, function()
		M.remove()
	end, "Review: remove")

	map("n", M.config.keymaps.clean, function()
		M.clean_missing()
	end, "Review: clean missing")
end

return M
