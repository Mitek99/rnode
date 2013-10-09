function table.map(array, func)
    local new_array = {}
    for i, v in ipairs(array) do
        new_array[i] = func(v)
    end
    return new_array
end

function redis.vcall(...)
    local pres = ""
    for i, v in ipairs(arg) do
        pres = pres .. tostring(v) .. " "
    end
    redis.log(redis.LOG_WARNING, pres)
    return redis.call(unpack(arg))
end

function string.starts(String, Start)
    return string.sub(String, 1, string.len(Start)) == Start
end

-- explode(seperator, string)
function string.explode(d, p)
    local t, ll, l
    t = {}
    ll = 0
    if (#p == 1) then return { p } end
    while true do
        l = string.find(p, d, ll, true) -- find the next d in the string
        if l ~= nil then -- if "not not" found then..
            table.insert(t, string.sub(p, ll, l - 1)) -- Save it in our array.
            ll = l + 1 -- save just after where we found it for searching next time.
        else
            table.insert(t, string.sub(p, ll)) -- Save what's left in our array.
            break -- Break at end, as it should be, according to the lua manual.
        end
    end
    return t
end

local rnode = {}



function table.array_merge(target, dist)
    if target == nil then
        target = {}
    end
    if dist ==
            nil then
        dist = {}
    end

    for k, v in pairs(dist) do target[k] = v end
    return target
end

function table.get_key_for_value(t, value)
    for k, v in pairs(t) do
        if tostring(v) == tostring(value) then return k
        end

    end
    return nil
end




