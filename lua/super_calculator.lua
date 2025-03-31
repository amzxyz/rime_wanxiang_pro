-- author: https://github.com/ChaosAlphard
-- 说明 https://github.com/gaboolic/rime-shuangpin-fuzhuma/pull/41

-- 原有功能：
-- 随机数生成、三角函数、幂函数、指数函数、对数函数求值
-- 计算n次方根、平均值、方差、阶乘、角度与弧度的相互转化

-- 新增功能：
-- 求解一元一次方程、二元一次方程组、一元二次方程、一元三次方程；
-- 求解一次、二次函数解析式、圆的方程；
-- 取整函数（包括向上取整和向下取整）、求余函数
-- 已知数列中任意两项，求通项公式(等差或等比);求数列的前n项和(等差或等比)
-- 已知三角形三边长，求面积；已知正多边形边数n、边长a，求面积

-- 功能代码一览：
-- sjs = "随机数"
-- zdbx = "已知边数n与边长a计算正多边形面积"
-- sjx = "已知三角形的三边长,求三角形面积"
-- dbsl = "已知等比数列的首项a1,公比q ,求指定的前n项和"
-- dcsl = "已知等差数列的首项a1,公差d ,求指定的前n项和"
-- txgs = "已知数列的任意两项,求其通项公式"
-- cexr = "已知圆心坐标和半径求圆的方程"
-- cexl = "已知圆心和圆上不同两点的坐标求圆方程"
-- cesd = "已知圆上不同三点的坐标，求圆方程"
-- yyyc = "求解一元一次方程"
-- eyyc = "求解二元一次方程组"
-- dxf = "点斜法求解一次函数解析式"
-- ldf = "两点法求解一次函数解析式"
-- yyec = "求解一元二次方程"
-- yysc = "求解一元三次方程"
-- dds = "顶点式求解二次函数解析式"
-- ybs = "一般式求解二次函数解析式"
-- sin = "正弦"
-- sinh = "双曲正弦"
-- asin = "反正弦"
-- cos = "余弦"
-- cosh = "双曲余弦"
-- acos = "反余弦"
-- tan = "正切"
-- tanh = "双曲正切"
-- atan = "反正切"
-- atan2 = "返回以弧度为单位的点(x,y)相对于x轴的逆时针角度"
-- deg = "弧度转换为角度"
-- rad = "角度转换为弧度"
-- ldexp = "返回 x*2^y"
-- exp = "返回 e^x"
-- nroot = "计算 x 开 N 次方"
-- sqrt = "计算 x 平方根"
-- log = "x作为底数的对数"
-- loge = "e作为底数的对数"
-- logt = "10作为底数的对数"
-- avg = "平均值"
-- var = "方差"
-- fact = "阶乘"
-- xsqz = "向上取整"
-- xxqz = "向下取整"
-- mod = "求余函数"

local T = {}

function T.init(env)
    local config = env.engine.schema.config
    env.name_space = env.name_space:gsub('^*', '')
    local _calc_pat = config:get_string("recognizer/patterns/calculator") or nil
    T.prefix = _calc_pat and _calc_pat:match("%^.?([a-zA-Z/=]+).*") or "V"
    T.tips = config:get_string("calculator/tips") or "计算器"
end

local function startsWith(str, start)
    return string.sub(str, 1, string.len(start)) == start
end

-- 函数表
local calc_methods = {
    -- e, exp(1) = e^1 = e
    e = math.exp(1),
    -- π
    pi = math.pi,
    b = 10 ^ 2,
    q = 10 ^ 3,
    k = 10 ^ 3,
    w = 10 ^ 4,
    tw = 10 ^ 5,
    m = 10 ^ 6,
    tm = 10 ^ 7,
    y = 10 ^ 8,
    g = 10 ^ 9
}

local methods_desc = {
	["e"] = "自然常数, 欧拉数",
	["pi"] = "圆周率 π",
    ["b"] = "百",
    ["q"] = "千",
    ["k"] = "千",
    ["w"] = "万",
    ["tw"] = "十万",
    ["m"] = "百万",
    ["tm"] = "千万",
    ["y"] = "亿",
    ["g"] = "十亿"
}

-- random([m [,n ]]) 返回m-n之间的随机数, n为空则返回1-m之间, 都为空则返回0-1之间的小数
local function random(...) return math.random(...) end
-- 注册到函数表中
calc_methods["sjs"] = random
methods_desc["sjs"] = "随机数"



-- 保留返回值的非零有效数字(返回结果为数字)
function f(n)
    -- 将数字转换为字符串以便处理
    local s = tostring(n)

    -- 查找小数点的位置
    local i = string.find(s, "%.")
    if i == nil then
        -- 如果没有小数点，直接返回原数字
        return n
    end

    -- 去除小数点后的尾随零
    local j = string.len(s)
    while j > i and string.sub(s, j, j) == "0" do
        j = j - 1
    end

    -- 如果小数点后没有数字了，移除小数点
    if j == i then
        -- 返回整数部分
        return tonumber(string.sub(s, 1, i - 1))
    else
        -- 否则，返回处理后的数字
        return tonumber(string.sub(s, 1, j))
    end
end


