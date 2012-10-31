TOOL.Category		= "Wire - Physics"
TOOL.Name			= "Wired Npc Controller"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
    language.Add( "Tool.wnpc.name", "Wired Npc Controller" )
    language.Add( "Tool.wnpc.desc", "Makes a controllable npc" )
    language.Add( "Tool.wnpc.3", "Primary: Place controller\nSecondary: Place Npc" )
    language.Add( "Tool.wnpc.0", "Left Click to place the controller" )
    language.Add( "Tool.wnpc.1", "Right Click to place the npc" )
	language.Add( "Undone_npc_npc", "Undone Wired Npc" )
	language.Add( "Undone_wire controlled npc", "Undone Wired Npc Controller" )
	language.Add( "Undone_wnpc", "Undone Wired Npc" )
end

function TOOL:LeftClick( trace )
	if ( CLIENT ) then return true end
	local stage = self:GetStage()
	if (stage == 0) then
		local ply = self:GetOwner()
		local cont = MakeCont( trace )
		undo.Create( "Controller Npc" )
			undo.AddEntity( cont )
			undo.SetPlayer( ply )
		undo.Finish()
		self:SetStage(1)
	end	
end

function TOOL:RightClick( trace )
	if ( CLIENT ) then return true end
	local stage = self:GetStage()
	if ( stage == 1 ) then
		local ply = self:GetOwner()
		local npcc = MakeNpc( trace )
		undo.Create( "Wire Controlled Npc" )
			undo.AddEntity( npcc )
			undo.SetPlayer( ply )
		undo.Finish()
		self:SetStage(0)
	end
end

if ( SERVER ) then
	function MakeCont( tr )
		local pos = tr.HitPos + tr.HitNormal * 16
		local ent = ents.Create( "npc_controller" )
		ent:SetPos( pos )
		ent:Spawn()
		ent:Activate()
		return ent
	end
	
	function MakeNpc( tr )
		local pos = tr.HitPos + tr.HitNormal * 16
		local ent = ents.Create( "npc_npc" )
		ent:SetPos( pos )
		ent:Spawn()
		ent:Activate()
		return ent
	end
end

function TOOL.BuildCPanel( CPanel )
	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool.wnpc.name", Description = "#Tool.wnpc.desc" }  )
end




