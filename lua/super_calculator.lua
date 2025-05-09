-- author: https://github.com/ChaosAlphard
-- 说明 https://github.com/gaboolic/rime-shuangpin-fuzhuma/pull/41

-- 原有功能：
-- 随机数生成、三角函数、幂函数、指数函数、对数函数求值
-- 计算n次方根、平均值、方差、阶乘、角度与弧度的相互转化

-- 新增功能：
-- 求解一元一次方程、二元一次方程组、一元二次方程、一元三次方程、一元四次方程；
-- 求解一次、二次函数解析式、圆的方程；
-- 取整函数（包括向上取整和向下取整）、求余函数；
-- 已知数列中任意两项，求通项公式(等差或等比)；求数列的前n项和(等差或等比)；
-- 已知三角形三边长，求面积；已知正多边形边数n、边长a，求面积；
-- 判断两直线位置关系，给出距离或交点坐标；点到点、点到直线距离求解；
-- 求解两点间线段的垂直平分线方程；求解点绕点旋转后的坐标；
-- 组合数、排列数、最大公因数、最小公倍数求解；
-- 点关于直线的对称点坐标、直线关于直线(或点)的对称直线方程求解；
-- 连续自然数的幂方求和，包括平方和、立方和、4次方之和；前n个奇数或偶数的平方和、立方和、4次方之和；

-- 功能引导键一览：
-- cb = "连续自然数立方和(从1开始)"
-- fp = "连续自然数4次方之和(从1开始)"
-- sq = "连续自然数平方和(从1开始)"
-- tx = "已知数列的任意两项aᵢ、aₖ，求其通项公式"
-- avg = "平均值"
-- cos = "余弦"
-- deg = "弧度转换为角度"
-- dds = "顶点式求解二次函数解析式"
-- dxf = "点斜法求解一次函数解析式"
-- ecb = "前n个偶数的立方和"
-- efp = "前n个偶数的4次方之和"
-- esq = "前n个偶数的平方和"
-- exp = "返回 e^x"
-- gbs = "计算多个数的最小公倍数"
-- gys = "计算多个数的最大公因数"
-- hls = "计算行列式"
-- ldf = "两点法求解一次函数解析式"
-- ld1 = "已知两点坐标，求两点间的距离"
-- ld2 = "已知两点坐标，求两点间线段的垂直平分线方程"
-- ld3 = "已知两点P(x₁, y₁)和Q(x₂, y₂)，求点P绕点Q旋转角度a(角度制)后的P'坐标"
-- log = "x作为底数的对数"
-- mod = "求余函数"
-- ocb = "前n个奇数的立方和"
-- ofp = "前n个奇数的4次方之和"
-- osq = "前n个奇数的平方和"
-- pls = "计算排列数"
-- rad = "角度转换为弧度"
-- sin = "正弦"
-- sjs = "随机数"
-- tan = "正切"
-- var = "方差"
-- ybs = "一般式求解二次函数解析式"
-- zhs = "计算组合数"
-- acos = "反余弦"
-- asin = "反正弦"
-- atan = "反正切"
-- cesd = "已知圆上不同三点的坐标，求圆方程"
-- cexl = "已知圆心和圆上不同两点的坐标求圆方程"
-- cexr = "已知圆心坐标和半径求圆的方程"
-- cosh = "双曲余弦"
-- dbsl = "已知等比数列的首项a₁，公比q，求指定的前n项和"
-- dcsl = "已知等差数列的首项a₁，公差d，求指定的前n项和"
-- eyyc = "求解二元一次方程组"
-- fact = "阶乘"
-- lzx1 = "已知两直线方程A₁x+B₁y+C₁=0和A₂x+B₂y+C₂=0，判断它们的位置关系"
-- lzx2 = "已知直线l₁:A₁x+B₁y+C₁=0和l₂:A₂x+B₂y+C₂=0，求两条直线以彼此为轴的对称直线方程"
-- loge = "e作为底数的对数"
-- logt = "10作为底数的对数"
-- sinh = "双曲正弦"
-- sjxx = "已知三角形三个顶点坐标，求其“心”的坐标"
-- sjx1 = "已知三角形的三边长a、b、c，求三角形面积"
-- sjx2 = "已知三角形的三个顶点坐标(x₁,y₁)，(x₂,y₂)，(x₃,y₃)，求三角形面积"
-- sqrt = "计算x平方根或虚根"
-- tanh = "双曲正切"
-- tcr1 = "已知两圆一般方程x²+y²+D₁x+E₁y+F₁=0和x²+y²+D₂x+E₂y+F₂=0，判断它们的位置关系"
-- tcr2 = "已知两圆标准方程(x-x₁)²+(y-y₁)²=r₁²和(x-x₂)²+(y-y₂)²=r₂²，判断它们的位置关系"
-- yyec = "求解一元二次方程"
-- yyyc = "求解一元一次方程"
-- xsqz = "向上取整"
-- xxqz = "向下取整"
-- zdbx = "已知边数n与边长a计算正多边形面积"
-- atan2 = "返回以弧度为单位的点(x,y)相对于x轴的逆时针角度"
-- dyzx1 = "已知一点坐标和直线方程，求点到直线的距离及对称点坐标"
-- dyzx2 = "已知一点P(x₁,y₁)和直线l:Ax+By+C=0，求直线l关于点P的对称直线l'的方程"
-- ldexp = "返回 x*2^y"
-- nroot = "计算 x 开 N 次方"
-- sjxy1 = "已知三角形三边长，求内切圆半径和外接圆半径"
-- sjxy2 = "已知三角形三个顶点坐标，求内切圆半径和外接圆半径"
-- yysc1 = "求解一元三次方程"
-- yysc2 = "求解一元四次方程"


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


-- 实现计算输入
function replaceToFactorial(str)
    return str:gsub("([0-9]+)!", "fact(%1)")
end



-- 保留返回值的非零有效数字(返回结果为数字)
function fn(n)
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



-- 四舍五入保留小数点后n位
function round(m,n)
    local factor = 10 ^ n
    return floor(m * factor + 0.5) / factor
end




-- 计算两个数的最大公因数（GCD）
function gcd(a, b)
    while b ~= 0 do
        local temp = b
        b = a % b
        a = temp
    end
    return a
end




-- 计算两个数的最小公倍数（LCM）
function lcm(a, b)
    return a * b / gcd(a, b)
end




-- random([m [,n ]]) 返回m-n之间的随机数，n为空则返回1-m之间，都为空则返回0-1之间的小数
function random(...) return math.random(...) end
-- 注册到函数表中
calc_methods["sjs"] = random
methods_desc["sjs"] = "随机数"



-- 计算开 N 次方
function nth_root(x, n)
    if n % 2 == 0 and x < 0 then
        return nil -- 偶次方时负数没有实数解
    elseif x < 0 then
        return -((-x)^(1/n))
    else
        return x^(1/n)
    end
end
calc_methods["nroot"] = nth_root
methods_desc["nroot"] = "计算 x 开 N 次方"




-- 正弦
function sin(x) return math.sin(x) end
calc_methods["sin"] = sin
methods_desc["sin"] = "正弦"




-- 双曲正弦
function sinh(x)
    return (math.exp(x) - math.exp(-x)) / 2
end
calc_methods["sinh"] = sinh
methods_desc["sinh"] = "双曲正弦"




-- 反正弦
function asin(x) return math.asin(x) end
calc_methods["asin"] = asin
methods_desc["asin"] = "反正弦"




-- 余弦
function cos(x) return math.cos(x) end
calc_methods["cos"] = cos
methods_desc["cos"] = "余弦"




-- 双曲余弦
function cosh(x)
    return (math.exp(x) + math.exp(-x)) / 2
end
calc_methods["cosh"] = cosh
methods_desc["cosh"] = "双曲余弦"




-- 反余弦
function acos(x) return math.acos(x) end
calc_methods["acos"] = acos
methods_desc["acos"] = "反余弦"




-- 正切
function tan(x) return math.tan(x) end
calc_methods["tan"] = tan
methods_desc["tan"] = "正切"




-- 双曲正切
function tanh(x)
    local e = math.exp(2 * x)
    return (e - 1) / (e + 1)
end
calc_methods["tanh"] = tanh
methods_desc["tanh"] = "双曲正切"




-- 反正切
function atan(x) return math.atan(x) end
calc_methods["atan"] = atan
methods_desc["atan"] = "反正切"




-- 返回以弧度为单位的点(x,y)相对于x轴的逆时针角度。y是点的纵坐标，x是点的横坐标
-- 返回范围从−π到π （以弧度为单位），其中负角度表示向下旋转，正角度表示向上旋转
-- 它与传统的 math.atan(y/x) 函数相比，具有更好的数学定义，因为它能够正确处理边界情况（例如x=0）
function atan2(y, x)
    if x == 0 and y == 0 then
        return 0/0 -- 返回NaN
    elseif x == 0 and y ~= 0 then
        if y > 0 then
            return math.pi/2
        else
            return -math.pi/2
        end
    else
        return math.atan(y/x) + (x < 0 and math.pi or 0)
    end
end
calc_methods["atan2"] = atan2
methods_desc["atan2"] = "返回以弧度为单位的点(x,y)相对于x轴的逆时针角度"




-- 将角度从弧度转换为度
function deg(x) return math.deg(x) end
calc_methods["deg"] = deg
methods_desc["deg"] = "弧度转换为角度"




-- 将角度从度转换为弧度
function rad(x) return math.rad(x) end
calc_methods["rad"] = rad
methods_desc["rad"] = "角度转换为弧度"