-- 保留返回值的非零有效数字(返回结果为字符串)
function fs(n)
    -- 将数字转换为字符串以便处理
    local s = tostring(n)

    -- 查找小数点的位置
    local i = string.find(s, "%.")
    if i == nil then
        -- 如果没有小数点，直接返回原数字
        return n
    end

    -- 去除小数点后的尾随零
    local j = string.len(s)
    while j > i and string.sub(s, j, j) == "0" do
        j = j - 1
    end

    -- 如果小数点后没有数字了，移除小数点
    if j == i then
        -- 返回整数部分
        return string.sub(s, 1, i - 1)
    else
        -- 否则，返回处理后的数字
        return string.sub(s, 1, j)
    end
end




-- 计算开 N 次方
local function nth_root(x, n)
    if n % 2 == 0 and x < 0 then
        return nil -- 偶次方时负数没有实数解
    elseif x < 0 then
        return -((-x) ^ (1 / n))
    else
        return x ^ (1 / n)
    end
end
calc_methods["nroot"] = nth_root
methods_desc["nroot"] = "计算 x 开 N 次方"




-- 正弦
local function sin(x) return math.sin(x) end
calc_methods["sin"] = sin
methods_desc["sin"] = "正弦"




-- 双曲正弦
local function sinh(x)
    return (math.exp(x) - math.exp(-x)) / 2
end
calc_methods["sinh"] = sinh
methods_desc["sinh"] = "双曲正弦"




-- 反正弦
local function asin(x) return math.asin(x) end
calc_methods["asin"] = asin
methods_desc["asin"] = "反正弦"




-- 余弦
local function cos(x) return math.cos(x) end
calc_methods["cos"] = cos
methods_desc["cos"] = "余弦"




-- 双曲余弦
local function cosh(x)
    return (math.exp(x) + math.exp(-x)) / 2
end
calc_methods["cosh"] = cosh
methods_desc["cosh"] = "双曲余弦"




-- 反余弦
local function acos(x) return math.acos(x) end
calc_methods["acos"] = acos
methods_desc["acos"] = "反余弦"




-- 正切
local function tan(x) return math.tan(x) end
calc_methods["tan"] = tan
methods_desc["tan"] = "正切"




-- 双曲正切
local function tanh(x)
    local e = math.exp(2 * x)
    return (e - 1) / (e + 1)
end
calc_methods["tanh"] = tanh
methods_desc["tanh"] = "双曲正切"




-- 反正切
local function atan(x) return math.atan(x) end
calc_methods["atan"] = atan
methods_desc["atan"] = "反正切"




-- 返回以弧度为单位的点(x,y)相对于x轴的逆时针角度。y是点的纵坐标，x是点的横坐标
-- 返回范围从−π到π （以弧度为单位），其中负角度表示向下旋转，正角度表示向上旋转
-- 它与传统的 math.atan(y/x) 函数相比，具有更好的数学定义，因为它能够正确处理边界情况（例如x=0）
local function atan2(y, x)
    if x == 0 and y == 0 then
        return 0 / 0 -- 返回NaN
    elseif x == 0 and y ~= 0 then
        if y > 0 then
            return math.pi / 2
        else
            return -math.pi / 2
        end
    else
        return math.atan(y / x) + (x < 0 and math.pi or 0)
    end
end
calc_methods["atan2"] = atan2
methods_desc["atan2"] = "返回以弧度为单位的点(x,y)相对于x轴的逆时针角度"




-- 将角度从弧度转换为度 e.g. deg(π) = 180
local function deg(x) return math.deg(x) end
calc_methods["deg"] = deg
methods_desc["deg"] = "弧度转换为角度"




-- 将角度从度转换为弧度 e.g. rad(180) = π
local function rad(x) return math.rad(x) end
calc_methods["rad"] = rad
methods_desc["rad"] = "角度转换为弧度"




-- 返回 x*2^y
local function ldexp(x, y) return x * 2 ^ y end
calc_methods["ldexp"] = ldexp
methods_desc["ldexp"] = "返回 x*2^y"




-- 返回 e^x
local function exp(x) return math.exp(x) end
calc_methods["exp"] = exp
methods_desc["exp"] = "返回 e^x"




-- 返回x的平方根 e.g. sqrt(x) = x^0.5
local function sqrt(x) return math.sqrt(x) end
calc_methods["sqrt"] = sqrt
methods_desc["sqrt"] = "计算 x 平方根"




-- x为底的对数, log(10, 100) = log(100) / log(10) = 2
local function log(x, y)
    -- 不能为负数或0
    if x <= 0 or y <= 0 then
        return nil
    end

    return math.log(y) / math.log(x)
end
calc_methods["log"] = log
methods_desc["log"] = "x作为底数的对数"




-- 自然数e为底的对数
local function loge(x)
    -- 不能为负数或0
    if x <= 0 then return nil end

    return math.log(x)
end
calc_methods["loge"] = loge
methods_desc["loge"] = "e作为底数的对数"




-- 10为底的对数
local function logt(x)
    -- 不能为负数或0
    if x <= 0 then return nil end

    return math.log(x) / math.log(10)
end
calc_methods["logt"] = logt
methods_desc["logt"] = "10作为底数的对数"




-- 平均值
local function avg(...)
    local data = {...}
    local n = select("#", ...)
    -- 样本数量不能为0
    if n == 0 then return nil end

    -- 计算总和
    local sum = 0
    for _, value in ipairs(data) do
        sum = sum + value
    end

    return sum / n
end
calc_methods["avg"] = avg
methods_desc["avg"] = "平均值"




