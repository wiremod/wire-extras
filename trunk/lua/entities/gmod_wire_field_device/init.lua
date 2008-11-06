
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "WIRE_FieldGen"

local MODEL = Model( "models/props_lab/binderblue.mdl" )
local EMP_IGNORE_INPUTS = { Kill=true , Pod=true , Eject=true , Lock=true , Terminate = true };
EMP_IGNORE_INPUTS["Damage Armor"]=true;
EMP_IGNORE_INPUTS["Strip weapons"]=true;
EMP_IGNORE_INPUTS["Damage Health"]=true;

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.multiplier=1;
	self.active=0;
	self.objects={};
	self.prox=100;
	self.direction=Vector(0,1,0);
	self.ignore={}
	
	if ( self.Type == "Wind" ) then
		self.direction=Vector(1,0,0);
	end
	
	self:ConfigInOuts();		
	self:SetOverlayText( self:GetDisplayText() )
	
end

function ENT:SetType( v )
	self.Type=v;
end

function ENT:Setworkonplayers( v )
	self.workonplayers=v;
end

function ENT:Setignoreself( v )
	self.ignoreself=v;
end
function ENT:Setarc( v )
	self.arc=v;
end

function ENT:BuildIgnoreList()

	local queue={self.Entity}
	self.ignore={}
	self.ignore[ self.Entity:EntIndex() ] =  self.Entity

	while ( # queue > 0 ) do
	
		local CEnt = constraint.GetTable( table.remove( queue ) )
		if type(CEnt) == "table" then
			for _, mc in pairs( CEnt ) do 
				if mc.Constraint.Type != "Rope" then
					for _, my in pairs( mc.Entity ) do 
						if self.ignore[ my.Index ] != my.Entity then
							self.ignore[ my.Index ] = my.Entity
							table.insert( queue , my.Entity );
						end
					end
				end
			end
		end	
	
	end
	
end

function ENT:GetTypes()
	return { "Gravity" , "Pull" , "Push" , "Hold" , "Wind" , "Vortex" , "Flame" , "Crush" , "EMP" , "Death" };
end

function ENT:GetTypeName( Type )
	
	local Text="";
	
	if Type == "Gravity" then
		Text = "Zero Gravity";
	elseif Type == "Pull" then
		Text = "Attraction";
	elseif Type == "Push" then
		Text = "Repulsion";
	elseif Type == "Hold" then
		Text = "Stasis";
	elseif Type == "Wind" then
		Text = "Wind";
	elseif Type == "Vortex" then
		Text = "Vortex";
	elseif Type == "Flame" then
		Text = "Flame";
	elseif Type == "Crush" then
		Text = "Pressure";
	elseif Type == "EMP" then
		Text = "Electromagnetic";
	elseif Type == "Death" then
		Text = "Radiation";
	elseif Type == "Heal" then
		Text = "Recovery";
	end
	
	return Text;
	
end

function ENT:GetDisplayText()
	
	local Text = self:GetTypeName( self.Type ) .. " Field Generator ( ";
	
	if self.active == 0 then
		Text = Text .. "Off )"
	else
		Text = Text .. "On )"
	end
	
	return Text;
	
end

function ENT:ConfigInOuts()

	if ( self.Type == "Gravity" ) then
		self.Inputs = Wire_CreateInputs(self, { "Active" , "Distance" } )
	elseif ( self.Type == "Wind" || self.Type == "Vortex" ) then
		self.Inputs = Wire_CreateInputs(self, { "Active" , "Distance","Multiplier", "Direction.X" , "Direction.Y", "Direction.Z", "Direction" } )
		WireLib.AdjustSpecialInputs(self.Entity, { "Active", "Distance","Multiplier", "Direction.X" , "Direction.Y", "Direction.Z", "Direction"}, { "NORMAL","NORMAL", "NORMAL", "NORMAL", "NORMAL","NORMAL", "VECTOR"})
	else
		self.Inputs = Wire_CreateInputs(self, { "Active" , "Distance" , "Multiplier" } )
	end
	
	
	self.Outputs = Wire_CreateOutputs(self, {  } )
	
end

function ENT:TriggerInput(iname, value)

	if ( value != nil && iname == "Distance" ) then
		self.prox=value;
	end
	
	if ( value != nil && iname == "Direction.X" ) then
		self.direction.x=value;
	end
	if ( value != nil && iname == "Direction.Y" ) then
		self.direction.y=value;
	end
	if ( value != nil && iname == "Direction.Z" ) then
		self.direction.z=value;
	end
	
	if ( value != nil && iname == "Direction" ) then
		if (type(value) != "Vector") then Msg("non vector passed!\n") return end
		self.direction=value;
	end
	
	if ( value != nil && iname == "Multiplier" ) then
		if value > 0 then
			self.multiplier=value;
		else
			self.multiplier=1.0;
		end
	end
	
	if ( value != nil && iname == "Active" ) then
		self.active=value;
	end
	
	if self.active == 0 then
		self:Disable();
	end
	self:SetOverlayText( self:GetDisplayText() )
	
end

function ENT:is_true( value )
	
	if type(value) == "number" and math.abs(value) < 0.0001 then
		return false;
	end
	
	if type(value) == "string" and value == "0" then
		return false;
	end
	
	return value;
	
end

function ENT:Toogle_Prop_Gravity( prop , yes_no )
	
	if ( !prop:IsValid() ) then return end 

	if ( self.ignore[ prop:EntIndex() ] == prop ) then return false; end
	
	if ( !self:is_true(self.workonplayers) && prop:GetClass() == "player" ) then
		return false;
	end
	
	if prop:GetMoveType() == MOVETYPE_NONE then return false; end
	if prop:GetMoveType() == MOVETYPE_NOCLIP then return false; end //do this to prevent -uncliping-
	
	if prop:GetClass() != "player" && !gamemode.Call("PhysgunPickup",self.pl,prop) then return false; end
	
	if prop:GetMoveType() != MOVETYPE_VPHYSICS then
		if yes_no == false then
		
			if prop:IsNPC() || prop:IsPlayer() then
				prop:SetMoveType(MOVETYPE_FLY);
				prop:SetMoveCollide(MOVECOLLIDE_FLY_BOUNCE);
			else
				prop:SetGravity(0);
			end
			
		else

			if prop:IsPlayer() then
				prop:SetMoveType(MOVETYPE_WALK);
				prop:SetMoveCollide(MOVECOLLIDE_DEFAULT);
			elseif prop:IsNPC() then
				prop:SetMoveType(MOVETYPE_STEP);
				prop:SetMoveCollide(MOVECOLLIDE_DEFAULT);
			else
				prop:SetGravity(1);
			end
			
		end
	end
	
	if prop:GetPhysicsObjectCount() > 1 then
		for x=0,prop:GetPhysicsObjectCount()-1 do
			local part=prop:GetPhysicsObjectNum(x)
			part:EnableGravity( yes_no );
		end
		return false;
	end
		
	local phys=prop:GetPhysicsObject();
	
	if ( !phys:IsValid() ) then return end 
	
	phys:EnableGravity( yes_no );
	
end

function ENT:Gravity_Logic()

	local NewObjs={};

	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
		self:Toogle_Prop_Gravity( contact , false );
		NewObjs[ contact:EntIndex() ] = contact;	
	end

	for idx,contact in pairs( self.objects ) do
		if ( NewObjs[ idx ] != contact ) then
			self:Toogle_Prop_Gravity( contact , true )
		end
	end

	self.objects = NewObjs;

end

function ENT:Gravity_Disable()

	for _,contact in pairs( self.objects ) do
		self:Toogle_Prop_Gravity( contact , true )
	end

end

function ENT:Slow_Prop( prop , yes_no )
	
	if ( !prop:IsValid() ) then return end 

	if ( self.ignore[ prop:EntIndex() ] == prop ) then return false; end
	
	if ( !self:is_true(self.workonplayers) && prop:GetClass() == "player" ) then
		return false;
	end
	
	if prop:GetMoveType() == MOVETYPE_NONE then return false; end
	if prop:GetMoveType() == MOVETYPE_NOCLIP then return false; end //do this to prevent -uncliping-
	
	if prop:GetClass() != "player" && !gamemode.Call("PhysgunPickup",self.pl,prop) then return false; end
	
	local MulU=self.multiplier+15.1;
	
	if MulU < 15.1 then
		MulU=15.1;
	end
	
	if prop:GetMoveType() != MOVETYPE_VPHYSICS then
		if yes_no == false then
		
			if prop:IsNPC() || prop:IsPlayer() then
			
				if !prop:Alive() && prop:GetRagdollEntity() then
					local RagDoll=prop:GetRagdollEntity()
					for x=1,RagDoll:GetPhysicsObjectCount() do
						local part=RagDoll:GetPhysicsObjectNum(x)
						
						part:EnableGravity( yes_no );
						part:SetDragCoefficient( 100 * self.multiplier );
						
					end
				end 
				
				prop:SetMoveType(MOVETYPE_FLY);
				prop:SetMoveCollide(MOVECOLLIDE_FLY_BOUNCE);
			else
				prop:SetGravity(0);
			end
			
			local Mul = -( 1 - 1 / ( MulU / 15 ) );
			local vel = prop:GetVelocity();
			
			if prop.AddVelocity then
				prop:AddVelocity( vel * Mul );
			else
				prop:SetVelocity( vel * Mul );
			end
			
		else
			

			if prop:IsNPC() || prop:IsPlayer() then
				if !prop:Alive() && prop:GetRagdollEntity() then
					local RagDoll=prop:GetRagdollEntity()
					for x=1,RagDoll:GetPhysicsObjectCount() do
						local part=RagDoll:GetPhysicsObjectNum(x)
						
						part:EnableGravity( yes_no );
						part:SetDragCoefficient( 1 );
						
					end
				end 
			end
			
			
			if prop:IsPlayer() then
				prop:SetMoveCollide(MOVETYPE_WALK);
				prop:SetMoveCollide(MOVECOLLIDE_DEFAULT);
			elseif prop:IsNPC() then
				prop:SetMoveCollide(MOVETYPE_STEP);
				prop:SetMoveCollide(MOVECOLLIDE_DEFAULT);
			else
				prop:SetGravity(1);
			end
			
		end
	end

	if prop:GetPhysicsObjectCount() > 1 then
		for x=0,prop:GetPhysicsObjectCount()-1 do
			local part=prop:GetPhysicsObjectNum(x)
			
			part:EnableGravity( yes_no );
			if ! yes_no then
				part:SetDragCoefficient( 100 * self.multiplier );
			else
				part:SetDragCoefficient( 1 );
			end
			
		end
		return false;
	end
	
	local phys=prop:GetPhysicsObject();
	
	if ( !phys:IsValid() ) then return end 
	
	phys:EnableGravity( yes_no );
	if ! yes_no then
		phys:SetDragCoefficient( 100 * self.multiplier );
	else
		phys:SetDragCoefficient( 1 );
	end
	
end

function ENT:Static_Logic()

	local NewObjs={};

	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
		self:Slow_Prop( contact , false );
		NewObjs[ contact:EntIndex() ] = contact;	
	end

	for idx,contact in pairs( self.objects ) do
		if ( NewObjs[ idx ] != contact ) then
			self:Slow_Prop( contact , true )
		end
	end

	self.objects = NewObjs;

end

function ENT:Static_Disable()

	for _,contact in pairs( self.objects ) do
		self:Slow_Prop( contact , true )
	end

end

function ENT:PullPushProp( prop , vec )
	
	if ( !prop:IsValid() ) then return end 
	
	if ( self.ignore[ prop:EntIndex() ] == prop ) then return false; end
	
	if ( !self:is_true(self.workonplayers) && prop:GetClass() == "player" ) then
		return false;
	end
	
	if prop:GetMoveType() == MOVETYPE_NONE then return false; end
	
	if prop:GetClass() != "player" && !gamemode.Call("PhysgunPickup",self.pl,prop) then return false; end
	
	if prop:GetMoveType() != MOVETYPE_VPHYSICS then
		if prop.AddVelocity then
			prop:AddVelocity( vec );
		else
			prop:SetVelocity( vec );
		end
	end

	if prop:GetPhysicsObjectCount() > 1 then
		for x=0,prop:GetPhysicsObjectCount()-1 do
			local part=prop:GetPhysicsObjectNum(x)
			part:AddVelocity( vec );
		end
		return false;
	end
	
	local phys=prop:GetPhysicsObject();
	
	if ( !phys:IsValid() ) then return end 
	
	phys:AddVelocity( vec );
	
end


function ENT:Pull_Logic()

	local Center=self.Entity:GetPos();
	
	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
	
		local Path = Center-contact:GetPos();
		local Length = Path:Length();
		Path = Path * ( 1.0 / Length ) * math.sqrt(1-Length/self.prox)
		self:PullPushProp( contact , Path * self.multiplier );
				
	end

end

function ENT:Pull_Disable()


end

function ENT:Push_Logic()

	local Center=self.Entity:GetPos(); 
	local HalfProx=self.prox / 2;
	
	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
		
		local Path = contact:GetPos()-Center;
		local Length = Path:Length();
		Path = Path * ( 1.0 / Length )
		self:PullPushProp( contact , Path * self.multiplier );		
		
	end

end


function ENT:Push_Logic()

	local Center=self.Entity:GetPos(); 
	local HalfProx=self.prox / 2;
	
	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
		
		local Path = contact:GetPos()-Center;
		local Length = Path:Length();
		Path = Path * ( 1.0 / Length )
		self:PullPushProp( contact , Path * self.multiplier );		
		
	end

end



function ENT:Push_Logic()

	local Center=self.Entity:GetPos(); 
	local HalfProx=self.prox / 2;
	
	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
		
		local Path = contact:GetPos()-Center;
		local Length = Path:Length();
		Path = Path * ( 1.0 / Length )
		self:PullPushProp( contact , Path * self.multiplier );		
		
	end

end


function ENT:Push_Disable()


end


function ENT:Wind_Logic()

	local Up = self.direction:Normalize();
	
	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
		
		self:PullPushProp( contact , Up * self.multiplier );		
		
	end
	
end

function ENT:Wind_Disable()


end

function ENT:GetEverythingInSphere( center , range )

	local Objs=ents.FindInSphere( self.Entity:GetPos(), range )
	
	if self.arc >= 0 && self.arc < 360 then
		
		local rgc=math.cos( (self.arc/360) * math.pi ); //decrease arc by half, 0-360 isntead of 0-180
		local Tmp={}
		local upvec=self.Entity:GetUp();
		local pos = self.Entity:GetPos();
		
		for _,obj in pairs( Objs ) do
			if obj:GetMoveType() != MOVETYPE_NOCLIP then
				local dir = ( obj:GetPos() - pos ):Normalize();
				if dir:Dot( upvec ) > rgc then
					table.insert( Tmp , obj );
				end
			end
		end
		
		Objs=Tmp;
		
	else
	
		local Tmp={}
		local upvec=self.Entity:GetUp();
		local pos = self.Entity:GetPos();
		
		for _,obj in pairs( Objs ) do
			if obj:GetMoveType() != MOVETYPE_NOCLIP then
				table.insert( Tmp , obj );
			end
		end
		
		Objs=Tmp;
		
	end
	
	return Objs;

end

function ENT:Vortex_Logic()

	local Up = self.direction:Normalize();
	local Center=self.Entity:GetPos(); 
	local HalfProx=self.prox / 2;

	for _,contact in pairs( self:GetEverythingInSphere( Center , self.prox || 10 ) ) do
		
		local Path = ( contact:GetPos()+contact:GetVelocity() )-Center;
		self:PullPushProp( contact , Path:Normalize():Cross( Up ) * self.multiplier );		
		
	end

end



function ENT:Vortex_Disable()


end

function ENT:Flame_Apply( prop  , yes_no )

	if ( !prop:IsValid() ) then return end 

	if ( self.ignore[ prop:EntIndex() ] == prop ) then return false; end
	
	if prop:GetMoveType() == MOVETYPE_NONE then return false; end
	
	if ( !self:is_true(self.workonplayers) && prop:GetClass() == "player" ) then
		return false;
	end
	
	if prop:GetClass() != "player" && !gamemode.Call("PhysgunPickup",self.pl,prop) then return false; end
	
	if yes_no == true then
		prop:Ignite( self.multiplier , 0.0 );
	else
		prop:Extinguish();
	end
	
end


function ENT:Flame_Logic()

	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos() , self.prox || 10 ) ) do
		self:Flame_Apply( contact , true );
	end
	
