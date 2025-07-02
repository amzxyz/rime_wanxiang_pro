-- 欢迎使用万象拼音方案
-- @amzxyz
-- https://github.com/amzxyz/rime_wanxiang

local wanxiang = require("wanxiang")

-- 检查系统类型
-- 各类 rime 前端详见：https://rime.im/download/
-- 输入法           code_name   OS
-- 小狼毫           Weasel      Windows
-- 仓               Hamster     iOS
-- 鼠鬚管           Squirrel    macOS
-- 同文             trime       Android
-- iBus             ibus-rime   Linux
-- fcitx5-macos     fcitx-rime  macOS
-- Fcitx5           fcitx-rime  Linux
-- fcitx5-android   fcitx-rime  Android
---@return 'windows' | 'unknown' | 'ios' | 'macos' | 'android' | 'linux'
local function detect_os_type()
    -- 先判断 Windows，因为只有 Windows 的路径分隔符为 \
    if package.config:sub(1, 1) == '\\' then return 'windows' end

    local dist_name = rime_api.get_distribution_code_name()
    if not dist_name then return "unknown" end

    if dist_name == 'Hamster' then return 'ios' end
    if dist_name == 'Squirrel' then return 'macos' end
    if dist_name == 'trime' then return 'android' end
    if dist_name == 'ibus-rime' then return 'linux' end

    if dist_name == 'fcitx-rime' then
        local user_data_dir = rime_api.get_user_data_dir()
        if user_data_dir:match("^/org%.fcitx%.fcitx5%.android/$") then
            return "android"
        end

        local popen_status, popen_result = pcall(io.popen, "")
        if popen_status and popen_result then
            popen_result:close()
            local uname = io.popen('uname -s', 'r')
            if uname then
                local raw_os_name = uname:read('*l'):lower()
                uname:close()

                local kernel_patterns = {
                    ['linux'] = 'linux',
                    ['mac'] = 'macos',
                    ['darwin'] = 'macos',
                }
                for pattern, name in pairs(kernel_patterns) do
                    if raw_os_name:match(pattern) then
                        return name
                    end
                end
            end
        end
    end

    return 'unknown'
end

local os_type = detect_os_type()

local function trim(s)
    return s:match("^%s*(.-)%s*$") or ""
end

local function startsWith(str, starts)
    return string.sub(str, 1, string.len(starts)) == starts
end

-- 解析 installation.yaml 文件
local function detect_yaml_installation()
    local yaml = {}
    local user_data_dir = rime_api.get_user_data_dir()
    local yaml_path = user_data_dir .. "/installation.yaml"
    local file, _ = io.open(yaml_path, "r")
    if not file then
        return yaml, "无法打开 installation.yaml 文件"
    end

    for line in file:lines() do
        if not line:match("^%s*#") and not line:match("^%s*$") then
            local key_part, value_part = line:match("^([^:]-):(.*)")
            if key_part then
                local key = trim(key_part)
                local raw_value = trim(value_part)
                if key ~= "" and raw_value ~= "" then
                    local value = trim(raw_value)
                    if #value >= 2 and value:sub(1, 1) == '"' and value:sub(-1) == '"' then
                        value = trim(value:sub(2, -2))
                    end
                    yaml[key] = value
                end
            end
        end
    end

    file:close()
    return yaml
end

-- 初始化函数
local function init(env)
    if not env.initialized then
        env.initialized = true
        env.yaml_installation = detect_yaml_installation() -- 解析 installation.yaml 文件，获取配置信息
        env.total_deleted = 0                              -- 记录删除的总条目数
    end
end

-- 检测并处理路径分隔符转换
local function convert_path_separator(path)
    if os_type == "windows" then
        path = path:gsub("\\\\", "\\") -- 将双反斜杠替换为单反斜杠
        path = path:gsub("/", "\\")    -- 将斜杠替换为反斜杠
    end
    return path
end

-- 从 installation.yaml 文件中获取 sync_dir 路径
local function get_sync_path_from_yaml(env)
    local sync_dir = env.yaml_installation["sync_dir"]
    if not sync_dir then
        local user_data_dir = rime_api.get_user_data_dir()
        sync_dir = user_data_dir .. "/sync"
    end

    local installation_id = env.yaml_installation["installation_id"]
    if installation_id then
        sync_dir = sync_dir .. "/" .. installation_id
    end

    sync_dir = convert_path_separator(sync_dir)

    return sync_dir, nil
end

-- 预定义数字0-9的ANSI编码表示
local digit_to_ansi = {
    ["0"] = "\x30",
    ["1"] = "\x31",
    ["2"] = "\x32",
    ["3"] = "\x33",
    ["4"] = "\x34",
    ["5"] = "\x35",
    ["6"] = "\x36",
    ["7"] = "\x37",
    ["8"] = "\x38",
    ["9"] = "\x39"
}

-- 定义固定部分的ANSI编码
local base_message = "\xD3\xC3\xBB\xA7\xB4\xCA\xB5\xE4\xB9\xB2\xC7\xE5\xC0\xED\x20" -- "用户词典共清理 "（注意结尾有一个空格）
local end_message = "\x20\xD0\xD0\xCE\xDE\xD0\xA7\xB4\xCA\xCC\xF5"                  -- " 行无效词条"（前面带一个空格）