-- 方差
local function variance(...)
    local data = {...}
    local n = select("#", ...)
    -- 样本数量不能为0
    if n == 0 then return nil end

    -- 计算均值
    local sum = 0
    for _, value in ipairs(data) do
        sum = sum + value
    end
    local mean = sum / n

    -- 计算方差
    local sum_squared_diff = 0
    for _, value in ipairs(data) do
        sum_squared_diff = sum_squared_diff + (value - mean) ^ 2
    end

    return sum_squared_diff / n
end
calc_methods["var"] = variance
methods_desc["var"] = "方差"




-- 阶乘
local function factorial(x)
    -- 不能为负数
    if x < 0 then return nil end
    if x == 0 or x == 1 then return 1 end

    local result = 1
    for i = 1, x do
        result = result * i
    end

    return result
end
calc_methods["fact"] = factorial
methods_desc["fact"] = "阶乘"




-- 实现阶乘计算(!)
local function replaceToFactorial(str)
    -- 替换[0-9]!字符为fact([0-9])以实现阶乘
    return str:gsub("([0-9]+)!", "fact(%1)")
end




-- 向上取整函数
function ceil(x)
    return math.ceil(x)
end
calc_methods["xsqz"] = ceil
methods_desc["xsqz"] = "向上取整"




-- 向下取整函数
function floor(x)
    return math.floor(x)
end
calc_methods["xxqz"] = floor
methods_desc["xxqz"] = "向下取整"




-- 取余函数
-- 定义一个取余函数
function remainder(x, y)
    -- 使用math.fmod函数计算余数
    local result = math.fmod(x, y)
    -- 如果x是负数，math.fmod会返回负数，需要调整为正数
    if result < 0 then
        result = result + y
    end
    return result
end
calc_methods["mod"] = remainder
methods_desc["mod"] = "求余函数"




-- 计算正多边形面积
function calculateRegularPolygonArea(n, a)
    -- 检查边数n是否为正整数
    if n ~= math.floor(n) or n <= 0 then
        return "错误：边数n必须为正整数。"
    end
    -- 检查边长a是否为正数
    if a <= 0 then
        return "错误：边长a必须为正数。"
    end

    -- 计算正多边形的面积
    local s = (n * a^2) / (4 * math.tan(math.pi / n))
    s = f(s)
    return s
end
calc_methods["zdbx"] = calculateRegularPolygonArea
methods_desc["zdbx"] = "已知边数n与边长a计算正多边形面积"




-- 已知等比数列的首项a1,公比q,求指定的前n项和
function geometricSeriesSum(a1, q, n)
    -- 检查首项是否为0
    if a1 == 0 then
        return 0
    -- 检查公比是否为0
    elseif q == 0 and a1 ~= 0 then
        return a1
    -- 检查公比是否为1
    elseif q == 1 then
        return a1 * n
    else
        -- 正常计算前n项和
        local s = a1 * (1-q^n)/(1-q)
        s = f(s)
        return s
    end
end
calc_methods["dbsl"] = geometricSeriesSum
methods_desc["dbsl"] = "已知等比数列的首项a1,公比q ,求指定的前n项和"




-- 已知等差数列的首项a1,公差d ,求指定的前n项和
function ArithmeticSeriesSum(a1, d, n)
    -- 检查首项和公差是否都为0
    if a1 == 0 and d == 0 then
        return 0
    -- 检查首项是否不为0而公差为0
    elseif a1 ~= 0 and d == 0 then
        return a1 * n
    else
        -- 正常计算前n项和
        local s = n*a1 + n*(n-1)*d/2
        s = f(s)
        return s
    end
end
calc_methods["dcsl"] = ArithmeticSeriesSum
methods_desc["dcsl"] = "已知等差数列的首项a1,公差d ,求指定的前n项和"




-- 已知数列中任意两项,求通项公式(等差或等比),b=0为等差数列,b=1为等比数列
function findSequenceFormula(ai, i, ak, k, b)
    -- 检查参数正确性
    if i ~= math.floor(i) or i <= 0 or k ~= math.floor(k) or k<= 0 then
        return "i 和 k 必须是正整数"
    end
    if ai == ak and i == k then
        return "ai 、 ak 和对应的项数不能同时相等"
    end

    -- 计算等差数列的通项公式
    local function arithmeticSequence(ai, i, ak, k)
        local d = (ak - ai) / (k - i)
        local a1 = ai - (i - 1) * d
        d = f(d)
        a1 = f(a1)
        -- 根据公差d的正负调整公式
        if d >= 0 then
            return "aₙ=" .. a1 .. "+(n-1)*" .. d
        else
            return "aₙ=" .. a1 .. "-(n-1)*" .. -d
        end
    end

    -- 计算等比数列的通项公式
    local function geometricSequence(ai, i, ak, k)
        local q = ak/ai
        local n = k-i

        -- 计算 x 开 n 次方
        local function nth_root(x, n)
            if n % 2 == 0 and x < 0 then
                return nil -- 开偶次方时负数没有实数解
            elseif x < 0 then
                return -((-x) ^ (1 / n))
            else
                return x ^ (1 / n)
            end
        end
        
        local s = nth_root(q, n) -- 使用 nth_root 函数计算 q 的 n 次方根
        if s == nil then
            return "无法计算通项公式"
        end
        local a1 = ai / (s ^ (i - 1)) -- 计算首项 a1
        s = f(s)
        a1 = f(a1)

        -- 根据公比s的正负调整公式
        if s < 0 then
            return "aₙ=" .. a1 .. "*(" .. s .. ")ⁿ⁻¹"
        else
            return "aₙ=" .. a1 .. "*" .. s .. "ⁿ⁻¹"
        end
    end

    -- 检查是否为常数列
    if ai == ak and i ~= k then
        return "aₙ=" .. ai
    end

    -- 根据b值返回通项公式
    if b == 0 then
        return arithmeticSequence(ai, i, ak, k)
    elseif b == 1 then
        if ai == 0 or ak == 0 then
            return "等比数列中不能有0项"
        end
        return geometricSequence(ai, i, ak, k)
    else
        return "b 参数必须是0或1"
    end
