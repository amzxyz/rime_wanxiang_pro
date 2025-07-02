---@diagnostic disable: undefined-global

-- 万象的一些共用工具函数
local wanxiang = {}

-- 全局内容
---@alias PROCESS_RESULT ProcessResult
wanxiang.RIME_PROCESS_RESULTS = {
    kRejected = 0, -- 表示处理器明确拒绝了这个按键，停止处理链但不返回 true
    kAccepted = 1, -- 表示处理器成功处理了这个按键，停止处理链并返回 true
    kNoop = 2,     -- 表示处理器没有处理这个按键，继续传递给下一个处理器
}

-- 整个生命周期内不变，缓存判断结果
local is_mobile_device = nil
-- 判断是否为手机设备
---@author amzxyz
---@return boolean
function wanxiang.is_mobile_device()
    local function _is_mobile_device()
        local dist = rime_api.get_distribution_code_name() or ""
        local user_data_dir = rime_api.get_user_data_dir() or ""
        local sys_dir = rime_api.get_shared_data_dir() or ""
        -- 转换为小写以便比较
        local lower_dist = dist:lower()
        local lower_path = user_data_dir:lower()
        local sys_lower_path = sys_dir:lower()
        -- 主判断：常见移动端输入法
        if lower_dist == "trime" or
            lower_dist == "hamster" or
            lower_dist == "squirrel" then
            return true
        end

        -- 补充判断：路径中包含移动设备特征，很可以mac的运行逻辑和手机一球样
        if lower_path:find("/android/") or
            lower_path:find("/mobile/") or
            lower_path:find("/sdcard/") or
            lower_path:find("/data/storage/") or
            lower_path:find("/storage/emulated/") or
            lower_path:find("applications") or
            lower_path:find("library") then
            return true
        end
        -- 补充判断：路径中包含移动设备特征，很可以mac的运行逻辑和手机一球样
        if sys_lower_path:find("applications") or
            sys_lower_path:find("library") then
            return true
        end
        -- 特定平台判断（Android/Linux）
        if jit and jit.os then
            local os_name = jit.os:lower()
            if os_name:find("android") then
                return true
            end
        end

        -- 所有检查未通过则默认为桌面设备
        return false
    end

    if is_mobile_device == nil then
        is_mobile_device = _is_mobile_device()
    end
    return is_mobile_device
end

--- 检测是否为万象专业版
---@param env Env
---@return boolean
function wanxiang.is_pro_scheme(env)
    -- local schema_name = env.engine.schema.schema_name
    -- return schema_name:gsub("PRO$", "") ~= schema_name
    return env.engine.schema.schema_id == "wanxiang_pro"
end

-- 以 `tag` 方式检测是否处于反查模式
function wanxiang.is_in_radical_mode(env)
    local seg = env.engine.context.composition:back()
    return seg and (
        seg:has_tag("radical_lookup")
        or seg:has_tag("reverse_stroke")
        or seg:has_tag("add_user_dict")
    ) or false
end

-- 按照优先顺序加载文件：用户目录 > 系统目录
---@param path string 相对路径
---@retur file*, function
function wanxiang.load_file_with_fallback(path, mode)
    local _path = path:gsub("^/+", "") -- 去掉开头的斜杠
    local user_path = rime_api.get_user_data_dir() .. '/' .. _path
    local shared_path = rime_api.get_shared_data_dir() .. '/' .. _path

    mode = mode or "r" -- 默认读取模式
    local file, err = io.open(user_path, mode)
    if not file then
        file, err = io.open(shared_path, mode)
    end

    local function close()
        if file then file:close() end
    end

    return file, close, err
end

return wanxiang
