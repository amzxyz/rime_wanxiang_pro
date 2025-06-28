-- 输入习惯记录器 (Version 12 - JSON Output)
local rime = require "lib"

-- Simple Lua JSON encoder
local function escape_str(s)
    return '"' .. s:gsub('[\\"]', {['\\']='\\\\', ['"']='\\"'
    }):gsub('\n','\\n'):gsub('\r','\\r'):gsub('\t','\\t'):gsub('[\001-\031]', '') .. '"' -- Control chars
end
local to_json_value_func -- Forward declaration for mutual recursion
local function table_to_json(val, is_array_hint)
    local parts = {}
    local is_array = is_array_hint
    if is_array == nil then -- Auto-detect
        is_array = true
        local expected_idx = 1
        for k, _ in pairs(val) do -- Check if keys are sequential numbers starting from 1
            if type(k) ~= 'number' or k ~= expected_idx then
                is_array = false; break
            end
            expected_idx = expected_idx + 1
        end
        if expected_idx -1 ~= #val then is_array = false end -- handles empty table or sparse
        if #val == 0 and next(val) ~= nil and not is_array then is_array = false end -- if #val is 0 but has string keys
    end

    if is_array then
        for i = 1, #val do
            table.insert(parts, to_json_value_func(val[i]))
        end
        return '[' .. table.concat(parts, ',') .. ']'
    else -- Object
        for k, v in pairs(val) do
            if type(k) == 'string' then -- Only string keys for JSON objects
                 table.insert(parts, escape_str(k) .. ':' .. to_json_value_func(v))
            else -- Skip non-string keys for simplicity or convert them
                 table.insert(parts, escape_str(tostring(k)) .. ':' .. to_json_value_func(v))
            end
        end
        return '{' .. table.concat(parts, ',') .. '}'
    end
end
to_json_value_func = function(val)
    local t = type(val)
    if t == 'string' then return escape_str(val)
    elseif t == 'number' then 
        if val ~= val or val == math.huge or val == -math.huge then return 'null' end -- NaN/Infinity
        return tostring(val)
    elseif t == 'boolean' then return tostring(val)
    elseif t == 'nil' then return 'null'
    elseif t == 'table' then return table_to_json(val)
    else return '"[unsupported_type:' .. t .. ']"'
    end
end
local function json_encode(tbl)
    if type(tbl) ~= 'table' then return to_json_value_func(tbl) end -- Allow encoding single non-table value
    -- Determine if root is array or object for table_to_json hint
    local is_array_root = true
    local expected_idx_root = 1
    for k, _ in pairs(tbl) do
        if type(k) ~= 'number' or k ~= expected_idx_root then
            is_array_root = false; break
        end
        expected_idx_root = expected_idx_root + 1
    end
    if expected_idx_root - 1 ~= #tbl then is_array_root = false end
    if #tbl == 0 and next(tbl) ~= nil and not is_array_root then is_array_root = false end

    return table_to_json(tbl, is_array_root)
end


-- Log file path
local log_file_path = ""
if os.getenv("OS") == "Windows_NT" then
  log_file_path = os.getenv("APPDATA") .. "\\Rime\\input_habit_log_structured.jsonl" -- Changed extension
else
  if os.execute("test -d " .. os.getenv("HOME") .. "/Library/Rime") == 0 then
    log_file_path = os.getenv("HOME") .. "/Library/Rime/input_habit_log_structured.jsonl"
  else
    log_file_path = os.getenv("HOME") .. "/.config/rime/input_habit_log_structured.jsonl"
  end
end

-- Write JSON object to log file
local function log_json_event(event_data)
  event_data.timestamp = os.date("!%Y-%m-%dT%H:%M:%S.") .. string.format("%03dZ", math.floor((os.clock() * 1000) % 1000))
  local json_string = json_encode(event_data)
  
  local file = io.open(log_file_path, "a")
  if file then
    file:write(json_string .. "\n")
    file:close()
  else
    print("LUA_JSON_LOGGER :: ERROR: Could not open log file: " .. log_file_path .. " | JSON: " .. json_string)
  end
