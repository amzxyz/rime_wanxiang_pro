-- 万象拼音方案新成员：手动自由排序
-- 数据存放于 userdb 中，处于性能考量，此排序仅影响当前输入码
-- ctrl+j 前移
-- ctrl+k 后移
-- ctrl+l 重置
-- ctrl+p 置顶
local wanxiang = require("wanxiang")

local Property = {
    ADJUST_KEY = "sequence_adjustment_code",
}
---@param context Context
function Property.get(context)
    return context:get_property(Property.ADJUST_KEY)
end

---@param context Context
function Property.reset(context)
    local code = Property.get(context)
    if code ~= nil and code ~= "" then
        context:set_property(Property.ADJUST_KEY, "")
    end
end

local CurrentState = {}
---@enum AdjustStateMode
CurrentState.ADJUST_MODE = {
    None = -1,
    Reset = 0,
    Pin = 1,
    Adjust = 2
}
CurrentState.default = {
    ---@type string | nil 当前选中的候选词，用户正常模式排序
    selected_phrase = nil,
    ---@type integer 当前选中的位置索引，用于命令模式排序
    offset = 0,
    ---@type AdjustStateMode 当前调整模式
    mode = CurrentState.ADJUST_MODE.None,
    ---@type integer | nil 当前高亮索引。nil 为初始值
    highlight_index = nil,
    ---@type string | nil 当前的 adjust_code
    adjust_code = nil,
    ---@type string | integer | nil 当前的 adjust_key
    adjust_key = nil,
}
function CurrentState.reset()
    -- 如果是 nil，则已经是默认值了，不行要重置
    if not CurrentState.has_adjustment() then return end

    for key, value in pairs(CurrentState.default) do
        CurrentState[key] = value
    end
end

function CurrentState.is_pin_mode()
    return CurrentState.mode == CurrentState.ADJUST_MODE.Pin
end

function CurrentState.is_reset_mode()
    return CurrentState.mode == CurrentState.ADJUST_MODE.Reset
end

function CurrentState.is_adjust_mode()
    return CurrentState.mode == CurrentState.ADJUST_MODE.Adjust
end

function CurrentState.has_adjustment()
    return CurrentState.mode ~= CurrentState.ADJUST_MODE.None
end

local db_file_name = "lua/sequence"
local _user_db = nil
-- 获取或创建 LevelDb 实例，避免重复打开
local function get_user_db()
    _user_db = _user_db or LevelDb(db_file_name)

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
---@return { fixed_position: integer, offset: integer, updated_at: integer }
local function parse_adjustment_value(value)
    local result = {}

    local fixed_position, offset, updated_at = value:match("([-%d]+),?([-%d]*)\t([.%d]+)")
    result.fixed_position = tonumber(fixed_position);
    result.offset = offset and tonumber(offset) or 0;
    result.updated_at = tonumber(updated_at);

    return result
end

---@param code string
---@param adjust_key string | number
local function get_adjust_db_key(code, adjust_key)
    if tostring(adjust_key) == "" or code == "" then
        return nil
    end
    return string.format("%s|%s", code, adjust_key)
end

---@param code string 当前输入码
---@return table<string, { fixed_position: integer, offset: integer, updated_at: integer, raw_position?: integer }> | nil
local function get_adjustments(code)
    if code == "" or code == nil then return nil end

    local db = get_user_db()

    local accessor = db:query(code .. "|")
    if accessor == nil then return nil end

    local adjustment = nil
    for key, value in accessor:iter() do
        if adjustment == nil then adjustment = {} end

        local adjust_key = string.match(key, "^.*|(%S+)$")
        local adjust_value = parse_adjustment_value(value)
        -- 忽略为 0 的位置，0 位置代表重置
        if adjust_value.fixed_position > 0 then
            adjustment[adjust_key] = adjust_value
            -- log.warning(string.format("[sequence] %s: %s", adjust_key, value))
        end
    end

    ---@diagnostic disable-next-line: cast-local-type
    accessor = nil

    return adjustment
end