end
calc_methods["txgs"] = findSequenceFormula
methods_desc["txgs"] = "已知数列的任意两项,求其通项公式"




-- 已知圆心坐标(h,k)和半径r,求圆的标准方程和一般方程
function CircleEquationsxr(h, k, r)
    -- 检查半径是否为正数
    if r <= 0 then
        return "半径必须大于0"
    end

    -- 计算r^2的具体数值
    local r_squared = r^2
    r_squared= f(r_squared)

    -- 圆的标准方程
    local standardEquation
    if h == 0 then
        if k > 0 then
            standardEquation = "x²+(y-" .. k .. ")²=" .. r_squared
        elseif k == 0 then
            standardEquation = "x²+y²=" .. r_squared
        else
            standardEquation = "x²+(y+" .. -k .. ")²=" .. r_squared
        end
    elseif k == 0 then
        if h > 0 then
            standardEquation = "(x-" .. h .. ")²+y²=" .. r_squared
        elseif h == 0 then
            standardEquation = "x²+y²=" .. r_squared
        else
            standardEquation = "(x+" .. -h .. ")²+y²=" .. r_squared
        end
    else
        if h > 0 and k > 0 then
            standardEquation = "(x-" .. h .. ")²+(y - " .. k .. ")²=" .. r_squared
        elseif h > 0 and k < 0 then
            standardEquation = "(x-" .. h .. ")²+(y + " .. -k .. ")²=" .. r_squared
        elseif h < 0 and k > 0 then
            standardEquation = "(x+" .. -h .. ")²+(y - " .. k .. ")²=" .. r_squared
        else
            standardEquation = "(x+" .. -h .. ")²+(y+" .. -k ..")²=" .. r_squared
        end
    end

    -- 圆的一般方程
    local D = -2 * h
    local E = -2 * k
    local F = h^2 + k^2 - r^2
    F= f(F)
    local generalEquation = "x²+y²"

    -- 处理D项
    if D ~= 0 then
        if D == -1 then
            generalEquation = generalEquation .. "-x"
        elseif D == 1 then
            generalEquation = generalEquation .. "+x"
        elseif D > 0 then
            generalEquation = generalEquation .. "+" .. D .. "x"
        else
            generalEquation = generalEquation .. "-" .. -D .. "x"
        end
    end

    -- 处理E项
    if E ~= 0 then
        if E == -1 then
            generalEquation = generalEquation .. "-y"
        elseif E == 1 then
            generalEquation = generalEquation .. "+y"
        elseif E > 0 then
            generalEquation = generalEquation .. "+" .. E .. "y"
        else
            generalEquation = generalEquation .. "-" .. -E .. "y"
        end
    end

    -- 处理F项
    if F ~= 0 then
        if F > 0 then
            generalEquation = generalEquation .. "+" .. F .. "=0"
        else
            generalEquation = generalEquation .. "-" .. -F .. "=0"
        end
    end

    -- 返回两个方程
    return "标准方程: " .. standardEquation .. "\n一般方程: " .. generalEquation
end
calc_methods["cexr"] = CircleEquationsxr
methods_desc["cexr"] = "已知圆心坐标和半径求圆的方程"




