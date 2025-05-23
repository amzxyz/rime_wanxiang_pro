--万象家族lua,超级提示,表情\化学式\方程式\简码等等直接上屏,不占用候选位置
--采用leveldb数据库,支持大数据遍历,支持多种类型混合,多种拼音编码混合,维护简单
--支持候选匹配和编码匹配两种
--https://github.com/amzxyz/rime_wanxiang_pro
--https://github.com/amzxyz/rime_wanxiang
--     - lua_processor@*super_tips*S              手机电脑有着不同的逻辑,除了编码匹配之外,电脑支持光标高亮匹配检索,手机只支持首选候选匹配
--     - lua_filter@*super_tips*M                  
--     key_binder/tips_key: "slash"  #上屏按键配置
local _db_pool = _db_pool or {}  -- 数据库池
-- 获取或创建 LevelDb 实例，避免重复打开
local function wrapLevelDb(dbname, mode)
    _db_pool[dbname] = _db_pool[dbname] or LevelDb(dbname)
    local db = _db_pool[dbname]
    if db and not db:loaded() then
        if mode then
            db:open()  -- 读写模式
        else
            db:open_read_only()  -- 只读模式
        end
    end
    return db
end

local M = {}
local S = {}

local function ensure_dir_exist(dir)
    -- 获取系统路径分隔符
    local sep = package.config:sub(1,1)

    dir = dir:gsub([["]], [[\"]])  -- 处理双引号

    if sep == "/" then
        local cmd = 'mkdir -p "'..dir..'" 2>/dev/null'
        local success = os.execute(cmd)
    end
end

-- 初始化词典（写模式，把 txt 加载进 db）
function M.init(env)
    local config = env.engine.schema.config
    local dist = rime_api.get_distribution_code_name() or ""
    local user_lua_dir = rime_api.get_user_data_dir() .. "/lua"
    if dist ~= "hamster" and dist ~= "Weasel" then
        ensure_dir_exist(user_lua_dir)
        ensure_dir_exist(user_lua_dir .. "/tips")
    end

    local db = wrapLevelDb('lua/tips', true)
    local user_path = rime_api.get_user_data_dir() .. "/lua/tips/tips_show.txt"
    local shared_path = rime_api.get_shared_data_dir() .. "/lua/tips/tips_show.txt"
    local path = nil

    local f = io.open(user_path, "r")
    if f then 
        f:close()
        path = user_path 
    else
        f = io.open(shared_path, "r")
        if f then
            f:close()
            path = shared_path
        end
    end
    if not path then
        db:close()
        return
    end

    local file = io.open(path, "r")
    if not file then 
        db:close()
        return 
    end
    for line in file:lines() do
        if not line:match("^#") then
            local value, key = line:match("([^\t]+)\t([^\t]+)")
            if value and key then
                db:update(key, value)
            end
        end
    end
    file:close()

    -- 加载用户覆盖文件
    local user_override_path = rime_api.get_user_data_dir() .. "/lua/tips/tips_user.txt"
    local override_file = io.open(user_override_path, "r")
    if override_file then
        for line in override_file:lines() do
            if not line:match("^#") then
                local value, key = line:match("([^\t]+)\t([^\t]+)")
                if value and key then
                    db:update(key, value)  -- 高优先级覆盖
                end
            end
        end
        override_file:close()
    end

    collectgarbage()
    db:close()
end
-- 判断是否为手机设备，通过路径来判断（可以根据实际路径修改判断方式）
local function is_mobile_device()
    local dist = rime_api.get_distribution_code_name() or ""
    local user_data_dir = rime_api.get_user_data_dir() or ""
    -- 主判断：trime 或 hamster
    if dist == "trime" or dist == "hamster" or dist == "Squirrel" then
        return true
    end
    -- 补充判断：路径中出现 mobile/Android/手机特征，/data/storage/el2/随机字符串/group是鸿蒙的路径
    local lower_path = user_data_dir:lower()
    if lower_path:find("/android/") or lower_path:find("/mobile/") or lower_path:find("/sdcard/") or lower_path:find("/data/storage/") then
        return true
    end
    return false
end
-- 滤镜：设置提示内容
function M.func(input, env)
    local segment = env.engine.context.composition:back()
    if not segment then
        return 2
    end
    env.settings = { super_tips = env.engine.context:get_option("super_tips") } or true
    local is_super_tips = env.settings.super_tips
    local db = wrapLevelDb("lua/tips", false)
    -- 手机设备：读取数据库并输出候选
    if is_mobile_device() then
        local input_text = env.engine.context.input or ""
        local stick_phrase = db:fetch(input_text)

        -- 收集候选
        local first_cand, candidates = nil, {}
        for cand in input:iter() do
            if not first_cand then first_cand = cand end
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
    env.settings = { super_tips = context:get_option("super_tips") }
    local is_super_tips = env.settings.super_tips
    local tipspc
    local tipsph
    -- 电脑设备：直接处理按键事件并使用数据库
    if not is_mobile_device() then
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
    if (context:is_composing() or context:has_menu())
        and S.tips_key
        and is_super_tips
        and ((tipspc and tipspc ~= "") or (tipsph and tipsph ~= "")) then
        local trigger = key:repr() == S.tips_key
        local text = selected_cand and selected_cand.text or input_text
        if trigger then
            local formatted = (tipspc and (tipspc:match(".+：(.*)") or tipspc:match(".+:(.*)") or tips)) or (tipsph and (tipsph:match("〔.+：(.*)〕") or tipsph:match("〔.+:(.*)〕"))) or ""
            env.engine:commit_text(formatted)
            context:clear()
            return 1
        end
    end
    return 2
end
return { M = M, S = S }