-- 返回 x*2^y
function ldexp(x, y) return x * 2 ^ y end
calc_methods["ldexp"] = ldexp
methods_desc["ldexp"] = "返回 x*2^y"




-- 返回 e^x
function exp(x)
    -- 检查参数正确性
    if type(x) ~= "number" then
        return "参数必须是数字"
    end
    return math.exp(x)
end
calc_methods["exp"] = exp
methods_desc["exp"] = "返回 e^x"




-- 如果x>=0，返回x的平方根; 如果x<0，则返回虚数根
function sqrt(x)
    -- 检查参数正确性
    if type(x) ~= "number" then
        return "参数必须是数字"
    end
    local s
    if x < 0 and x ~= -1 then
        s = fn(math.sqrt(-x))
        return "±"..s.."i"
    elseif x == -1 then
        return "±i"
    elseif x == 0 then
        return 0
    else
        s = fn(math.sqrt(x))
        return "±"..s
    end
end
calc_methods["sqrt"] = sqrt
methods_desc["sqrt"] = "计算x平方根或虚根"




-- x为底的对数， log(10, 100) = log(100) / log(10) = 2
function log(x, y)
    -- 不能为负数或0
    if x <= 0 or y <= 0 then
        return nil
    end
    return math.log(y)/math.log(x)
end
calc_methods["log"] = log
methods_desc["log"] = "x作为底数的对数"




-- 自然数e为底的对数
function loge(x)
    -- 不能为负数或0
    if x <= 0 then
        return nil
    end
    return math.log(x)
end
calc_methods["loge"] = loge
methods_desc["loge"] = "e作为底数的对数"




-- 10为底的对数
function logt(x)
    -- 不能为负数或0
    if x <= 0 then
        return nil 
    end
    return math.log(x)/math.log(10)
end
calc_methods["logt"] = logt
methods_desc["logt"] = "10作为底数的对数"




-- 平均值
function avg(...)
    local data,n,sum
    data = {...}
    n = #data
    sum = 0
    -- 样本数量不能为0
    if n == 0 then
        return nil 
    end
    -- 计算总和
    for _, value in ipairs(data) do
        sum = sum + value
    end
    return fn(sum/n)
end
calc_methods["avg"] = avg
methods_desc["avg"] = "平均值"




-- 方差
function variance(...)
    local data,n,sum,mean,sum_squared_diff
    data = {...}
    n = #data
    sum = 0
    sum_squared_diff = 0
    -- 样本数量不能为0
    if n == 0 then
        return nil
    end
    -- 计算均值
    for _, value in ipairs(data) do
        sum = sum + value
    end
    mean = sum / n
    -- 计算方差
    for _, value in ipairs(data) do
        sum_squared_diff = sum_squared_diff + (value - mean) ^ 2
    end
    return fn(sum_squared_diff/n)
end
calc_methods["var"] = variance
methods_desc["var"] = "方差"




-- 阶乘
function factorial(x)
    -- 不能为负数
    if x < 0 then
        return nil
    elseif x == 0 or x == 1 then
        return 1
    end
    local result = 1
    for i = 1, x do
        result = result * i
    end
    return fn(result)
end
calc_methods["fact"] = factorial
methods_desc["fact"] = "阶乘"




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
    return fn(result)
end
calc_methods["mod"] = remainder
methods_desc["mod"] = "求余函数"




-- 连续自然数平方和(从1开始)
function sum_of_squares(n)
    -- 检查参数
    if type(n) ~= "number" or n < 1 or n~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- 计算平方和
    local result = n*(n+1)*(2*n+1)/6
    return fn(result)
end
calc_methods["sq"] = sum_of_squares
methods_desc["sq"] = "连续自然数平方和(从1开始)"




-- 连续自然数立方和(从1开始)
function sum_of_cubes(n)
    -- 检查参数
    if type(n) ~= "number" or n < 1 or n~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- 计算立方和
    local result = (n*(n+1))^2/4
    return fn(result)
end
calc_methods["cb"] = sum_of_cubes
methods_desc["cb"] = "连续自然数立方和(从1开始)"




-- 连续自然数4次方之和(从1开始)
function sum_of_fourth_powers(n)
    -- 检查参数
    if type(n) ~= "number" or n < 1 or n~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- 计算4次方和
    local result = n*(n+1)*(2*n+1)*(3*n^2+3*n-1)/30
    return fn(result)
end
calc_methods["fp"] = sum_of_fourth_powers
methods_desc["fp"] = "连续自然数4次方之和(从1开始)"




-- 前n个奇数的平方和
function sum_of_odd_squares(n)
    -- 检查参数
    if type(n) ~= "number" or n < 1 or n~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- 计算平方和
    local result = n*(4*n^2-1)/3
    return fn(result)
end
calc_methods["osq"] = sum_of_odd_squares
methods_desc["osq"] = "前n个奇数的平方和"




-- 前n个偶数的平方和
function sum_of_even_squares(n)
    -- 检查参数
    if type(n) ~= "number" or n < 1 or n~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- 计算平方和
    local result = 2*n*(n+1)*(2*n+1)/3
    return fn(result)
end
calc_methods["esq"] = sum_of_even_squares
methods_desc["esq"] = "前n个偶数的平方和"




-- 前n个奇数的立方和
function sum_of_odd_cubes(n)
    -- 检查参数
    if type(n) ~= "number" or n < 1 or n~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- 计算立方和
    local result = n^2*(2*n^2-1)
    return fn(result)
end
calc_methods["ocb"] = sum_of_odd_cubes
methods_desc["ocb"] = "前n个奇数的立方和"




-- 前n个偶数的立方和
function sum_of_even_cubes(n)
    -- 检查参数
    if type(n) ~= "number" or n < 1 or n~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- 计算立方和
    local result = 2*(n*(n+1))^2
    return fn(result)
end
calc_methods["ecb"] = sum_of_even_cubes
methods_desc["ecb"] = "前n个偶数的立方和"




-- 前n个奇数的4次方之和
function sum_of_odd_fourth_powers(n)
    -- 检查参数
    if type(n) ~= "number" or n < 1 or n~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- 计算4次方和
    local result = (48*n^5-40*n^3+7*n)/15
    return fn(result)
end
calc_methods["ofp"] = sum_of_odd_fourth_powers
methods_desc["ofp"] = "前n个奇数的4次方之和"




-- 前n个偶数的4次方之和
function sum_of_even_fourth_powers(n)
    -- 检查参数
    if type(n) ~= "number" or n < 1 or n~= floor(n) then
        return "错误：参数必须为正整数"
    end
    -- 计算4次方和
    local result = 8*n*(n+1)*(2*n+1)*(3*n^2+3*n-1)/15
    return fn(result)
end
calc_methods["efp"] = sum_of_even_fourth_powers
methods_desc["efp"] = "前n个偶数的4次方之和"




-- 圆的标准方程的表达式优化
function CircleStandardEquation(h, k, r_squared)
    local standardEquation
    if h == 0 then
        if k > 0 then
            standardEquation = "x²+(y-"..k..")²="..r_squared
        elseif k == 0 then
            standardEquation = "x²+y²="..r_squared
        else
            standardEquation = "x²+(y+"..-k..")²="..r_squared
        end
    elseif k == 0 then
        if h > 0 then
            standardEquation = "(x-"..h..")²+y²="..r_squared
        elseif h == 0 then
            standardEquation = "x²+y²="..r_squared
        else
            standardEquation = "(x+"..-h..")²+y²="..r_squared
        end
    else
        if h > 0 and k > 0 then
            standardEquation = "(x-"..h.. ")²+(y-"..k..")²=".. r_squared
        elseif h > 0 and k < 0 then
            standardEquation = "(x-"..h.. ")²+(y+"..-k..")²="..r_squared
        elseif h < 0 and k > 0 then
            standardEquation = "(x+"..-h..")²+(y-"..k..")²="..r_squared
        else
            standardEquation = "(x+"..-h..")²+(y+"..-k..")²=".. r_squared
        end
    end
    return standardEquation
end




-- 圆的一般方程表达式优化
function CircleGeneralEquation(D, E, F)
    local generalEquation = "x²+y²"
    -- 处理D项
    if D ~= 0 then
        if D == -1 then
            generalEquation = generalEquation.."-x"
        elseif D == 1 then
            generalEquation = generalEquation.."+x"
        elseif D > 0 then
            generalEquation = generalEquation.."+"..D.."x"
        else
            generalEquation = generalEquation.."-"..-D.."x"
        end
    end
    -- 处理E项
    if E ~= 0 then
        if E == -1 then
            generalEquation = generalEquation.."-y"
        elseif E == 1 then
            generalEquation = generalEquation.."+y"
        elseif E > 0 then
            generalEquation = generalEquation.."+"..E.."y"
        else
            generalEquation = generalEquation.."-"..-E.."y"
        end
    end
    -- 处理F项
    if F ~= 0 then
        if F > 0 then
            generalEquation = generalEquation.."+"..F.."=0"
        else
            generalEquation = generalEquation.."-"..-F.."=0"
        end
    end
    return generalEquation
end




-- 直线方程(斜截式)表达式优化
function LineEquation(x1, y1, k)
    local equation,b
    -- 特殊情况
    if k == nil then
        return "x="..x1
    else
        equation = "y="
    end
    if k == 0 then
        equation = equation..y1
        return equation
    end
    -- 计算截距b
    b = fn(y1-k*x1)
    -- 优化k的表示
    if k == -1 then
        equation = equation.."-x"
    elseif k == 1 then
        equation = equation.."x"
    else
        if k > 0 then
            equation = equation..k.."x"
        else
            equation = equation.."-"..-k.."x"
        end
    end
    -- 优化b的表示
    if b ~= 0 then
        if b > 0 then
            equation = equation.."+"..b
        else
            equation = equation .."-"..-b
        end
    end
    return equation
