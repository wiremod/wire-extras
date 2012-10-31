TOOL.Category = "Wire - Render"
TOOL.Name = "Interactable Holography Emitter"
TOOL.Command = nil
TOOL.ConfigName = ""

if CLIENT then
	language.Add( "Tool.wire_useholoemitter.name", "Interactable Holographic Emitter Tool (Wire)" )
	language.Add( "Tool.wire_useholoemitter.desc", "The emitter required for interactable holographic projections" )
	language.Add( "Tool.wire_useholoemitter.0", "Primary: Create emitter      Secondary: Link emitter" )
	language.Add( "Tool.wire_useholoemitter.1", "Select the emitter point to link to." )
	language.Add( "Tool_wire_useholoemitter_showbeams", "Show beams" )
	language.Add( "Tool_wire_useholoemitter_groundbeams", "Show Emitter->Point beams" )
	language.Add( "Tool_wire_useholoemitter_size", "Point size" )
	language.Add( "Tool_wire_useholoemitter_minimum_fade_rate", "CLIENT: Minimum Fade Rate - Applyed to all holoemitters" )
	language.Add( "sboxlimit_wire_useholoemitters", "You've hit the holoemitters limit!" )
	language.Add("Undone_gmod_wire_useholoemitter", "Undone Wire Interactable Holoemitter" )
end

if SERVER then CreateConVar( "sbox_maxwire_useholoemitters", 5 ) end

TOOL.Model = "models/jaanus/wiretool/wiretool_range.mdl"
TOOL.Emitter = nil
TOOL.NoGhostOn = { "gmod_wire_hologrid" }
timer.Simple(0,function() function _my2(TOOL)
	setmetatable(TOOL, WireToolObj)
end end)
TOOL.WireClass = "gmod_wire_useholoemitter"

TOOL.ClientConVar = {
	r	= "255",
	g	= "255",
	b	= "255",
	a	= "255",
	showbeams	= "1",
	groundbeams = "0",
	size	= "4"
}

function TOOL:RightClick( tr )
	if( !tr.HitNonWorld || tr.Entity:GetClass() != "gmod_wire_useholoemitter" ) then return false end
	if CLIENT then return true end
	
	self.Emitter = tr.Entity
	
	return true
end

function TOOL.BuildCPanel( panel )
	WireToolHelpers.MakePresetControl(panel, "wire_useholoemitter")
	panel:CheckBox("#Tool_wire_useholoemitter_showbeams", "wire_useholoemitter_showbeams")
	panel:CheckBox("#Tool_wire_useholoemitter_groundbeams", "wire_useholoemitter_groundbeams")
	panel:NumSlider("#Tool_wire_useholoemitter_size","wire_useholoemitter_size", 1, 32, 1)

	panel:AddControl( "Color", {
		Label 	= "Color",
		Red 	= "wire_useholoemitter_r",
		Green 	= "wire_useholoemitter_g",
		Blue 	= "wire_useholoemitter_b",
		Alpha 	= "wire_useholoemitter_a",
		ShowAlpha	= "1",
		ShowHSV		= "1",
		ShowRGB		= "1",
		Multiplier	= "255",
	})

	if(not game.SinglePlayer()) then
		panel:NumSlider("#Tool_wire_useholoemitter_minimum_fade_rate", "cl_wire_useholoemitter_minfaderate", 0.1, 100, 1)
	end
end

if SERVER then
	function WireToolMakeUseEmitter( self, tr, pl )
		local r = self:GetClientNumber( "r" );
		local g = self:GetClientNumber( "g" );
		local b = self:GetClientNumber( "b" );
		local a = self:GetClientNumber( "a" );
		local size = self:GetClientNumber( "size" );
		local showbeams = util.tobool( self:GetClientNumber( "showbeams" ) );
		local groundbeams = util.tobool( self:GetClientNumber( "groundbeams" ) );
		
		// did we hit another holoemitter?
		if( tr.HitNonWorld && tr.Entity:GetClass() == "gmod_wire_useholoemitter" ) then
			// update it.
			tr.Entity:SetColor( Color(r, g, b, a) );
			
			// update size and show states
			tr.Entity:SetNetworkedBool( "ShowBeam", showbeams );
			tr.Entity:SetNetworkedBool( "GroundBeam", groundbeams );
			tr.Entity:SetNetworkedFloat( "PointSize", size );
			
			tr.Entity.r = r
			tr.Entity.g = g
			tr.Entity.b = b
			tr.Entity.a = a
			tr.Entity.showbeams = showbeams
			tr.Entity.groundbeams = groundbeams
			tr.Entity.size = size
			
			return true;
		end

		// we linking?
		if( tr.HitNonWorld && tr.Entity:IsValid() && tr.Entity:GetClass() == "gmod_wire_hologrid" ) then
			// link to this point.
			if( self.Emitter && self.Emitter:IsValid() ) then
				// link.
				self.Emitter:LinkToGrid( tr.Entity );
				
				// reset selected emitter
				self.Emitter = nil;
				
				//
				return true;
			else
				// prevent effects
				return false;
			end
		end
		
		// create a holo emitter.
		if( !self:GetSWEP():CheckLimit( "wire_useholoemitters" ) ) then return false; end
		
		// fix angle
		local ang = tr.HitNormal:Angle();
		ang.pitch = ang.pitch + 90;
		
		// create emitter
		local emitter = MakeWireUseHoloemitter( pl, tr.HitPos, ang, r, g, b, a, showbeams, groundbeams, size );
		
		// pull it out of the spawn point
		local mins = emitter:OBBMins();
		emitter:SetPos( tr.HitPos - tr.HitNormal * mins.z );
		
		return emitter
	end
	TOOL.LeftClick_Make = WireToolMakeUseEmitter
end
