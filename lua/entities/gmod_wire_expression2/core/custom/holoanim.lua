-- holoAnim E2 Extension
-- Originally by dlb (ben1066)

-- To Enable, run 'wire_expression2_extension_enable holoanim'

E2Lib.RegisterExtension("holoanim", false)

local CheckIndex 
registerCallback("postinit",function()
	CheckIndex = wire_holograms.CheckIndex
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
		Holo.ent:SetCycle(Frame)
		Holo.ent:SetPlaybackRate(Rate)
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

e2function void holoSetPose(index, string pose, value)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	
	Holo.ent:SetPoseParameter( pose, value )
end

e2function number holoGetPose(index, string pose)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	
	return Holo.ent:GetPoseParameter( pose )
end
