---@diagnostic disable: undefined-global

-- 全局内容
RIME_PROCESS_RESULTS = {
    kRejected = 0,
    kAccepted = 1,
    kNoop = 2,
}

-- 万象的一些共用工具函数
local wanxiang = {}

-- 提供跨平台设备检测功能
-- @author amzxyz
-- 判断是否为手机设备（返回布尔值）
function wanxiang.is_mobile_device()
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

return wanxiang
