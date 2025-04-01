--万象家族lua,超级提示,表情\化学式\方程式\简码等等直接上屏,不占用候选位置
--采用leveldb数据库,支持大数据遍历,支持多种类型混合,多种拼音编码混合,维护简单
--支持候选匹配和编码匹配两种
--https://github.com/amzxyz/rime_wanxiang_pro
--https://github.com/amzxyz/rime_wanxiang
--     - lua_processor@*super_tips               #超级提示模块：表情、简码、翻译、化学式
--     key_binder/tips_key: "slash"     参数配置
local _db_pool = _db_pool or {}  -- 数据库池
local M = {}

-- 获取或创建 LevelDb 实例，避免重复打开
local function wrapLevelDb(dbname, mode)
    _db_pool[dbname] = _db_pool[dbname] or LevelDb(dbname)
    local db = _db_pool[dbname]
    if db and not db:loaded() then
        if mode then db:open() else db:open_read_only() end
    end
    return db
end

-- 优先读取用户目录，如果不存在则尝试系统目录
local function find_dict_file(filename)
    local user_path = rime_api.get_user_data_dir() .. "/jm_dicts/" .. filename
    local shared_path = rime_api.get_shared_data_dir() .. "/jm_dicts/" .. filename

    local f = io.open(user_path, "r")
    if f then f:close(); return user_path end

    f = io.open(shared_path, "r")
    if f then f:close(); return shared_path end

    return nil
end

-- 初始化词典并加载数据到 LevelDB
function M.init(env)
    local config = env.engine.schema.config
    M.tips_key = config:get_string('key_binder/tips_key')

    local db = wrapLevelDb('tips', true)
    local path = find_dict_file("tips_show.txt")

    if not path then
        db:close()
        return
    end

    local file = io.open(path, "r")
    if not file then db:close(); return end

    for line in file:lines() do
        if not line:match("^#") then
            local value, key = line:match("([^\t]+)\t([^\t]+)")
            if value and key then
                db:update(key, value)
            end
        end
    end

    file:close()
    db:close()
end

-- 处理候选词及提示逻辑
function M.func(key, env)
    local engine = env.engine
    local context = engine.context
    local segment = context.composition:back()
    if not segment then return 2 end

    local input_text = context.input or ""
    env.settings = { super_tips = context:get_option("super_tips") } or true
    local is_super_tips = env.settings.super_tips

    local db = wrapLevelDb("tips", false)
    local stick_phrase = db:fetch(input_text)

    local selected_cand = context:get_selected_candidate()
    local selected_cand_match = selected_cand and db:fetch(selected_cand.text) or nil

    local tips = stick_phrase or selected_cand_match
    env.last_tips = env.last_tips or ""

    if is_super_tips and tips and tips ~= "" then
        env.last_tips = tips
        segment.prompt = "〔" .. tips .. "〕"
    else
        if segment.prompt == "〔" .. env.last_tips .. "〕" then
            segment.prompt = ""
        end
    end

    if (context:is_composing() or context:has_menu()) and M.tips_key and is_super_tips then
        local trigger = key:repr() == M.tips_key
        local text = selected_cand and selected_cand.text or input_text

        if trigger then
            local formatted = tips and (tips:match(".+：(.*)") or tips:match(".+:(.*)") or tips) or ""
            engine:commit_text(formatted)
            context:clear()
            return 1
        end
    end

    return 2
end
return M

