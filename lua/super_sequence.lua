-- 万象拼音方案新成员：手动自由排序
-- 数据存放于 userdb 中，处于性能考量，此排序仅影响当前输入码
-- ctrl+j 前移
-- ctrl+k 后移
-- ctrl+l 重置
-- ctrl+p 置顶
local wanxiang = require("wanxiang")

--- seq_db start
local seq_db = {}
seq_db.db_name = "lua/sequence"
seq_db._instance = nil
function seq_db.close()
    if seq_db._instance and seq_db._instance:loaded() then
        collectgarbage()
        seq_db._instance:close()
        seq_db._instance = nil
    end
end

function seq_db._get()
    seq_db._instance = seq_db._instance or LevelDb(seq_db.db_name)
    if seq_db._instance and not seq_db._instance:loaded() then
        seq_db._instance:open()
    end
    return seq_db._instance
end

local META_KEY_PREFIX = "\001" .. "/"
local META_KEY_M_VERSION = "migration_version"

function seq_db.update(key, value) return seq_db._get():update(key, value) end

function seq_db.fetch(key) return seq_db._get():fetch(key) end

function seq_db.erase(key) return seq_db._get():erase(key) end

function seq_db.query(prefix) return seq_db._get():query(prefix) end

function seq_db.meta_fetch(key)
    return seq_db.fetch(META_KEY_PREFIX .. key)
end

function seq_db.meta_update(key, value)
    return seq_db.update(META_KEY_PREFIX .. key, value)
end

function seq_db.get_migration_version()
    return seq_db.meta_fetch(META_KEY_M_VERSION)
end

---@param version string
function seq_db.update_migration_version(version)
    return seq_db.meta_update(META_KEY_M_VERSION, version)
end

--- seq_db end

local seq_property = {
    ADJUST_KEY = "sequence_adjustment_code",
}
---@param context Context
function seq_property.get(context)
    return context:get_property(seq_property.ADJUST_KEY)
end

---@param context Context
function seq_property.reset(context)
    local code = seq_property.get(context)
    if code ~= nil and code ~= "" then
        context:set_property(seq_property.ADJUST_KEY, "")
    end
end

local curr_state = {}
---@enum AdjustStateMode
curr_state.ADJUST_MODE = {
    None = -1,
    Reset = 0,
    Pin = 1,
    Adjust = 2
}
curr_state.default = {
    ---@type string | nil 当前选中的候选词，用户正常模式排序
    selected_phrase = nil,
    ---@type integer 当前选中的位置索引，用于命令模式排序
    offset = 0,
    ---@type AdjustStateMode 当前调整模式
    mode = curr_state.ADJUST_MODE.None,
    ---@type integer | nil 当前高亮索引。nil 为初始值
    highlight_index = nil,
    ---@type string | nil 当前的 adjust_code
    adjust_code = nil,
    ---@type string | integer | nil 当前的 adjust_key
    adjust_key = nil,
}
function curr_state.reset()
    -- 如果是 nil，则已经是默认值了，不行要重置
    if not curr_state.has_adjustment() then return end

    for key, value in pairs(curr_state.default) do
        curr_state[key] = value
    end
end

function curr_state.is_pin_mode()
    return curr_state.mode == curr_state.ADJUST_MODE.Pin
end

function curr_state.is_reset_mode()
    return curr_state.mode == curr_state.ADJUST_MODE.Reset
end

function curr_state.is_adjust_mode()
    return curr_state.mode == curr_state.ADJUST_MODE.Adjust
end

function curr_state.has_adjustment()
    return curr_state.mode ~= curr_state.ADJUST_MODE.None
end

---@return table<string, RuntimeAdjustment> | nil
local function parse_adjustment_value(value_str)
    local adjustment = nil

    for value in value_str:gmatch("[^\t]+") do
        if adjustment == nil then adjustment = {} end

        local item, fixed_position, offset, updated_at = value:match("i=(%S+) p=(%S+) o=(%S+) t=(%S+)")
        fixed_position = fixed_position and tonumber(fixed_position)
        offset = offset and tonumber(offset)
        updated_at = updated_at and tonumber(updated_at)
        -- 忽略为 0 的位置，0 位置代表重置
        if fixed_position > 0 then
            adjustment[item] = {
                fixed_position = fixed_position,
                offset = offset,
                updated_at = updated_at,
            }
            -- log.warning(string.format("[sequence] %s: %s", adjust_key, value))
        end
    end

    return adjustment
end

local adjustments_cache = {
    key = nil,
    value = nil,
}
---@param input string 当前输入码
---@return table<string, RuntimeAdjustment> | nil
local function get_adjustments(input)
    if adjustments_cache.key == input then return adjustments_cache.value end

    if input == "" or input == nil then return nil end

    local value_str = seq_db.fetch(input)
    if value_str == nil then return nil end

    local adjustment = parse_adjustment_value(value_str)
    adjustments_cache.value = adjustment
    return adjustments_cache.value
