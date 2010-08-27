--------------------------------------------------------
-- Parenting functions
--------------------------------------------------------
local EGP = EGP

function EGP:GetGlobalPos( Ent, index )
	local bool, k, v = self:HasObject( Ent, index )
	if (bool) then
		if (v.parent and v.parent != 0) then
			local x, y, ang = self:GetGlobalPos( Ent, v.parent )
			local vec, ang = LocalToWorld( Vector( v.x or 0, v.y or 0, 0 ), Angle( 0, v.angle or 0, 0 ), Vector( x or 0, y or 0, 0 ), Angle( 0, -ang or 0, 0 ) )
			return vec.x, vec.y, ang.y
		end
		return v.x, v.y, v.angle or 0
	end
end

--[[ I have not yet found a use for this, but I'll keep it just in case
function EGP:GetLocalPos( Ent, index )
	local bool, k, v = self:HasObject( Ent, index )
	if (bool) then
		if (v.parent and v.parent != 0) then
			local x, y, ang = self:GetLocalPos( Ent, v.parent )
			local vec, ang = WorldToLocal( Vector( v.x or 0, v.y or 0, 0 ), Angle( 0, v.angle or 0, 0 ), Vector( x or 0, y or 0, 0 ), Angle( 0, -ang or 0, 0 ) )
			return vec.x, vec.y, ang.y
		end
		return v.x, v.y, v.angle
	end
end
]]

function EGP:SetParent( Ent, index, parentindex )
	local bool, k, v = self:HasObject( Ent, index )
	if (bool) then
		local bool2, k2, v2 = self:HasObject( Ent, parentindex )
		if (bool2) then
			if (self:EditObject( v, { parent = parentindex }, Ent:GetPlayer() )) then return true, v end
		end
	end
end

function EGP:UnParent( Ent, index )
	local bool, k, v = self:HasObject( Ent, index )
	if (bool) then
		local x, y = self:GetGlobalPos( Ent, index )
		if (self:EditObject( v, { x = x, y = y, parent = 0 }, Ent:GetPlayer() )) then return true, v end
	end
end