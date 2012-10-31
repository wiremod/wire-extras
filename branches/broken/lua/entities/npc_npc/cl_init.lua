include('shared.lua')

ENT.RenderGroup = RENDERGROUP_BOTH

/*---------------------------------------------------------
   Name: Draw
   Desc: Draw it!
---------------------------------------------------------*/
function ENT:Draw()
	self:DrawModel()
end

/*---------------------------------------------------------
   Name: DrawTranslucent
   Desc: Draw translucent
---------------------------------------------------------*/
function ENT:DrawTranslucent()

	// This is here just to make it backwards compatible.
	// You shouldn't really be drawing your model here unless it's translucent

	self:Draw()
	
end

/*---------------------------------------------------------
   Name: BuildBonePositions
   Desc: 
---------------------------------------------------------*/
function ENT:BuildBonePositions( NumBones, NumPhysBones )

	// You can use this section to position the bones of
	// any animated model using self:SetBonePosition( BoneNum, Pos, Angle )
	
	// This will override any animation data and isn't meant as a 
	// replacement for animations. We're using this to position the limbs
	// of ragdolls.
	
end



/*---------------------------------------------------------
   Name: SetRagdollBones
   Desc: 
---------------------------------------------------------*/
function ENT:SetRagdollBones( bIn )

	// If this is set to true then the engine will call 
	// DoRagdollBone (below) for each ragdoll bone.
	// It will then automatically fill in the rest of the bones

	self.m_bRagdollSetup = bIn

end


/*---------------------------------------------------------
   Name: DoRagdollBone
   Desc: 
---------------------------------------------------------*/
function ENT:DoRagdollBone( PhysBoneNum, BoneNum )

	// self:SetBonePosition( BoneNum, Pos, Angle )
	
end