end

-- 由于 lua os.time() 的精度只到秒，排序过快可能会引起问题
local function get_timestamp()
    return rime_api.get_time_ms
        and os.time() + tonumber(string.format("0.%s", rime_api.get_time_ms()))
        or os.time()
end

---@class Adjustment
---@field fixed_position integer `0` 为重置，>0 为目标位置
---@field offset integer 0 表示置顶／重置，<0 前移位数，>0 后移位数
---@field updated_at number 操作时间戳

---@class RuntimeAdjustment: Adjustment
---@field raw_position? integer 去重后的原始位置
---@field from_position? integer 每次应用移动后的当前位置

---@param input string 匹配的输入码
---@param item string 调整项：命令模式为候选索引，其他为候选词
---@param adjustment Adjustment
local function save_adjustment(input, item, adjustment)
    if input == "" or input == nil then return end

    local adjustments = get_adjustments(input) or {}

    adjustments[item] = {
        fixed_position = adjustment.fixed_position,
        offset = adjustment.offset,
        updated_at = adjustment.updated_at,
    }

    local values = {}
    for key, value in pairs(adjustments) do
        local value_str = string.format("i=%s p=%s o=%s t=%s", key, value.fixed_position, value.offset, value.updated_at)
        table.insert(values, value_str)
    end

    if adjustments_cache.key == input then
        adjustments_cache.key = nil
        adjustments_cache.value = nil
    end

    return seq_db.update(input, table.concat(values, "\t"))
end

---从 context 中获取当前排序匹配码
---@param context Context
---@return string | nil
local function extract_adjustment_code(context)
    if wanxiang.is_function_mode_active(context) then
        local code = seq_property.get(context)
        if code and code ~= "" then
            return code
        end
        return nil
    end

    return context.input:sub(1, context.caret_pos)
end

local sync_file_name = rime_api.get_user_data_dir() .. "/" .. seq_db.db_name .. ".txt"

local function db_migration()
    local migration_version = seq_db.get_migration_version()
    if migration_version then return end

    local migration_count = 0
    ---@type nil | DbAccessor
    local da = nil
    da = seq_db.query("")
    if not da then return end

    for old_key, old_value in da:iter() do
        -- 兼容旧数据
        local input, item = old_key:match("(%S+)|(%S+)")
        if input and item then
            local fixed_position, offset, updated_at = old_value:match("([-%d]+),?([-%d]*)\t([.%d]+)")
            seq_db.erase(old_key)
            save_adjustment(input, item, { fixed_position = fixed_position, offset = offset, updated_at = updated_at })
            migration_count = migration_count + 1
        end
    end
    da = nil

    seq_db.update_migration_version("8.9.3")
    if migration_count > 0 then
        log.info(string.format("[super_sequence] 完成旧格式数据迁移，共 %s 条", migration_count))
    end
end

local function export_to_file()
    -- 文件已存在不进行覆盖
    if wanxiang.file_exists(sync_file_name) then return end

    local file = io.open(sync_file_name, "w")
    if not file then return end;

    ---@type nil | DbAccessor
    local da = nil
    da = seq_db.query("")
    if not da then return end

    for key, value in da:iter() do
        -- 兼容旧数据
        local input, item = key:match("(%S+)|(%S+)")
        if input and item then
            key = input
            local fixed_position, offset, updated_at = value:match("([-%d]+),?([-%d]*)\t([.%d]+)")
            value = string.format("i=%s p=%s o=%s t=%s", item, fixed_position, offset, updated_at)
        end

        if key:sub(1, 2) == "\001" .. "/" then
            local line = string.format("%s\t%s", key, value)
            local from_user_id = string.match(line, "^" .. "\001" .. "/user_id\t(.+)")
            if from_user_id ~= nil then
                local fixed_user_id = wanxiang.get_user_id()
                if fixed_user_id ~= from_user_id then
                    line = "\001" .. "/user_id\t" .. fixed_user_id
                end
            end
            file:write(line, "\n")
        else
            for adj_str in value:gmatch("[^\t]+") do
                local line = string.format("%s\t%s", key, adj_str)
                file:write(line, "\n")
            end
        end
    end
    da = nil

    log.info(string.format("[super_sequence] 已导出排序数据至文件 %s", sync_file_name))

    file:close()
end