end





-- 直线方程(一般式)表达式优化
function LineGeneralEquation(A, B, C)
    -- 检查参数正确性
    if A == 0 and B == 0 then
        return "错误：直线方程系数A和B不能同时为0"
    end
    -- 求最大公约数，简化系数
    local s,result
    s = gcd_multiple(math.abs(A), math.abs(B),math.abs(C))
    if A < 0 then
        A = -A
        B = -B
        C = -C
    end
    A = fn(A/s)
    B = fn(B/s)
    C = fn(C/s)
    if A ~= 0 and B == 0 and C == 0 then
        result = "x=0"
    end
    if A ~= 0 and B == 0 and C ~= 0 then
        result = "x="..fn(-C/A)
    end
    if A == 0 and B ~= 0 and C == 0 then
        result = "y=0"
    end
    if A == 0 and B ~= 0 and C ~= 0 then
        result = "y="..fn(-C/B)
    end
    if A ~= 0 and B ~= 0 then
        if A == 1 then
            result = "x"
        else
            result = A.."x"
        end
        if B == 1 then
            result = result.."+y"
        elseif B == -1 then
            result = result.."-y"
        elseif B > 0 then
            result = result.."+"..B.. "y"
        else
            result = result.."-"..-B.."y"
        end
        if C ~= 0 then
            if C > 0 then
                result = result.."+"..C.."=0"
            else
                result = result.."-"..-C.."=0"
            end
        else
            result = result.."=0"
        end
    end
    return result
end




-- 二次函数表达式优化
function QuadraticEquation(a,b,c)
    local result = "y="
    -- 格式化a的值
    if a ~= 0 then
        if a == 1 then
            result = result.."x²"
        elseif a == -1 then
            result = result.."-x²"
        else
            result = result..a.."x²"
        end
    end
    -- 格式化b的值
    if b ~= 0 then
        if b == 1 then
            result = result.."+x"
        elseif b == -1 then
            result = result.."-x"
        elseif b > 0 then
            result = result.."+"..b.."x"
        else
            result = result.."-"..-b.."x"
        end
    end
    -- 格式化c的值
    if c ~= 0 then
        if c > 0 then
            result = result.."+"..c
        else
            result = result.."-"..-c
        end
    end
    return result
end




-- 已知正多边形边数n和边长a，计算正多边形面积
function calculateRegularPolygonArea(n, a)
    -- 检查参数正确性
    if type(n) ~= "number" or type(a) ~= "number" or n ~= floor(n) or n < 1 or a <= 0 then
        return "错误：边数n必须为正整数，边长a必须为正数"
    end
    -- 计算正多边形的面积
    local s = (n*a^2)/(4*math.tan(math.pi/n))
    return fn(s)
end
calc_methods["zdbx"] = calculateRegularPolygonArea
methods_desc["zdbx"] = "已知边数n与边长a计算正多边形面积"




-- 已知等比数列的首项a₁，公比q，求指定的前n项和
function geometricSeriesSum(a1, q, n)
    -- 检查参数正确性
    if type(a1) ~= "number" or type(q) ~= "number" or type(n) ~= "number" or n ~= floor(n) or n < 1 then
        return "错误：a₁、q、n必须为数字且n是正整数"
    end
    -- 计算前n项和
    if a1 == 0 then
        return 0
    elseif q == 0 and a1 ~= 0 then
        return a1
    elseif q == 1 then
        return a1*n
    else
        local s = a1*(1-q^n)/(1-q)
        return fn(s)
    end
end
calc_methods["dbsl"] = geometricSeriesSum
methods_desc["dbsl"] = "已知等比数列的首项a₁，公比q，求指定的前n项和"




-- 已知等差数列的首项a₁，公差d，求指定的前n项和
function ArithmeticSeriesSum(a1, d, n)
    -- 检查参数正确性
    if type(a1) ~= "number" or type(d) ~= "number" or type(n) ~= "number" or n ~= floor(n) or n < 1 then
        return "错误：a₁、d、n必须为数字且n是正整数"
    end
    -- 计算前n项和
    if a1 == 0 and d == 0 then
        return 0
    elseif a1 ~= 0 and d == 0 then
        return a1*n
    else
        local s = n*a1+n*(n-1)*d/2
        return fn(s)
    end
end
calc_methods["dcsl"] = ArithmeticSeriesSum
methods_desc["dcsl"] = "已知等差数列的首项a₁，公差d，求指定的前n项和"




-- 已知数列中任意两项aᵢ、aₖ，求通项公式
-- 对应项数分别为i、k
-- b=0为等差数列，b=1为等比数列
function findSequenceFormula(i, ai, k, ak, b)
    -- 检查参数正确性
    if type(i) ~= "number" or i ~= floor(i) or i < 1 or type(k) ~= "number" or k ~= floor(k) or k < 1 then
        return "错误：i 和 k 必须是正整数"
    end
    if ai == ak and i == k then
        return "错误：aᵢ、aₖ 和对应的项数不能同时相等"
    elseif ai ~= ak and i == k then
        return "错误：同一项数对应不同的项值"
    end
    -- 计算等差数列的通项公式
    function arithmeticSequence(i, ai, k, ak)
        local d,a1,s
        d = fn((ak-ai)/(k-i))
        a1 = ai-(i-1)*d
        s = fn(a1-d)
        if d == 0 then
            return "aₙ="..a1
        elseif d == 1 then
            if s == 0 then
                return "aₙ=n"
            elseif s > 0 then
                return "aₙ=n+"..s
            else
                return "aₙ=n-"..-s
            end
        elseif d == -1 then
            if s == 0 then
                return "aₙ=-n"
            elseif s > 0 then
                return "aₙ=-n+"..s
            else
                return "aₙ=-n-"..-s
            end
        else
            if s == 0 then
                return "aₙ="..d.."n"
            elseif s > 0 then
                return "aₙ="..d.."n+"..s
            else
                return "aₙ="..d.."n-"..-s
            end            
        end
    end
    -- 计算等比数列的通项公式
    function geometricSequence(i, ai, k, ak)
        if ai == 0 or ak == 0 then
            return "错误：等比数列中不能有0项"
        end
        local s,q,n,a1
        s = fn(ak/ai)
        n = fn(k-i)
        if s < 0 and n % 2 == 0 then
            return "无法求解通项公式"
        end
        q = fn(nth_root(s, n))
        a1 = fn(ai/(q^(i-1)))
        if a1 == q then
            if q == 1 then
                return "aₙ="..q
            elseif q > 0 then
                return "aₙ="..q.."ⁿ"
            elseif q < 0 then
                return "aₙ=("..q..")ⁿ"
            end
        elseif a1 == -q then
            if q == 1 then
                return "aₙ=-"..q
            elseif q == -1 then
                return "aₙ=("..q..")ⁿ⁻¹"
            elseif q > 0 then
                return "aₙ=-"..q.."ⁿ"
            else
                return "aₙ=-("..q..")ⁿ"
            end
        else
            if q > 0 then
                if a1 == 1 then
                    return "aₙ="..q.."ⁿ⁻¹"
                elseif a1 == -1 then
                    return "aₙ=-"..q.."ⁿ⁻¹"
                else
                    return "aₙ="..a1.."×"..q.."ⁿ⁻¹"
                end
            else
                if a1 == 1 then
                    return "aₙ=("..q..")ⁿ⁻¹"
                elseif a1 == -1 then
                    return "aₙ=-("..q..")ⁿ⁻¹"
                else
                    return "aₙ="..a1.."×("..q..")ⁿ⁻¹"
                end
            end
        end
    end
    -- 根据b值返回通项公式
    if b == 0 then
        return arithmeticSequence(i, ai, k, ak)
    elseif b == 1 then
        return geometricSequence(i, ai, k, ak)
    else
        return "错误：参数b必须是0或1"
    end
end
calc_methods["tx"] = findSequenceFormula
methods_desc["tx"] = "已知数列的任意两项aᵢ、aₖ及对应的项数i、k，求其通项公式"




-- 已知圆心坐标(h,k)和半径r，求圆的标准方程和一般方程
function CircleEquationsxr(h, k, r)
    -- 检查半径是否为正数
    if r <= 0 then
        return "错误：半径必须大于0"
    end
    -- 圆的标准方程
    local r_squared,se,ge,D,E,F
    r_squared = fn(r^2)
    se = CircleStandardEquation(h, k, r_squared)
    -- 圆的一般方程
    D = fn(-2*h)
    E = fn(-2*k)
    F = fn(h^2+k^2-r^2)
    ge = CircleGeneralEquation(D, E, F)
    -- 返回两个方程
    return "标准方程: "..se.."\n一般方程: "..ge
end
calc_methods["cexr"] = CircleEquationsxr
methods_desc["cexr"] = "已知圆心坐标和半径求圆的方程"




-- 已知圆心坐标(h,k)和圆上不同两点(x₁,y₁),(x₂,y₂)，求圆的标准方程和一般方程
function CircleEquationsxl(h ,k ,x1, y1, x2, y2)
    -- 检查三个坐标中是否有任意两个点坐标完全相同
    if (x1 == x2 and y1 == y2) or (x1 == h and y1 == k) or (x2 == h and y2 == k) then
        return "错误：三个坐标中不能有任意两个点坐标完全相同"
    end
    local distance1,distance2,r,r_squared,se,ge,D,E,F
    -- 计算两点到圆心的距离，并检查是否相等
    distance1 = math.sqrt((x1 - h)^2 + (y1 - k)^2)
    distance2 = math.sqrt((x2 - h)^2 + (y2 - k)^2)
    if distance1 ~= distance2 then
        return "错误：给定的圆心坐标和两个点无法构成圆"
    end
    -- 圆的标准方程
    r = distance1
    r_squared = fn(r^2)
    se = CircleStandardEquation(h, k, r_squared)
    -- 圆的一般方程
    D = fn(-2*h)
    E = fn(-2*k)
    F = fn(h^2+k^2-r_squared)
    ge = CircleGeneralEquation(D, E, F)
    -- 返回两个方程
    return "标准方程: "..se.."\n一般方程: "..ge