end

-- Module-level state for correlating events
local last_input_state_for_commit = {
  input_buffer = nil,
  first_candidate = nil,
  candidates = nil,
  key_action_for_selection = nil, -- "space", "1", "2", etc.
  timestamp = nil
}

-- Helper to get candidate info
local function get_current_candidate_info(context, max_to_display)
  local info = {
    candidates_list = {},
    first_candidate_text = nil,
    has_menu = false
  }
  if not context then return info end

  info.has_menu = context:has_menu()

  local sel_cand_success, sel_cand_val = pcall(function() return context:get_selected_candidate() end)
  if sel_cand_success and sel_cand_val and sel_cand_val.text then
    info.first_candidate_text = sel_cand_val.text
  end

  if not info.has_menu then return info end

  local composition = context.composition
  if not composition or composition:empty() then return info end
  local segment = composition:back()
  if not segment or not segment.menu or segment.menu:empty() then return info end
  
  local current_menu = segment.menu
  local count_success, cand_count = pcall(function() return current_menu:candidate_count() end)
  if not count_success or not cand_count or cand_count == 0 then return info end

  local display_limit = math.min(max_to_display or 5, cand_count)
  for i = 0, display_limit - 1 do
    local cand_obj_success, cand_obj_val = pcall(function() return current_menu:get_candidate_at(i) end)
    if cand_obj_success and cand_obj_val then
      if cand_obj_val.text then table.insert(info.candidates_list, cand_obj_val.text)
      elseif cand_obj_val.comment then table.insert(info.candidates_list, cand_obj_val.comment .. " (comment)")
      else table.insert(info.candidates_list, "?") end
    else table.insert(info.candidates_list, "?err") end
  end
  return info
end

-- Commit callback
local function on_commit_callback(context)
  local committed_text_val = "N/A"
  local ct_succ, ct_val = pcall(function() return context:get_commit_text() end)
  if ct_succ and ct_val then committed_text_val = ct_val end

  local input_sequence_at_commit = "N/A"
  local st_succ, st_val = pcall(function() return context:get_script_text() end)
  if st_succ and st_val and st_val ~= "" then input_sequence_at_commit = st_val
  else -- Fallback
      local sel_cand_obj_commit
      local sel_c_succ, sel_c_val = pcall(function() return context:get_selected_candidate() end)
      if sel_c_succ and sel_c_val then sel_cand_obj_commit = sel_c_val end
      if sel_cand_obj_commit and sel_cand_obj_commit.preedit and sel_cand_obj_commit.preedit ~= "" then
          input_sequence_at_commit = sel_cand_obj_commit.preedit
      elseif context.input and context.input ~= "" then
          input_sequence_at_commit = context.input
      end
  end

  local selection_method = "unknown"
  local selected_rank = -1

  if last_input_state_for_commit.key_action_for_selection then
    if last_input_state_for_commit.key_action_for_selection == "space" then
      if last_input_state_for_commit.first_candidate and committed_text_val == last_input_state_for_commit.first_candidate then
        selection_method = "first_choice_space"
        selected_rank = 0
      else
        selection_method = "space_other" -- Space selected something not matching stored first_candidate
      end
    elseif tonumber(last_input_state_for_commit.key_action_for_selection) then
      local num = tonumber(last_input_state_for_commit.key_action_for_selection)
      selection_method = "nth_choice_number_" .. num
      selected_rank = num - 1 -- 0-indexed rank
    end
  elseif not last_input_state_for_commit.input_buffer then -- No prior input state with menu
     selection_method = "direct_commit_no_menu"
  end
  
  -- If rank is still -1, try to find it in the source_candidates list
  if selected_rank == -1 and last_input_state_for_commit.candidates then
      for i, cand_text in ipairs(last_input_state_for_commit.candidates) do
          if cand_text == committed_text_val then
              selected_rank = i - 1
              break
          end
      end
  end


  log_json_event({
    event_type = "text_committed",
    committed_text = committed_text_val,
    input_sequence_at_commit = input_sequence_at_commit,
    selection_method = selection_method,
    selected_candidate_rank = selected_rank, -- 0-indexed, -1 if not determined
    source_input_buffer = last_input_state_for_commit.input_buffer,
    source_first_candidate = last_input_state_for_commit.first_candidate,
    source_candidates_list = last_input_state_for_commit.candidates,
    source_event_timestamp = last_input_state_for_commit.timestamp
  })
  
  -- Reset for next cycle
  last_input_state_for_commit.key_action_for_selection = nil
