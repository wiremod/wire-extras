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