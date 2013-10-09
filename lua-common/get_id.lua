function rnode.get_id(ntype)
    return redis.vcall("hincrby", "last_id", ntype, 1)
end

-- Удостовериться, что текущий последний ключ не менее используемого
-- Это нужно только при импорте, чтобы счетчик ключей рос
function rnode.use_id(ntype, id)
    id = tonumber(id)
    local last_id = redis.call("hget", "last_id", ntype)

    if ( tonumber(id) > tonumber(last_id)) then

        redis.vcall("hset", "last_id", ntype, tonumber(id))
    end
end