end

-- Main processor
local function main_processor_func(key, env)
  if not key then return rime.process_results.kNoop end

  local key_name_val
  local kn_succ, kn_val = pcall(function() return key:repr() end)
  if not kn_succ then return rime.process_results.kNoop end
  key_name_val = kn_val

  if key_name_val == "0x0000" then return rime.process_results.kNoop end
  if key:release() then return rime.process_results.kNoop end

  local context = env.engine and env.engine.context
  if not context then return rime.process_results.kNoop end

  local pcall_success, err_msg = pcall(function()
    local current_input_buffer = "N/A"
    local st_succ_main, st_val_main = pcall(function() return context:get_script_text() end)
    if st_succ_main and st_val_main and st_val_main ~= "" then current_input_buffer = st_val_main
    elseif context.input and context.input ~= "" then current_input_buffer = context.input end

    local cand_info = get_current_candidate_info(context)
    
    local event_data = {
      event_type = "input_state_changed",
      key_action = key_name_val,
      input_buffer = current_input_buffer,
      candidates = cand_info.candidates_list,
      first_candidate = cand_info.first_candidate_text,
      has_menu = cand_info.has_menu
    }
    log_json_event(event_data)

    -- Update state for commit correlation
    if cand_info.has_menu then
        last_input_state_for_commit.input_buffer = current_input_buffer
        last_input_state_for_commit.first_candidate = cand_info.first_candidate_text
        last_input_state_for_commit.candidates = cand_info.candidates_list
        last_input_state_for_commit.timestamp = event_data.timestamp -- Use the timestamp of this event
    else 
        -- If no menu, clear parts of the state that depend on a menu
        last_input_state_for_commit.input_buffer = current_input_buffer -- Still useful
        last_input_state_for_commit.first_candidate = nil
        last_input_state_for_commit.candidates = nil
        last_input_state_for_commit.timestamp = event_data.timestamp
    end
    last_input_state_for_commit.key_action_for_selection = nil -- Reset this specifically

    if cand_info.has_menu then
        if key_name_val == "space" then
            last_input_state_for_commit.key_action_for_selection = "space"
        elseif key_name_val:match("^[1-9]$") then
            last_input_state_for_commit.key_action_for_selection = key_name_val
        end
    end

  end)

  if not pcall_success then
    log_json_event({ event_type = "error", component = "main_processor", message = tostring(err_msg), key_repr = key_name_val })
  end
  return rime.process_results.kNoop
end

-- Component definition
return {
  init = function(env)
    log_json_event({
        event_type = "session_start",
        schema_id = (env.engine and env.engine.context and env.engine.context.schema and env.engine.context.schema.id) or "N/A"
    })
    if env.engine and env.engine.context and env.engine.context.commit_notifier then
        env.commit_notifier_connection = env.engine.context.commit_notifier:connect(on_commit_callback)
    else
        log_json_event({event_type = "error", component = "init", message = "Could not connect to commit_notifier."})
    end
    -- Initialize last_input_state_for_commit
    last_input_state_for_commit = {
        input_buffer = nil, first_candidate = nil, candidates = nil,
        key_action_for_selection = nil, timestamp = nil
    }
  end,
  fini = function(env)
    if env.commit_notifier_connection then
        env.commit_notifier_connection:disconnect()
    end
    log_json_event({event_type = "session_end"})
  end,
  func = main_processor_func
}