end

function ENT:Flame_Disable()

	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos() , self.prox || 10 ) ) do
		self:Flame_Apply( contact , false );
	end
	
end

function ENT:Crush_Apply( prop , yes_no )

	if ( !prop:IsValid() ) then return end 

	if ( self.ignore[ prop:EntIndex() ] == prop ) then return false; end
	
	if ( !self:is_true(self.workonplayers) && prop:GetClass() == "player" ) then
		return false;
	end
	
	if prop:GetClass() != "player" && !gamemode.Call( "PhysgunPickup", self.pl , prop ) then return false; end
	
	if yes_no == true then
		prop:TakeDamage( self.multiplier ,  self.pl );
	end
	
end

function ENT:Health_Apply( prop , yes_no )

	local x,maxx;
	
	if ( !prop:IsValid() ) then return end 

	if ( self.ignore[ prop:EntIndex() ] == prop ) then return false; end
	
	if ( !self:is_true(self.workonplayers) && prop:GetClass() == "player" ) then
		return false;
	end
	
	if prop:GetClass() != "player" && !gamemode.Call( "PhysgunPickup", self.pl , prop ) then return false; end
	
	if yes_no == true then
	
		x=prop:Health()+self.multiplier;
		maxx=prop:GetMaxHealth();
		
		if ( x > maxx ) then
			x=maxx;
		end
		
		prop:SetHealth( x )
		
	end
	