end
calc_methods["cexl"] = CircleEquationsxl
methods_desc["cexl"] = "已知圆心和圆上不同两点的坐标求圆方程"




-- 已知不共线的三点(x₁,y₁)，(x₂,y₂)，(x₃,y₃)，求过它们的圆的方程
function CircleEquationssd(x1, y1, x2, y2, x3, y3)
    local determinant,A,B,detA,detAD,detAE,detAF,D,E,F,ge,se,r_squared,h,k
    -- 检查三个点是否共线
    determinant = x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2)
    if determinant == 0 then
        return "错误：三个点共线或重合，无法构成圆"
    end
    -- 构建系数矩阵A和常数矩阵B
    A = {
        {x1, y1, 1},
        {x2, y2, 1},
        {x3, y3, 1}
    }
    B = {
        (-x1^2 - y1^2),
        (-x2^2 - y2^2),
        (-x3^2 - y3^2)
    }
    -- 计算系数矩阵A的行列式detA
    detA = hls(A[1][1],A[1][2],A[1][3],A[2][1],A[2][2],A[2][3],A[3][1],A[3][2],A[3][3])
    -- 计算D、E、F的行列式
    detAD = hls(B[1],A[1][2],A[1][3],B[2],A[2][2],A[2][3],B[3],A[3][2],A[3][3])
    detAE = hls(A[1][1],B[1],A[1][3],A[2][1],B[2],A[2][3],A[3][1],B[3],A[3][3])
    detAF = hls(A[1][1],A[1][2],B[1],A[2][1],A[2][2],B[2],A[3][1],A[3][2],B[3])
    -- 计算系数D、E、F
    D = fn(detAD/detA)
    E = fn(detAE/detA)
    F = fn(detAF/detA)
    -- 圆的一般方程
    ge = CircleGeneralEquation(D, E, F)
    -- 圆的标准方程
    h = fn(-D/2)
    k = fn(-E/2)
    r_squared = fn(h^2+k^2-F)
    se = CircleStandardEquation(h, k, r_squared)
    -- 返回两个方程
    return "标准方程: "..se.."\n一般方程: "..ge
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
        local x = fn(-b/a)
        return "x="..x
    end
end
calc_methods["yyyc"] = solveLinearEquation
methods_desc["yyyc"] = "求解一元一次方程"




-- 求解二元一次方程组：ax+by=e，cx+dy=f
function solveLinearSystem(a, b, c, d, e, f)
    local D,x,y
    -- 计算行列式D
    D = a*d-b*c
    -- 检查方程组是否有解
    if D == 0 then
        if (a*f-c*e) == 0 and (b*e-d*f) == 0 then
            return "方程组有无穷多解"
        else
            return "方程组无解"
        end
    end
    -- 计算x和y
    x = fn((d*e-b*f)/D)
    y = fn((a*f-c*e)/D)
    -- 返回解的字符串表示
    return "x="..x.."\ny="..y
end
calc_methods["eyyc"] = solveLinearSystem
methods_desc["eyyc"] = "求解二元一次方程组"




-- 点斜法求解一次函数解析式
-- 定义函数，输入斜率k和点的坐标(x₁, y₁)
function pointSlopeForm(k, x1, y1)
    local le = LineEquation(x1, y1, k)
    return "直线方程: "..le
end
calc_methods["dxf"] = pointSlopeForm
methods_desc["dxf"] = "点斜法求解一次函数解析式"




-- 两点法求解一次函数解析式
-- 定义函数，输入两点坐标(x₁, y₁)、(x₂,y₂)
function twoPointsForm(x1, y1, x2, y2)
    -- 检查两点是否相同
    if x1 == x2 and y1 == y2 then
        return "错误：两点坐标完全相同，无法确定直线方程"
    end
    local k,le
    -- 计算斜率k
    if x1 == x2 then
        k = nil
    else
        k = (y2 - y1) / (x2 - x1)
        k = fn(k)
    end
    le = LineEquation(x1, y1, k)
    return "直线方程: "..le
end
calc_methods["ldf"] = twoPointsForm
methods_desc["ldf"] = "两点法求解一次函数解析式"




-- 求解一元二次方程ax²+bx+c=0
function solveQuadraticEquation(a, b, c)
    -- 检查参数正确性
    if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" then
        return "错误：系数必须是数字"
    end
    if a == 0 then
        return "错误：二次项系数不能为0"
    end
    local Delta,x1,x2,P,Q
    Delta = b^2-4*a*c
    P = fn(-b/(2*a))
    if Delta == 0 then
        x1 = P
        return "x₁=x₂="..x1
    elseif Delta > 0 then
        Q = fn(math.sqrt(Delta)/(2*a))
        x1 = P+Q
        x2 = P-Q
    else
        Q = fn(math.sqrt(-Delta)/(2*a))
        if P == 0 then
            if Q == 1 then
                x1 = "i"
                x2 = "-i"
            elseif Q == -1 then
                x1 = "-i"
                x2 = "i"
            else
                x1 = Q.."i"
                x2 = -Q.."i"
            end
        else
            if Q == 1 then
                x1 = P.."+i"
                x2 = P.."-i"
            elseif Q == -1 then
                x1 = P.."-i"
                x2 = P.."+i"
            elseif Q > 0 then
                x1 = P.."+"..Q.."i"
                x2 = P.."-"..Q.."i"
            else
                x1 = P.."-"..-Q.."i"
                x2 = P.."+"..-Q.."i"
            end
        end
    end
    return "x₁="..x1.."\nx₂="..x2
end
calc_methods["yyec"] = solveQuadraticEquation
methods_desc["yyec"] = "求解一元二次方程"




-- 求解一元三次方程ax³+bx²+cx+d=0
function solveCubicEquation(a, b, c, d)
    -- 检查参数正确性
    if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" or type(d) ~= "number" then
        return "错误：系数必须是数字"
    end
    if a == 0 then
        return "错误：系数a不能为零"
    end
    -- 计算重根判别式
    local A,B,C,Delta
    A = b^2-3*a*c
    B = b*c-9*a*d
    C = c^2-3*b*d
    -- 计算总判别式
    Delta = B^2-4*A*C
    -- 根据盛金公式进行求解
    -- 情况1：A = B = 0，方程有一个三重实根
    if A == 0 and B == 0 then
        local x = fn(-b/(3*a))
        return "x₁=x₂=x₃=" .. x
    -- 情况2：Delta > 0，方程有一个实根和一对共轭虚根
    elseif Delta > 0 then
        local Y1,Y2,y1,y2,x1,x2,x3,P,Q
        Y1 = A*b+3*a*(-B+math.sqrt(Delta))/2
        Y2 = A*b+3*a*(-B-math.sqrt(Delta))/2
        y1 = nth_root(Y1, 3)
        y2 = nth_root(Y2, 3)
        x1 = fn((-b-y1-y2)/(3*a))
        P = fn((-b+0.5*(y1+y2))/(3*a))
        Q = fn((0.5*math.sqrt(3)*(y1-y2))/(3*a))
        if P == 0 then
            if Q == 1 then
                x2 = "i"
                x3 = "-i"
            elseif Q == -1 then
                x2 = "-i"
                x3 = "i"
            else
                x2 = Q.."i"
                x3 = -Q.."i"
            end
        elseif P ~= 0 and Q == 1 then
            x2 = P.."+i"
            x3 = P.."-i"
        elseif P ~= 0 and Q == -1 then
            x2 = P.."-i"
            x3 = P.."+i"
        elseif P ~= 0 and Q > 0 then
            x2 = P.."+"..Q.."i"
            x3 = P.."-"..Q.."i"
        elseif P ~= 0 and Q < 0 then
            x2 = P.."-"..-Q.. "i"
            x3 = P.."+"..-Q.. "i"
        end
        return "x₁="..x1.."\nx₂="..x2.."\nx₃="..x3
    -- 情况3：Delta = 0，方程有三个实根，其中有一个两重根
    elseif Delta == 0 and A ~= 0 then
        local K,x1,x2
        K = B/A
        x1 = fn(-b/a+K)
        x2 = fn(-0.5*K)
        return "x₁="..x1.."\nx₂=x₃="..x2
    elseif Delta < 0 and A > 0 then
        -- 情况4：Delta < 0，方程有三个不相等的实根
        local T,M,S,R,x1,x2,x3
        T = (2*A*b-3*a*B)/(2*math.sqrt(A^3))
        M = acos(T)
        S = cos(M/3)
        R = sin(M/3)
        x1 = fn((-b-2*math.sqrt(A)*S)/(3*a))
        x2 = fn((-b+math.sqrt(A)*(S+math.sqrt(3)*R))/(3*a))
        x3 = fn((-b+math.sqrt(A)*(S-math.sqrt(3)*R))/(3*a))
        return "x₁="..x1.."\nx₂="..x2.."\nx₃="..x3
    end
end
calc_methods["yysc1"] = solveCubicEquation
methods_desc["yysc1"] = "求解一元三次方程"