-- 已知圆心坐标(h,k)和圆上不同两点(x1,y1),(x2,y2),求圆的标准方程和一般方程
function CircleEquationsxl(h ,k ,x1, y1, x2, y2)
    -- 检查三个坐标中是否有任意两个点坐标完全相同
    if (x1 == x2 and y1 == y2) or (x1 == h and y1 == k) or (x2 == h and y2 == k) then
        return "错误：三个坐标中不能有任意两个点坐标完全相同。"
    end

    -- 计算两点到圆心的距离，并检查是否相等
    local distance1 = math.sqrt((x1 - h)^2 + (y1 - k)^2)
    local distance2 = math.sqrt((x2 - h)^2 + (y2 - k)^2)
    if distance1 ~= distance2 then
        return "错误：给定的圆心坐标和两个点无法构成圆。"
    end

    -- 计算半径
    local r = distance1

    -- 计算r^2的具体数值
    local r_squared = r^2
    r_squared= f(r_squared)

    -- 圆的标准方程
    local standardEquation
    if h == 0 then
        if k == 0 then
            standardEquation = "x²+y²=" .. r_squared
        else
            if k > 0 then
                standardEquation = "x²+(y-" .. k .. ")²=" .. r_squared
            else
                standardEquation = "x²+(y+" .. -k .. ")²=" .. r_squared
            end
        end
    elseif k == 0 then
        if h == 0 then
            standardEquation = "x²+y²=" .. r_squared
        else
            if h > 0 then
                standardEquation = "(x-" .. h .. ")²+y²=" .. r_squared
            else
                standardEquation = "(x+" .. -h .. ")²+y²=" .. r_squared
            end
        end
    else
        if h > 0 and k > 0 then
            standardEquation = "(x-" .. h .. ")²+(y-" .. k .. ")²=" .. r_squared
        elseif h > 0 and k < 0 then
            standardEquation = "(x-" .. h .. ")²+(y+" .. -k .. ")²=" .. r_squared
        elseif h < 0 and k > 0 then
            standardEquation = "(x+" .. -h .. ")²+(y-" .. k .. ")²=" .. r_squared
        else
            standardEquation = "(x+" .. -h .. ")²+(y+" .. -k .. ")²=" .. r_squared
        end
    end

    -- 圆的一般方程
    local D = -2 * h
    local E = -2 * k
    local F = h^2 + k^2 - r_squared
    F= f(F)
    local generalEquation = "x²+y²"

    -- 处理D项
    if D ~= 0 then
        if D == -1 then
            generalEquation = generalEquation .. "-x"
        elseif D == 1 then
            generalEquation = generalEquation .. "+x"
        else
            if D > 0 then
                generalEquation = generalEquation .. "+" .. D .. "x"
            else
                generalEquation = generalEquation .. "-" .. -D .. "x"
            end
        end
    end

    -- 处理E项
    if E ~= 0 then
        if E == -1 then
            generalEquation = generalEquation .. "-y"
        elseif E == 1 then
            generalEquation = generalEquation .. "+y"
        else
            if E > 0 then
                generalEquation = generalEquation .. "+" .. E .. "y"
            else
                generalEquation = generalEquation .. "-" .. -E .. "y"
            end
        end
    end

    -- 处理F项
    if F ~= 0 then
        if F > 0 then
            generalEquation = generalEquation .. "+" .. F .. "=0"
        else
            generalEquation = generalEquation .. "-" .. -F .. "=0"
        end
    end

    -- 返回两个方程
    return "标准方程: " .. standardEquation .. "\n一般方程: " .. generalEquation
end
calc_methods["cexl"] = CircleEquationsxl
methods_desc["cexl"] = "已知圆心和圆上不同两点的坐标求圆方程"




-- 已知不共线的三点(x1,y1),(x2,y2),(x3,y3),求过它们的圆的方程
function CircleEquationssd(x1, y1, x2, y2, x3, y3)
    -- 检查三个点是否共线
    local determinant = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
    if determinant == 0 then
        return "错误：三个点共线或重合，无法构成圆。"
    end

    -- 构建系数矩阵A和常数矩阵B
    local A = {
        {x1, y1, 1},
        {x2, y2, 1},
        {x3, y3, 1}
    }
    local B = {
         (-x1^2 - y1^2),
         (-x2^2 - y2^2),
         (-x3^2 - y3^2)
    }

    -- 计算系数矩阵A的行列式detA
    local detA = A[1][1] * (A[2][2] * A[3][3] - A[2][3] * A[3][2]) -
                 A[1][2] * (A[2][1] * A[3][3] - A[2][3] * A[3][1]) +
                 A[1][3] * (A[2][1] * A[3][2] - A[2][2] * A[3][1])

    -- 计算D、E、F的行列式
    local detAD = B[1] * (A[2][2] * A[3][3] - A[2][3] * A[3][2]) -
                  A[1][2] * (B[2] * A[3][3] - B[3] * A[2][3]) +
                  A[1][3] * (B[2] * A[3][2] - B[3] * A[2][2])

    local detAE = A[1][1] * (B[2] * A[3][3] - B[3] * A[2][3]) -
                  B[1] * (A[2][1] * A[3][3] - A[2][3] * A[3][1]) +
                  A[1][3] * (A[2][1] * B[3] - A[3][1] * B[2])

    local detAF = A[1][1] * (A[2][2] * B[3] - A[3][2] * B[2]) -
                  A[1][2] * (A[2][1] * B[3] - A[3][1] * B[2]) +
                  B[1] * (A[2][1] * A[3][2] - A[3][1] * A[2][2])

    -- 计算系数D、E、F
    local D = detAD / detA
    local E = detAE / detA
    local F = detAF / detA
    D= f(D)
    E= f(E)
    F= f(F)

    local generalEquation = "x²+y²"

    -- 处理D项
    if D ~= 0 then
        if D == -1 then
            generalEquation = generalEquation .. "-x"
        elseif D == 1 then
            generalEquation = generalEquation .. "+x"
        else
            if D > 0 then
                generalEquation = generalEquation .. "+" .. D .. "x"
            else
                generalEquation = generalEquation .. "-" .. -D .. "x"
            end
        end
    end

    -- 处理E项
    if E ~= 0 then
        if E == -1 then
            generalEquation = generalEquation .. "-y"
        elseif E == 1 then
            generalEquation = generalEquation .. "+y"
        else
            if E > 0 then
                generalEquation = generalEquation .. "+" .. E .. "y"
            else
                generalEquation = generalEquation .. "-" .. -E .. "y"
            end
        end
    end

    -- 处理F项
    if F ~= 0 then
        if F > 0 then
            generalEquation = generalEquation .. "+" .. F .. "=0"
        else
            generalEquation = generalEquation .. "-" .. -F .. "=0"
        end
    end

    -- 由D、E、F求得圆心(h, k)的值
    local h = -D / 2
    local k = -E / 2
    h= f(h)
    k= f(k)

    -- 计算半径r的平方
    local r_squared = h^2 + k^2 - F
    r_squared= f(r_squared)

    -- 根据圆心和半径写出标准方程
    local standardEquation
    if h == 0 then
        if k == 0 then
            standardEquation = "x²+y²=" .. r_squared
        else
            if k > 0 then
                standardEquation = "x²+(y-" .. k .. ")²=" .. r_squared
            else
                standardEquation = "x²+(y+" .. -k .. ")²=" .. r_squared
            end
        end
    elseif k == 0 then
        if h == 0 then
            standardEquation = "y²+x²=" .. r_squared
        else
            if h > 0 then
                standardEquation = "(x-" .. h .. ")²+y²=" .. r_squared
            else
                standardEquation = "(x+" .. -h .. ")²+y²=" .. r_squared
            end
        end
    else
        if h > 0 and k > 0 then
            standardEquation = "(x-" .. h .. ")²+(y-" .. k .. ")²=" .. r_squared
        elseif h > 0 and k < 0 then
            standardEquation = "(x-" .. h .. ")²+(y+ " .. -k .. ")²=" .. r_squared
        elseif h < 0 and k > 0 then
            standardEquation = "(x+".. -h .. ")²+(y-" .. k .. ")²=" .. r_squared
        else
            standardEquation = "(x+" .. -h .. ")²+(y+" .. -k .. ")²=" .. r_squared
        end
    end

    -- 返回两个方程
    return "标准方程: " .. standardEquation .. "\n一般方程: " .. generalEquation
