-- conflict is a function which takes three parameters, table, key, and new value
-- it is called when table[key] already has a value, but we have a new value for that key from another table.
-- conflict is expected to resolve the issue itself, and the merge continues
-- note: if nil is passed for conflict, the default behaviour is to maintain the current value and ignore the new

function table_merge(object, conflict, copy, ...)
	local t = object or { }

	for i, v in ipairs({ ... }) do
		for j, k in pairs(v) do
			if not t[j] then
				t[j] = copy and copy(k) or k
			else
				if conflict then
					conflict(t, j, k)
				end
			end
		end
	end

	return t
end

-- takes a vararg of arrays, and creates a new one with all their elements combined
function array_append(...)
	local t = { }

	for i, v in ipairs({ ... }) do
		for j, k in ipairs(v) do
			table.insert(t, k)
		end
	end

	return t
end

-- applies the what function to each value in the vararg, and returns a vararg of what's return value in the same order.
function apply(what, ...)
	local t = { ... }

	for i, v in ipairs(t) do
		t[i] = what(v)
	end

	return unpack(t)
end