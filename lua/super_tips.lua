-- 万象家族lua,超级提示,表情\化学式\方程式\简码等等直接上屏,不占用候选位置
-- 采用leveldb数据库,支持大数据遍历,支持多种类型混合,多种拼音编码混合,维护简单
-- 支持候选匹配和编码匹配两种，候选支持方向键高亮遍历
-- https://github.com/amzxyz/rime_wanxiang
--     - lua_processor@*super_tips
--     key_binder/tips_key: "slash" # 上屏按键配置

local META_KEY_PREFIX = "\001"
local META_KEY_VERSION = "wanxiang_version"
local META_KEY_USER_TIPS_FILE_HASH = "user_tips_file_hash"

local FILENAME_TIPS_PRESET = "lua/tips/tips_show.txt"
local FILENAME_TIPS_USER = "lua/tips/tips_user.txt"

local wanxiang = require("wanxiang")

local tips_db = {}
---@type UserDb | nil
tips_db.instance = nil -- 数据库池
function tips_db.close()
    if tips_db.instance and tips_db.instance:loaded() then
        collectgarbage()
        return tips_db.instance:close()
    end
    return true
end

-- 获取或创建 LevelDb 实例，避免重复打开
---@param write_mode? boolean 是否需要写权限
---@return UserDb
function tips_db.get(write_mode)
    if tips_db.instance == nil then tips_db.instance = LevelDb("lua/tips") end

    local is_loaded = tips_db.instance:loaded()
    local needs_open = false

    if is_loaded and write_mode and tips_db.instance.read_only then
        -- 需要写权限，但当前是只读模式，需要重新打开
        needs_open = true
    elseif not is_loaded then
        -- 尚未加载，需要打开
        needs_open = true
    end

    if needs_open then
        if is_loaded then tips_db.instance:close() end -- 确保关闭旧连接
        if write_mode then
            tips_db.instance:open()
        else
            tips_db.instance:open_read_only()
        end
    end

    return tips_db.instance
end

function tips_db.empty()
    local db = tips_db.get(true)
    local da
    da = db:query("")
    for key, _ in da:iter() do
        db:erase(key)
    end
    da = nil
end

function tips_db.fetch(key)
    return tips_db.get():fetch(key)
end

function tips_db.update(key, value)
    return tips_db.get(true):update(key, value)
end

function tips_db.meta_fetch(key)
    return tips_db.fetch(META_KEY_PREFIX .. key)
end

function tips_db.meta_update(key, value)
    return tips_db.update(META_KEY_PREFIX .. key, value)
end

function tips_db.get_wanxiang_version()
    return tips_db.meta_fetch(META_KEY_VERSION)
end

---@param version string
function tips_db.update_wanxiang_version(version)
    return tips_db.meta_update(META_KEY_VERSION, version)
end

function tips_db.get_user_tips_file_hash()
    return tips_db.meta_fetch(META_KEY_USER_TIPS_FILE_HASH)
end

---@param hash string
function tips_db.update_user_tips_file_hash(hash)
    return tips_db.meta_update(META_KEY_USER_TIPS_FILE_HASH, hash)
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

local function sync_tips_db_from_file(path)
    local file = io.open(path, "r")
    if not file then return end

    for line in file:lines() do
        local value, key = line:match("([^\t]+)\t([^\t]+)")
        if value and key then
            tips_db.update(key, value)
        end
    end

    file:close()
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

local function init_tips_userdb()
    local has_preset_tips_changed = wanxiang.version ~= tips_db.get_wanxiang_version()

    local has_user_tips_changed = false
    local user_override_path = rime_api.get_user_data_dir() .. "/" .. FILENAME_TIPS_USER
    local user_tips_file_hash = calculate_file_hash(user_override_path)
    if user_tips_file_hash then
        has_user_tips_changed = user_tips_file_hash ~= tips_db.get_user_tips_file_hash()
    end

    if not has_preset_tips_changed and not has_user_tips_changed then
        return
    end

    tips_db.empty()

    tips_db.update_wanxiang_version(wanxiang.version)
    tips_db.update_user_tips_file_hash(user_tips_file_hash or "")

    local preset_file_path = wanxiang.get_filename_with_fallback(FILENAME_TIPS_PRESET)
    sync_tips_db_from_file(preset_file_path)
    sync_tips_db_from_file(user_override_path)

    tips_db.close() -- 主动关闭数据库，后续只需要只读方式打开
end

local function update_tips_prompt(context, env)
    local segment = context.composition:back()
    if segment == nil then return end

    ---@type string | nil 存放 db 中查到的 tips 值
    env.current_tip = context.input and tips_db.fetch(context.input)

    -- 如果 context.input 没有匹配的 tips，则使用候选词查找
    if env.current_tip == nil or env.current_tip == "" then
        local candidate = context:get_selected_candidate()
        env.current_tip = candidate and tips_db.fetch(candidate.text)
    end

    if env.current_tip ~= nil and env.current_tip ~= "" then
        -- 有 tips 则直接设置 prompt
        segment.prompt = "〔" .. env.current_tip .. "〕"
        env.last_prompt = segment.prompt
    elseif segment.prompt ~= "" and env.last_prompt == segment.prompt then
        -- 没有 tips，且当前 prompt 不为空，且是由 super_tips 设置的，则重置
        segment.prompt = ""
        env.last_prompt = segment.prompt
    end
end

---@class Env
---@field current_tip string | nil
---@field last_prompt string
---@field tips_update_connection any

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
    tips_db.close()
    -- 清理连接
    if env.tips_update_connection then
        env.tips_update_connection:disconnect()
        env.tips_update_connection = nil
    end
end

---@param key KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key, env)
    local context = env.engine.context

    local is_tips_enabled = context:get_option("super_tips")
    local segment = context.composition:back()
    if not is_tips_enabled or not segment then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- 如果启用了 tips 功能，则应使用此 workaround
    -- rime 内核在移动候选时并不会触发 update_notifier，这里做一个临时修复
    -- 如果是 paging，则主动调用 update_tips_prompt
    if segment:has_tag("paging") then
        update_tips_prompt(context, env)
    end

    -- 以下处理 tips 上屏逻辑
    if not P.tips_key                                   -- 未设置上屏键
        or P.tips_key ~= key:repr()                     -- 或者当前按下的不是上屏键
        or wanxiang.is_function_mode_active(context)    -- 或者是功能模式不用上屏
        or not env.current_tip or env.current_tip == "" --  或匹配的 tips 为空/空字符串
    then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    ---@type string 从 tips 内容中获取上屏文本
    local commit_txt = env.current_tip:match("：%s*(.*)%s*") -- 优先匹配常规的全角冒号
        or env.current_tip:match(":%s*(.*)%s*") -- 没有匹配则回落到半角冒号

    if commit_txt and #commit_txt > 0 then
        env.engine:commit_text(commit_txt)
        context:clear()
        return wanxiang.RIME_PROCESS_RESULTS.kAccepted
    end

    return wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
