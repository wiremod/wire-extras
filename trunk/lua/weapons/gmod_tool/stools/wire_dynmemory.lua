/*******************************
	Adv. Consolescreen Wrapper
	  for Wiremod
	  
	(C) Sebastian J.
********************************/

TOOL.Category		= "Wire Extras/Memory"
TOOL.Name			= "Dynamic Memory"
TOOL.Command		= nil
TOOL.ConfigName		= ""
TOOL.Tab			= "Wire"

if ( CLIENT ) then
	language.Add( "Tool.wire_dynmemory.name", "Dynamic Memory Chip Tool (Wire)" )
	language.Add( "Tool.wire_dynmemory.desc", "Spawns a Dynamic Memory Chip" )
	language.Add( "Tool.wire_dynmemory.pers", "Persistant Memory" )
	language.Add( "Tool.wire_dynmemory.0", "Primary: Create/Update Memory Chip" )
	
	language.Add( "sboxlimit_wire_dynmemorys", "You've hit the Dynamic Memory Chips limit!" )
	language.Add( "Undone_WireDynMemory", "Dynamic Memory Chip undone" )
end

if (SERVER) then
	CreateConVar('sbox_maxwire_dynmemorys', 2)
end

TOOL.ClientConVar[ "model" ] = "models/jaanus/wiretool/wiretool_gate.mdl"
TOOL.ClientConVar[ "size" ] = 1
TOOL.ClientConVar[ "persistant" ] = 0

cleanup.Register( "wire_dynmemorys" )

function TOOL:LeftClick( trace )
	if trace.Entity:IsPlayer() then return false end
	
	if (CLIENT) then return true end

	local Model = self:GetClientInfo( "model" )
	local Size = math.floor(self:GetClientNumber( "size" ))
	local Pers = self:GetClientNumber( "persistant" )
	
	if ( Size < 1 ) then Size = 1 end
	
	if (!self:GetSWEP():CheckLimit( "wire_dynmemorys" ) ) then return false end	
	if (!util.IsValidModel(Model)) then return false end
	if (!util.IsValidProp(Model)) then return false end

	local ply = self:GetOwner()
	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90
		
	ent = MakeWireDynMemory( ply, trace.HitPos, Ang, Size,Model )
	if (!ent || !ent:IsValid()) then return false end	
	
	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetPersistant( Pers > 0 )

	local const = WireLib.Weld( ent, trace.Entity, trace.PhysicsBone, true )

	undo.Create("WireDynMemory")
		undo.AddEntity( ent )
		undo.AddEntity( const )
		undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "wire_dynmemorys", ent )

	return true
end

function TOOL:RightClick( trace )
	return false
end

function TOOL:Think()
	if (!self.GhostEntity || !self.GhostEntity:IsValid() || !self.GhostEntity:GetModel() || self.GhostEntity:GetModel() != self:GetClientInfo( "model" ) ) then
		self:MakeGhostEntity( self:GetClientInfo( "model" ), Vector(0,0,0), Angle(0,0,0) )
	end
	self:UpdateGhost( self.GhostEntity, self:GetOwner() )
end

function TOOL:UpdateGhost( ent, player )

	if ( !ent ) then return end
	if ( !ent:IsValid() ) then return end

	local trace = player:GetEyeTrace()
	if (!trace.Hit) then return end

	if ( trace.Entity && trace.Entity:GetClass() == "gmod_wire_dynamicmemory" || trace.Entity:IsPlayer() ) then
		ent:SetNoDraw( true )
		return
	end

	local Ang = trace.HitNormal:Angle()
	Ang.pitch = Ang.pitch + 90

	local min = ent:OBBMins()
	ent:SetPos( trace.HitPos - trace.HitNormal * min.z )
	ent:SetAngles( Ang )
	ent:SetNoDraw( false )
end


if ( SERVER ) then
	function MakeWireDynMemory( ply, Pos, Ang, Size, Model )		
		if ( !ply:CheckLimit( "wire_dynmemorys" ) ) then return false end
		
		local ent = ents.Create( "gmod_wire_dynamicmemory" )
		if (!ent:IsValid()) then return false end
		
		ent:SetModel(Model)		
		ent:SetAngles( Ang )
		ent:SetPos( Pos )
		ent:Spawn()
		ent:Setup( Size )
		
		ent:SetPlayer( ply )
		
		local ttable = {
			ply = ply,
			Model = Model,
			Size = Size
		}
		table.Merge(ent:GetTable(), ttable )
		
		ply:AddCount( "wire_dynmemorys", ent )
		
		return ent		
	end
	duplicator.RegisterEntityClass("gmod_wire_dynamicmemory", MakeWireDynMemory, "Pos", "Ang", "Size", "Model")
end

function TOOL.BuildCPanel(panel)
	panel:AddControl("Slider", {
		Label = "Memory Size",
		Type = "Integer",
		Min = "1",
		Max = "2097152",
		Command = "wire_dynmemory_size"
	})
	
	ModelPlug_AddToCPanel(panel, "gate", "wire_dynmemory", "model:", nil, "Model:")
	
	panel:AddControl("Checkbox", {
		Label = "#Tool.wire_dynmemory.pers",
		Description = "Saves memory content in duplicator saves!",
		Command = "wire_dynmemory_persistant"
	})
end
