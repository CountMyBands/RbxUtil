local Utils = {}

function Utils.Get(tbl1, tbl2)
    local diff = {}

    local function recurse(t1, t2, path)
        for key, value2 in pairs(t2) do
            local value1 = t1[key]
            if type(value1) ~= type(value2) or type(value2) ~= "table" and value2 ~= value1 then
                diff[path .. key] = {op = 1, value = value2}
            elseif type(value2) == "table" then
                recurse(value1 or {}, value2, path .. key .. ".")
            end
        end

        for key, value1 in pairs(t1) do
            if t2[key] == nil then
                diff[path .. key] = {op = 0}
            end
        end
    end

    recurse(tbl1, tbl2, "")
    return diff
end

function Utils.Apply(tbl, diff)
    for key, change in pairs(diff) do
        local path = {}
        for part in string.gmatch(key, "[^.]+") do
            table.insert(path, part)
        end

        local lastKey = table.remove(path)
        local target = tbl
        for _, part in ipairs(path) do
            target = target[part] or {}
        end

        if change.op == 1 then
            target[lastKey] = change.value
        elseif change.op == 0 then
            target[lastKey] = nil
        end
    end
end

function Utils.HasChanges(diff)
    for key, change in pairs(diff) do
        if next(change) ~= nil then
            return true
        end
    end
    return false
end


return Utils