-- 求解一元四次方程ax⁴+bx³+cx²+dx+e=0
function solveQuarticEquation(a, b, c, d, e)
    -- 检查参数正确性
    if type(a) ~= "number" or type(b) ~= "number" or type(c) ~= "number" or type(d) ~= "number" or type(e) ~= "number" then
        return "错误：系数必须是数字"
    end
    if a == 0 then
        return "错误：系数a不能为零"
    end
    -- 计算重根判别式
    local D,E,F,A,B,C,Delta
    D = 3*b^2-8*a*c
    E = -b^3+4*a*b*c-8*a^2*d
    F = 3*b^4+16*a^2*c^2-16*a*b^2*c+16*a^2*b*d-64*a^3*e
    A = D^2-3*F
    B = D*F-9*E^2
    C = F^2-3*D*E^2
    -- 计算总判别式
    Delta = B^2-4*A*C
    -- 符号因子函数
    local function sgn(x)
        if x == 0 then
            return 0
        else
            return fn(math.abs(x)/x)
        end
    end
    -- 根据天珩公式求解四次方程
    -- 情况1:当D=E=F=0时，方程有一个四重实根
    if D == 0 and E == 0 and F == 0 then
        local x
        x = fn(-b/(4*a))
        return "x₁=x₂=x₃=x₄="..x
    end
    -- 情况2:当DEF≠0，A=B=C=0时，方程有四个实根，其中有一个三重根
    if (D*E*F ~= 0) and (A == 0 and B == 0 and C == 0) then
        local x1,x2
        x1 = fn((-b*D+9*E)/(4*a*D))
        x2 = fn((-b*D-3*E)/(4*a*D))
        return "x₁="..x1 .."\nx₂=x₃=x₄="..x2
    end
    -- 情况3:当E=F=0，D≠0时，方程有两对二重根；若D＞0，根为实数；若D＜0，根为虚数
    if E == 0 and F == 0 and D ~= 0 then
        local x1,x2,P,Q
        if D > 0 then
            x1 = fn((-b+math.sqrt(D))/(4*a))
            x2 = fn((-b-math.sqrt(D))/(4*a))
        else
            P = fn(-b/(4*a))
            Q = fn(math.sqrt(-D)/(4*a))
            if P == 0 then
                if Q == 1 then
                    x1 = "i"
                    x2 = "-i"
                elseif Q == -1 then
                    x1 = "-i"
                    x2 = "i"
                else
                    x1 = Q.."i"
                    x2 = -Q.."i"
                end
            else
                if Q == 1 then
                    x1 = P.."+i"
                    x2 = P.."-i"
                elseif Q == -1 then
                    x1 = P.."-i"
                    x2 = P.."+i"
                elseif Q > 0 then
                    x1 = P.."+"..Q.."i"
                    x2 = P.."-"..Q.."i"
                else
                    x1 = P.."-"..-Q.."i"
                    x2 = P.."+"..-Q.."i"
                end
            end
        end
        return "x₁=x₂="..x1.."\nx₃=x₄="..x2
    end
    -- 情况4:当ABC≠0，Δ=0时，方程有一对二重实根；
    -- 若AB＞0，则其余两根为不等实根；若AB＜0，则其余两根为共轭虚根
    if (A*B*C ~= 0) and (Delta == 0) then
        local P,Q,R,x1,x2,x3
        P = -b/(4*a)
        Q = 2*A*E/(4*a*B)
        x1 = fn(P-Q)
        if A*B > 0 then
            R = math.sqrt(2*B/A)/(4*a)
            x2 = fn(P+Q+R)
            x3 = fn(P+Q-R)
        else
            R = fn(math.sqrt(-2*B/A)/(4*a))
            if (P+Q) == 0 then
                if R == 1 then
                    x2 = "i"
                    x3 = "-i"
                elseif R == -1 then
                    x2 = "-i"
                    x3 = "i"
                else
                    x2 = R.."i"
                    x3 = -R.."i"
                end
            else
                if R == 1 then
                    x2 = fn(P+Q).."+i"
                    x3 = fn(P+Q).."-i"
                elseif R == -1 then
                    x2 = fn(P+Q).."-i"
                    x3 = fn(P+Q).."+i"
                elseif R > 0 then
                    x2 = fn(P+Q).."+"..R.."i"
                    x3 = fn(P+Q).."-"..R.."i"
                else
                    x2 = fn(P+Q).."-"..-R.."i"
                    x3 = fn(P+Q).."+"..-R.."i"
                end
            end
        end
        return "x₁=x₂="..x1.."\nx₃="..x2.."\nx₄="..x3
    end
    -- 情况5:当Δ>0时，方程有两个不等实根和一对共轭虚根
    if Delta > 0 then
        local z,z1,z2,z3,x1,x2,x3,x4,P,Q,R1,R2
        z1 = A*D+3*((-B+math.sqrt(Delta))/2)
        z2 = A*D+3*((-B-math.sqrt(Delta))/2)
        z3 = nth_root(z1,3) + nth_root(z2,3)
        z = D^2-D*z3+z3^2-3*A
        P = -b/(4*a)
        Q = sgn(E)*math.sqrt((D+z3)/3)/(4*a)
        R1 = math.sqrt((2*D-z3+2*math.sqrt(z))/3)/(4*a)
        R2 = fn(math.sqrt((-2*D+z3+2*math.sqrt(z))/3)/(4*a))
        x1 = fn(P+Q+R1)
        x2 = fn(P+Q-R1)
        if (P-Q) == 0 then
            if R2 == 1 then
                x3 = "i"
                x4 = "-i"
            elseif R2 == -1 then
                x3 = "-i"
                x4 = "i"
            else
                x3 = R2.."i"
                x4 = -R2.."i"
            end
        else
            if R2 == 1 then
                x3 = fn(P-Q).."+i"
                x4 = fn(P-Q).."-i"
            elseif R2 == -1 then
                x3 = fn(P-Q).."-i"
                x4 = fn(P-Q).."+i"
            elseif R2 > 0 then
                x3 = fn(P-Q).."+"..R2.."i"
                x4 = fn(P-Q).."-"..R2.."i"
            else
                x3 = fn(P-Q).."-"..-R2.."i"
                x4 = fn(P-Q).."+"..-R2.."i"
            end
        end
        return "x₁="..x1.."\nx₂="..x2.."\nx₃="..x3.."\nx₄="..x4
    end
    -- 情况6:当Δ<0时，若D与F均为正数，则方程有四个不等实根；否则方程有两对不等共轭虚根
    if Delta < 0 then
        local T,M,N,O,y1,y2,y3,x1,x2,x3,x4,P,Q1,Q2,Q3
        T = (3*B-2*A*D)/(2*A*math.sqrt(A))
        M = acos(T)
        N = cos(M/3)
        O = sin(M/3)
        y1 = (D-2*math.sqrt(A)*N)/3
        y2 = (D+math.sqrt(A)*(N+math.sqrt(3)*O))/3
        y3 = (D+math.sqrt(A)*(N-math.sqrt(3)*O))/3
        -- 情况6.1:若E=0,D>0,F>0,方程有四实根
        if E == 0 and D > 0 and F > 0 then
            x1 = fn((-b+math.sqrt(D+2*math.sqrt(F)))/(4*a))
            x2 = fn((-b-math.sqrt(D+2*math.sqrt(F)))/(4*a))
            x3 = fn((-b+math.sqrt(D-2*math.sqrt(F)))/(4*a))
            x4 = fn((-b-math.sqrt(D-2*math.sqrt(F)))/(4*a))
        -- 情况6.2:若E=0,D<0,F>0,方程有两对共轭虚根
        elseif E == 0 and D < 0 and F > 0 then
            P = fn(-b/(4*a))
            Q1 = fn(math.sqrt(-D+2*math.sqrt(F))/(4*a))
            Q2 = fn(math.sqrt(-D-2*math.sqrt(F))/(4*a))
            if P == 0 then
                if Q1 == 1 then
                    x1 = "i"
                    x2 = "-i"
                elseif Q1 == -1 then
                    x1 = "-i"
                    x2 = "i"
                else
                    x1 = Q1.."i"
                    x2 = -Q1.."i"
                end
                if Q2 == 1 then
                    x3 = "i"
                    x4 = "-i"
                elseif Q2 == -1 then
                    x3 = "-i"
                    x4 = "i"
                else
                    x3 = Q2.."i"
                    x4 = -Q2.."i"
                end
            else
                if Q1 == 1 then
                    x1 = P.."+i"
                    x2 = P.."-i"
                elseif Q1 == -1 then
                    x1 = P.."-i"
                    x2 = P.."+i"
                elseif Q1 > 0 then
                    x1 = P.."+"..Q1.."i"
                    x2 = P.."-"..Q1.."i"
                else
                    x1 = P.."-"..-Q1.."i"
                    x2 = P.."+"..-Q1.."i"
                end
                if Q2 == 1 then
                    x3 = P.."+i"
                    x4 = P.."-i"
                elseif Q2 == -1 then
                    x3 = P.."-i"
                    x4 = P.."+i"
                elseif Q2 > 0 then
                    x3 = P.."+"..Q2.."i"
                    x4 = P.."-"..Q2.."i"
                else
                    x3 = P.."-"..-Q2.."i"
                    x4 = P.."+"..-Q2.."i"
                end
            end
        -- 情况6.3:若E=0,F<0,方程有两对共轭虚根
        elseif E == 0 and F < 0 then
            P = -b/(4*a)
            Q1 = math.sqrt(2*D+2*math.sqrt(A-F))/(8*a)
            Q2 = fn(math.sqrt(-2*D+2*math.sqrt(A-F))/(8*a))
            if (P+Q1) == 0 then
                if Q2 == 1 then
                    x1 = "i"
                    x2 = "-i"
                elseif Q2 == -1 then
                    x1 = "-i"
                    x2 = "i"
                else
                    x1 = Q2.."i"
                    x2 = -Q2.."i"
                end
            else
                if Q2 == 1 then
                    x1 = fn(P+Q1).."+i"
                    x2 = fn(P+Q1).."-i"
                elseif Q2 == -1 then
                    x1 = fn(P+Q1).."-i"
                    x2 = fn(P+Q1).."+i"
                elseif Q2 > 0 then
                    x1 = fn(P+Q1).."+"..Q2.."i"
                    x2 = fn(P+Q1).."-"..Q2.."i"
                else
                    x1 = fn(P+Q1).."-"..-Q2.."i"
                    x2 = fn(P+Q1).."+"..-Q2.."i"
                end
            end
            if (P-Q1) == 0 then
                if Q2 == 1 then
                    x3 = "i"
                    x4 = "-i"
                elseif Q2 == -1 then
                    x3 = "-i"
                    x4 = "i"
                else
                    x3 = Q2.."i"
                    x4 = -Q2.."i"
                end
            else
                if Q2 == 1 then
                    x3 = fn(P-Q1).."+i"
                    x4 = fn(P-Q1).."-i"
                elseif Q2 == -1 then
                    x3 = fn(P-Q1).."-i"
                    x4 = fn(P-Q1).."+i"
                elseif Q2 > 0 then
                    x3 = fn(P-Q1).."+"..Q2.."i"
                    x4 = fn(P-Q1).."-"..Q2.."i"
                else
                    x3 = fn(P-Q1).."-"..-Q2.."i"
                    x4 = fn(P-Q1).."+"..-Q2.."i"
                end
            end
        -- 情况6.4:若E≠0,当D与F均为正时，方程有四实根；否则方程有两对共轭虚根
        elseif E ~= 0 then
            if D > 0 and F > 0 then
                P = -b/(4*a)
                Q1 = sgn(E)*math.sqrt(y1)/(4*a)
                Q2 = (math.sqrt(y2)+math.sqrt(y3))/(4*a)
                Q3 = (math.sqrt(y2)-math.sqrt(y3))/(4*a)
                x1 = fn(P+Q1+Q2)
                x2 = fn(P+Q1-Q2)
                x3 = fn(P-Q1+Q3)
                x4 = fn(P-Q1-Q3)
            else
                P = -b/(4*a)
                Q1 = math.sqrt(y2)/(4*a)
                Q2 = sgn(E)*math.sqrt(-y1)/(4*a)
                Q3 = math.sqrt(-y3)/(4*a)
                if (P-Q1) == 0 then
                    if (Q2+Q3) == 1 then
                        x1 = "i"
                        x2 = "-i"
                    elseif (Q2+Q3) == -1 then
                        x1 = "-i"
                        x2 = "i"
                    else
                        x1 = fn(Q2+Q3).."i"
                        x2 = -fn(Q2+Q3).."i"                    
                    end
                else
                    if fn(Q2+Q3) == 1 then
                        x1 = fn(P-Q1).."+i"
                        x2 = fn(P-Q1).."-i"
                    elseif fn(Q2+Q3) == -1 then
                        x1 = fn(P-Q1).."-i"
                        x2 = fn(P-Q1).."+i"
                    elseif fn(Q2+Q3) > 0 then
                        x1 = fn(P-Q1).."+"..fn(Q2+Q3).."i"
                        x2 = fn(P-Q1).."-"..fn(Q2+Q3).."i"
                    else
                        x1 = fn(P-Q1).."-"..-fn(Q2+Q3).."i"
                        x2 = fn(P-Q1).."+"..-fn(Q2+Q3).."i"
                    end
                end
                if (P+Q1) == 0 then
                    if fn(Q2-Q3) == 1 then
                        x3 = "i"
                        x4 = "-i"
                    elseif fn(Q2-Q3) == -1 then
                        x3 = "-i"
                        x4 = "i"
                    else
                        x3 = fn(Q2-Q3).."i"
                        x4 = -fn(Q2-Q3).."i"
                    end
                else
                    if fn(Q2-Q3) == 1 then
                        x3 = fn(P+Q1).."+i"
                        x4 = fn(P+Q1).."-i"
                    elseif fn(Q2-Q3) == -1 then
                        x3 = fn(P+Q1).."-i"
                        x4 = fn(P+Q1).."+i"
                    elseif fn(Q2-Q3) > 0 then
                        x3 = fn(P+Q1).."+"..fn(Q2-Q3).."i"
                        x4 = fn(P+Q1).."-"..fn(Q2-Q3).."i"
                    else
                        x3 = fn(P+Q1).."-"..-fn(Q2-Q3).."i"
                        x4 = fn(P+Q1).."+"..-fn(Q2-Q3).."i"
                    end
                end
            end
        end
        return "x₁="..x1.."\nx₂="..x2.."\nx₃="..x3.."\nx₄="..x4
    end
