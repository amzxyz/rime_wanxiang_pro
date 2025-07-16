-- backspace_limiter.lua
-- 防止连续 Backspace 在编码为空时删除已上屏内容，虽然我更推荐拍下esc。
-- 这个功能依赖按键事件的处理,运行逻辑的问题在手机上无法得到好的效果,其中macOS特非常特殊,它的按键事件等同于手机逻辑,因此手机和Mac都屏蔽了这一功能
-- @author amzxyz
local M = {}
local ACCEPT, PASS = 1, 2

-- 引入移动设备检测模块
local wanxiang = require("wanxiang")

-- 状态标志说明:
-- env.prev_input_len: 上一次按键前的输入长度
-- env.bs_sequence:  当前是否处于连续 Backspace 序列中

function M.init(env)
    env.prev_input_len = -1 -- 初始化为无效值
    env.bs_sequence = false
end

function M.func(key, env)
    local ctx = env.engine.context
    local kc = key.keycode
    -- 非 Backspace 键或按键释放事件：重置状态
    if kc ~= 0xFF08 or key:release() then
        env.bs_sequence = false
        env.prev_input_len = -1
        return PASS
    end

    -- 获取当前输入长度
    local current_len = #ctx.input

    -- 处于连续 Backspace 序列中
    if env.bs_sequence then
        -- 移动设备由于运行逻辑的问题不能实现友好的逻辑
        if wanxiang.is_mobile_device() then
            return PASS -- 直接放行
            -- PC设备保持原有逻辑：长度1变0时拦截
        else
            if env.prev_input_len == 1 and current_len == 0 then
                return ACCEPT -- 拦截：PC设备上从1变为0的情况
            end
        end
        -- 更新状态
        env.prev_input_len = current_len
        return PASS
    end
    -- 开始新的 Backspace 序列
    env.bs_sequence = true
    env.prev_input_len = current_len
    -- 首次按键总是允许
    return PASS
end

return M