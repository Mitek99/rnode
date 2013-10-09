function rnode.get_sums(node_type, order_by, ties, sums)

-- Сначала найдем все ID объектов, удовлетворяющих ties	
-- order_by нужен хоть какой-нибудь, иначе мы не можем узать имя таблицы индекса
	local cmd = {"ZINTERSTORE"}
	local keyname = node_type .. "_sortby_" .. order_by
	table.insert(cmd, keyname)
	local key_count = 1
	for tie in string.gmatch(ties, "[%a%d_]+") do
		if redis.call("EXISTS", tie) == 0 then
			return {} -- Tie is empty
		end
		table.insert(cmd, tie)
		keyname = keyname.."_"..tie
		key_count = key_count+1
	end
	table.insert(cmd, 2, keyname)
	if key_count > 1 then 
		if redis.call("EXPIRE", keyname, 1) == 0 then 
			table.insert(cmd, 3, key_count)
			table.insert(cmd, "WEIGHTS")
			table.insert(cmd, "1")
			while key_count > 1 do 
				table.insert(cmd, "0") 
				key_count = key_count-1
			end
			redis.vcall(unpack(cmd))
			redis.call("EXPIRE", keyname, 1)
		end
	end

	-- Список ID объектов связи которых мы будем суммировать хранится в keyname

	local res = {}
	cmd = {"ZUNIONSTORE"}
	for ntype, sum, value in string.gmatch(sums, "(%w+)_(%w+)=(%w+)") do
		local keyname_sum = keyname.."_sum_"..sum.."_"..ntype
		if redis.call("EXPIRE", keyname_sum, 600) == 0 then 
			key_count = 0
			table.insert(cmd, keyname_sum)
			local ids = redis.call("ZRANGE", keyname, 1, -1)
			for pos,id in ipairs(ids) do 
				table.insert(cmd, node_type..id.."_"..sum.."_"..ntype)
				key_count = key_count + 1
			end
			table.insert(cmd, 3, key_count)
			table.insert(cmd, "AGGREGATE")
			table.insert(cmd, "SUM")
			redis.call(unpack(cmd))
			redis.call("EXPIRE", keyname_sum, 600)
		end
		local sum_keys = redis.call("ZREVRANGE", keyname_sum, 1, -1, "WITHSCORES")
		local val = {}
		res[sum] = {}
		for pos,count in ipairs(sum_keys) do
			if math.mod(pos, 2) == 0 then
				local val = rnode.get_by_id(ntype, sum_keys[pos-1], value)
				if(type(val) == "table") then
					val.count = count
					table.insert(res[sum], val)
				end
			end
		end
	end
	return res
end
