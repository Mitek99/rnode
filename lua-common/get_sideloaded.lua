function rnode.get_sideloaded(objs, field, node_type, values) 
	local loaded_ids = {}
	local res = {}
	for k, obj in pairs(objs) do
		local id = obj[field]
		if type(id) == "number" then
			if loaded_ids[id] == nil then
				loaded_ids[id] = true
				local side_obj = rnode.get_by_id(node_type, id, values)
				if type(side_obj) == "table" then
					table.insert(res, side_obj)
				end
			end
		end
	end
	return res
end

