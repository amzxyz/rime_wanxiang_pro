-- 万象家族lua,超级提示,表情\化学式\方程式\简码等等直接上屏,不占用候选位置
-- 采用leveldb数据库,支持大数据遍历,支持多种类型混合,多种拼音编码混合,维护简单
-- 支持候选匹配和编码匹配两种，候选支持方向键高亮遍历
-- https://github.com/amzxyz/rime_wanxiang
--     - lua_processor@*super_tips
--     key_binder/tips_key: "slash" # 上屏按键配置
local wanxiang = require("wanxiang")

---@type UserDb | nil
local db = nil -- 数据库池
local function close_db()
    if db and db:loaded() then
        collectgarbage()
        return db:close()
    end
    return true
end

-- 获取或创建 LevelDb 实例，避免重复打开
---@param mode? boolean
---@return UserDb
local function getUserDB(mode)
    if db == nil then db = LevelDb("lua/tips") end

    mode = mode or false

    if mode == true and db and db:loaded() and db.read_only then
        close_db()
    end

    if db and not db:loaded() then
        if mode then
            db:open()
        else
            db:open_read_only()
        end
    end

    return db
end

local function ensure_dir_exist(dir)
    -- 获取系统路径分隔符
    local sep = package.config:sub(1, 1)

    dir = dir:gsub([["]], [[\"]]) -- 处理双引号

    if sep == "/" then
        local cmd = 'mkdir -p "' .. dir .. '" 2>/dev/null'
        os.execute(cmd)
    end
end

---@return table<string>
local function sync_tips_db_from_file(db, path)
    local keys = {}

    local file = io.open(path, "r")
    if not file then return keys end

    for line in file:lines() do
        local value, key = line:match("([^\t]+)\t([^\t]+)")
        if value and key then
            db:update(key, value)
            table.insert(keys, key)
        end
    end

    file:close()
    return keys
end

-- 获取文件内容哈希值，使用 FNV-1a 哈希算法（增强兼容性，避免位运算依赖）
local function calculate_file_hash(filepath)
    local file = io.open(filepath, "rb")
    if not file then return nil end

    -- FNV-1a 哈希参数（32位）
    local FNV_OFFSET_BASIS = 0x811C9DC5
    local FNV_PRIME = 0x01000193

    local bit_xor = function(a, b)
        local p, c = 1, 0
        while a > 0 and b > 0 do
            local ra, rb = a % 2, b % 2
            if ra ~= rb then c = c + p end
            a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
        end
        if a < b then a = b end
        while a > 0 do
            local ra = a % 2
            if ra > 0 then c = c + p end
            a, p = (a - ra) / 2, p * 2
        end
        return c
    end

    local bit_and = function(a, b)
        local p, c = 1, 0
        while a > 0 and b > 0 do
            local ra, rb = a % 2, b % 2
            if ra + rb > 1 then c = c + p end
            a, b, p = (a - ra) / 2, (b - rb) / 2, p * 2
        end
        return c
    end

    local function hash_compt()
        local hash = FNV_OFFSET_BASIS
        while true do
            local chunk = file:read(4096)
            if not chunk then break end
            for i = 1, #chunk do
                local byte = string.byte(chunk, i)
                hash = bit_xor(hash, byte)
                hash = (hash * FNV_PRIME) % 0x100000000
                hash = bit_and(hash, 0xFFFFFFFF)
            end
        end
        return hash
    end

    local function hash_native()
        local hash = FNV_OFFSET_BASIS
        while true do
            local chunk = file:read(4096)
            if not chunk then break end
            for i = 1, #chunk do
                local byte = string.byte(chunk, i)
                hash = hash ~ byte
                hash = hash * FNV_PRIME
                hash = hash & 0xFFFFFFFF
            end
        end
        return hash
    end

    local r, hash = pcall(hash_native)
    if not r then
        file:seek("set", 0)
        hash = hash_compt()
        log.warning("[super_tips] 不支持位运算符，使用兼容 hash 计算方式")
    end

    file:close()
    return string.format("%08x", hash)
end

local function file_exists(name)
    local f = io.open(name, "r")
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

---清理 db
---@param db UserDb
---@param user_keys? function | nil
---@param erase_presets? boolean
local function empty_tips_db(db, user_keys, erase_presets)
    erase_presets = erase_presets or false

    local da = db:query("")
    if user_keys and not erase_presets then
        for key in user_keys do
            db:erase(key)
        end
    elseif user_keys and erase_presets then
        local user_keys_d = {}
        for key in user_keys do
            user_keys_d[key] = true
        end
        for key, _ in da:iter() do
            local is_preset = user_keys_d[key] == nil
            if is_preset then db:erase(key) end
        end
    else
        for key, _ in da:iter() do
            db:erase(key)
        end
    end
    ---@diagnostic disable-next-line: cast-local-type
    da = nil
end

local function get_preset_file_path()
    local preset_path = "/lua/tips/tips_show.txt"
    local preset_path_user = rime_api.get_user_data_dir() .. preset_path
    local preset_path_shared = rime_api.get_shared_data_dir() .. preset_path

    if file_exists(preset_path_user) then
        return preset_path_user
    end
    return preset_path_shared
end

local function init_tips_userdb()
    local preset_file_path = get_preset_file_path()
    local user_override_path = rime_api.get_user_data_dir() .. "/lua/tips/tips_user.txt"

    local db = getUserDB()


    local version_key = "wanxiang_version"
    local version_in_db = db:fetch("\001" .. version_key)
    local is_version_need_update = version_in_db ~= wanxiang.version

    local is_preset_tips_need_update = false
    local preset_hash_key = "\001" .. "hash_preset"
    local preset_file_hash = nil
    -- 如果版本号有变化，则判断 preset tips hash
    if is_version_need_update then
        local db_hash = db:fetch(preset_hash_key)
        preset_file_hash = calculate_file_hash(preset_file_path)
        is_preset_tips_need_update = preset_file_hash ~= db_hash
    end

    local user_hash_key = "\001" .. "hash_user"
    local db_hash = db:fetch(user_hash_key)
    local user_file_hash = calculate_file_hash(user_override_path)
    local is_user_tips_need_update = user_file_hash ~= db_hash

    if not is_version_need_update
        and not is_user_tips_need_update
        and not is_user_tips_need_update
    then
        return
    end

    local user_keys_key = "\001" .. "user_keys"

    ---@param userdb UserDb
    ---@param keys table<string>
    local function update_user_keys(userdb, keys)
        userdb:update(user_keys_key, table.concat(keys, '\t'))
    end

    ---@param userdb UserDb
    ---@return function | nil
    local function get_user_keys(userdb)
        local db_value = userdb:fetch(user_keys_key)
        if db_value then
            return db_value:gmatch("([^\t]+)")
        end
        return nil
    end

    -- userdb 需要更新
    db = getUserDB(true) -- 以读写模式打开数据库

    if is_version_need_update then
        db:update(version_key, wanxiang.version)
    end

    local user_keys = nil
    if is_preset_tips_need_update then
        empty_tips_db(db)
        sync_tips_db_from_file(db, preset_file_path)
        user_keys = sync_tips_db_from_file(db, user_override_path)
    elseif is_user_tips_need_update then
        empty_tips_db(db, get_user_keys(db))
        user_keys = sync_tips_db_from_file(db, user_override_path)
    end
    if user_keys then
        update_user_keys(db, user_keys)
    end
    if preset_file_hash then
        db:update(preset_hash_key, preset_file_hash)
    end
    if user_file_hash then
        db:update(user_hash_key, user_file_hash)
    end
    close_db() -- 主动关闭数据库，后续只需要只读方式打开
end

local function update_tips_prompt(context, env)
    local segment = context.composition:back()
    if segment == nil then return end

    local db = getUserDB()

    ---@type string | nil 存放 db 中查到的 tips 值
    local tips_text = context.input and db:fetch(context.input)

    -- 如果 context.input 没有匹配的 tips，则使用候选词查找
    if tips_text == nil or tips_text == "" then
        local candidate = context:get_selected_candidate()
        tips_text = candidate and db:fetch(candidate.text)
    end

    if tips_text ~= nil and tips_text ~= ""
    then -- 有 tips 则直接设置 prompt
        env.last_tip_prompt = "〔" .. tips_text .. "〕"
        segment.prompt = env.last_tip_prompt
    else -- 没有则重置
        if env.last_tip_prompt == segment.prompt then
            env.last_tip_prompt = nil
            segment.prompt = ""
        end
    end
end

local P = {}

-- Processor：按键触发上屏 (S)
function P.init(env)
    local dist = rime_api.get_distribution_code_name() or ""
    local user_lua_dir = rime_api.get_user_data_dir() .. "/lua"
    if dist ~= "hamster" and dist ~= "Weasel" then
        ensure_dir_exist(user_lua_dir)
        ensure_dir_exist(user_lua_dir .. "/tips")
    end

    init_tips_userdb()

    P.tips_key = env.engine.schema.config:get_string("key_binder/tips_key")

    -- 注册 tips 查找监听器
    local context = env.engine.context
    env.tips_update_connection = context.update_notifier:connect(
        function(context)
            local is_tips_enabled = context:get_option("super_tips")
            if is_tips_enabled == true then
                update_tips_prompt(context, env)
            end
        end
    )
end

function P.fini(env)
    close_db()
    -- 清理连接
    if env.tips_update_connection then
        env.tips_update_connection:disconnect()
    end
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
    local is_tips_enabled = env.engine.context:get_option("super_tips")

    local context = env.engine.context
    local segment = context.composition:back()

    if not is_tips_enabled
        or not segment
        or wanxiang.is_function_mode_active(context)
    then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- rime 内核在移动候选时并不会触发 update_notifier，这里做一个临时修复
    -- 如果是 paging，则主动调用 update_tips_prompt
    if segment:has_tag("paging") then
        update_tips_prompt(context, env)
    end

    -- 检查是否触发提示上屏
    ---@type string 从 prompt 中获取的当前 tip 文本
    local tip_text = segment.prompt and (
        segment.prompt:match("：%s*(.*)%s*〕") -- 优先匹配常规的全角冒号
        or segment.prompt:match(":%s*(.*)%s*〕") -- 没有匹配则回落到半角冒号
        or "")

    if (context:is_composing() or context:has_menu())
        and P.tips_key
        and key:repr() == P.tips_key
        and tip_text:len() > 0
    then
        env.engine:commit_text(tip_text)
        context:clear()
        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end

    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
