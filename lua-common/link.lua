function rnode.link(type_src, id_src, type_dst, id_dst, name, value)
	local key_fwd = type_src .. id_src .. "_" .. name .. "ed" .. "_" .. type_dst
	local key_back = type_dst .. id_dst .. "_" .. name .. "s" .. "_" .. type_src
	redis.vcall("zadd", key_fwd, value, id_dst)
	redis.vcall("zadd", key_back, value, id_src)
	return true;
end
