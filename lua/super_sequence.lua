--万象拼音方案新成员，手动自由排序
--一个基于快捷键计数偏移量来手动调整排序的工具
--这个版本是db数据库支持的版本,可能会支持更多的排序记录,作为一个备用版本留存
--ctrl+j左移 ctrl+k左移  ctrl+0移除排序信息,固定词典其实没必要删除,直接降权到后面
--排序算法可能还不完美,有能力的朋友欢迎帮忙变更算法
local cur_selected_text = nil

local _user_db = nil
-- 获取或创建 LevelDb 实例，避免重复打开
---@param mode? boolean 默认为只读，true 为写模式
local function getUserDB(mode)
    _user_db = _user_db or LevelDb('lua/sequence')

    local function close()
        if _user_db:loaded() then
            collectgarbage()
            _user_db:close()
        end
    end

    if mode == true and _user_db and _user_db:loaded() and _user_db.read_only then
        close()
    end

    if _user_db and not _user_db:loaded() then
        if mode == true then
            _user_db:open()
        else
            _user_db:open_read_only()
        end
    end

    return _user_db, close
end

---@param value string LevelDB 中序列化的值
---@return table<{index: number, updated_at: number}>
local function parsePhraseValue(value)
    local result = {}

    local match = value:gmatch("%d+")
    result.index = tonumber(match());
    result.updated_at = tonumber(match());

    return result
end

---@param input string 当前输入码
---@param phrase string 候选词
---@return table<{index: number, updated_at: number}> | nil
local function getUserPhrase(input, phrase)
    local db = getUserDB()

    local key = string.format("%s|%s", input, phrase)
    local value = db:fetch(key)

    return value ~= nil and parsePhraseValue(value) or nil
end

---@param input string 当前输入码
---@return table<string, {index: number, updated_at: number, candidate: Candidate}> | nil
local function getUserSegment(input)
    local db = getUserDB()

    local accessor = db:query(input)
    if accessor == nil then return nil end

    local table = nil
    for key, value in accessor:iter() do
        if table == nil then table = {} end
        local phrase = string.gsub(key, "^.*|", "")
        table[phrase] = parsePhraseValue(value)
    end

    ---@diagnostic disable-next-line: cast-local-type
    accessor = nil

    return table
end

---@param input string
---@param phrase string
---@param index number | nil
local function saveUserSegment(input, phrase, index)
    local db = getUserDB(true)

    local key = string.format("%s|%s", input, phrase)
    local value = string.format("%s\t%s", index, os.time())

    local result = index == nil and db:erase(key) or db:update(key, value)
    return result
end

local P = {}
function P.init() end

function P.fini()
    local _, db_close = getUserDB()
    db_close()
end

local PROCESS_RESULTS = {
    kRejected = 0,
    kAccepted = 1,
    kNoop = 2,
}

-- P 阶段按键处理
---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key_event, env)
    if not key_event:ctrl() or key_event:release() then
        return PROCESS_RESULTS.kNoop
    end

    local context = env.engine.context
    local segment = context.composition:back()
    if not segment then
        return PROCESS_RESULTS.kNoop
    end

    local input = context.input
    local selected_cand = context:get_selected_candidate()
    cur_selected_text = selected_cand.text
    local user_segment = getUserPhrase(input, cur_selected_text) or { index = nil }

    local from_index = user_segment.index or segment.selected_index
    local new_index
    -- 判断按下的键，更新偏移量
    if key_event.keycode == 0x6A then -- ctrl + j (向左移动 1 个)
        new_index = from_index - 1
        if new_index < 0 then
            new_index = 0
        end
    elseif key_event.keycode == 0x6B then -- ctrl + k (向右移动 1 个)
        new_index = from_index + 1

        -- 加载候选
        segment.menu:prepare(new_index + 1)
        local candidate_count = segment.menu:candidate_count()
        if new_index > candidate_count - 1 then
            new_index = candidate_count - 1
        end
    elseif key_event.keycode == 0x30 then -- ctrl + 0 (删除位移信息)
        new_index = nil
    end

    -- 索引位置未变化
    if new_index == segment.selected_index then
        return PROCESS_RESULTS.kNoop
    end

    saveUserSegment(input, cur_selected_text, new_index)

    context:refresh_non_confirmed_composition()
    if new_index and context.highlight then
        context:highlight(new_index)
    end

    return PROCESS_RESULTS.kAccepted
end

local F = {}
function F.init() end

function F.fini()
    local _, db_close = getUserDB()
    db_close()
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local context = env.engine.context
    local user_segment = getUserSegment(context.input)

    if user_segment == nil then
        for cand in input:iter() do
            yield(cand)
        end
        return
    end

    local dedup = {} -- 用于去重
    local new_candidates = {}
    for cand in input:iter() do
        local text = cand.text

        dedup[text] = (dedup[text] or 0) + 1
        if dedup[text] == 1 then goto continue end

        if user_segment[text] ~= nil then
            user_segment[text].candidate = cand
        else
            table.insert(new_candidates, cand)
        end

        ::continue::
    end

    local user_cand_list = {}
    for _, info in pairs(user_segment) do
        if info.candidate ~= nil then
            table.insert(user_cand_list, info)
        end
    end

    table.sort(user_cand_list, function(a, b) return a.updated_at < b.updated_at end)

    for _, info in ipairs(user_cand_list) do
        table.insert(new_candidates, info.index + 1, info.candidate)
    end

    for _, cand in ipairs(new_candidates) do
        yield(cand)
    end
end

return { P = P, F = F }
