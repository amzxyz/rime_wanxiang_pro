-- 万象拼音方案新成员：手动自由排序
-- 数据存放于 userdb 中，处于性能考量，此排序仅影响当前输入码
-- ctrl+j 前移
-- ctrl+k 后移
-- ctrl+l 重置
-- ctrl+p 置顶

---@type string | nil 当前选中的词
local cur_selected_text = nil
---@type integer | nil 当前高亮索引
local cur_highlight_idx = nil
---@type -1 | 1 | 0 | nil 当前调整的偏移量，0 为未调整，nil 为重置
local cur_offset = 0

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

    if _user_db and not _user_db:loaded() then
        _user_db:open()
    end

    return _user_db, close
end

---@param value string LevelDB 中序列化的值
---@return table<{to_position: integer, updated_at: integer}>
local function parsePhraseValue(value)
    local result = {}

    local match = value:gmatch("[-.%d]+")
    result.to_position = tonumber(match());
    result.updated_at = tonumber(match());

    return result
end

---@param input string
---@param phrase string
---@param to_position integer | nil
local function saveUserSegment(input, phrase, to_position)
    local db = getUserDB(true)
    local key = string.format("%s|%s", input, phrase)

    if (to_position == nil) then
        return db:erase(key)
    end

    -- 由于 lua os.time() 的精度只到秒，排序可能会引起问题
    local timestamp = os.time()
    local ms = 0
    if rime_api.get_time_ms then
        ms = rime_api.get_time_ms()
    end
    local value = string.format("%s\t%s.%s", to_position, timestamp, ms)
    return db:update(key, value)
end

---@param input string 当前输入码
---@return table<string, { to_position: integer, updated_at: integer, from_position?: integer, candidate?: Candidate}> | nil
local function getUserSegment(input)
    local db = getUserDB()

    local accessor = db:query(input .. "|")
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

local P = {}
function P.init() end

function P.fini()
    local _, db_close = getUserDB()
    db_close()
end

local PROCESS_RESULTS = {
    kRejected = 0, -- 表示处理器明确拒绝了这个按键，停止处理链但不返回 true
    kAccepted = 1, -- 表示处理器成功处理了这个按键，停止处理链并返回 true
    kNoop = 2,     -- 表示处理器没有处理这个按键，继续传递给下一个处理器
}

local start = os.clock()

-- P 阶段按键处理
---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key_event, env)
    start = os.clock()

    -- 每次按键都需要重置参数
    cur_selected_text, cur_highlight_idx, cur_offset = nil, nil, 0

    if not key_event:ctrl() or key_event:release() then
        return PROCESS_RESULTS.kNoop
    end

    -- 判断按下的键，更新偏移量
    local is_pin = key_event.keycode == 0x70
    if key_event.keycode == 0x6A then     -- 前移
        cur_offset = -1
    elseif key_event.keycode == 0x6B then -- 后移
        cur_offset = 1
    elseif key_event.keycode == 0x6C then -- 重置
        cur_offset = nil
    elseif is_pin then                    -- 置顶
        cur_offset = nil
    else
        return PROCESS_RESULTS.kNoop
    end

    if cur_offset == 0 then -- 未有移动操作，不用操作
        return PROCESS_RESULTS.kAccepted
    end

    local context = env.engine.context
    local selected_cand = context:get_selected_candidate()
    if cur_offset == nil then
        if selected_cand ~= nil and selected_cand.text ~= nil then
            saveUserSegment(context.input, selected_cand.text, is_pin and 1 or nil)
        end
    else
        cur_selected_text = selected_cand.text
    end

    context:refresh_non_confirmed_composition()

    if context.highlight and cur_highlight_idx and cur_highlight_idx > 0 then
        context:highlight(cur_highlight_idx)
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
    local need_reorder = user_segment ~= nil or (cur_selected_text ~= nil and cur_offset ~= 0 and cur_offset ~= nil)

    if not need_reorder then -- 如果没有自定义排序，不用去重，直接 yield 并返回
        for cand in input:iter() do yield(cand) end
        return
    end

    ---@type table<Candidate>
    local reordered_candidates = {}
    local dedupe_position = 1
    local text_counts = {} -- 用于去重
    local cur_selected_from_position = nil
    local cur_selected_cand = nil

    for cand in input:iter() do
        local text = cand.text
        text_counts[text] = (text_counts[text] or 0) + 1

        if text_counts[text] == 1 then -- 都需要去重
            -- 依次插入得到去重后的列表
            table.insert(reordered_candidates, cand)

            if cur_selected_text == text then
                cur_selected_cand = cand
                cur_selected_from_position = dedupe_position
            end

            if user_segment ~= nil and user_segment[text] ~= nil then
                user_segment[text].candidate = cand
                user_segment[text].from_position = dedupe_position
            end

            dedupe_position = dedupe_position + 1
        end
    end

    -- 获取当前输入码的自定义排序项数组，并按操作时间从前到后手动排序
    local user_ordered_records = {}
    if user_segment ~= nil then
        for _, info in pairs(user_segment) do
            table.insert(user_ordered_records, info)
        end
        table.sort(user_ordered_records, function(a, b) return a.updated_at < b.updated_at end)

        -- 恢复至上次调整状态
        for _, record in ipairs(user_ordered_records) do
            if record.from_position ~= record.to_position then
                local from_position, to_position = record.from_position, record.to_position
                table.remove(reordered_candidates, from_position)
                table.insert(reordered_candidates, to_position, record.candidate)
                -- 修正由于移位导致的 from_position 变动
                for idx, r in ipairs(user_ordered_records) do
                    local is_move_top = to_position < from_position
                    local min_position = is_move_top and to_position or from_position
                    local max_position = is_move_top and from_position or to_position
                    if min_position <= r.from_position and r.from_position <= max_position then
                        user_ordered_records[idx].from_position = r.from_position + (is_move_top and 1 or -1)
                    end
                end
            end
        end
    end

    -- 应用当前调整
    if cur_selected_text ~= nil and cur_offset ~= 0 and cur_offset ~= nil then
        ---@type integer | nil
        local from_position = nil
        for position, cand in ipairs(reordered_candidates) do
            if cand.text == cur_selected_text then
                from_position = position
                break
            end
        end

        if from_position ~= nil then
            local to_position = from_position + cur_offset

            if from_position ~= to_position then
                if to_position < 1 then
                    to_position = 1
                elseif to_position > #reordered_candidates then
                    to_position = #reordered_candidates
                end

                table.remove(reordered_candidates, from_position)
                table.insert(reordered_candidates, to_position, cur_selected_cand)
                saveUserSegment(context.input, cur_selected_text, to_position)
                cur_highlight_idx = to_position - 1
            end
        end
    end

    log.warning(string.format(
        "[wanxiang/super_sequence] %s：耗时 %.2fms，共调整：%s/%s",
        context.input,
        (os.clock() - start) * 1000,
        #user_ordered_records,
        #reordered_candidates))

    -- 输出最终结果
    for _, cand in ipairs(reordered_candidates) do
        yield(cand)
    end
end

return { P = P, F = F }
