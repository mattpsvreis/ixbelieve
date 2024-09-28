
function Schema:ZeroNumber(number, length)
	local amount = math.max(0, length - string.len(number or 0))
	return string.rep("0", amount)..tostring(number)
end

function Schema:IsHomeServer()
	return game.GetMap() == ix.config.Get("HomeMap")
end

function Schema:PopulateFactionModels(root, path, skins, bgstring)
	for i= 0, skins do
		local tab = {}
		tab[1] = path
		tab[2] = i
		tab[3] = bgstring
		table.insert(root, tab)
	end
end

function Schema:GetBodygroupsAsString(bodygroup)
	local out = ""
	for i= 1, 9 do
		if (bodygroup[i]) then
			out = out .. tostring(bodygroup[i])
		else
			out = out .. "0"
		end
	end
	return out
end