end
calc_methods["cesd"] = CircleEquationssd
methods_desc["cesd"] = "已知圆上不同三点的坐标，求圆方程"




-- 求解一元一次方程:ax+b=0
function solveLinearEquation(a, b)
    -- 检查a是否为0，因为如果a为0，方程将不再是一元一次方程
    if a == 0 then
        if b == 0 then
            return "方程有无数解"
        else
            return "方程无解"
        end
    else
        -- 计算x的值
        local x = -b / a
        x = f(x)
        return "x=" .. x
    end
end
calc_methods["yyyc"] = solveLinearEquation
methods_desc["yyyc"] = "求解一元一次方程"




-- 求解二元一次方程组：ax+by=e, cx+dy=f
function solveLinearSystem(a, b, c, d, e, f)
    -- 计算行列式D
    local D = a * d - b * c

    -- 检查方程组是否有解
    if D == 0 then
        if (a * f - c * e) == 0 and (b * e - d * f) == 0 then
            return "方程组有无穷多解"
        else
            return "方程组无解"
        end
    end
    -- 计算x和y
    local x = (d * e - b * f) / D
    local y = (a * f - c * e) / D
    x= fs(x)
    y= fs(y)
    -- 返回解的字符串表示
    return "x=" .. x .. ",y=" .. y
    
end
calc_methods["eyyc"] = solveLinearSystem
methods_desc["eyyc"] = "求解二元一次方程组"




-- 点斜法求解一次函数解析式
-- 定义函数，输入斜率k和点的坐标x1, y1
function pointSlopeForm(k, x1, y1)
    -- 特殊情况：平行于y轴
    if k == nil then
        return "x=" .. x1
    end

    -- 特殊情况：平行于x轴
    if k == 0 then
        return "y=" .. y1
    end

    -- 计算截距b
    local b = y1 - k * x1

    -- 构建直线方程
    local equation = "y"

    -- 优化k的表示
    if k == -1 then
        equation = equation .. "=-x"
    elseif k == 1 then
        equation = equation .. "=x"
    else
        if k > 0 then
            equation = equation .. "=" .. k .. "x"
        else
            equation = equation .. "=-" .. -k .. "x"
        end
    end

    -- 优化b的表示
    if b == 0 then
        -- b为0，不添加b项
    elseif b > 0 then
        equation = equation .. "+" .. b
    else
        equation = equation .. "-" .. -b
    end

    return equation
end
calc_methods["dxf"] = pointSlopeForm
methods_desc["dxf"] = "点斜法求解一次函数解析式"




-- 两点法求解一次函数解析式
-- 定义函数，输入两点坐标(x1, y1)、(x2,y2)
function twoPointsForm(x1, y1, x2, y2)
    -- 检查两点是否相同
    if x1 == x2 and y1 == y2 then
        return "两点坐标完全相同，无法确定直线方程。"
    end

    -- 计算斜率k
    local k = (y2 - y1) / (x2 - x1)
    k = f(k)
    local b

    -- 特殊情况处理
    if k == 0 then
        -- 平行于x轴的直线
        return "y=" .. y1
    elseif x2 == x1 then
        -- 平行于y轴的直线
        return "x=" .. x1
    else
        -- 计算截距b
        b = y1 - k * x1

        -- 格式化斜率k
        if k == -1 then
            k = "-x"
        elseif k == 1 then
            k = "x"
        else
            k = k .. "x"
        end

        -- 格式化截距b
        if b == 0 then
            b = ""
        elseif b > 0 then
            b = "+" .. b
        else
            b = b
        end

        -- 组合直线方程
        return "y=" .. k .. b
    end
end
calc_methods["ldf"] = twoPointsForm
methods_desc["ldf"] = "两点法求解一次函数解析式"