end
calc_methods["yysc2"] = solveQuarticEquation
methods_desc["yysc2"] = "求解一元四次方程"




-- 顶点式求解二次函数解析式：y=a(x-h)²+k
-- (x₁,y₁)为顶点坐标，(x₂,y₂)为其函数图像上除顶点坐标外任意一点坐标
function getQuadraticEquationdd(x1, y1, x2, y2)
    -- 检查两个点是否相同
    if x1 == x2 or y1 == y2 then
        return "错误：两个点的横坐标不能相同"
    end
    local a,b,c,qe
    a = fn((y2-y1)/(x2-x1)^2)
    b = fn(-2*a*x1)
    c = fn(y1+a*x1^2)
    qe = QuadraticEquation(a,b,c)
    return "二次函数解析式为："..qe
end
calc_methods["dds"] = getQuadraticEquationdd
methods_desc["dds"] = "顶点式求解二次函数解析式"




-- 一般式求解二次函数解析式
function getQuadraticEquationy(x1, y1, x2, y2, x3, y3)
    local A,B,detA,detAx,detAy,detAz,a,b,c,qe,determinant
    -- 检查三个点是否共线
    determinant = x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2)
    if determinant == 0 then
        return "错误：三个点共线或重合，无法求解二次函数解析式"
    end
    -- 构建方程组的系数矩阵和常数矩阵
    A = {
        {x1^2, x1, 1},
        {x2^2, x2, 1},
        {x3^2, x3, 1}
    }
    B = {
        (y1), 
        (y2), 
        (y3)
    }
    -- 计算系数矩阵A的行列式detA
    detA = hls(A[1][1], A[1][2], A[1][3], A[2][1], A[2][2], A[2][3], A[3][1], A[3][2], A[3][3])
    -- 计算行列式detAx，detAy，detAz
    detAx = hls(B[1], A[1][2], A[1][3], B[2], A[2][2], A[2][3], B[3], A[3][2], A[3][3])
    detAy = hls(A[1][1], B[1], A[1][3], A[2][1], B[2], A[2][3], A[3][1], B[3], A[3][3])
    detAz = hls(A[1][1], A[1][2], B[1], A[2][1], A[2][2], B[2], A[3][1], A[3][2], B[3])
    -- 计算系数a，b，c
    a = fn(detAx/detA)
    b = fn(detAy/detA)
    c = fn(detAz/detA)
    qe = QuadraticEquation(a,b,c)
    return "二次函数解析式为："..qe
end
calc_methods["ybs"] = getQuadraticEquationy
methods_desc["ybs"] = "一般式求解二次函数解析式"




-- 已知三角形的三边a、b、c，求三角形面积
function calculateTriangleArea(a, b, c)
    -- 检查是否能构成三角形
    if a + b <= c or a + c <= b or b + c <= a then
        return "错误：不能构成三角形"
    end
    local p,s
    -- 计算半周长
    p = (a+b+c)/2
    -- 使用海伦公式计算面积
    s = math.sqrt(p*(p-a)*(p-b)*(p-c))
    return fn(s)
end
calc_methods["sjx1"] = calculateTriangleArea
methods_desc["sjx1"] = "已知三角形的三边长a、b、c，求三角形面积"




-- 已知三角形的三个顶点坐标(x₁, y₁)，(x₂, y₂)，(x₃, y₃)，求三角形面积
function calculateTriangleArea2(x1, y1, x2, y2, x3, y3)
    -- 检查参数正确性
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(x3) ~= "number" or type(y3) ~= "number" then
        return "错误：参数必须是数字"
    end
    local determinant,s
    determinant = x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2)
    -- 检查是否能构成三角形
    if determinant == 0 then
        return "错误：三个点重合或共线，不能构成三角形"
    end
    -- 计算三角形面积
    s = fn(math.abs(determinant/2))
    return s
end
calc_methods["sjx2"] = calculateTriangleArea2
methods_desc["sjx2"] = "已知三角形的三个顶点坐标(x₁,y₁)，(x₂,y₂)，(x₃,y₃)，求三角形面积"




-- 已知一点(x₁, y₁)和直线方程Ax+By+C=0，求点到直线的距离和它关于直线的对称点坐标
function dyzx1(x1, y1, A, B, C)
    -- 检查参数正确性
    if type(x1) ~= "number" or type(y1) ~= "number" or type(A) ~= "number" or type(B) ~= "number" or type(C) ~= "number" then
        return "错误：参数必须是数字"
    end
    if A == 0 and B == 0 then
        return "错误：直线方程的系数不能同时为零"
    end
    local S,D,s,x,y
    -- 判断点是否在直线上
    S = A*x1+B*y1+C
    if S == 0 then
        return "点在直线上，距离为0，无法求解对称点坐标"
    end
    -- 计算点到直线的距离
    D = fn(math.abs(S)/math.sqrt(A^2+B^2))
    -- 计算对称点坐标
    s = S/(A^2+B^2)
    x = fn(x1-2*A*s)
    y = fn(y1-2*B*s)
    return "点到直线距离为"..D.."\n点关于直线的对称点坐标为("..x..","..y..")"