end

function ENT:Heal_Logic()
	
	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos() , self.prox || 10 ) ) do
		if contact:IsNPC() || contact:IsPlayer() then
			
			self:Health_Apply( contact , true );
			
		end
	end
	
end

function ENT:Heal_Disable()

end

function ENT:Death_Logic()

	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos() , self.prox || 10 ) ) do
		if contact:IsNPC() || contact:IsPlayer() then
			self:Crush_Apply( contact , true )//cheat and use crushing effect, just do it on npcs/players tho.
		end
	end
	
end

function ENT:Death_Disable()

end

function ENT:Crush_Logic()

	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos() , self.prox || 10 ) ) do
		self:Crush_Apply( contact , true )
	end
	
end

function ENT:Crush_Disable()

end

function ENT:EMP_Apply( prop , yes_no )

	if ( !prop:IsValid() ) then return end 

	if ( self.ignore[ prop:EntIndex() ] == prop ) then return false; end
	
	if ( !self:is_true(self.workonplayers) && prop:GetClass() == "player" ) then
		return false;
	end
	
	if prop:GetClass() != "player" && !gamemode.Call( "PhysgunPickup", self.pl , prop ) then return false; end
	
	if (prop) and (prop.Inputs) and type(prop.Inputs) == 'table' then
		for k,v in pairs(prop.Inputs) do
		
			if EMP_IGNORE_INPUTS[ k ] != true then
				//Msg( k .. "\n" ); use to find out what inputs are bad to override. =D
			
				if v.Type == "NORMAL" then
					
					if (prop.TriggerInput) then
						if yes_no then
							prop:TriggerInput( k , prop.Inputs[ k ].Value + math.random() * ( self.multiplier * 2 ) - self.multiplier )
						else
							prop:TriggerInput( k , prop.Inputs[ k ].Value )
						end
						
					end
					
				elseif v.Type == "VECTOR" then
					
					if (prop.TriggerInput) then
						if yes_no then
							prop:TriggerInput( k , prop.Inputs[ k ].Value + Vector(math.random() * ( self.multiplier * 2 ) - self.multiplier,math.random() * ( self.multiplier * 2 ) - self.multiplier ,math.random() * ( self.multiplier * 2 ) - self.multiplier) )
						else
							prop:TriggerInput( k , prop.Inputs[ k ].Value )
						end
						
					end
				
				end
				
			end
		end
	end
	
