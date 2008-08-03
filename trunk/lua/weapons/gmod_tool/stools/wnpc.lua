TOOL.Category		= "Wire - Physics"
TOOL.Name			= "#Wired Npc Controller"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
    language.Add( "Tool_wnpc_name", "Wired Npc Controller" )
    language.Add( "Tool_wnpc_desc", "Makes a controllable npc" )
    language.Add( "Tool_wnpc_0", "Primary: Place controller\nSecondary: npc" )
    language.Add( "Tool_wnpc_1", "Left click to place the controller" )
    language.Add( "Tool_wnpc_2", "Right Click to place the npc" )
end

function TOOL:LeftClick( trace )
	local ply = self:GetOwner()
	MakeCont( trace )	
end

function TOOL:RightClick( trace )
	local ply = self:GetOwner()
	MakeNpc( trace )
end

function MakeNpc( tr )
	local pos = tr.HitPos + tr.HitNormal * 16
	local ent = ents.Create( "npc_npc" )
		ent:SetPos( pos )
	ent:Spawn()
	ent:Activate()
	return ent
end

function MakeCont( tr )
	local pos = tr.HitPos + tr.HitNormal * 16
	local ent = ents.Create( "npc_controller" )
		ent:SetPos( pos )
	ent:Spawn()
	ent:Activate()
	return ent
end
