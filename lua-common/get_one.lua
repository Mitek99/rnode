

function rnode.get_one(node_type, node_id, values, links)

	local field, id = string.match(node_id, "(.+)=(.+)")
	if field ~= "id" then
		id = redis.vcall("hget", node_type .. "_indexby_"..field, id)
		if type(id) ~= "string" then return false end
	end

	local res = {[node_type] = rnode.get_by_id(node_type, id, values)}

	for ntype, link, value in string.gmatch(links, "(%w+)_(%w+)=(%w+)") do
		local linked_keys = redis.vcall("zrange", node_type .. id .. "_" .. link .. "_" .. ntype, 0, -1)
		if(type(linked_keys) == "string") then linked_keys = {linked_keys} end
		linked_keys = table.map(linked_keys, function(v) return tonumber(v) end)
		redis.log(redis.LOG_WARNING, "LINKED KEYS "..cjson.encode(linked_keys))
		res[node_type][link] = linked_keys
		local linkEntities =  table.map(linked_keys, function (v)
			local val = rnode.get_by_id(ntype, v, value)
			if type(val) == "table" then
				return val
			else
				return false
			end
			end )

        if (res[ntype.."s"] == nil) then
            res[ntype.."s"] = {}
        end

        for k,v in pairs(linkEntities) do table.insert(res[ntype.."s"] ,  v )  end

	end
	return res
end


