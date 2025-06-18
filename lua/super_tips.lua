-- 万象家族lua,超级提示,表情\化学式\方程式\简码等等直接上屏,不占用候选位置
-- 采用leveldb数据库,支持大数据遍历,支持多种类型混合,多种拼音编码混合,维护简单
-- 支持候选匹配和编码匹配两种
-- https://github.com/amzxyz/rime_wanxiang_pro
-- https://github.com/amzxyz/rime_wanxiang
--     - lua_processor@*super_tips*S              手机电脑有着不同的逻辑,除了编码匹配之外,电脑支持光标高亮匹配检索,手机只支持首选候选匹配
--     - lua_filter@*super_tips*M
--     key_binder/tips_key: "slash"  #上屏按键配置
local wanxiang = require("wanxiang")
local _db_pool = {} -- 数据库池
-- 获取或创建 LevelDb 实例，避免重复打开
local function wrapLevelDb(dbname, mode)
    _db_pool[dbname] = _db_pool[dbname] or LevelDb(dbname)
    local db = _db_pool[dbname]

    local function close()
        if db:loaded() then
            collectgarbage()
            db:close()
        end
    end

    if db then
        if mode then
            close()
            db:open()
        elseif not db:loaded() then
            -- 读写模式需要 lock 数据
            db:open_read_only() -- 只读模式
        end
    end

    return db, close
end

local M = {}
local S = {}

