
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "WIRE_FieldGen"

local MODEL = Model( "models/props_lab/binderblue.mdl" )

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.multiplier=1;
	self.active=0;
	self.objects={};
	self.prox=100;
	
	self:ConfigInOuts();		
	self:SetOverlayText( self:GetDisplayText() )
	
end

function ENT:GetTypes()
	return { "Gravity" , "Pull" , "Push" , "Hold" };
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
		Text = "Static";
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
	else
		self.Inputs = Wire_CreateInputs(self, { "Active" , "Distance" , "Multiplier" } )
	end
	
	self.Outputs = Wire_CreateOutputs(self, {  } )
	
end

function ENT:TriggerInput(iname, value)

	if ( value != nil && iname == "Distance" ) then
		self.prox=value;
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

function ENT:Toogle_Prop_Gravity( prop , yes_no )
	
	if ( !prop:IsValid() ) then return end 
	
	local class = prop:GetClass()
	local state = "On";
	
	if yes_no == false then state = "Off"; end
	
	local phys=prop:GetPhysicsObject();
	
	if ( !phys:IsValid() ) then return end 
	
	phys:EnableGravity( yes_no );
	
end

function ENT:Gravity_Logic()

	local NewObjs={};

	for _,contact in pairs( ents.FindInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
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
	
	local class = prop:GetClass()
	local state = "On";
	
	if yes_no == false then state = "Off"; end
	
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

	for _,contact in pairs( ents.FindInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
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
	
	local class = prop:GetClass()
	local state = "On";
	
	if yes_no == false then state = "Off"; end
	
	local phys=prop:GetPhysicsObject();
	
	if ( !phys:IsValid() ) then return end 
	
	phys:AddVelocity( vec );
	
end


function ENT:Pull_Logic()

	local Center=self.Entity:GetPos();
	
	for _,contact in pairs( ents.FindInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
	
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
	
	for _,contact in pairs( ents.FindInSphere( self.Entity:GetPos(), self.prox || 10 ) ) do
		
		local Path = contact:GetPos()-Center;
		local Length = Path:Length();
		Path = Path * ( 1.0 / Length )
		self:PullPushProp( contact , Path * self.multiplier );		
		
	end

end

function ENT:Push_Disable()


end


function ENT:Think()
	
	if self.active != 0 then
	
		if self.Type == "Gravity" then
			self:Gravity_Logic();
		elseif self.Type == "Hold" then
			self:Static_Logic();
		elseif self.Type == "Pull" then
			self:Pull_Logic();
		elseif self.Type == "Push" then
			self:Push_Logic();
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
	end
	
	self.BaseClass.Think(self)
end

function ENT:OnRemove()
	self:Disable();
end
