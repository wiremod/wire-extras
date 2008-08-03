
TOOL.Category		= "Constraints"
TOOL.Name		= "WireLib Weld"
TOOL.Command		= nil
TOOL.ConfigName		= ""

/*

	To see the constraints do :

		ent_bbox phys_constraint

*/

TOOL.ClientConVar[ "nocollide" ]		= "0"

if CLIENT then
	language.Add ("Tool_wireweld_name", "WireLib Weld")
	language.Add ("Tool_wireweld_desc", "Uses the WireLib Weld instead of regular weld.")
	language.Add ("Tool_wireweld_0", "Left-click on the child object (will be deleted when the parent is removed).")
	language.Add ("Tool_wireweld_1", "Left-click on the parent object (the child will be deleted when this is removed).")
end 

function TOOL:LeftClick( trace )

	if ((trace.Entity:IsValid() && trace.Entity:IsPlayer()) or trace.Entity:IsWorld()) then return false end
	
	// If there's no physics object then we can't constraint it!
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

	local iNum = self:NumObjects()
	local Phys = trace.Entity:GetPhysicsObjectNum( trace.PhysicsBone )
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, Phys, trace.PhysicsBone, trace.HitNormal )
	
	if ( CLIENT ) then
	
		if ( iNum > 0 ) then self:ClearObjects() end
		
		return true
		
	end

	if ( iNum > 0 ) then
	
		// Get client's CVars
		local nocollide  = ( self:GetClientNumber( "nocollide" ) == 1 )

		// Get information we're about to use
		local Ent1,  Ent2  = self:GetEnt(1),  self:GetEnt(2)
		local Bone1, Bone2 = self:GetBone(1), self:GetBone(2)

		local constraint = WireLib.Weld( Ent1, Ent2, Bone2, true, !nocollide, false )
		if (constraint) then 
		
			undo.Create("Weld")
			undo.AddEntity( constraint )
			undo.SetPlayer( self:GetOwner() )
			undo.Finish()
			
			self:GetOwner():AddCleanup( "constraints", constraint )
		
		end

		// Clear the objects so we're ready to go again
		self:ClearObjects()

	else
	
		self:SetStage( iNum+1 )
	
	end
	
	return true

end

function TOOL:RightClick( trace )

	// This was doing stuff that was totally overcomplicated
	// And I'm guessing no-one ever used it - because it didn't work

	return false
	
end

function TOOL:Reload( trace )

	if (!trace.Entity:IsValid() || trace.Entity:IsPlayer() ) then return false end
	if ( CLIENT ) then return true end
	
	local  bool = constraint.RemoveConstraints( trace.Entity, "Weld" )
	return bool
	
end

function TOOL.BuildCPanel( panel ) 
	panel:AddControl("Header", { Text = "WireLib Weld tool", Description = "Uses the wirelib weld instead of the regular weld." })
	panel:AddControl("CheckBox", {
		Label = "NoCollide until break",
		Command = "wireweld_nocollide"
	})
end