-- 求解一元二次方程
function solveQuadraticEquation(a, b, c)
    -- 检查二次项系数是否为0
    if a == 0 then
        return "二次项系数不能为0"
    end

    -- 计算判别式
    local discriminant = b^2  - 4*a*c

    -- 检查判别式以确定根的性质
    if discriminant < 0 then
        return "无实根，有复数解"
    elseif discriminant == 0 then
        local x = -b / (2 * a)
        x = f(x)
        return "x₁=x₂=" .. x
    else
        local x1 = (-b + math.sqrt(discriminant)) / (2 * a)
        local x2 = (-b - math.sqrt(discriminant)) / (2 * a)
        x1 = f(x1)
        x2 = f(x2)
        return "x₁=" .. x1 .. ",x₂=" .. x2
    end
end
calc_methods["yyec"] = solveQuadraticEquation
methods_desc["yyec"] = "求解一元二次方程"




-- 求解一元三次方程
function solveCubicEquation(a, b, c, d)
    -- 检查参数正确性
    if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" or type(d) ~= "number" then
        return "错误：系数必须是数字。"
    end
    if a == 0 then
        return "错误：系数a不能为零。"
    end

    -- 计算重根判别式
    local A = b^2 - 3*a*c
    local B = b*c - 9*a*d
    local C = c^2 - 3*b*d
    A = f(A)
    B = f(B)
    C = f(C)

    -- 计算总判别式
    local Delta = B^2 - 4*A*C
    Delta = f(Delta)

    -- 根据盛金公式进行求解
    if A == 0 and B == 0 then
        -- 条件一：A = B = 0，方程有一个三重实根
        local x = -b / (3*a)
        x = f(x)
        return "x₁=x₂=x₃=" .. x
    elseif Delta > 0 then
        -- 条件二：Delta > 0，方程有一个实根和一对共轭虚根
        local Y1 = A * b + 3 * a * (-B + math.sqrt(Delta)) / 2
        local Y2 = A * b + 3 * a * (-B - math.sqrt(Delta)) / 2
        local y1 = nth_root(Y1, 3)
        local y2 = nth_root(Y2, 3)
        local x1 = (-b - y1 - y2) / (3*a)
        x1 = f(x1)
        local P = (-b+0.5*(y1+y2)) / (3*a)
        P = f(P)
        local Q = (0.5*math.sqrt(3)*(y1-y2))/ (3*a)
        Q = f(Q)
        Q = Q .. "i"
        local x2 = P + Q
        local x3 = P - Q
        return "x₁=" .. x1 .. ",x₂=" .. x2 .. ",x₃=" .. x3
    elseif Delta == 0 and A ~= 0 then
        -- 条件三：Delta = 0，方程有三个实根，其中有一个两重根
        local K = B / A
        local x1 = -b / a + K
        local x2 = -0.5 * K
        x1 = f(x1)
        x2 = f(x2)
        return "x₁=" .. x1 .. ",x₂=x₃=" .. x2
    elseif Delta < 0 and A > 0 then
        -- 条件四：Delta < 0，方程有三个不相等的实根
        local T = (2*A*b - 3*a*B) / (2*math.sqrt(A^3))
        local M = math.acos(T)
        local S = math.cos(M/3)
        local R = math.sin(M/3)
        local x1 = (-b - 2*math.sqrt(A)*S) / (3*a)
        local x2 = (-b + math.sqrt(A)*(S + math.sqrt(3)*R)) / (3*a)
        local x3 = (-b + math.sqrt(A)*(S - math.sqrt(3)*R)) / (3*a)
        x1 = f(x1)
        x2 = f(x2)
        x3 = f(x3)
        return "x₁=" .. x1 .. ",x₂=" .. x2 .. ",x₃=" .. x3
    end
end
calc_methods["yysc"] = solveCubicEquation
methods_desc["yysc"] = "求解一元三次方程"




-- 顶点式求解二次函数解析式：y=a(x-h)^2+k
-- (x1,y1)为顶点坐标，(x2,y2)为其函数图像上除顶点坐标外任意一点坐标
function getQuadraticEquationdd(x1, y1, x2, y2)
    -- 检查两个点是否相同
    if x1 == x2 or y1 == y2 then
        error("错误：两个点的横坐标或纵坐标不能相同。")
    end

    -- 已知顶点坐标 (x1, y1) 和另一个点 (x2, y2)，求解二次函数的系数
    local a = (y2 - y1) / (x2 - x1)^2
    local b = -2 * a * x1
    local c = y1 + a * x1^2
    a = f(a)
    b = f(b)
    c = f(c)

    -- 定义一个局部函数用于格式化系数
    local function formatCoefficient(a, b, c)
        local result = ""

        -- 格式化a的值
        if a > 0 and a ~= 1 then
            result = result .. a .. "x²" -- a大于0且不等于1时，保持a不变
        elseif a == 1 then
            result = result .. "x²" -- a等于1时，省略a
        elseif a < 0 and a ~= -1 then
            result = result .. a .. "x²" -- a小于0且不等于-1时，保持a不变
        elseif a == -1 then
            result = result .. "-x²" -- a等于-1时，在x²前面加负号
        end

        -- 格式化b的值
        if b ~= 0 then
            if b == 1 then
                result = result .. "+x"
            elseif b == -1 then
                result = result .. "-x"
            elseif b > 0 then
                result = result .. "+" .. b .. "x"
            else
                result = result .. "-" .. -b .. "x"
            end
        end
    
        -- 格式化c的值
        if c ~= 0 then
            if c > 0 then
                result = result .. "+" .. c
            else
                result = result .. "-" .. -c
            end
        end

        return result
    end

    -- 使用格式化函数并返回解析式
    return "y=" .. formatCoefficient(a, b, c)