local function get_timestamp()
    return rime_api.get_time_ms
        and os.time() + tonumber(string.format("0.%s", rime_api.get_time_ms()))
        or os.time()
end

---@param code string 匹配的输入码
---@param adjust_key string | number 匹配键，为候选索引（命令模式），或候选词（普通模式）
---@param fixed_position integer `0` 为重置排序，>0 为目标位置
---@param offset? integer | nil
---@param timestamp? number 操作时间戳，默认去当前时间戳
local function save_adjustment(code, adjust_key, fixed_position, offset, timestamp)
    if code == "" or code == nil then return end

    local key = get_adjust_db_key(code, adjust_key)
    if key == nil then return false end

    local db = get_user_db()

    -- 由于 lua os.time() 的精度只到秒，排序可能会引起问题
    if not timestamp then
        timestamp = get_timestamp()
    end

    local value = string.format("%s,%s\t%s", fixed_position, offset or 0, timestamp)
    -- log.warning(string.format("[sequence/save_adjustment] %s: %s", key, value, fixed_position))
    return db:update(key, value)
end

---从 context 中获取当前排序匹配码
---@param context Context
---@return string | nil
local function extract_adjustment_code(context)
    if wanxiang.is_function_mode_active(context) then
        local code = Property.get(context)
        if code and code ~= "" then
            return code
        end
        return nil
    end

    return context.input:sub(1, context.caret_pos)
end

local sync_file_name = rime_api.get_user_data_dir() .. "/" .. db_file_name .. ".txt"

local function file_exists(name)
    local f = io.open(name, "r")
    if f then
        io.close(f)
        return true
    end
    return false
end

local function export_to_file(db)
    -- 文件已存在不进行覆盖
    if file_exists(sync_file_name) then return end

    local file = io.open(sync_file_name, "w")
    if not file then return end;

    ---@type nil | DbAccessor
    local da = nil
    da = db:query("")
    if not da then return end

    for key, value in da:iter() do
        local line = string.format("%s\t%s", key, value)
        local from_user_id = string.match(line, "^" .. "\001" .. "/user_id\t(.+)")
        if from_user_id ~= nil then
            local fixed_user_id = wanxiang.get_user_id()
            if fixed_user_id ~= from_user_id then
                line = "\001" .. "/user_id\t" .. fixed_user_id
            end
        end
        file:write(line, "\n")
    end
    da = nil

    log.info(string.format("[super_sequence] 已导出排序数据至文件 %s", sync_file_name))

    file:close()
end

local function import_from_file(db)
    local file = io.open(sync_file_name, "r")
    if not file then return end;

    local import_count = 0

    local user_id = wanxiang.get_user_id()
    local from_user_id = nil
    for line in file:lines() do
        if line == "" then goto continue end
        -- 先找 from_user_id
        if from_user_id == nil then
            from_user_id = string.match(line, "^" .. "\001" .. "/user_id\t(.+)")
            goto continue
        end
        -- 如果 user_id 一致，则不进行同步
        if from_user_id == user_id then break end
        -- 忽略开头是 "\001/" 开头
        if line:sub(1, 2) == "\001" .. "/" then goto continue end

        -- 以下开始处理输入
        local key, value = string.match(line, "^(.-)\t(.+)$")

        if key and value then
            local code, phrase = string.match(key, "^(.+)|(.+)$")
            local info = parse_adjustment_value(value)
            local exist_value = db:fetch(key)
            if exist_value then -- 跳过旧的数据
                local exist_info = parse_adjustment_value(exist_value)
                if info.updated_at <= exist_info.updated_at then
                    goto continue
                end
            end

            import_count = import_count + 1
            save_adjustment(code, phrase, info.fixed_position, info.offset, info.updated_at)
        end

        ::continue::
    end

    log.info(string.format("[super_sequence] 自动导入排序数据 %s 条", import_count))

    file:close()
    if import_count > 0 then
        os.remove(sync_file_name)
    end
end