local function ensure_dir_exist(dir)
    -- 获取系统路径分隔符
    local sep = package.config:sub(1, 1)

    dir = dir:gsub([["]], [[\"]]) -- 处理双引号

    if sep == "/" then
        local cmd = 'mkdir -p "' .. dir .. '" 2>/dev/null'
        os.execute(cmd)
    end
end

local function sync_tips_db_from_file(db, path)
    local file = io.open(path, "r")
    if not file then return end

    for line in file:lines() do
        local value, key = line:match("([^\t]+)\t([^\t]+)")
        if value and key then
            db:update(key, value)
        end
    end

    file:close()
end

-- 获取文件内容哈希值，使用 FNV-1a 哈希算法
local function calculate_file_hash(filepath)
    local file = io.open(filepath, "rb")
    if not file then return nil end

    -- FNV-1a 哈希参数（32位）
    local FNV_OFFSET_BASIS = 0x811C9DC5
    local FNV_PRIME = 0x01000193

    local hash = FNV_OFFSET_BASIS

    -- 分块读取文件（提高大文件处理效率）
    while true do
        local chunk = file:read(4096) -- 4KB 块大小
        if not chunk then break end

        -- 处理每个字节
        for i = 1, #chunk do
            local byte = string.byte(chunk, i)
            hash = hash ~ byte       -- XOR 操作
            hash = hash * FNV_PRIME  -- 乘法操作
            hash = hash & 0xFFFFFFFF -- 确保32位
        end
    end

    file:close()
    return string.format("%08x", hash) -- 返回16进制字符串
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

local function empty_tips_db(db)
    local da = db:query("")
    local count_before = 0
    for key, _ in da:iter() do
        db:erase(key)
        count_before = count_before + 1
    end
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
    local db, close_db = wrapLevelDb('lua/tips', true)
    local hash_key = "__TIPS_FILE_HASH"
    local hash_in_db = db:fetch(hash_key)

    local preset_file_path = get_preset_file_path()
    local user_override_path = rime_api.get_user_data_dir() .. "/lua/tips/tips_user.txt"
    local file_hash = string.format("%s|%s",
        calculate_file_hash(preset_file_path),
        calculate_file_hash(user_override_path))

    if hash_in_db == file_hash then
        close_db()
        return
    end

    empty_tips_db(db)
    db:update(hash_key, file_hash)
    sync_tips_db_from_file(db, preset_file_path)
    sync_tips_db_from_file(db, user_override_path)
    close_db()
end

-- 初始化词典（写模式，把 txt 加载进 db）
function M.init(env)
    local dist = rime_api.get_distribution_code_name() or ""
    local user_lua_dir = rime_api.get_user_data_dir() .. "/lua"
    if dist ~= "hamster" and dist ~= "Weasel" then
        ensure_dir_exist(user_lua_dir)
        ensure_dir_exist(user_lua_dir .. "/tips")
    end

    local start = os.clock()
    init_tips_userdb()
    log.info(string.format("[wanxiang/super_tips]: init_tips_userdb 共耗时 %s 秒", os.clock() - start))
end

-- 滤镜：设置提示内容
function M.func(input, env)
    local segment = env.engine.context.composition:back()
    if not segment then
        return 2
    end
    env.settings = {
        super_tips = env.engine.context:get_option("super_tips")
    } or true
    local is_super_tips = env.settings.super_tips
    local db = wrapLevelDb("lua/tips", false)
    -- 手机设备：读取数据库并输出候选
    if wanxiang.is_mobile_device() then
        local input_text = env.engine.context.input or ""
        local stick_phrase = db:fetch(input_text)

        -- 收集候选
        local first_cand, candidates = nil, {}
        for cand in input:iter() do
            if not first_cand then
                first_cand = cand
            end
            table.insert(candidates, cand)
        end
        local first_cand_match = first_cand and db:fetch(first_cand.text)
        local tipsph = stick_phrase or first_cand_match
        env.last_tips = env.last_tips or ""

        if is_super_tips and tipsph and tipsph ~= "" then
            env.last_tips = tipsph
            segment.prompt = "〔" .. tipsph .. "〕"
        else
            if segment.prompt == "〔" .. env.last_tips .. "〕" then
                segment.prompt = ""
            end
        end
        -- 输出候选
        for _, cand in ipairs(candidates) do
            yield(cand)
        end
        -- 输出候选
    else
        -- 如果不是手机设备，直接输出候选，不进行数据库操作
        for cand in input:iter() do
            yield(cand)
        end
    end
end

-- Processor：按键触发上屏 (S)
function S.init(env)
    local config = env.engine.schema.config
    S.tips_key = config:get_string("key_binder/tips_key")
    local db = wrapLevelDb("lua/tips", false)
end

function S.func(key, env)
    local context = env.engine.context
    local segment = context.composition:back()
    local input_text = context.input or ""
    if not segment then
        return 2
    end
    if string.match(input_text, "^[VRNU/]") then
        return 2
    end
    local db = wrapLevelDb("lua/tips", false)
    env.settings = {
        super_tips = context:get_option("super_tips")
    }
    local is_super_tips = env.settings.super_tips
    local tipspc
    local tipsph
    -- 电脑设备：直接处理按键事件并使用数据库
    if not wanxiang.is_mobile_device() then
        local input_text = context.input or ""
        local stick_phrase = db:fetch(input_text)
        local selected_cand = context:get_selected_candidate()
        local selected_cand_match = selected_cand and db:fetch(selected_cand.text) or nil
        tipspc = stick_phrase or selected_cand_match
        env.last_tips = env.last_tips or ""
        if is_super_tips and tipspc and tipspc ~= "" then
            env.last_tips = tipspc
            segment.prompt = "〔" .. tipspc .. "〕"
        else
            if segment.prompt == "〔" .. env.last_tips .. "〕" then
                segment.prompt = ""
            end
        end
    else
        tipsph = segment.prompt
    end
    -- 检查是否触发提示上屏
    if (context:is_composing() or context:has_menu()) and S.tips_key and is_super_tips and
        ((tipspc and tipspc ~= "") or (tipsph and tipsph ~= "")) then
        local trigger = key:repr() == S.tips_key
        if trigger then
            local formatted = (tipspc and (tipspc:match(".+：(.*)") or tipspc:match(".+:(.*)") or tips)) or
                (tipsph and (tipsph:match("〔.+：(.*)〕") or tipsph:match("〔.+:(.*)〕"))) or ""
            env.engine:commit_text(formatted)
            context:clear()
            return 1
        end
    end
    return 2
end

return {
    M = M,
    S = S
}
