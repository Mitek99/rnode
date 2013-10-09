function rnode.set(node)
	local node_type = node.type 
	local id = 0
	if node.id then 
		id = tonumber(node.id) 
		rnode.use_id(node_type, id)
	else
		id = rnode.get_id(node_type)
	end

	if node.sort_fields then 
		for k,v in pairs(node.sort_fields) do
			local field_name = k 
			local field_keyname = node_type .. "_sortby_" .. field_name
			redis.call("zadd", field_keyname, v, id)
		end
		-- TODO: remove old sort_fields
		local keyname = node_type .. "_" .. "sort_fields"
		redis.call("hset", keyname, id, cmsgpack.pack(node.sort_fields))
	end

	if node.index_fields then 
		for k,v in pairs(node.index_fields) do
			local field_name = k
			local field_keyname = node_type .. "_indexby_" .. field_name
			redis.call("hset", field_keyname, v, id)
		end
		-- TODO: remove old index_fields
		local keyname = node_type .. "_" .. "index_fields"
		redis.call("hset", keyname, id, cmsgpack.pack(node.index_fields))
	end 

	for k,v in pairs(node.values) do
		local keyname = node_type .. "_" .. k .. "_values" 
		redis.call("hset", keyname, id, cmsgpack.pack(v))
	end
	return id
end
