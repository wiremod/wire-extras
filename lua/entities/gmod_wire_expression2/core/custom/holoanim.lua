-- holoAnim E2 Extension
-- Originally by dlb (ben1066)

-- To Enable, run 'wire_expression2_extension_enable holoanim'

E2Lib.RegisterExtension("holoanim", false)

local CheckIndex 
registerCallback("postinit",function()
	CheckIndex = wire_holograms.CheckIndex
end)

registerCallback("construct", function(self)
	self.data.poseParamCount = 0
	self.data.posesToSend = {}
end)

local flush_pose_param
registerCallback("postexecute", function(self)
	flush_pose_param(self)
end)

local function SetHoloAnim( Holo, Animation, Frame, Rate )
	if (Holo and Animation and Frame and Rate) then
		if not Holo.ent.Animated then
			-- This must be run once on entities that will be animated
			Holo.ent.Animated = true
			Holo.ent.AutomaticFrameAdvance = true
			
			local OldThink = Holo.ent.Think
			function Holo.ent:Think()
				OldThink(self)
				self:NextThink( CurTime() )
				return true
			end
		end
		Holo.ent:ResetSequence(Animation)
		Holo.ent:SetCycle(math.Clamp(Frame,0,1))
		-- over 12 is clamped by the engine, negative values break cycle value
		Holo.ent:SetPlaybackRate(math.Clamp(Rate,0,12)) 
	end
end

e2function void holoAnim(index, string animation)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	
	SetHoloAnim(Holo, Holo.ent:LookupSequence(animation), 0, 1)
end

e2function void holoAnim(index, string animation, frame)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	SetHoloAnim(Holo, Holo.ent:LookupSequence(animation), frame, 1)
end

e2function void holoAnim(index, string animation, frame, rate)
	local Holo = CheckIndex(self, index)
	if not Holo then return end

	SetHoloAnim(Holo, Holo.ent:LookupSequence(animation), frame, rate)
end

e2function void holoAnim(index, animation)
	local Holo = CheckIndex(self, index)
	
	SetHoloAnim(Holo, animation, 0, 1)
end

e2function void holoAnim(index, animation, frame)
	local Holo = CheckIndex(self, index)
	
	SetHoloAnim(Holo, animation, frame, 1)
end

e2function void holoAnim(index, animation, frame, rate)
	local Holo = CheckIndex(self, index)
	
	SetHoloAnim(Holo, animation, frame, rate)
end

e2function number holoAnimLength(index)
	local Holo = CheckIndex(self, index)
	if not Holo then return 0 end
	
	return Holo.ent:SequenceDuration()
end

e2function number holoAnimNum(index, string animation)
	local Holo = CheckIndex(self, index)
	if not Holo then return 0 end
	
	return Holo.ent:LookupSequence(animation) or 0
end

util.AddNetworkString("wire_expression2_updateposeparameters")

function flush_pose_param(self)
	if next(self.data.posesToSend) then
		net.Start("wire_expression2_updateposeparameters")
		for holo, _ in pairs(self.data.posesToSend) do
			if next(holo.poseCache.poses) then
				net.WriteEntity(holo.ent)
				for index, value in pairs(holo.poseCache.poses) do
					holo.poseCache.poses[index] = nil
					holo.poseCache.curPose[index] = value
					net.WriteUInt(index, 8)
					net.WriteFloat(value)
				end
				net.WriteUInt(255, 8)
			end
		end
		net.WriteEntity(NULL)
		net.Broadcast()

		self.data.poseParamCount = 0
		self.data.posesToSend = {}
	end
end

e2function void holoSetPose(index, string pose, value)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	
	if not Holo.poseCache then
		Holo.poseCache = {curPose = {}, poses = {}, stringToInt = {}}
		for i = 0, Holo.ent:GetNumPoseParameters()-1 do
			local name = Holo.ent:GetPoseParameterName(i)
			Holo.poseCache.stringToInt[ Holo.ent:GetPoseParameterName(i) ] = i
		end
	end

	local i = Holo.poseCache.stringToInt[ pose ]
	if i then
		if Holo.poseCache.curPose[ i ] == value then
			Holo.poseCache.poses[ i ] = nil
		elseif self.data.poseParamCount < 16 then
			self.data.poseParamCount = self.data.poseParamCount + 1
			Holo.poseCache.poses[ i ] = value
			self.data.posesToSend[ Holo ] = true
		end
	end
end

e2function number holoGetPose(index, string pose)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	
	if Holo.poseCache then
		local i = Holo.poseCache.stringToInt[ pose ]
		return i and (Holo.poseCache.poses[ i ] or Holo.poseCache.curPose[ i ]) or Holo.ent:GetPoseParameter( pose )
	else
		return Holo.ent:GetPoseParameter( pose )
	end
end
