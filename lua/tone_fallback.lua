-- 欢迎使用万象拼音方案
-- @amzxyz
-- https://github.com/amzxyz/rime_wanxiang
--用来在声调辅助的时候当你输入2个数字的时候自动将声调替换为第二个数字，
--也就是说你发现输入错误声调你可以手动轮巡输入而不用回退删除直接输入下一个即可

local wanxiang = require("wanxiang")

---@return string
local function get_fallback_input(input_text)
    return input_text:gsub("%d+", function(match) return match:sub(-1) end)
end

local function should_ignore_context(ctx)
    return wanxiang.is_function_mode_active(ctx) or ctx.input == ""
end

local P = {}
function P.init(env)
    env.tone_fallback_update_connection =
        env.engine.context.update_notifier:connect(function(ctx)
            local input_text = ctx.input

            if should_ignore_context(ctx) then return end

            local new_input = get_fallback_input(input_text)
            if new_input ~= input_text then
                ctx.input = new_input
            end
        end)
end

function P.fini(env)
    if env.tone_fallback_update_connection then
        env.tone_fallback_update_connection:disconnect()
    end
end

---@return ProcessResult
function P.func(_, env)
    local ctx = env.engine.context
    local input_text = ctx.input

    if should_ignore_context(ctx) then
        return wanxiang.RIME_PROCESS_RESULTS.kNoop
    end

    local new_fallback = get_fallback_input(input_text)

    return new_fallback ~= input_text
        and wanxiang.RIME_PROCESS_RESULTS.kAccepted
        or wanxiang.RIME_PROCESS_RESULTS.kNoop
end

return P