-- 生成ANSI编码的删除条目数量部分
local function encode_deleted_count_to_ansi(deleted_count)
    local digits_str = tostring(deleted_count) -- 预转换字符串
    local parts = {}
    for digit in digits_str:gmatch(".") do     -- 直接遍历每个字符
        table.insert(parts, digit_to_ansi[digit] or "")
    end
    return table.concat(parts) -- 一次性连接结果
end

-- 动态生成完整的ANSI消息（适用于Windows）
local function generate_ansi_message(deleted_count)
    local encoded_count = encode_deleted_count_to_ansi(deleted_count)
    return base_message .. encoded_count .. end_message
end

-- 动态生成UTF-8消息（适用于Linux）
local function generate_utf8_message(deleted_count)
    return "用户词典共清理 " .. tostring(deleted_count) .. " 行无效词条"
end

-- 发送通知反馈函数，使用动态生成的消息
local function send_user_notification(deleted_count)
    if os_type == "windows" then
        local ansi_message = generate_ansi_message(deleted_count)
        os.execute('msg * "' .. ansi_message .. '"')
    elseif os_type == "linux" then
        local utf8_message = generate_utf8_message(deleted_count)
        os.execute('notify-send "' .. utf8_message .. '" "--app-name=万象输入法"')
    elseif os_type == "macos" then
        local utf8_message = generate_utf8_message(deleted_count)
        os.execute('osascript -e \'display notification "' .. utf8_message .. '" with title "万象输入法"\'')
    elseif os_type == "android" then
        local utf8_message = generate_utf8_message(deleted_count)
        os.execute('notify "' .. utf8_message .. '"')
    end
end

-- 删除 installation.yaml 同级目录下的 .userdb 文件夹
local function process_userdb_folders()
    local user_data_dir = rime_api.get_user_data_dir()

    -- 遍历文件夹，删除以 .userdb 结尾的文件夹下的所有数据库文件
    local command = string.format('find "%s"/*.userdb/ -maxdepth 1 -mindepth 1 -type f 2>/dev/null',
        user_data_dir)
    local os_is_windows = os_type == "windows"
    if os_is_windows then
        command = string.format(
            'for /f "tokens=*" %%G in (\'dir "%s"\\*.userdb /AD /B\') do dir "%s\\%%G" /A-D /B /S 2>nul',
            user_data_dir, user_data_dir)
    end

    local handle = io.popen(command)
    if not handle then return end

    local output = handle:read("*a") -- 一次性读取全部内容以尽快释放句柄
    handle:close()
    if not output then return end

    -- 然后处理收集到的行
    for line in output:gmatch("[^\r\n]+") do
        if startsWith(line, user_data_dir) then
            local success, err = os.remove(line)
            if not success then
                log.warning(string.format("清理 userdb 文件夹出错：%s。", err))
            end
        end
    end
end

-- 处理 .userdb.txt 文件并删除 c < 0 条目的函数
local function clean_userdb_file(file_path, env)
    local file, _ = io.open(file_path, "r")
    if not file then return end

    local temp_file_path = file_path .. ".tmp"
    local temp_file, _ = io.open(temp_file_path, "w")
    if not temp_file then
        file:close()
        return
    end

    local delete_count = 0
    for line in file:lines() do
        local c_str = line:match("c=(%-?%d+)")
        if c_str and tonumber(c_str) <= 0 then
            delete_count = delete_count + 1
        else
            temp_file:write(line, "\n")
        end
    end

    file:close()
    temp_file:close()

    -- 仅当有删除时才写入文件
    if delete_count > 0 then
        -- 原子替换文件
        os.remove(file_path)
        os.rename(temp_file_path, file_path)
        -- 更新计数器
        env.total_deleted = env.total_deleted + delete_count
    else
        os.remove(temp_file_path)
    end
end

-- 处理 .userdb.txt 文件并删除 c <= 0 条目
local function process_userdb_files(env)
    local sync_path, _ = get_sync_path_from_yaml(env)
    if not sync_path then return end

    local command = os_type == "windows"
        and (string.format("dir %s\\*.userdb.txt /A-D /B /S 2>nul", sync_path))
        or (string.format("find %s/ -maxdepth 1 -mindepth 1 -type f -name '*.userdb.txt' 2>/dev/null", sync_path))

    local handle = io.popen(command)
    if not handle then return end

    local output = handle:read("*a") -- 一次性读取全部内容以尽快释放句柄
    handle:close()
    if not output then return end

    -- 然后处理收集到的行
    for line in output:gmatch("[^\r\n]+") do
        if startsWith(line, sync_path) then
            pcall(clean_userdb_file, line, env)
        end
    end
end

-- 触发清理操作
local function trigger_sync_cleanup(env)
    process_userdb_files(env)
    process_userdb_folders()
end

-- 捕获输入并执行相应的操作
local function UserDictCleaner_process(_, env)
    local context = env.engine.context
    local input = context.input

    -- 检查是否输入 /del
    if input == "/del" and env.initialized then
        context:clear()       -- 清空输入内容，防止输入保留
        env.total_deleted = 0 -- 重置计数器

        pcall(trigger_sync_cleanup, env)
        -- 失败情况下会发送 0
        send_user_notification(env.total_deleted)

        return wanxiang.RIME_PROCESS_RESULTS.kAccepted -- 返回 1 表示已处理该事件
    end
    return wanxiang.RIME_PROCESS_RESULTS.kNoop     -- 返回 2 继续处理其它输入
end

-- 返回初始化和处理函数
return {
    init = init,
    func = UserDictCleaner_process
}