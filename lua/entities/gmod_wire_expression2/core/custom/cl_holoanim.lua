local poseParams = {}
local function hologramPoseParams()
	if next(poseParams) then
		for ent, poses in pairs(poseParams) do
			if ent:IsValid() then
				for pose, value in pairs(poses) do
					ent:SetPoseParameter(pose, value)
				end
			end
		end
	else
		hook.Remove("Think","wire_hologram_poseparameters")
	end
end

net.Receive("wire_expression2_updateposeparameters", function()
	if not next(poseParams) then 
		hook.Add("Think","wire_hologram_poseparameters", hologramPoseParams)
	end

	local ent = net.ReadEntity()
	while ent:IsValid() do

		local tbl = poseParams[ent]
		if not tbl then
			if table.Count(poseParams)==32 then return end --32 holograms max
			tbl = {}
			poseParams[ent] = tbl
			ent:CallOnRemove("cleanup_poseparameters", function() timer.Simple(0, function() if not ent:IsValid() then poseParams[ent] = nil end end) end)
		end

		local idx = net.ReadUInt(8)
		while idx ~= 255 do
			tbl[ent:GetPoseParameterName(idx)] = net.ReadFloat()
			idx = net.ReadUInt(8)
		end

		ent = net.ReadEntity()
	end
end)