---执行排序调整
---@param context Context
local function process_adjustment(context)
    local selected_cand = context:get_selected_candidate()
    CurrentState.selected_phrase = selected_cand.text

    context:refresh_non_confirmed_composition()

    if context.highlight
        and CurrentState.highlight_index
        and CurrentState.highlight_index > 0 then
        context:highlight(CurrentState.highlight_index)
    end
end

---当前 context 是否允许自定义排序
---@param context Context
---@return boolean
local function is_adjustment_allowed(context)
    if wanxiang.is_function_mode_active(context) -- function mode 必须有设置 sequence_adjustment_code
        and Property.get(context) == nil then
        return false
    end

    return true
end

local P = {}
function P.init()
    local db = get_user_db()
    import_from_file(db)
end

-- P 阶段按键处理
---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key_event, env)
    local context = env.engine.context
    ---重置状态
    Property.reset(context)
    CurrentState.reset()

    local selected_cand = context:get_selected_candidate()

    if not context:has_menu()
        or selected_cand == nil
        or selected_cand.text == nil
        or not key_event:ctrl()
        or key_event:release()
    then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    -- 判断按下的键，更新偏移量
    if key_event.keycode == 0x6A then -- 前移
        CurrentState.offset = -1
        CurrentState.mode = CurrentState.ADJUST_MODE.Adjust
    elseif key_event.keycode == 0x6B then -- 后移
        CurrentState.offset = 1
        CurrentState.mode = CurrentState.ADJUST_MODE.Adjust
    elseif key_event.keycode == 0x6C then -- 重置
        CurrentState.offset = nil
        CurrentState.mode = CurrentState.ADJUST_MODE.Reset
    elseif key_event.keycode == 0x70 then -- 置顶
        CurrentState.offset = nil
        CurrentState.mode = CurrentState.ADJUST_MODE.Pin
    else
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    process_adjustment(context)

    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

local F = {}
function F.init() end

function F.fini()
    local db, db_close = get_user_db()
    export_to_file(db)
    db_close()
end

---应用之前的调整
-- 注意：此函数按时间顺序重新应用调整。
-- 在候选数量较多且单个输入代码需要进行多次调整的情况下，
-- 在循环中使用 `table.remove` 可能会成为性能瓶颈，
-- 因为它具有线性时间复杂度 (O(n))。
---@param candidates table<Candidate>
---@param prev_adjustments table
local function apply_prev_adjustment(candidates, prev_adjustments)
    -- 获取当前输入码的自定义排序项数组，并按操作时间从前到后手动排序
    local user_adjustment_list = {}
    for _, info in pairs(prev_adjustments) do
        if info.raw_position then
            info.from_position = info.raw_position -- from_position 用于动态排序
            table.insert(user_adjustment_list, info)
        end
    end
    table.sort(user_adjustment_list, function(a, b) return a.updated_at < b.updated_at end)

    -- 恢复至上次调整状态
    for i, record in ipairs(user_adjustment_list) do
        local from_position = record.from_position

        if from_position == nil or record.fixed_position <= 0 then
            goto continue_restore
        end

        local to_position = record.offset == 0
            and record.fixed_position
            or record.raw_position + record.offset

        if from_position == to_position then
            goto continue_restore
        end

        local candidate = table.remove(candidates, from_position)
        table.insert(candidates, to_position, candidate)
        -- log.warning(string.format("[sequence] %s: %s -> %s", candidate.text, from_position, to_position))

        -- 修正后续由于移位导致的 from_position 变动
        local min_position = math.min(from_position, to_position)
        local max_position = math.max(from_position, to_position)
        for j = i, #user_adjustment_list, 1 do
            local r = user_adjustment_list[j]
            if min_position <= r.from_position and r.from_position <= max_position then
                local offset = to_position < from_position and 1 or -1
                user_adjustment_list[j].from_position = r.from_position + offset
            end
        end
        ::continue_restore::
    end
end

