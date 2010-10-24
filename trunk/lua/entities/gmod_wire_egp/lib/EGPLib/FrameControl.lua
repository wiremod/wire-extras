--------------------------------------------------------
--  Frame Saving & Loading
--------------------------------------------------------

local EGP = EGP

EGP.Frames = {}

function EGP:SaveFrame( ply, Ent, index )
	if (!EGP.Frames[ply]) then EGP.Frames[ply] = {} end
	EGP.Frames[ply][index] = Ent.RenderTable
end

function EGP:LoadFrame( ply, Ent, index )
	if (!EGP.Frames[ply]) then EGP.Frames[ply] = {} return false end
	if (SERVER) then
		return (EGP.Frames[ply][index] != nil), EGP.Frames[ply][index]
	else
		local frame = EGP.Frames[ply][index]
		if (!frame) then return false end
		Ent.RenderTable = frame
		Ent:EGP_Update()
	end
end