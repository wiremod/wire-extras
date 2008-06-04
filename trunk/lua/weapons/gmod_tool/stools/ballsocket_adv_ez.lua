
TOOL.Category		= "Constraints"
TOOL.Name			= "#Ball Socket - Ez Adv"
TOOL.Command		= nil
TOOL.ConfigName		= nil

if ( CLIENT ) then
    language.Add( "Tool_ballsocket_adv_ez_name", "Bacllsocket Easy Advanced" )
    language.Add( "Tool_ballsocket_adv_ez_desc", "Creates an Easy Advanced Ballsocket" )
    language.Add( "Tool_ballsocket_adv_ez_0", "Primary: Click First Object" )
	language.Add( "Tool_ballsocket_adv_ez_1", "Primary: Click Second Object" )
	language.Add( "undone_ballsocketadvez", "Undone Adv Easy Ballsocket" )
end

TOOL.ClientConVar[ "forcelimit" ] = "0"
TOOL.ClientConVar[ "torquelimit" ] = "0"
TOOL.ClientConVar[ "xmin" ] = "-180"
TOOL.ClientConVar[ "ymin" ] = "-180"
TOOL.ClientConVar[ "zmin" ] = "-180"
TOOL.ClientConVar[ "xmax" ] = "180"
TOOL.ClientConVar[ "ymax" ] = "180"
TOOL.ClientConVar[ "zmax" ] = "180"
TOOL.ClientConVar[ "xfric" ] = "0"
TOOL.ClientConVar[ "yfric" ] = "0"
TOOL.ClientConVar[ "zfric" ] = "0"
TOOL.ClientConVar[ "nocollide" ] = "0"
TOOL.ClientConVar[ "onlyrotation" ] = "0"

function TOOL:LeftClick( trace )

	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end

	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	local iNum = self:NumObjects()

	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )

	if ( iNum > 0 ) then
	
		if ( CLIENT ) then return true end
		
		if ( !self:GetEnt(1):IsValid() && !self:GetEnt(2):IsValid() ) then
			self:ClearObjects()
		return end
	
		// Get client's CVars
		local _forcelimit	= self:GetClientNumber( "forcelimit" )
		local _torquelimit 	= self:GetClientNumber( "torquelimit" )
		local _xmin			= self:GetClientNumber( "xmin" )
		local _xmax			= self:GetClientNumber( "xmax" )
		local _ymin			= self:GetClientNumber( "ymin" )
		local _ymax			= self:GetClientNumber( "ymax" )
		local _zmin			= self:GetClientNumber( "zmin" )
		local _zmax			= self:GetClientNumber( "zmax" )
		local _xfric		= self:GetClientNumber( "xfric" )
		local _yfric		= self:GetClientNumber( "yfric" )
		local _zfric		= self:GetClientNumber( "zfric" )
		local _nocollide	= self:GetClientNumber( "nocollide" )
		local _onlyrotation	= self:GetClientNumber( "onlyrotation" )
		
		local Ent1,  Ent2  = self:GetEnt(1),		self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1),		self:GetBone(2)
		local LPos1, LPos2 = self:GetLocalPos(1),	self:GetLocalPos(2)
		local Norm1, Norm2 = self:GetNormal(1),	 self:GetNormal(2)
		local WPos	   = self:GetPos(2)
		local LPos	   = self:GetLocalPos(2)
		local Phys	   = self:GetPhys(1)
		
		local Ang1, Ang2 = Norm1:Angle(), (Norm2 * -1):Angle()
		local TargetAngle = Phys:AlignAngles( Ang1, Ang2 )

		Phys:SetAngle( TargetAngle )

		// Move the object so that the hitpos on our object is at the second hitpos
		local TargetPos = WPos + (Phys:GetPos() - self:GetPos(1)) + (Norm2)

		// Offset slightly so it can rotate
		TargetPos = TargetPos + Norm2

		// Set the position
		Phys:SetPos( TargetPos )

		// Wake up the physics object so that the entity updates
		Phys:Wake()
		
		local constraint = constraint.AdvBallsocket( Ent1, Ent2, Bone1, Bone2, LPos1, LPos2, _forcelimit, _torquelimit, _xmin, _ymin, _zmin, _xmax, _ymax, _zmax, _xfric, _yfric, _zfric, _onlyrotation, _nocollide )
	
		undo.Create("AdvBallsocket")
		undo.AddEntity( constraint )
		undo.SetPlayer( self:GetOwner() )
		undo.Finish()
		
		self:GetOwner():AddCleanup( "constraints", constraint )

		// Clear the objects so we're ready to go again
		self:ClearObjects()
		
	else
	
		self:SetStage( iNum+1 )
		
	end
	
	return true

end

function TOOL:Reload( trace )

	if (!trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return false end
	if ( CLIENT ) then return true end
	
	local  bool = constraint.RemoveConstraints( trace.Entity, "AdvBallsocket" )
	return bool
	
end