end
calc_methods["dyzx1"] = dyzx1
methods_desc["dyzx1"] = "已知一点坐标和直线方程，求点到直线的距离及对称点坐标"




-- 已知两点(x₁, y₁)和(x₂, y₂)，求两点间的距离
function ld1(x1, y1, x2, y2)
    -- 检查参数正确性
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" then
        return "错误：参数必须是数字"
    end
    -- 判断两点是否重合
    if x1 == x2 and y1 == y2 then
        return "两点重合，距离为0"
    end
    -- 计算两点间的距离
    local D = math.sqrt((x2-x1)^2+(y2-y1)^2)
    return fn(D)
end
calc_methods["ld1"] = ld1
methods_desc["ld1"] = "已知两点坐标，求两点间的距离"




-- 已知两点(x₁, y₁)和(x₂, y₂)，求两点连线的垂直平分线方程
function ld2(x1, y1, x2, y2)
    -- 检查参数正确性
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" then
        return "错误：参数必须是数字"
    end
    if x1 == x2 and y1 == y2 then
        return "错误：两点重合，无法求解垂直平分线方程"
    end
    local x3,y3,k,kl,se
    -- 两点所成线段的中点坐标
    x3 = fn((x1 + x2)/2)
    y3 = fn((y1 + y2)/2)
    if x1 == x2 then
        k = nil
        kl = 0
    else
        k = (y2-y1)/(x2-x1)
        if k == 0 then
            kl = nil
        else
            kl = -1/k
            kl = fn(kl)
        end
    end
    se = LineEquation(x3, y3, kl)
    return "垂直平分线方程为："..se
end
calc_methods["ld2"] = ld2
methods_desc["ld2"] = "已知两点坐标，求两点间线段的垂直平分线方程"




-- 已知两点P(x₁, y₁)和Q(x₂, y₂)，求点P绕点Q旋转角度a(角度制)后的P'坐标
-- 逆时针时a为正，顺时针时a为负
function ld3(x1, y1, x2, y2, a)
    -- 检查参数正确性
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(a) ~= "number" then
        return "错误：参数必须是数字"
    end
    -- 计算旋转角度的弧度值
    local a1,x,y
    a1 = rad(a)
    -- 计算旋转后的点坐标
    x = fn(x2+(x1-x2)*cos(a1)-(y1-y2)*sin(a1))
    y = fn(y2+(x1-x2)*sin(a1)+(y1-y2)*cos(a1))
    return "点P("..x1..","..y1..")绕点Q("..x2..","..y2..")旋转"..a.."°后的P'坐标为("..x..","..y..")"
end
calc_methods["ld3"] = ld3
methods_desc["ld3"] = "已知两点P(x₁, y₁)和Q(x₂, y₂)，求点P绕点Q旋转角度a(角度制)后的P'坐标"




-- 已知两条直线方程 A₁x+B₁y+C₁=0和 A₂x+B₂y+C₂=0，判断它们的位置关系
function lines_relationship(A1, B1, C1, A2, B2, C2)
    -- 参数正确性检查
    if (A1 == 0 and B1 == 0) or (A2 == 0 and B2 == 0) then
        return "错误：直线方程的系数不能同时为零"
    end
    local px,ch,D,x,y,k
    -- 判断两直线是否平行或重合的条件
    px = (A1*B2 == A2*B1) and (A1*C2 ~= A2*C1)
    ch = (A1*B2 == A2*B1) and (C1*B2 == C2*B1) and (C1*A2 == C2*A1)
    -- 两直线重合
    if ch then
        return "两直线重合，距离为0"
    -- 两直线平行但不重合，计算距离
    elseif px then
        if B1 ~= B2 then
            k = math.max(B1,B2)/math.min(B1,B2)
            if B1 < B2 then
                A1 = A1*k
                B1 = B1*k
                C1 = C1*k
            else
                C2 = C2*k
            end
        end
        D = fn(math.abs(C2-C1)/math.sqrt(A1^2+B1^2))
        return "两直线平行，距离为"..D
    -- 两直线相交，计算交点坐标
    else
        x = fn((B1*C2-B2*C1)/(A1*B2-A2*B1))
        y = fn((C1*A2-C2*A1)/(A1*B2-A2*B1))
        return "两直线相交，交点坐标为("..x..","..y..")"
    end
end
calc_methods["lzx1"] = lines_relationship
methods_desc["lzx1"] = "已知两直线方程A₁x+B₁y+C₁=0和A₂x+B₂y+C₂=0，判断它们的位置关系"




-- 已知三角形的三边a、b、c，求内切圆半径和外接圆半径
function triangle_circles(a, b, c)
    -- 参数正确性检查
    if a <= 0 or b <= 0 or c <= 0 then
        return "错误：边长必须为正数"
    end
    -- 检查能否构成三角形
    if a + b <= c or a + c <= b or b + c <= a then
        return "错误：给定的边长不能构成三角形"
    end
    local s,A,r,R
    -- 计算半周长
    s = (a+b+c)/2
    -- 计算面积
    A = math.sqrt(s*(s-a)*(s-b)*(s-c))
    -- 计算内切圆半径
    r = fn(A/s)
    -- 计算外接圆半径
    R = fn((a*b*c)/(4*A))
    return "内切圆半径为"..r.."\n外接圆半径为"..R
end
calc_methods["sjxy1"] = triangle_circles
methods_desc["sjxy1"] = "已知三角形三边长，求内切圆半径和外接圆半径"




-- 已知三角形三个顶点坐标(x₁,y₁)，(x₂,y₂)，(x₃,y₃)，求其内切圆半径和外接圆半径
function triangle_circles_by_points(x1, y1, x2, y2, x3, y3)
    -- 参数正确性检查
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(x3) ~= "number" or type(y3) ~= "number" then
        return "错误：参数必须是数字"
    end
    local a,b,c
    -- 检查三个点是否共线
    if x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2) == 0 then
        return "错误：三个点共线或重合，无法构成三角形"
    end
    -- 计算三边长
    a = ld1(x1, y1, x2, y2)
    b = ld1(x2, y2, x3, y3)
    c = ld1(x1, y1, x3, y3)
    -- 调用已知三边长的函数计算内切圆半径和外接圆半径
    return triangle_circles(a, b, c)
end
calc_methods["sjxy2"] = triangle_circles_by_points
methods_desc["sjxy2"] = "已知三角形三个顶点坐标，求内切圆半径和外接圆半径"




