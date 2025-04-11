--万象家族lua,超级提示,表情\化学式\方程式\简码等等直接上屏,不占用候选位置
--采用leveldb数据库,支持大数据遍历,支持多种类型混合,多种拼音编码混合,维护简单
--支持候选匹配和编码匹配两种
--https://github.com/amzxyz/rime_wanxiang_pro
--https://github.com/amzxyz/rime_wanxiang
--     - lua_processor@*super_tips               #超级提示模块：表情、简码、翻译、化学式
--     key_binder/tips_key: "slash"     参数配置

local _db_pool = _db_pool or {}  -- 数据库池

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
-- 初始化词典（写模式，把 txt 加载进 db）
function M.init(env)
    local config = env.engine.schema.config
    M.tips_key = config:get_string('key_binder/tips_key')

    local db = wrapLevelDb('tips', true)
    local user_path = rime_api.get_user_data_dir() .. "/jm_dicts/tips_show.txt"
    local shared_path = rime_api.get_shared_data_dir() .. "/jm_dicts/tips_show.txt"
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
    db:close()  -- 初始化完，关闭数据库
end
-- 处理逻辑：有输入(或候选)时保持 db 打开；无输入(或候选)时关闭 db
function M.func(key, env)
    local context = env.engine.context
    local segment = context.composition:back()

    -- 如果没有输入 or 候选就关闭数据库，便于同步
    if not segment then
        local db = _db_pool["tips"]
        if db then
            db:close()  -- 没有输入，关闭 db
        end
        return 2
    end
    -- 有输入或候选时：只读方式打开 db
    local db = wrapLevelDb("tips", false)  -- 只读
    if not db then return 2 end

    local input_text = context.input or ""
    env.settings = { super_tips = context:get_option("super_tips") } or true
    local is_super_tips = env.settings.super_tips

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
    -- 如果按下了指定的提示键，并且启用了超级提示
    if (context:is_composing() or context:has_menu()) and M.tips_key and is_super_tips then
        local trigger = key:repr() == M.tips_key
        local text = selected_cand and selected_cand.text or input_text
        if trigger then
            local formatted = tips and (tips:match(".+：(.*)") or tips:match(".+:(.*)") or tips) or ""
            env.engine:commit_text(formatted)
            context:clear()
            return 1
        end
    end

    return 2
end

return M