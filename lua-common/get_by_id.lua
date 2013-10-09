function rnode.get_by_id(node_type, id, values) 
--	redis.log(redis.LOG_WARNING, "GET_BY_ID node_type=" .. node_type .. " id=" .. id .." values="..values)
	local elem = false

	for value in string.gmatch(values, "%a+") do
		if type(elem) ~= 'table' then
			local res = redis.vcall("HGET", node_type .. "_" .. value .. "_values", id)
			if type(res) == 'string' then
				elem = cmsgpack.unpack(res)
			else
				return false
			end
		else 
			local res = redis.vcall("HGET", node_type .. "_" .. value .. "_values", id)
			if type(res) == 'string' then
				local data = cmsgpack.unpack(res)
				for k,v in pairs(data) do elem[k] = v end
			else
				return false
			end
		end
	end
	if type(elem) == 'table' then
		elem.id = tonumber(id)
	end
	return elem
end
