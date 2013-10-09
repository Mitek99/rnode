function rnode.get(node_type, order_by, order, start, stop, values, links, ties)

    local cmd = { "zinterstore" }
    local keyname = node_type .. "_sortby_" .. order_by
    table.insert(cmd, keyname)
    local key_count = 1
    for tie in string.gmatch(ties, "[%a%d_]+") do
        table.insert(cmd, tie)
        keyname = keyname .. "_" .. tie
        key_count = key_count + 1
    end
    table.insert(cmd, 2, keyname)
    if key_count > 1 then
        if redis.call("expire", keyname, 1) == 0 then
            table.insert(cmd, 3, key_count)
            table.insert(cmd, "WEIGHTS")
            table.insert(cmd, "1")
            while key_count > 1 do
                table.insert(cmd, "0")
                key_count = key_count - 1
            end
            redis.call(unpack(cmd))
            redis.call("expire", keyname, 1)
        end
    end

    local command = "ZRANGE";
    if order == "desc" then
        command = "ZREVRANGE"
    end

    local ids = redis.call(command, keyname, start, stop)
    redis.log(redis.LOG_WARNING, cjson.encode(ids))
    local res = {}
    for pos, id in ipairs(ids) do
        local elem = { ["id"] = id }
        for value in string.gmatch(values, "%a+") do
            local data = cmsgpack.unpack(redis.call("HGET", node_type .. "_" .. value .. "_values", id))
            for k, v in pairs(data) do elem[k] = v end
        end
        for ntype, link, value in string.gmatch(links, "([_%w]+)_(%w+)=(%w+)") do
            local linked_keys = redis.call("ZRANGE", node_type .. id .. "_" .. link .. "_" .. ntype, 0, -1)
            if (type(linked_keys) == "string") then linked_keys = { linked_keys } end
            elem[link] = table.map(linked_keys, function(v)
                local linked_obj = cmsgpack.unpack(redis.call("HGET", ntype .. "_" .. values .. "_values", v))
                linked_obj.id = tonumber(v)
                return linked_obj
            end)
        end
        table.insert(res, elem)
    end
    return res
end


--TODO refactoring , add abstract functions for get and get_by_parent_link_and_position. Add get_by_parent_link function
--TODO remove to new file
function rnode.get_by_parent_link_and_position(node_type, node_id, parent_node, parent_node_id, link, order_by, order, left, right, values, links, ties)

    local allIds = redis.vcall("sort", parent_node .. parent_node_id .. "_" .. link .. "_" .. node_type, "by", node_type .. "_sortby_" .. order_by, order)

    local position = table.get_key_for_value( allIds, node_id )
--    position = position -1 --bugfix
    local start = position - left
    local stop = position + right


    local idsIndex = 0
    local idsStop = table.getn(allIds)
    local ids = {}


    if start then
        if start >= 0 and start <= idsStop then
            idsIndex = start
        end
    end

    if stop then
        if stop >= 0 and stop <= idsStop then
            idsStop = stop
        end
    end



    while idsIndex <= idsStop do
        table.insert(ids, allIds[idsIndex])
        idsIndex = idsIndex + 1
    end

    redis.log(redis.LOG_WARNING, cjson.encode(ids))
    local res = {}
    for pos, id in ipairs(ids) do
        local elem = { ["id"] = id }
        for value in string.gmatch(values, "%a+") do
            local data = cmsgpack.unpack(redis.vcall("HGET", node_type .. "_" .. value .. "_values", id))
            for k, v in pairs(data) do elem[k] = v end
        end
        for ntype, link, value in string.gmatch(links, "([_%w]+)_(%w+)=(%w+)") do
            local linked_keys = redis.vcall("ZRANGE", node_type .. id .. "_" .. link .. "_" .. ntype, 0, -1)
            if (type(linked_keys) == "string") then linked_keys = { linked_keys } end
            elem[link] = table.map(linked_keys, function(v)
                local linked_obj = cmsgpack.unpack(redis.vcall("HGET", ntype .. "_" .. values .. "_values", v))
                linked_obj.id = tonumber(v)
                return linked_obj
            end)
        end
        table.insert(res, elem)
    end

    local result = {
        ["values"] = res,
        ["pos"] = position

    }

    return result
end