local function apply_curr_adjustment(candidates, curr_adjustment)
    if curr_adjustment == nil then return end

    ---@type integer | nil
    local from_position = nil
    for position, cand in ipairs(candidates) do
        if cand.text == CurrentState.selected_phrase then
            from_position = position
            break
        end
    end

    if from_position == nil then return end

    local to_position = from_position
    if CurrentState.is_adjust_mode() then
        to_position = from_position + CurrentState.offset
        curr_adjustment.offset = to_position - curr_adjustment.raw_position
        curr_adjustment.fixed_position = to_position

        local min_position, max_position = 1, #candidates
        if from_position ~= to_position then
            if to_position < min_position then
                to_position = min_position
            elseif to_position > max_position then
                to_position = max_position
            end

            local candidate = table.remove(candidates, from_position)
            table.insert(candidates, to_position, candidate)

            save_adjustment(CurrentState.adjust_code, CurrentState.adjust_key,
                curr_adjustment.fixed_position, curr_adjustment.offset, curr_adjustment.updated_at)
        end
    end

    CurrentState.highlight_index = to_position - 1
end

---@param input Translation
---@param env Env
function F.func(input, env)
    local function original_list()
        for cand in input:iter() do yield(cand) end
    end

    local context = env.engine.context

    local adjustment_allowed = is_adjustment_allowed(context)
    if not adjustment_allowed then
        log.warning(string.format("[sequence] 暂不支持当前指令的手动排序"))
        return original_list()
    end

    local adjust_code = extract_adjustment_code(context)
    if adjust_code == nil then
        return original_list()
    end

    local prev_adjustments = get_adjustments(adjust_code)

    local curr_adjustment = nil
    if CurrentState.has_adjustment() then
        curr_adjustment = {
            updated_at = get_timestamp(),
        }
    end

    log.warning(string.format("[sequence] curr: %s", CurrentState.mode))

    if curr_adjustment == nil       -- 如果当前没有排序调整
        and prev_adjustments == nil -- 并且之前也没有自定义排序
    then                            -- 直接 yield 并返回
        return original_list()
    end

    --- 原始候选去重，并获取原始位置信息和 adjust_key & adjust_code
    ---@type table<Candidate>
    local candidates = {}  -- 去重排序后的候选列表
    local hash_phrase = {} -- 用于去重
    local is_function_mode_active = wanxiang.is_function_mode_active(context)
    local position = 0
    for candidate in input:iter() do
        local phrase = candidate.text
        if not hash_phrase[phrase] then
            hash_phrase[phrase] = true

            -- 依次插入得到去重后的列表
            position = position + 1
            table.insert(candidates, candidate)

            local curr_key = is_function_mode_active
                and position - 1 -- function mode 使用索引模式
                or phrase
            local curr_key_str = tostring(curr_key)

            if curr_adjustment ~= nil and CurrentState.selected_phrase == phrase then
                CurrentState.adjust_code = adjust_code
                CurrentState.adjust_key = curr_key

                curr_adjustment.raw_position = position
            end

            if prev_adjustments and prev_adjustments[curr_key_str] ~= nil then
                prev_adjustments[curr_key_str].raw_position = position -- raw_position 记录原始顺序
            end
        end
    end

    prev_adjustments = prev_adjustments or {}

    -- 提前处理置顶/重置操作，以简化逻辑
    if curr_adjustment ~= nil and not CurrentState.is_adjust_mode() then
        curr_adjustment.offset = 0

        local key = tostring(CurrentState.adjust_key)
        if CurrentState.is_reset_mode() then -- reset mode 提前清空之前的旧数据
            curr_adjustment.fixed_position = 0
            prev_adjustments[key] = nil
        elseif CurrentState.is_pin_mode() then
            curr_adjustment.fixed_position = 1
            prev_adjustments[key] = curr_adjustment
        end

        save_adjustment(CurrentState.adjust_code, CurrentState.adjust_key,
            curr_adjustment.fixed_position, curr_adjustment.offset, curr_adjustment.updated_at)
    end

    apply_prev_adjustment(candidates, prev_adjustments)

    apply_curr_adjustment(candidates, curr_adjustment)

    -- 输出最终结果
    for _, cand in ipairs(candidates) do
        yield(cand)
    end
end

return { P = P, F = F }
