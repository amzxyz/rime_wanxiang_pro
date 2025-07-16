-- github.com/amzxyz
-- 一个用于统计输入字数和其他时间维度的统计。先搭起一个框架，有志之士看看如何优化，统计什么数据，什么维度，构建一个有效的统计信息
-- 硬编码输入方案信息
local schema_name = "万象拼音"
local software_name = rime_api.get_distribution_code_name()
local software_version = rime_api.get_distribution_version()

-- 初始化统计表（若未加载）
input_stats = input_stats or {
    daily = {count = 0, length = 0, fastest = 0, ts = 0},
    weekly = {count = 0, length = 0, fastest = 0, ts = 0},
    monthly = {count = 0, length = 0, fastest = 0, ts = 0},
    yearly = {count = 0, length = 0, fastest = 0, ts = 0},
    lengths = {},
    daily_max = 0,
    recent = {}
}

-- 时间戳工具函数
local function start_of_day(t)
    return os.time{year=t.year, month=t.month, day=t.day, hour=0}
end
local function start_of_week(t)
    local d = t.wday == 1 and 6 or (t.wday - 2)
    return os.time{year=t.year, month=t.month, day=t.day - d, hour=0}
end
local function start_of_month(t)
    return os.time{year=t.year, month=t.month, day=1, hour=0}
end
local function start_of_year(t)
    return os.time{year=t.year, month=1, day=1, hour=0}
end

-- 判断是否是统计命令
local function is_summary_command(text)
    return text == "/rtj" or text == "/ztj" or text == "/ytj" or text == "/ntj" or text == "/tj"
end

-- 更新统计数据
local function update_stats(input_length)
    local now = os.date("*t")
    local now_ts = os.time(now)

    local day_ts = start_of_day(now)
    local week_ts = start_of_week(now)
    local month_ts = start_of_month(now)
    local year_ts = start_of_year(now)

    if input_stats.daily.ts ~= day_ts then
        input_stats.daily = {count = 0, length = 0, fastest = 0, ts = day_ts}
        input_stats.daily_max = 0
        input_stats.recent = {}
    end
    if input_stats.weekly.ts ~= week_ts then
        input_stats.weekly = {count = 0, length = 0, fastest = 0, ts = week_ts}
    end
    if input_stats.monthly.ts ~= month_ts then
        input_stats.monthly = {count = 0, length = 0, fastest = 0, ts = month_ts}
    end
    if input_stats.yearly.ts ~= year_ts then
        input_stats.yearly = {count = 0, length = 0, fastest = 0, ts = year_ts}
    end

    -- 更新记录
    local update = function(stat)
        stat.count = stat.count + 1
        stat.length = stat.length + input_length
    end
    update(input_stats.daily)
    update(input_stats.weekly)
    update(input_stats.monthly)
    update(input_stats.yearly)

    if input_length > input_stats.daily_max then
        input_stats.daily_max = input_length
    end

    input_stats.lengths[input_length] = (input_stats.lengths[input_length] or 0) + 1

    -- 最近一分钟统计
    local ts = os.time()
    table.insert(input_stats.recent, {ts = ts, len = input_length})
    local threshold = ts - 60
    local total = 0
    local new_recent = {}
    for _, item in ipairs(input_stats.recent) do
        if item.ts >= threshold then
            total = total + item.len
            table.insert(new_recent, item)
        end
    end
    input_stats.recent = new_recent
    if total > input_stats.daily.fastest then input_stats.daily.fastest = total end
    if total > input_stats.weekly.fastest then input_stats.weekly.fastest = total end
    if total > input_stats.monthly.fastest then input_stats.monthly.fastest = total end
    if total > input_stats.yearly.fastest then input_stats.yearly.fastest = total end
end

-- 表序列化工具（请自行根据实际添加到环境中）
table.serialize = function(tbl)
    local lines = {"{"}
    for k, v in pairs(tbl) do
        local key = (type(k) == "string") and ("[\"" .. k .. "\"]") or ("[" .. k .. "]")
        local val
        if type(v) == "table" then
            val = table.serialize(v)
        elseif type(v) == "string" then
            val = '"' .. v .. '"'
        else
            val = tostring(v)
        end
        table.insert(lines, string.format("    %s = %s,", key, val))
    end
    table.insert(lines, "}")
    return table.concat(lines, "\n")
end

-- 保存至文件
local function save_stats()
    local path = rime_api.get_user_data_dir() .. "/lua/input_stats.lua"
    local file = io.open(path, "w")
    if not file then return end
    file:write("input_stats = " .. table.serialize(input_stats) .. "\n")
    file:close()
end

-- 显示函数（以日统计为例）
local function format_daily_summary()
    local s = input_stats.daily
    if s.count == 0 then return "※ 今天没有任何记录。" end
    return string.format(
        "※ 今天的统计：\n%s\n◉ 今天\n共上屏[%d]次\n共输入[%d]字\n最快一分钟输入了[%d]字\n%s\n◉ 方案：%s\n◉ 平台：%s %s\n%s",
        string.rep("─", 14), s.count, s.length, s.fastest,
        string.rep("─", 14), schema_name, software_name, software_version,
        string.rep("─", 14))
end