end

function ENT:EMP_Logic()
	
	local NewObjs={};

	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos() , self.prox || 10 ) ) do
		self:EMP_Apply( contact , true );
		NewObjs[ contact:EntIndex() ] = contact;	
	end
	
	for idx,contact in pairs( self.objects ) do
		if ( NewObjs[ idx ] != contact ) then
			self:EMP_Apply( contact , false )
		end
	end

	self.objects = NewObjs;
	
end

function ENT:EMP_Disable()

	for _,contact in pairs( self:GetEverythingInSphere( self.Entity:GetPos() , self.prox || 10 ) ) do
		self:EMP_Apply( contact , false );
	end
	
end

function ENT:Think()
	
	if self:is_true( self.ignoreself ) then
		self:BuildIgnoreList(); // ignore these guys...
	else
		self.ignore={}
	end
	
	if self.active != 0 then
	
		if self.Type == "Gravity" then
			self:Gravity_Logic();
		elseif self.Type == "Hold" then
			self:Static_Logic();
		elseif self.Type == "Pull" then
			self:Pull_Logic();
		elseif self.Type == "Push" then
			self:Push_Logic();
		elseif self.Type == "Wind" then
			self:Wind_Logic();
		elseif self.Type == "Vortex" then
			self:Vortex_Logic();
		elseif self.Type == "Flame" then
			self:Flame_Logic();
		elseif self.Type == "Crush" then
			self:Crush_Logic();
		elseif self.Type == "Death" then
			self:Death_Logic();
		elseif self.Type == "Heal" then
			self:Heal_Logic();
		elseif self.Type == "EMP" then
			self:EMP_Logic();
		end
	
	end
	
	self.BaseClass.Think(self)
end


function ENT:Disable()

	if self.Type == "Gravity" then
		self:Gravity_Disable();
	elseif self.Type == "Hold" then
		self:Static_Disable();
	elseif self.Type == "Pull" then
		self:Pull_Disable();
	elseif self.Type == "Push" then
		self:Push_Disable();
	elseif self.Type == "Wind" then
		self:Wind_Disable();
	elseif self.Type == "Vortex" then
		self:Vortex_Disable();
	elseif self.Type == "Flame" then
		self:Flame_Disable();
	elseif self.Type == "Crush" then
		self:Crush_Disable();
	elseif self.Type == "Death" then
		self:Death_Disable();
	elseif self.Type == "Heal" then
		self:Heal_Disable();
	elseif self.Type == "EMP" then
		self:EMP_Disable();
	end
	
	self.BaseClass.Think(self)
end

function ENT:OnRemove()
	self:Disable();
end