local function import_from_file()
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
        local input, value = line:match("^(%S+)\t(%S+)$")

        if input and value then
            local old_input, item = input:match("^(.+)|(.+)$")
            if old_input and item then
                input = old_input
                local fixed_position, offset, updated_at = value:match("([-%d]+),?([-%d]*)\t([.%d]+)")
                value = string.format("i=%s p=%s o=%s t=%s", item, fixed_position, offset, updated_at)
            end

            local from_adjustment = parse_adjustment_value(value)
            if not from_adjustment then goto continue end

            local exist_adjustments = get_adjustments(input)
            local exist_adjustment  = exist_adjustments and exist_adjustments[from_adjustment.item] or nil
            if exist_adjustment then -- 跳过旧的数据
                if from_adjustment.updated_at <= exist_adjustment.updated_at then
                    goto continue
                end
            end

            import_count = import_count + 1
            save_adjustment(input, item, from_adjustment)
        end

        ::continue::
    end

    log.info(string.format("[super_sequence] 自动导入排序数据 %s 条", import_count))

    file:close()
    if import_count > 0 then
        os.remove(sync_file_name)
    end
end

local P = {}
function P.init()
    db_migration()
    import_from_file()
end

---执行排序调整
---@param context Context
local function process_adjustment(context)
    local selected_cand = context:get_selected_candidate()
    curr_state.selected_phrase = selected_cand.text

    context:refresh_non_confirmed_composition()

    if context.highlight
        and curr_state.highlight_index
        and curr_state.highlight_index > 0 then
        context:highlight(curr_state.highlight_index)
    end
end

-- P 阶段按键处理
---@param key_event KeyEvent
---@param env Env
---@return ProcessResult
function P.func(key_event, env)
    local context = env.engine.context
    ---重置状态
    seq_property.reset(context)
    curr_state.reset()

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
        curr_state.offset = -1
        curr_state.mode = curr_state.ADJUST_MODE.Adjust
    elseif key_event.keycode == 0x6B then -- 后移
        curr_state.offset = 1
        curr_state.mode = curr_state.ADJUST_MODE.Adjust
    elseif key_event.keycode == 0x6C then -- 重置
        curr_state.offset = nil
        curr_state.mode = curr_state.ADJUST_MODE.Reset
    elseif key_event.keycode == 0x70 then -- 置顶
        curr_state.offset = nil
        curr_state.mode = curr_state.ADJUST_MODE.Pin
    else
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    process_adjustment(context)

    return wanxiang.RIME_PROCESS_RESULTS.kAccepted
end

local F = {}
function F.init() end

function F.fini()
    export_to_file()
    seq_db.close()
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
        if cand.text == curr_state.selected_phrase then
            from_position = position
            break
        end
    end

    if from_position == nil then return end

    local to_position = from_position
    if curr_state.is_adjust_mode() then
        to_position = from_position + curr_state.offset
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

            save_adjustment(curr_state.adjust_code, curr_state.adjust_key, curr_adjustment)
        end
    end

    curr_state.highlight_index = to_position - 1
end

---当前 context 是否允许自定义排序
---@param context Context
---@return boolean
local function is_adjustment_allowed(context)
    if wanxiang.is_function_mode_active(context) -- function mode 必须有设置 sequence_adjustment_code
        and seq_property.get(context) == nil then
        return false
    end

    return true
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

    ---@type RuntimeAdjustment | nil
    local curr_adjustment = nil
    if curr_state.has_adjustment() then
        curr_adjustment = {
            fixed_position = 0,
            offset = 0,
            updated_at = get_timestamp(),
        }
    end

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
                and tostring(position - 1) -- function mode 使用索引模式
                or phrase

            if curr_adjustment ~= nil and curr_state.selected_phrase == phrase then
                curr_state.adjust_code = adjust_code
                curr_state.adjust_key = curr_key

                curr_adjustment.raw_position = position
            end

            if prev_adjustments and prev_adjustments[curr_key] ~= nil then
                prev_adjustments[curr_key].raw_position = position -- raw_position 记录原始顺序
            end
        end
    end

    prev_adjustments = prev_adjustments or {}

    -- 提前处理置顶/重置操作，以简化逻辑
    if curr_adjustment ~= nil and not curr_state.is_adjust_mode() then
        curr_adjustment.offset = 0

        local key = tostring(curr_state.adjust_key)
        if curr_state.is_reset_mode() then -- reset mode 提前清空之前的旧数据
            curr_adjustment.fixed_position = 0
            prev_adjustments[key] = nil
        elseif curr_state.is_pin_mode() then
            curr_adjustment.fixed_position = 1
            prev_adjustments[key] = curr_adjustment
        end

        save_adjustment(curr_state.adjust_code, curr_state.adjust_key, curr_adjustment)
    end

    apply_prev_adjustment(candidates, prev_adjustments)

    apply_curr_adjustment(candidates, curr_adjustment)

    -- 输出最终结果
    for _, cand in ipairs(candidates) do
        yield(cand)
    end
end

return { P = P, F = F }
