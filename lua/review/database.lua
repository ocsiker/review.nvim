local M = {}

local uv = vim.uv or vim.loop

local data_dir = vim.fn.stdpath("data") .. "/review"
local data_file = data_dir .. "/reviews.json"

local function ensure_dir()
	if vim.fn.isdirectory(data_dir) == 0 then
		vim.fn.mkdir(data_dir, "p")
	end
end

local function file_exists(path)
	local stat = uv.fs_stat(path)
	return stat ~= nil
end

function M.path()
	return data_file
end

function M.load()
	ensure_dir()

	if not file_exists(data_file) then
		return {}
	end

	local file = io.open(data_file, "r")
	if not file then
		return {}
	end

	local content = file:read("*a")
	file:close()

	if not content or content == "" then
		return {}
	end

	local ok, data = pcall(vim.json.decode, content)

	if not ok or type(data) ~= "table" then
		vim.notify("Không thể đọc review database.", vim.log.levels.ERROR, { title = "Review" })

		return {}
	end

	return data
end

function M.save(database)
	ensure_dir()

	local ok, encoded = pcall(vim.json.encode, database)

	if not ok then
		vim.notify("Không thể mã hóa review database.", vim.log.levels.ERROR, { title = "Review" })

		return false
	end

	local tmp_file = data_file .. ".tmp"

	local file = io.open(tmp_file, "w")

	if not file then
		vim.notify("Không thể ghi review database.", vim.log.levels.ERROR, { title = "Review" })

		return false
	end

	file:write(encoded)
	file:close()

	local ok_rename = os.rename(tmp_file, data_file)

	if not ok_rename then
		vim.notify("Không thể cập nhật review database.", vim.log.levels.ERROR, { title = "Review" })

		return false
	end

	return true
end

function M.get(database, path)
	return database[path]
end

function M.add(database, path, review)
	database[path] = review
end

function M.remove(database, path)
	database[path] = nil
end

function M.count(database)
	local count = 0

	for _ in pairs(database) do
		count = count + 1
	end

	return count
end

function M.missing(database, file_exists_fn)
	local result = {}

	for path, review in pairs(database) do
		if not file_exists_fn(path) then
			table.insert(result, {
				path = path,
				review = review,
			})
		end
	end

	table.sort(result, function(a, b)
		return a.path < b.path
	end)

	return result
end

return M
