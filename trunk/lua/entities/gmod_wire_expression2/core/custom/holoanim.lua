hook.Add("Initialize","Wire_HoloAnim_Init",function()
	local holo_meta = scripted_ents.Get( "gmod_wire_hologram" )

	holo_meta.AutomaticFrameAdvance = true
	holo_meta.OldThink = holo_meta.Think

	function holo_meta:Think()
		if self.OldThink then
			self:OldThink()
		end

		self:NextThink( CurTime() )
		return true
	end

	scripted_ents.Register(
		holo_meta,
		"gmod_wire_hologram",
		true
	)
end)

E2Lib.RegisterExtension("holoanim", false)

local CheckIndex 

registerCallback("postinit",function()
	CheckIndex = wire_holograms.CheckIndex
end)

local function SetHoloAnim( Holo, Animation, Frame, Rate )
	if (Holo and Animation and Frame and Rate) then
		Holo.ent:ResetSequence(Animation)
		Holo.ent:SetCycle(Frame)
		Holo.ent:SetPlaybackRate(Rate)
	end
end

e2function void holoAnim(index, string animation)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	
	local Sequence = Holo.ent:LookupSequence(animation)
	
	SetHoloAnim(Holo, Sequence, 0, 1)
end

e2function void holoAnim(index, string animation, frame)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	
	local Sequence = Holo.ent:LookupSequence(animation)

	SetHoloAnim(Holo, Sequence, frame, 1)
end

e2function void holoAnim(index, string animation, frame, rate)
	local Holo = CheckIndex(self, index)
	if not Holo then return end
	
	local Sequence = Holo.ent:LookupSequence(animation)

	SetHoloAnim(Holo, Sequence, frame, rate)
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
	
	local Sequence = Holo.ent:LookupSequence(animation)
	if not Sequence then return 0 end
	
	return Sequence
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