-- 显示函数（周统计）
local function format_weekly_summary()
    local s = input_stats.weekly
    if s.count == 0 then return "※ 本周没有任何记录。" end
    return string.format(
        "※ 本周的统计：\n%s\n◉ 本周共上屏[%d]次\n共输入[%d]字\n最快一分钟输入了[%d]字\n周内单日最多一次输入[%d]字\n%s\n◉ 方案：%s\n◉ 平台：%s %s\n%s",
        string.rep("─", 14), s.count, s.length, s.fastest, input_stats.daily_max,
        string.rep("─", 14), schema_name, software_name, software_version,
        string.rep("─", 14))
end

-- 显示函数（月统计）
local function format_monthly_summary()
    local s = input_stats.monthly
    if s.count == 0 then return "※ 本月没有任何记录。" end
    return string.format(
        "※ 本月的统计：\n%s\n◉ 本月共上屏[%d]次\n共输入[%d]字\n最快一分钟输入了[%d]字\n%s\n◉ 方案：%s\n◉ 平台：%s %s\n%s",
        string.rep("─", 14), s.count, s.length, s.fastest,
        string.rep("─", 14), schema_name, software_name, software_version,
        string.rep("─", 14))
end

-- 显示函数（年统计）
local function format_yearly_summary()
    local s = input_stats.yearly
    if s.count == 0 then return "※ 本年没有任何记录。" end
    local length_counts = {}
    for length, count in pairs(input_stats.lengths) do
        table.insert(length_counts, {length = length, count = count})
    end
    table.sort(length_counts, function(a, b) return a.count > b.count end)
    local fav = length_counts[1] and length_counts[1].length or 0
    return string.format(
        "※ 本年的统计：\n%s\n◉ 本年共上屏[%d]次\n共输入[%d]字\n最快一分钟输入了[%d]字\n您最常输入长度为[%d]的词组\n%s\n◉ 方案：%s\n◉ 平台：%s %s\n%s",
        string.rep("─", 14), s.count, s.length, s.fastest, fav,
        string.rep("─", 14), schema_name, software_name, software_version,
        string.rep("─", 14))
end
-- 转换器函数：处理命令 /rtj /ztj /ytj /ntj
local function translator(input, seg, env)
    if input:sub(1, 1) ~= "/" then return end
    local summary = ""
    if input == "/rtj" then
        summary = format_daily_summary()
    elseif input == "/ztj" then
        summary = format_weekly_summary()
    elseif input == "/ytj" then
        summary = format_monthly_summary()
    elseif input == "/ntj" then
        summary = format_yearly_summary()
    elseif input == "/tj" then
        summary = format_daily_summary() .. "\n\n" .. format_weekly_summary() .. "\n\n" .. format_monthly_summary() .. "\n\n" .. format_yearly_summary()
    elseif input == "/tjql" then
        input_stats = {
            daily = {count = 0, length = 0, fastest = 0, ts = 0},
            weekly = {count = 0, length = 0, fastest = 0, ts = 0},
            monthly = {count = 0, length = 0, fastest = 0, ts = 0},
            yearly = {count = 0, length = 0, fastest = 0, ts = 0},
            lengths = {},
            daily_max = 0,
            recent = {}
        }
        save_stats()
        summary = "※ 所有统计数据已清空。"
    end

    if summary ~= "" then
        yield(Candidate("stat", seg.start, seg._end, summary, ""))
    end
end
-- 加载保存的统计数据（input_stats.lua）
local function load_stats_from_lua_file()
    local path = rime_api.get_user_data_dir() .. "/lua/input_stats.lua"
    local ok, result = pcall(function()
        local env = {}
        local f = loadfile(path, "t", env)
        if f then f() end
        return env.input_stats
    end)
    if ok and type(result) == "table" then
        input_stats = result
    else
        -- 保底初始化，防止错误
        input_stats = {
            daily = {count = 0, length = 0, fastest = 0, ts = 0},
            weekly = {count = 0, length = 0, fastest = 0, ts = 0},
            monthly = {count = 0, length = 0, fastest = 0, ts = 0},
            yearly = {count = 0, length = 0, fastest = 0, ts = 0},
            lengths = {},
            daily_max = 0,
            recent = {}
        }
    end
end
local function init(env)
    local ctx = env.engine.context

    -- 加载历史统计数据
    load_stats_from_lua_file()

    -- 注册提交通知回调
    ctx.commit_notifier:connect(function()
        local commit_text = ctx:get_commit_text()
        if not commit_text or commit_text == "" then return end

        -- 排除统计命令（如 /rtj、/tj 等）
        if is_summary_command(commit_text) then return end

        -- 排除统计候选上屏内容（例如 "※ 今天..." 或 "◉ 本年..."）
        if commit_text:match("^[※◉]") then return end

        -- 排除我们自己生成的统计候选（comment 是 "input_stats_summary"）
      --  local cand = ctx:get_selected_candidate()
       -- if cand and cand.comment == "input_stats_summary" then return end

        -- 保存最近一次 commit 内容
        env.last_commit_text = commit_text

        -- 统计长度
        local input_length = utf8.len(commit_text) or string.len(commit_text)
        update_stats(input_length)
        save_stats()
    end)
end
return { init = init, func = translator }