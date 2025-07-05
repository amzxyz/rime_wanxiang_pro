-- 万象拼音方案新成员：手动自由排序
-- 数据存放于 userdb 中，处于性能考量，此排序仅影响当前输入码
-- ctrl+j 前移
-- ctrl+k 后移
-- ctrl+l 重置
-- ctrl+p 置顶
local wanxiang = require("wanxiang")

---@type string | nil 当前选中的词
local cur_adjustment = nil

---@type integer | nil 当前高亮索引
local cur_highlight_idx = nil

---- `0`: 无调整，默认值
---- `-1`: 前移一位
---- `1`: 后移一位
---- `nil`: 重置/置顶
---@type -1 | 1 | 0 | nil
local cur_adjust_offset = 0

---@type boolean 是否处于 pin 模式
local in_pin_mode = false

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
---@return { to_position: integer, updated_at: integer }
local function parse_adjustment_value(value)
    local result = {}

    local match = value:gmatch("[-.%d]+")
    result.to_position = tonumber(match());
    result.updated_at = tonumber(match());

    return result
end

---@param code string
---@param phrase string
---@param to_position integer | nil
---@param timestamp? number
local function save_adjustment(code, phrase, to_position, timestamp)
    local db = get_user_db()
    local key = string.format("%s|%s", code, phrase)

    if to_position == nil or to_position <= 0 then
        return db:erase(key)
    end

    -- 由于 lua os.time() 的精度只到秒，排序可能会引起问题
    if not timestamp then
        timestamp = rime_api.get_time_ms
            and os.time() + tonumber(string.format("0.%s", rime_api.get_time_ms()))
            or os.time()
    end
    local value = string.format("%s\t%s", to_position, timestamp)
    return db:update(key, value)
end

---@param code string 当前输入码
---@return table<string, { to_position: integer, updated_at: integer, from_position?: integer, candidate?: Candidate}> | nil
local function get_adjustment(code)
    if code == "" then return nil end

    local db = get_user_db()

    local accessor = db:query(code .. "|")
    if accessor == nil then return nil end

    local table = nil
    for key, value in accessor:iter() do
        if table == nil then table = {} end
        local phrase = string.gsub(key, "^.*|", "")
        table[phrase] = parse_adjustment_value(value)
    end

    ---@diagnostic disable-next-line: cast-local-type
    accessor = nil

    return table
end

---@param context Context
---@return string
local function extract_adjustment_code(context)
    return context.input:sub(1, context.caret_pos)
end

local sync_file_name = rime_api.get_user_data_dir() .. "/" .. db_file_name .. ".txt"

local function file_exists(name)
    local f = io.open(name, "r")
    return f ~= nil and io.close(f)
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

    local user_id = db:fetch("\001" .. "/user_id")
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
            save_adjustment(code, phrase, info.to_position, info.updated_at)
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

    if cur_adjust_offset == nil then -- 如果是重置/置顶，直接设置位置
        local code = extract_adjustment_code(context)
        save_adjustment(code, selected_cand.text, in_pin_mode and 1 or nil)
    else -- 否则进入 filter 调整位移
        cur_adjustment = selected_cand.text
    end

    context:refresh_non_confirmed_composition()

    if context.highlight and cur_highlight_idx and cur_highlight_idx > 0 then
        context:highlight(cur_highlight_idx)
    end

    ---重置全局状态
    cur_adjustment = nil
    cur_highlight_idx = nil
    cur_adjust_offset = 0
    in_pin_mode = false
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
    in_pin_mode = key_event.keycode == 0x70
    if key_event.keycode == 0x6A then     -- 前移
        cur_adjust_offset = -1
    elseif key_event.keycode == 0x6B then -- 后移
        cur_adjust_offset = 1
    elseif key_event.keycode == 0x6C then -- 重置
        cur_adjust_offset = nil
    elseif in_pin_mode then               -- 置顶
        cur_adjust_offset = nil
    else
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    if cur_adjust_offset == 0 then -- 未有移动操作，不用操作
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

---@param input Translation
---@param env Env
function F.func(input, env)
    local context = env.engine.context
    local valid_code = extract_adjustment_code(context)
    local user_adjustment = get_adjustment(valid_code)

    local has_unsaved_adjustment = cur_adjustment ~= nil
        and cur_adjust_offset ~= 0
        and cur_adjust_offset ~= nil
        and valid_code ~= ""

    if not has_unsaved_adjustment  -- 如果当前没有排序调整
        and user_adjustment == nil -- 并且之前也没有自定义排序
    then                           -- 直接 yield 并返回
        for cand in input:iter() do yield(cand) end
        return
    end

    ---@type table<Candidate>
    local candidates = {}     -- 去重排序后的候选列表

    local phrase_count = {}   -- 用于去重
    local dedupe_position = 1 -- 记录去重会的当前索引位置
    local cur_candidate = nil
    for cand in input:iter() do
        local text = cand.text
        phrase_count[text] = (phrase_count[text] or 0) + 1

        if phrase_count[text] == 1 then -- 都需要去重
            -- 依次插入得到去重后的列表
            table.insert(candidates, cand)

            if cur_adjustment == text then
                cur_candidate = cand
            end

            if user_adjustment ~= nil and user_adjustment[text] ~= nil then
                user_adjustment[text].candidate = cand
                user_adjustment[text].from_position = dedupe_position
            end

            dedupe_position = dedupe_position + 1
        end
    end

    -- 获取当前输入码的自定义排序项数组，并按操作时间从前到后手动排序
    local user_adjustment_list = {}
    if user_adjustment ~= nil then
        for _, info in pairs(user_adjustment) do
            if info.candidate then
                table.insert(user_adjustment_list, info)
            end
        end
        table.sort(user_adjustment_list, function(a, b) return a.updated_at < b.updated_at end)

        -- 恢复至上次调整状态
        for _, record in ipairs(user_adjustment_list) do
            if record.from_position ~= record.to_position then
                local from_position, to_position = record.from_position, record.to_position
                table.remove(candidates, from_position)
                table.insert(candidates, to_position, record.candidate)
                -- 修正由于移位导致的 from_position 变动
                for idx, r in ipairs(user_adjustment_list) do
                    local is_move_top = to_position < from_position
                    local min_position = is_move_top and to_position or from_position
                    local max_position = is_move_top and from_position or to_position
                    if min_position <= r.from_position and r.from_position <= max_position then
                        user_adjustment_list[idx].from_position = r.from_position + (is_move_top and 1 or -1)
                    end
                end
            end
        end
    end

    -- 应用当前调整
    if has_unsaved_adjustment then
        ---@type integer | nil
        local from_position = nil
        for position, cand in ipairs(candidates) do
            if cand.text == cur_adjustment then
                from_position = position
                break
            end
        end

        if from_position ~= nil then
            local to_position = from_position + cur_adjust_offset

            if from_position ~= to_position then
                if to_position < 1 then
                    to_position = 1
                elseif to_position > #candidates then
                    to_position = #candidates
                end

                table.remove(candidates, from_position)
                table.insert(candidates, to_position, cur_candidate)

                ---@diagnostic disable-next-line: param-type-mismatch
                save_adjustment(valid_code, cur_adjustment, to_position)
                cur_highlight_idx = to_position - 1
            end
        end
    end

    -- 输出最终结果
    for _, cand in ipairs(candidates) do
        yield(cand)
    end
end

return { P = P, F = F }
