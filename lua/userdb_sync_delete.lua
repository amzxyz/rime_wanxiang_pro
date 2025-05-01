-- 初始化函数
function init(env)
    if not env.initialized then
        env.initialized = true
        env.yaml_installation = detect_yaml_installation()  -- 解析 installation.yaml 文件，获取配置信息
        env.os_type = detect_os_type(env)  -- 全局变量，存储系统类型
        env.total_deleted = 0  -- 记录删除的总条目数
    end
end

-- 解析 installation.yaml 文件
function detect_yaml_installation()
    local function trim(s)
        return s:match("^%s*(.-)%s*$") or ""
    end

    local yaml = {}
    local user_data_dir = rime_api.get_user_data_dir()
    local yaml_path = user_data_dir .. "/installation.yaml"
    local file, err  = io.open(yaml_path, "r")
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
                    if #value >= 2 and value:sub(1,1) == '"' and value:sub(-1) == '"' then
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

-- 手动维护的操作系统检测模式表
local os_detection_patterns = {
    windows = { "weasel", "Weasel" },    -- Windows 的标识符列表
    linux = { "fcitx%-rime" },           -- Linux 的标识符
    macos = { "squirrel", "Squirrel" },  -- macOS 的标识符
    android = { "trime" }                -- android 的标识符
}

-- 检查系统类型
function detect_os_type(env)
    local os_type = "unknown"
    local dist_name = env.yaml_installation["distribution_code_name"]

    if not dist_name then
        return os_type
    end

    -- 遍历 os_detection_patterns 表来匹配系统类型
    for os, patterns in pairs(os_detection_patterns) do
        for _, pattern in ipairs(patterns) do
            if dist_name:match(pattern) then
                os_type = os
                break
            end
        end
        if os_type ~= "unknown" then break end
    end

    -- android 使用 fcitx5-android 输入法会误识别为 linux，这里额外处理一下
    if os_type == "linux" then
        local user_data_dir = rime_api.get_user_data_dir()
        if user_data_dir:match("^/org%.fcitx%.fcitx5%.android/$") then
            os_type = "android"
        end
    end

    return os_type
end

-- 检测并处理路径分隔符转换
function convert_path_separator(path, os_type)
    if os_type == "windows" then
        path = path:gsub("\\\\", "\\")  -- 将双反斜杠替换为单反斜杠
        path = path:gsub("/", "\\")     -- 将斜杠替换为反斜杠
    end
    return path
end

-- 从 installation.yaml 文件中获取 sync_dir 路径
function get_sync_path_from_yaml(env)
    local sync_dir = env.yaml_installation["sync_dir"]
    if not sync_dir then
        local user_data_dir = rime_api.get_user_data_dir()
        sync_dir = user_data_dir .. "/sync"
    end

    local installation_id = env.yaml_installation["installation_id"]
    if installation_id then
        sync_dir = sync_dir .. "/" .. installation_id
    end

    sync_dir = convert_path_separator(sync_dir, env.os_type)

    return sync_dir, nil
end

-- 捕获输入并执行相应的操作
function UserDictCleaner_process(key_event, env)
    local engine = env.engine
    local context = engine.context
    local input = context.input

    -- 检查是否输入 /del
    if input == "/del" and env.initialized then
        env.total_deleted = 0  -- 重置计数器

        pcall(trigger_sync_cleanup, env)
        send_user_notification(env.total_deleted, env) -- 失败情况下会发送0

        -- 清空输入内容，防止输入保留
        context:clear()
        return 1  -- 返回 1 表示已处理该事件
    end
    return 2  -- 返回 2 继续处理其它输入
end

-- 发送通知反馈函数，使用动态生成的消息
function send_user_notification(deleted_count, env)
    if env.os_type == "windows" then
        local ansi_message = generate_ansi_message(deleted_count)
        os.execute('msg * "' .. ansi_message .. '"')
    elseif env.os_type == "linux" then
        local utf8_message = generate_utf8_message(deleted_count)
        os.execute('notify-send "' .. utf8_message .. '"')
    elseif env.os_type == "macos" then
        local utf8_message = generate_utf8_message(deleted_count)
        os.execute('osascript -e \'display notification "' .. utf8_message .. '" with title "万象输入法"\'')
    elseif env.os_type == "android" then
        local utf8_message = generate_utf8_message(deleted_count)
        os.execute('notify "' .. utf8_message .. '"')
    end
end
-- 定义固定部分的ANSI编码
local base_message = "\xD3\xC3\xBB\xA7\xB4\xCA\xB5\xE4\xB9\xB2\xC7\xE5\xC0\xED\x20" -- "用户词典共清理 "（注意结尾有一个空格）
local end_message = "\x20\xD0\xD0\xCE\xDE\xD0\xA7\xB4\xCA\xCC\xF5" -- " 行无效词条"（前面带一个空格）