end
calc_methods["dds"] = getQuadraticEquationdd
methods_desc["dds"] = "顶点式求解二次函数解析式"




-- 一般式求解二次函数解析式
function getQuadraticEquationy(x1, y1, x2, y2, x3, y3)
    -- 构建方程组的系数矩阵和常数矩阵
    local A = {
        {x1^2, x1, 1},
        {x2^2, x2, 1},
        {x3^2, x3, 1}
    }
    local B = {
        (y1), 
        (y2), 
        (y3)
    }

    -- 计算系数矩阵A的行列式detA
    local detA = A[1][1] * (A[2][2] * A[3][3] - A[2][3] * A[3][2]) -
                 A[1][2] * (A[2][1] * A[3][3] - A[2][3] * A[3][1]) +
                 A[1][3] * (A[2][1] * A[3][2] - A[2][2] * A[3][1])

    -- 计算行列式detAx, detAy, detAz
    local detAx = B[1] * (A[2][2] * A[3][3] - A[2][3] * A[3][2]) -
                  A[1][2] * (B[2] * A[3][3] - B[3] * A[2][3]) +
                  A[1][3] * (B[2] * A[3][2] - B[3] * A[2][2])

    local detAy = A[1][1] * (B[2] * A[3][3] - A[2][3] * B[3]) -
                  B[1] * (A[2][1] * A[3][3] - A[2][3] * A[3][1]) +
                  A[1][3] * (A[2][1] * B[3] - A[3][1] * B[2])

    local detAz = A[1][1] * (A[2][2] * B[3] - A[3][2] * B[2]) -
                  A[1][2] * (A[2][1] * B[3] - A[3][1] * B[2]) +
                  B[1] * (A[2][1] * A[3][2] - A[3][1] * A[2][2])

    -- 计算系数a, b, c
    local a = detAx / detA
    local b = detAy / detA
    local c = detAz / detA
    a = f(a)
    b = f(b)
    c = f(c)

    -- 定义一个局部函数用于格式化系数
    local function formatCoefficient(a, b, c)
        local result = ""

        -- 格式化a的值
        if a ~= 0 then
            if a == 1 then
                result = result .. "x²"
            elseif a == -1 then
                result = result .. "-x²"
            else
                result = result .. a .. "x²"
            end
        end

        -- 格式化b的值
        if b ~= 0 then
            if b == 1 then
                result = result .. "+x"
            elseif b == -1 then
                result = result .. "-x"
            elseif b > 0 then
                result = result .. "+" .. b .. "x"
            else
                result = result .. "-" .. -b .. "x"
            end
        end

        -- 格式化c的值
        if c ~= 0 then
            if c > 0 then
                result = result .. "+" .. c
            else
                result = result .. "-" .. -c
            end
        end

        return result
    end

    -- 使用格式化函数并返回解析式
    local equation = "y=" .. formatCoefficient(a, b, c)
    return equation
end
calc_methods["ybs"] = getQuadraticEquationy
methods_desc["ybs"] = "一般式求解二次函数解析式"




-- 已知三角形的三边a、b、c,求三角形面积
function calculateTriangleArea(a, b, c)
    -- 检查是否能构成三角形
    if a + b <= c or a + c <= b or b + c <= a then
        return "不能构成三角形"
    end

    -- 计算半周长
    local p = (a + b + c) / 2

    -- 使用海伦公式计算面积
    local s = math.sqrt(p * (p - a) * (p - b) * (p - c))
    s = f(s)
    return s
end
calc_methods["sjx"] = calculateTriangleArea
methods_desc["sjx"] = "已知三角形的三边长,求三角形面积"




-- 简单计算器
function T.func(input, seg, env)
    local composition = env.engine.context.composition
    if composition:empty() then return end
    local segment = composition:back()

    if startsWith(input, T.prefix) or (seg:has_tag("calculator")) then
        segment.prompt = "〔" .. T.tips .. "〕"
        -- 提取算式
        local express = input:gsub(T.prefix, ""):gsub("^/vs", "")
        -- 算式长度 < 2 直接终止(没有计算意义)
        if (string.len(express) < 2) and (not calc_methods[express]) then return end
        if (string.len(express) == 2) and (express:match("^%d[^%!]$")) then return end
        local code = replaceToFactorial(express)

        local loaded_func, load_error = load("return " .. code, "calculate", "t", calc_methods)
        if loaded_func and (type(methods_desc[code]) == "string") then
            yield(Candidate(input, seg.start, seg._end, express .. ":" .. methods_desc[code], ""))
		elseif loaded_func then
            local success, result = pcall(loaded_func)
            if success then
                yield(Candidate(input, seg.start, seg._end, tostring(result), ""))
                yield(Candidate(input, seg.start, seg._end, express .. "=" .. tostring(result), ""))
            else
                -- 处理执行错误
				yield(Candidate(input, seg.start, seg._end, express, "执行错误"))
            end
        else
            -- 处理加载错误
			yield(Candidate(input, seg.start, seg._end, express, "解析失败"))
        end
    end
end

return T