-- 已知三角形三个顶点坐标A(x₁,y₁)，B(x₂,y₂)，C(x₃,y₃)，求其“心”的坐标
function triangle_centers(x1, y1, x2, y2, x3, y3)
    -- 参数正确性检查
    if type(x1) ~= "number" or type(y1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(x3) ~= "number" or type(y3) ~= "number" then
        return "错误：参数必须是数字"
    end
    local determinant,a,b,c,xg,yg,xn,yn,xw,yw,xc,yc,d1,s1,s2
    -- 检查三个点是否共线
    determinant = x1*(y2-y3)+x2*(y3-y1)+x3*(y1-y2)
    if determinant == 0 then
        return "错误：三个点共线或重合，无法构成三角形"
    end
    -- 计算三边长
    a = ld1(x2, y2, x3, y3)
    b = ld1(x1, y1, x3, y3)
    c = ld1(x1, y1, x2, y2)
    -- 计算重心坐标
    xg = fn((x1+x2+x3)/3)
    yg = fn((y1+y2+y3)/3)
    -- 计算内心坐标
    xn = fn((a*x1+b*x2+c*x3)/(a+b+c))
    yn = fn((a*y1+b*y2+c*y3)/(a+b+c))
    -- 计算外心坐标
    d1 = 2*determinant
    xw = fn(((x1^2+y1^2)*(y2-y3)+(x2^2+y2^2)*(y3-y1)+(x3^2+y3^2)*(y1-y2))/d1)
    yw = fn(((x1^2+y1^2)*(x3-x2)+(x2^2+y2^2)*(x1-x3)+(x3^2+y3^2)*(x2-x1))/d1)
    -- 计算垂心坐标
    s1 = x1*(x2*(y1-y2)+x3*(y3-y1))+(y2-y3)*(x2*x3+(y1-y2)*(y1-y3))
    s2 = x1^2*(x2-x3)+x1*(x3^2-x2^2+y1*y2-y1*y3)+x2^2*x3-x2*(x3^2+y1*y2-y2*y3)+x3*y3*(y1-y2)
    xc = fn(s1/-determinant)
    yc = fn(s2/determinant)
    return "重心("..xg..","..yg..")\n内心("..xn..","..yn..")\n外心("..xw..","..yw..")\n垂心("..xc..","..yc..")"
end
calc_methods["sjxx"] = triangle_centers
methods_desc["sjxx"] = "已知三角形三个顶点坐标，求其“心”的坐标"




-- 计算多个数的最大公因数
function gcd_multiple(...)
    local nums,result
    nums = {...}
    result = nums[1]
    for i = 2, #nums do
        result = gcd(result, nums[i])
    end
    return fn(result)
end
calc_methods["gys"] = gcd_multiple
methods_desc["gys"] = "计算多个数的最大公因数"




-- 计算多个数的最小公倍数
function lcm_multiple(...)
    local nums,result
    nums = {...}
    result = nums[1]
    for i = 2, #nums do
        result = lcm(result, nums[i])
    end
    return fn(result)
end
calc_methods["gbs"] = lcm_multiple
methods_desc["gbs"] = "计算多个数的最小公倍数"




-- 计算排列数
function permutation(n, r)
    -- 检查参数正确性
    if type(n) ~= "number" or type(r) ~= "number" then
        return "错误：参数必须为数字"
    end
    if n < 0 or r < 0 or n ~= floor(n) or r ~= floor(r) then
        return "错误：参数必须为非负整数"
    end
    if r > n then
        return "错误：第二个参数不能大于第一个参数"
    end
    -- 计算排列数
    local result = factorial(n)/factorial(n-r)
    return fn(result)
end
calc_methods["pls"] = permutation
methods_desc["pls"] = "计算排列数"




-- 计算组合数
function combination(n, r)
    -- 检查参数正确性
    if type(n) ~= "number" or type(r) ~= "number" then
        return "错误：参数必须为数字"
    end
    if n < 0 or r < 0 or n ~= floor(n) or r ~= floor(r) then
        return "错误：参数必须为非负整数"
    end
    if r > n then
        return "错误：第二个参数不能大于第一个参数"
    end
    -- 计算组合数
    local result = factorial(n)/(factorial(r)*factorial(n - r))
    return fn(result)
end
calc_methods["zhs"] = combination
methods_desc["zhs"] = "计算组合数"




-- 已知直线l₁:A₁x+B₁y+C₁=0和l₂:A₂x+B₂y+C₂=0，求两条直线以彼此为轴的对称直线方程
function symmetry_line(A1, B1, C1, A2, B2, C2)
    -- 检查参数正确性
    if type(A1) ~= "number" or type(B1) ~= "number" or type(C1) ~= "number" or type(A2) ~= "number" or type(B2) ~= "number" or type(C2) ~= "number" then
        return "错误：参数必须是数字"
    end
    if (A1 == 0 and B1 == 0) or (A2 == 0 and B2 == 0) then
        return "错误：直线方程的系数不能同时为零"
    end
    -- 计算对称直线方程的系数
    local a1,a2,b,A3,B3,C3,A4,B4,C4,ge1,ge2
    a1 = A2^2+B2^2
    b = 2*(A1*A2+B1*B2)
    A3 = a1*A1-b*A2
    B3 = a1*B1-b*B2
    C3 = a1*C1-b*C2
    a2 = A1^2+B1^2
    A4 = a2*A2-b*A1
    B4 = a2*B2-b*B1
    C4 = a2*C2-b*C1
    ge1 = LineGeneralEquation(A3, B3, C3)
    ge2 = LineGeneralEquation(A4, B4, C4)
    return "直线l₁关于l₂的对称直线l₃的方程为：" .. ge1.. "\n直线l₂关于l₁的对称直线l₄的方程为：".. ge2
end
calc_methods["lzx2"] = symmetry_line
methods_desc["lzx2"] = "已知直线l₁:A₁x+B₁y+C₁=0和l₂:A₂x+B₂y+C₂=0，求两条直线以彼此为轴的对称直线方程"




-- 已知一点P(x₁,y₁)和直线l:Ax+By+C=0，求直线l关于点P的对称直线l'的方程
function dyzx2(x1, y1, A, B, C)
    -- 检查参数正确性
    if type(x1) ~= "number" or type(y1) ~= "number" or type(A1) ~= "number" or type(B1) ~= "number" or type(C1) ~= "number" then
        return "错误：参数必须是数字"
    end
    if A == 0 and B == 0 then
        return "直线方程的系数不能同时为零"
    end
    local A1,B1,C1,ge
    -- 计算对称直线方程的系数
    A1 = A
    B1 = B
    C1 = -(2*A*x1+2*B*y1+C)
    ge = LineGeneralEquation(A1, B1, C1)
    return "直线l关于点P的对称直线l'的方程为："..ge
end
calc_methods["dyzx2"] = dyzx2
methods_desc["dyzx2"] = "已知一点P(x₁,y₁)和直线l:Ax+By+C=0，求直线l关于点P的对称直线l'的方程"




-- 已知两圆一般方程x²+y²+D₁x+E₁y+F₁=0和x²+y²+D₂x+E₂y+F₂=0，判断它们的位置关系
function tcr1(D1, E1, F1, D2, E2, F2)
    -- 参数正确性检查
    if type(D1) ~= "number" or type(E1) ~= "number" or type(F1) ~= "number" or type(D2) ~= "number" or type(E2) ~= "number" or type(F2) ~= "number" then
        return "错误：参数必须是数字"
    end
    local x1,y1,x2,y2,r1,r2
    -- 计算两圆圆心，半径，圆心距
    x1 = -D1/2
    y1 = -E1/2
    x2 = -D2/2
    y2 = -E2/2
    r1 = math.sqrt(x1^2+y1^2-F1)
    r2 = math.sqrt(x2^2+y2^2-F2)
    -- 调用函数输出结果
    return tcr2(x1, y1, r1, x2, y2, r2)
end
calc_methods["tcr1"] = tcr1
methods_desc["tcr1"] = "已知两圆一般方程x²+y²+D₁x+E₁y+F₁=0和x²+y²+D₂x+E₂y+F₂=0，判断它们的位置关系"




-- 已知两圆标准方程(x-x₁)²+(y-y₁)²=r₁²和(x-x₂)²+(y-y₂)²=r₂²，判断它们的位置关系
function tcr2(x1, y1, r1, x2, y2, r2)
    -- 参数正确性检查
    if type(x1) ~= "number" or type(y1) ~= "number" or type(r1) ~= "number" or type(x2) ~= "number" or type(y2) ~= "number" or type(r2) ~= "number" then
        return "错误：参数必须是数字"
    end
    -- 特殊情况:两圆重合
    if x1 == x2 and y1 == y2 and r1 == r2 then
        return "两圆重合"
    end
    local d,a,h,m,n,xj1,xj2,yj1,yj2,dj,e
    -- 计算两圆圆心距
    d = fn(math.sqrt((x1-x2)^2+(y1-y2)^2))
    -- 判断位置关系
    -- 两圆相离
    if d > (r1 + r2) then
        return "两圆外离，圆心距为"..d.."，无交点"
    elseif d < math.abs(r1 - r2) then
        return "两圆内含，圆心距为"..d.."，无交点"
    end
    -- 两圆相交或相切，先计算相关参数
    a = (r1^2-r2^2+d^2)/(2*d)
    h = math.sqrt(r1^2-a^2)
    m = (x2-x1)/d
    n = (y2-y1)/d
    -- 计算交点坐标
    xj1 = fn(x1+a*m+h*n)
    yj1 = fn(y1+a*n-h*m)
    xj2 = fn(x1+a*m-h*n)
    yj2 = fn(y1+a*n+h*m)
    e = 1e-8
    -- 精度控制，防止浮点数误差导致结果不准确
    if math.abs(xj1) < e then
        xj1 = 0
    end
    if math.abs(yj1) < e then
        yj1 = 0
    end
    if math.abs(xj2) < e then
        xj2 = 0
    end
    if math.abs(yj2) < e then
        yj2 = 0
    end
    -- 计算相交弦弦长
    dj = fn(math.sqrt((xj2-xj1)^2+(yj2-yj1)^2))
    -- 判断相切或相交，并给出交点坐标、圆心距和相交弦长
    if d == (r1 + r2) then
        return "两圆外切，圆心距为"..d.."\n交点坐标为("..xj1..","..yj1..")"
    elseif d == math.abs(r1 - r2) then
        return "两圆内切，圆心距为".. d.."\n交点坐标为("..xj1..","..yj1..")"
    elseif math.abs(r1 - r2) < d and d < (r1 + r2) then
        return "两圆相交，圆心距为"..d.."\n交点坐标为("..xj1..","..yj1..")和("..xj2..","..yj2..")\n相交弦弦长为"..dj
    end
end
calc_methods["tcr2"] = tcr2
methods_desc["tcr2"] = "已知两圆标准方程(x-x₁)²+(y-y₁)²=r₁²和(x-x₂)²+(y-y₂)²=r₂²，判断它们的位置关系"




-- 计算行列式
function hls(...)
    local args,n1,sqrt_n,matrix,index,side_length
    args = {...}
    n1 = #args
    sqrt_n = math.sqrt(n1)
    -- 判断n是否为完全平方数，如果是，则将输入的元素重新排列成一个方阵
    if sqrt_n == math.floor(sqrt_n) then
        matrix = {}
        index = 1
        side_length = math.floor(sqrt_n)
        for i = 1, side_length do
            matrix[i] = {}
            for j = 1, side_length do
                matrix[i][j] = args[index]
                index = index + 1
            end
        end
    else
        return "给出的元素不能组成一个方阵。"
    end
    -- 递归计算行列式的函数
    function determinant(matrix)
        local n,det,sign,row,sub_matrix
        n = #matrix
        det = 0
        -- 二阶行列式的边界条件
        if n == 2 then
            return matrix[1][1]*matrix[2][2]-matrix[1][2]*matrix[2][1]
        end
        -- 递归计算行列式
        for j = 1, n do
            sub_matrix = {}
            for i = 2, n do
                row = {}
                for k = 1, n do
                    if k ~= j then
                        table.insert(row, matrix[i][k])
                    end
                end
                table.insert(sub_matrix, row)
            end
            sign = (-1)^(1+j)
            det = det+sign*matrix[1][j]*determinant(sub_matrix)
        end
        return fn(det)
    end
    return determinant(matrix)
end
calc_methods["hls"] = hls
methods_desc["hls"] = "计算行列式"




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