-- 预定义数字0-9的ANSI编码表示
local digit_to_ansi = {
    ["0"] = "\x30", ["1"] = "\x31", ["2"] = "\x32", ["3"] = "\x33",
    ["4"] = "\x34", ["5"] = "\x35", ["6"] = "\x36", ["7"] = "\x37",
    ["8"] = "\x38", ["9"] = "\x39"
}

-- 生成ANSI编码的删除条目数量部分
function encode_deleted_count_to_ansi(deleted_count)
    local ansi_count = ""
    for i = 1, #tostring(deleted_count) do
        local digit = tostring(deleted_count):sub(i, i)
        local encoded_digit = digit_to_ansi[digit] or ""
        ansi_count = ansi_count .. encoded_digit
    end
    return ansi_count
end

-- 动态生成完整的ANSI消息（适用于Windows）
function generate_ansi_message(deleted_count)
    local encoded_count = encode_deleted_count_to_ansi(deleted_count)
    return base_message .. encoded_count .. end_message
end

-- 动态生成UTF-8消息（适用于Linux）
function generate_utf8_message(deleted_count)
    return "用户词典共清理 " .. tostring(deleted_count) .. " 行无效词条"
end

-- 收集 path 目录下的目录，不含文件
function list_dirs(path, os_type)
    local command = os_type == "windows" and ('dir "'..path..'" /AD /B 2>nul') or ('ls -p "'..path..'" | grep / 2>/dev/null')
    local handle = io.popen(command)
    if not handle then
        return nil, "无法遍历路径: " .. path
    end

    local dirs = {}
    for dir in handle:lines() do
        if dir:sub(-1) == "/" then
            dir = dir:sub(1, -2)
        end
        local full_path = path .. "/" .. dir
        full_path = convert_path_separator(full_path, os_type)
        table.insert(dirs, full_path)
    end
    handle:close()
    return dirs, nil
end

-- 收集 path 目录下的文件，不含目录
function list_files(path, os_type)
    local command = os_type == "windows" and ('dir "'..path..'" /A-D /B 2>nul') or ('ls -p "'..path..'" | grep -v / 2>/dev/null')
    local handle = io.popen(command)
    if not handle then
        return nil, "无法遍历路径: " .. path
    end

    local files = {}
    for file in handle:lines() do
        local full_path = path .. "/" .. file
        full_path = convert_path_separator(full_path, os_type)
        table.insert(files, full_path)
    end
    handle:close()
    return files, nil
end

-- 处理 .userdb.txt 文件并删除 c < 0 条目的函数
function clean_userdb_file(file_path, env)
    local file, err = io.open(file_path, "r")
    if not file then
        return
    end

    local temp_file_path = file_path .. ".tmp"
    local temp_file = io.open(temp_file_path, "w")
    if not temp_file then
        file:close()
        return
    end

    local entries_deleted = false
    local delete_count = 0
    for line in file:lines() do
        local c_value = line:match("c=(%-?%d+)")
        if c_value then
            c_value = tonumber(c_value)
            if c_value > 0 then
                temp_file:write(line .. "\n")
            else
                entries_deleted = true
                delete_count = delete_count + 1
            end
        else
            temp_file:write(line .. "\n")
        end
    end

    file:close()
    temp_file:close()

    if entries_deleted then
        os.remove(file_path)
        os.rename(temp_file_path, file_path)
        -- 更新总删除计数
        env.total_deleted = env.total_deleted + delete_count
    else
        os.remove(temp_file_path)
    end
end

-- 处理 .userdb.txt 文件并删除 c <= 0 条目
function process_userdb_files(env)
    local sync_path, err = get_sync_path_from_yaml(env)
    if not sync_path then
        return
    end

    local files, err = list_files(sync_path, env.os_type)
    if not files then
        return
    end

    for _, file in ipairs(files) do
        if file:match("%.userdb%.txt$") then
            clean_userdb_file(file, env)
        end
    end
end

-- 删除 installation.yaml 同级目录下的 .userdb 文件夹
function process_userdb_folders(env)
    local user_data_dir = rime_api.get_user_data_dir()
    local dirs, err = list_dirs(user_data_dir, env.os_type)

    if not dirs then
        return
    end

    -- 遍历文件夹，删除以 .userdb 结尾的文件夹
    for _, dir in ipairs(dirs) do
        if dir:match("%.userdb$") then
            local command = env.os_type == "windows" and ('rmdir /S /Q "' .. dir .. '"') or ('rm -rf "' .. dir .. '"')
            os.execute(command)
        end
    end
end

-- 触发清理操作
function trigger_sync_cleanup(env)
    -- 查找 .userdb.txt 文件，删除 c <= 0 条目
    process_userdb_files(env)

    -- 查找 .userdb 文件夹，删除
    process_userdb_folders(env)
end

-- 返回初始化和处理函数
return {
    init = init,
    func = UserDictCleaner_process
}
