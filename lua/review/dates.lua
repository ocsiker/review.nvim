local M = {}

local function today_timestamp()
	local now = os.date("*t")

	now.hour = 0
	now.min = 0
	now.sec = 0

	return os.time(now)
end

function M.today()
	return os.date("%Y-%m-%d")
end

function M.add_days(date_string, days)
	local year, month, day = date_string:match("^(%d+)-(%d+)-(%d+)$")

	if not year then
		return nil
	end

	local timestamp = os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = 0,
		min = 0,
		sec = 0,
	})

	timestamp = timestamp + days * 24 * 60 * 60

	return os.date("%Y-%m-%d", timestamp)
end

function M.days_from_today(date_string)
	local year, month, day = date_string:match("^(%d+)-(%d+)-(%d+)$")

	if not year then
		return nil
	end

	local target = os.time({
		year = tonumber(year),
		month = tonumber(month),
		day = tonumber(day),
		hour = 0,
		min = 0,
		sec = 0,
	})

	return math.floor((target - today_timestamp()) / (24 * 60 * 60))
end

function M.status(review)
	if not review or not review.next_review then
		return "FUTURE"
	end

	local diff = M.days_from_today(review.next_review)

	if not diff then
		return "FUTURE"
	end

	if diff < 0 then
		return "OVERDUE"
	elseif diff == 0 then
		return "TODAY"
	elseif diff == 1 then
		return "TOMORROW"
	elseif diff <= 7 then
		return "NEXT 7 DAYS"
	else
		return "FUTURE"
	end
end

function M.next_review(days)
	return M.add_days(M.today(), days)
end

return M
