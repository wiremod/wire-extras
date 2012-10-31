AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Wired Wirer"
ENT.OverlayDelay = 0


//ownership functions adapted from E2 code (Thanks Syranide) :)
local function isOwner(self, entity)
	return (getOwner(self, entity) == self.Owner)
end

local function getOwner(self, entity)
	if(entity == self.Owner) then return self.Owner end
	if(entity.pl != nil) then return entity.pl end
	if(entity.ply != nil) then return entity.ply end
	if(entity.OnDieFunctions == nil) then return nil end
	if(entity.OnDieFunctions.GetCountUpdate == nil) then return nil end
	if(entity.OnDieFunctions.GetCountUpdate.Args == nil) then return nil end
	if(entity.OnDieFunctions.GetCountUpdate.Args[1] != nil) then return entity.OnDieFunctions.GetCountUpdate.Args[1] end
	if(entity.OnDieFunctions.undo1 == nil) then return nil end
	if(entity.OnDieFunctions.undo1.Args == nil) then return nil end
	if(entity.OnDieFunctions.undo1.Args[2] != nil) then return entity.OnDieFunctions.undo1.Args[2] end
	return nil
end

local function IsWire(entity) //try to find out if the entity is wire
	if(entity.IsWire and entity.IsWire == true) then return true end //this shold always be true if the ent is wire compatible, but only is if the base of the entity is "base_wire_entity" THIS NEEDS TO BE FIXED
	if(entity.Inputs != nil or entity.Outputs != nil) then return true end //this is how the wire STool gun does it
	if(entity.inputs != nil or entity.outputs != nil) then return true end //try lower case
	return false
end

//replacement for lua's awful util.sort() function	
//TODO: Change this to merge sort?
local function StableBubbleSort(Ents,SortFuncion)
	for k=1,#Ents-1 do
		for j=1,#Ents-k do
				if SortFuncion(Ents[j],Ents[j+1]) == false then
						holder = Ents[j]
						Ents[j] = Ents[j+1]
						Ents[j+1] = holder
				end
		end
	end
end

function ENT:Initialize()
	/* Make Physics work */
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )  
	self:SetSolid( SOLID_VPHYSICS )        

	self:DrawShadow(false)

	/* Set wire I/O */
	self.Inputs = WireLib.CreateSpecialInputs(self, {"Wire", "Input", "Output", "SkewX", "SkewY", "TargetAssist", "ClearWire", "CreateWirelink"}, {"NORMAL", "STRING", "STRING", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL"})
	self.Outputs = WireLib.CreateSpecialOutputs(self, { "Stage", "Success", "TargetInputs", "TargetOutputs", "TargetEntity" }, {"NORMAL", "NORMAL", "STRING", "STRING", "ENTITY"})

	/* Initialize values */
	self.Owner = self.pl
	
	self.SkewX = 0
	self.SkewY = 0
	self.WireInSkewX = 0
	self.WireInSkewY = 0
	self.WireFire = 0
	self.PreviousWireFire = 0
	self.Range = 2
	self.Stage = 0
	self.Success = 0
	self.ClearLink = 0
	self.TargetAssist = 0
	self.TargetAssistTimer = 0
	self.LastLaserLineUpdate = CurTime()
	self.TargetEntity = nil
	self.CreateWirelink = 0
	self.PreviousCreateWirelink = 0
	self.TargetPos = Vector(0,0,0)
	self.DefaultColor = Color(255,255,255,255)
	self.TargetPos_Input = 0
	
	
	self.InputName = ""
	self.OutputName = ""
	self.Ents = {}
	
	self.WireWidth = 1
	self.WireMaterial = "cable/rope"
	self.WireColor = Vector(255,255,255)
	
	self:SetBeamRange(250)
	self:SetOverlayText( "Wired Wirer" )
end

function ENT:Setup(Range, WireWidth, WireMaterial, WireColor, Wiretype_Input, TargetPos_Input)
    self:SetBeamRange(math.Clamp(math.abs(Range), 2, math.abs(Range)+10))
	self.Range = math.Clamp(math.abs(Range), 2, math.abs(Range)+10)
	
	local Inputs = {"Wire", "Input", "Output", "SkewX", "SkewY", "TargetAssist", "ClearWire", "CreateWirelink"}
	local InputTypes = {"NORMAL", "STRING", "STRING", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL"}
	
	if(Wiretype_Input == 1) then //Take Wiretype Inputs
		if(TargetPos_Input == 1) then //take 3D TargetPos inputs
			Inputs = {"Wire", "Input", "Output", "TargetX", "TargetY", "TargetZ", "TargetPos", "TargetAssist", "ClearWire", "CreateWirelink", "WireWidth", "WireMaterial", "WireColor"}
			InputTypes = {"NORMAL", "STRING", "STRING", "NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING", "VECTOR"}
		else
			Inputs = {"Wire", "Input", "Output", "SkewX", "SkewY", "TargetAssist", "ClearWire", "CreateWirelink", "WireWidth", "WireMaterial", "WireColor"}
			InputTypes = {"NORMAL", "STRING", "STRING", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "STRING", "VECTOR"}
		end
	else //don't Take Wiretype Inputs
		if(TargetPos_Input == 1) then //take 3D TargetPos inputs
			Inputs = {"Wire", "Input", "Output", "TargetX", "TargetY", "TargetZ", "TargetPos", "TargetAssist", "ClearWire", "CreateWirelink"}
			InputTypes = {"NORMAL", "STRING", "STRING", "NORMAL", "NORMAL", "NORMAL", "VECTOR", "NORMAL", "NORMAL", "NORMAL"}
		else
			Inputs = {"Wire", "Input", "Output", "SkewX", "SkewY", "TargetAssist", "ClearWire", "CreateWirelink"}
			InputTypes = {"NORMAL", "STRING", "STRING", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL"}
		end
	end
	
	WireLib.AdjustSpecialInputs(self, Inputs, InputTypes)
	
	self.WireWidth = WireWidth
	self.WireMaterial = WireMaterial
	self.WireColor = WireColor
	
	self.TargetPos_Input = TargetPos_Input
	
end

function ENT:OnRemove()
	Wire_Remove(self)
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	/* Make sure the gate updates even if we don't receive any input */
	self:TriggerInput()
	
	//update the overlay
	local Txt = "Wired Wirer"
	if(self.Success == 1) then
		Txt = Txt.." - Target is wire"
	elseif(self.Success == 2) then
		Txt = Txt.." - Target is wire and has the corect input/output"
	elseif(self.Success == 3) then
		Txt = Txt.." - In process of wiring"
	end
	self:SetOverlayText( Txt )
	
	self:NextThink(CurTime()+0.5)
	return true
end

local function FixMaterialName(WireMaterial)
	local ValidWireMat = {"cable/rope", "cable/cable2", "cable/xbeam", "cable/redlaser", "cable/blue_elec", "cable/physbeam", "cable/hydra", "arrowire/arrowire", "arrowire/arrowire2"}
	if(!table.HasValue(ValidWireMat,WireMaterial)) then
		if(table.HasValue(ValidWireMat,"cable/"..WireMaterial)) then
			WireMaterial = "cable/"..WireMaterial
		elseif(table.HasValue(ValidWireMat,"arrowire/"..WireMaterial)) then
			WireMaterial = "arrowire/"..WireMaterial
		else
			WireMaterial = "cable/cable2"
		end
	end
	return WireMaterial
end

function ENT:TriggerInput(iname, value)
	/* Change variables to reflect input */
	if (iname == "SkewX") then
		self.WireInSkewX = math.max(-100, math.min(value, 100))
	elseif (iname == "SkewY") then
		self.WireInSkewY = math.max(-100, math.min(value, 100))
	elseif (iname == "Input") then
		self.InputName = value
	elseif (iname == "Output") then
		self.OutputName = value
	elseif (iname == "Wire") then
		self.WireFire = value
	elseif (iname == "TargetAssist") then
		if(value != 0) then 
			self.TargetAssist = 1 
		else 
			self.TargetAssist = 0
		end
	elseif (iname == "ClearWire") then
		self.ClearLink = value
	elseif (iname == "CreateWirelink") then
		self.CreateWirelink = value
	elseif (iname == "WireWidth" and value != self.WireWidth) then
		self.WireWidth = math.Clamp(math.abs(value),0,15)
	elseif (iname == "WireMaterial" and value != "" and value != FixMaterialName(self.WireMaterial)) then
		self.WireMaterial = FixMaterialName(value)
	elseif (iname == "WireColor" and value != self.WireColor) then
		self.WireColor = Vector(math.Clamp(math.abs(value.x),0,255),math.Clamp(math.abs(value.x),0,255),math.Clamp(math.abs(value.x),0,255))
	elseif (iname == "TargetPos") then
		self.TargetPos = Vector(value[1],value[2],value[3])
	elseif (iname == "TargetX") then
		self.TargetPos = Vector(value,self.TargetPos.y,self.TargetPos.z)
	elseif (iname == "TargetY") then
		self.TargetPos = Vector(self.TargetPos.x,value,self.TargetPos.z)
	elseif (iname == "TargetZ") then
		self.TargetPos = Vector(self.TargetPos.x,self.TargetPos.y,value)
	end
	
	
//============= Start of Target Assist ===============================================
	
	/*if the timer is past 0.7 seconds, do a target find to help the Target Assist*/
	if(CurTime()-0.7 >= self.TargetAssistTimer) then
		self.TargetEntity = nil
		self.TargetAssistTimer = CurTime()
		if(self.TargetAssist == 1) then
			//find the end position of the trace so that it can sort them corectly, but don't do it
			local Endpos = Vector(0,0,0)
			if(self.WireInSkewX == 0 and self.WireInSkewY == 0) then
				//find the end of the line
				Endpos = Vector(0,0,0)
				local MidSphere = self:GetPos() + self:GetUp()*self.Range
				if (self.SkewX == 0 and self.SkewY == 0) then
					Endpos = MidSphere
				else
					local skew = Vector(self.SkewX, self.SkewY, 1)
					skew = skew*(self.Range/skew:Length())
					local beam_x = self:GetRight()*skew.x
					local beam_y = self:GetForward()*skew.y
					local beam_z = self:GetUp()*skew.z
					Endpos = self:GetPos() + beam_x + beam_y + beam_z
				end
			else
				//find the end of the line
				Endpos = Vector(0,0,0)
				local MidSphere = self:GetPos() + self:GetUp()*self.Range
				if (self.SkewX == 0 and self.SkewY == 0) then
					Endpos = MidSphere
				else
					local skew = Vector(self.WireInSkewX, self.WireInSkewY, 1)
					skew = skew*(self.Range/skew:Length())
					local beam_x = self:GetRight()*skew.x
					local beam_y = self:GetForward()*skew.y
					local beam_z = self:GetUp()*skew.z
					Endpos = self:GetPos() + beam_x + beam_y + beam_z
				end
			end
			
			//find all of the ents in the sphere centerd at the pos of the wirer and with a radius of the trace lenth
			local PreFilterEnts = ents.FindInSphere(self:GetPos(), self.Range)
			self.Ents = {}
			
			//clip them to just wire things owned by you
			self.TargetEntity = nil
			local i = 1
			for i, CurrentEnt in pairs(PreFilterEnts) do
				if(CurrentEnt and CurrentEnt:IsValid() and CurrentEnt != self and IsWire(CurrentEnt) and getOwner(self, CurrentEnt) == self.pl) then
					if(!self.TargetEntity) then self.TargetEntity = CurrentEnt end
					table.insert(self.Ents,CurrentEnt)
				end
			end
			i = 1
			
			//clip the entities that are not in front of the wirer
			PreFilterEnts = self.Ents
			self.Ents = {}
			self.TargetEntity = nil
			local planeVec = self:GetUp()
			local relPos = self:GetPos():Dot(planeVec)
			for i, CurrentEnt in pairs(PreFilterEnts) do
				if(CurrentEnt and (CurrentEnt:GetPos():Dot(planeVec) - relPos) >= 0) then
					if(!self.TargetEntity) then self.TargetEntity = CurrentEnt end
					table.insert(self.Ents,CurrentEnt)
				end
			end
			
			//sort them by distance to the trace
			local selfEnt = self
			local P1 = selfEnt:GetPos()
			local P2 = Endpos
			table.sort(self.Ents, 
				function(a, b)
					if a == nil || !a:IsValid() then return false end
					if b == nil || !b:IsValid() then return true end
					local aDist = (a:GetPos()-P1):Cross(a:GetPos()-P2):Length()/(P2-P1):Length()
					local bDist = (b:GetPos()-P1):Cross(b:GetPos()-P2):Length()/(P2-P1):Length()
					return (aDist<bDist)
				end
			)
			
			//now sort them so that the first ones are the ones with the Input/Output that we want
			StableBubbleSort(self.Ents,function(a, b)
					if a == nil || !a:IsValid() then return false end
					if b == nil || !b:IsValid() then return true end
					if(self.Stage == 1) then
						if(a.Outputs and self.OutputName != "" and a.Outputs[self.OutputName]) then 
							return true //if a has the correct output do nothing
						elseif(b.Outputs and self.OutputName != "" and b.Outputs[self.OutputName]) then 
							return false //if b has the correct output switch a and b
						else
							return true //else do nothing
						end
					else
						if(a.Inputs and self.InputName != "" and a.Inputs[self.InputName]) then 
							return true //if a has the correct do nothing
						elseif(b.Inputs and self.InputName != "" and b.Inputs[self.InputName]) then
							return false //if b has the correct input switch a and b
						else
							return true //else do nothing
						end
					end
					return true //else do nothing
				end
			)
			
			
			//get the first entity
			self.TargetEntity = nil
			for i, CurrentEnt in pairs(self.Ents) do 
				if(!self.TargetEntity) then 
					self.TargetEntity = CurrentEnt 
					break
				end 
			end
			
		end
	end
	
//===================end of target assist find========================
	
	//set the trace to the correct pos
	if(self.TargetEntity and self.TargetEntity:IsValid() and self.TargetAssist == 1) then //Target Assist Trace
		self.SkewX = -1*self:WorldToLocal(self.TargetEntity:GetPos()).y/self:WorldToLocal(self.TargetEntity:GetPos()).z
		self.SkewY = self:WorldToLocal(self.TargetEntity:GetPos()).x/self:WorldToLocal(self.TargetEntity:GetPos()).z
	elseif(self.TargetAssist == 0 and self.TargetPos != Vector(0,0,0) and self.TargetPos_Input == 1) then //Using Target Vector Position Trace
		//is the point within reach
		if(self.TargetPos:Distance(self:GetPos()) < self.Range) then
			local planeVec = self:GetUp()
			local relPos = self:GetPos():Dot(planeVec)
			//and in front
			if((self.TargetPos:Dot(planeVec) - relPos) >= 0) then
				//set skew
				self.SkewX = -1*self:WorldToLocal(self.TargetPos).y/self:WorldToLocal(self.TargetPos).z
				self.SkewY = self:WorldToLocal(self.TargetPos).x/self:WorldToLocal(self.TargetPos).z
			else //else default to the front
				self.SkewX = 0
				self.SkewY = 0
			end
		else
			self.SkewX = 0
			self.SkewY = 0
		end
	else //using skew trace
		self.SkewX = self.WireInSkewX
		self.SkewY = self.WireInSkewY
	end
	
	//set the skews of the visual ranger (not the trace) only every 0.1 seconds
	if((self.LastLaserLineUpdate+0.1) < CurTime()) then
		self:SetSkewX(self.SkewX)
		self:SetSkewY(self.SkewY)
		self.LastLaserLineUpdate = CurTime()
	end
	
//===============Start the Wirings======================
	
	//start the trace
	local trace = {}
	trace.start = self:GetPos()
	if (self.SkewX == 0 and self.SkewY == 0) then
		trace.endpos = trace.start + self:GetUp()*self.Range
	else
		local skew = Vector(self.SkewX, self.SkewY, 1)
		skew = skew*(self.Range/skew:Length())
		local beam_x = self:GetRight()*skew.x
		local beam_y = self:GetForward()*skew.y
		local beam_z = self:GetUp()*skew.z
		trace.endpos = trace.start + beam_x + beam_y + beam_z
	end
	trace.filter = { self }
	if (self.trace_water) then trace.mask = -1 end
	trace = util.TraceLine(trace)
	
	//save the color
	local StartColor = self:GetColor()
	local UsedColors = { Color(255,181,26,StartColor.a),
						 Color(0,255,0,StartColor.a),
						 Color(0,0,255,StartColor.a) }
	local DefaultToStartColor = true
	local IsAUsedColor = false
	for i,v in ipairs(UsedColors) do
		if(   StartColor == v ) then
			  
			IsAUsedColor = true
			break
		end
	end
	if( IsAUsedColor == true ) then
		StartColor = self.DefaultColor 
		local TempCol = self:GetColor()
		StartColor = Color(StartColor.r,StartColor.g,StartColor.b,TempCol.a)
	else
		StartColor = self:GetColor()
		self.DefaultColor = self:GetColor()
	end
	
	//color the ranger based on the pos and set the sucsess num
	self.Success = 0
	if(trace.Hit) then
		//if it is wire, owned by you, and a valid entity
		if(trace.Entity:IsValid() and (IsWire(trace.Entity) == true) and getOwner(self, trace.Entity) == self.pl) then
			//set the target entity
			Wire_TriggerOutput(self, "Stage", self.Stage)
			//color it yellow
			self:SetColor(Color(255,181,26,StartColor.a))
			DefaultToStartColor = false
			self.Success = 1
			//if it is an input
			if( trace.Entity.Inputs and self.Stage == 0 ) then
				//check the wire
				if(self.InputName != "" and trace.Entity.Inputs[self.InputName]) then
					//color it green
					self:SetColor(Color(0,255,0,StartColor.a))
					DefaultToStartColor = false
					self.Success = 2
					//check for the goahead to wire
					if(self.WireFire != 0 and self.PreviousWireFire == 0) then
						//start the wire
						Wire_Link_Start(self.pl:UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos), self.InputName, self.WireMaterial, self.WireColor, self.WireWidth)
						self.Stage = 1
						//effect on wire
						local effectdata = EffectData()
							effectdata:SetOrigin( trace.HitPos )
							effectdata:SetNormal( trace.HitNormal )
							effectdata:SetMagnitude( 2 )
							effectdata:SetScale( 0.5 )
							effectdata:SetRadius( 2 )
						util.Effect( "Sparks", effectdata )
					end
				end	
			//if it is an output
			elseif( trace.Entity.Outputs and self.Stage == 1 ) then
				//check the wire
				if(self.OutputName != "" and trace.Entity.Outputs[self.OutputName]) then
					//color it green
					self:SetColor(Color(0,255,0,StartColor.a))
					DefaultToStartColor = false
					self.Success = 2
					//check for the goahead to wire
					if(self.WireFire != 0 and self.PreviousWireFire == 0) then
						//end the wire
						Wire_Link_End(self.pl:UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos), self.OutputName, self.pl)
						self.Stage = 0
						//effect on wire
						local effectdata = EffectData()
							effectdata:SetOrigin( trace.HitPos )
							effectdata:SetNormal( trace.HitNormal )
							effectdata:SetMagnitude( 2 )
							effectdata:SetScale( 0.5 )
							effectdata:SetRadius( 2 )
						util.Effect( "Sparks", effectdata )
					end
				end
			end
			
			//create a wirelink
			if(self.CreateWirelink != 0 and self.PreviousCreateWirelink == 0 and !trace.Entity.extended) then
				trace.Entity.extended = true
				RefreshSpecialOutputs(trace.Entity)
				//effect on creation of wirelink
				local effectdata = EffectData()
					effectdata:SetOrigin( trace.HitPos )
					effectdata:SetNormal( trace.HitNormal )
					effectdata:SetMagnitude( 2 )
					effectdata:SetScale( 0.5 )
					effectdata:SetRadius( 2 )
				util.Effect( "Sparks", effectdata )
			end
		elseif(	self.Stage == 1 ) then
			self:SetColor(Color(0,0,255,StartColor.a))
			DefaultToStartColor = false
			self.Success = 3
		end
		
		//create a wire node for "Preaty Wiring"
		if(trace.Entity:IsValid() and !trace.Entity:IsWorld() and self.Stage == 1 and self.WireFire != 0 and self.PreviousWireFire == 0 and getOwner(self, trace.Entity) == self.pl) then
					//effect on node
					local effectdata = EffectData()
						effectdata:SetOrigin( trace.HitPos )
						effectdata:SetNormal( trace.HitNormal )
						effectdata:SetMagnitude( 2 )
						effectdata:SetScale( 0.5 )
						effectdata:SetRadius( 2 )
					util.Effect( "Sparks", effectdata )
					Wire_Link_Node(self.pl:UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos+trace.HitNormal))
		end
	elseif(	self.Stage == 1 ) then
		self:SetColor(Color(0,0,255,StartColor.a))
		DefaultToStartColor = false
		self.Success = 3
	end
	
	if(DefaultToStartColor == true) then
		self:SetColor(StartColor)
	end
	
	//set self.PreviousWireFire and self.PreviousCreateWirelink so that there isn't a never ending cycle
	self.PreviousWireFire = self.WireFire
	self.PreviousCreateWirelink = self.CreateWirelink
	
	//if clear wire is equal to one, calcel the current link if one is started, or delete the wire leading to the current input if it exists, also display a little effect
	if(self.ClearLink == 1) then
		if(self.Stage == 1) then
			Wire_Link_Cancel(self.pl:UniqueID())
			self.Stage = 0
			//effect on cancel
			local effectdata = EffectData()
				effectdata:SetOrigin( self:GetPos()+5*self:GetUp() )
				effectdata:SetNormal( self:GetUp() )
				effectdata:SetMagnitude( 2 )
				effectdata:SetScale( 0.5 )
				effectdata:SetRadius( 2 )
			util.Effect( "Sparks", effectdata )
		elseif(self.Stage == 0)then
			if(trace.Hit and trace.Entity:IsValid() and (IsWire(trace.Entity) == true) and getOwner(self, trace.Entity) == self.pl
				and trace.Entity.Inputs and self.InputName != "" and trace.Entity.Inputs[self.InputName]
				and	trace.Entity.Inputs[self.InputName].Src  and trace.Entity.Inputs[self.InputName].Src:IsValid()) then
				
				Wire_Link_Clear(trace.Entity, self.InputName)
				//effect on clear
				local effectdata = EffectData()
					effectdata:SetOrigin( trace.HitPos )
					effectdata:SetNormal( trace.Entity:GetUp() )
					effectdata:SetMagnitude( 2 )
					effectdata:SetScale( 0.5 )
					effectdata:SetRadius( 2 )
				util.Effect( "Sparks", effectdata )
			end
		end
	end

	
	//get the names of the inputs and outputs
	local Inputs = ""
	local Outputs = ""
	if(trace.Hit) then
		//if it is wire, owned by you, and a valid entity
		if(trace.Entity:IsValid() and getOwner(self, trace.Entity) == self.pl) then
			//get inputs
			if(trace.Entity.Inputs != nil) then
				for Index,value in pairs(trace.Entity.Inputs) do
					Inputs = Inputs .. tostring(Index) .. ", "
				end
				Inputs = string.Trim(string.Left(Inputs, string.len(Inputs) - string.len(", ")))
			end
			
			//get outputs
			if(trace.Entity.Outputs != nil) then
				for Index,value in pairs(trace.Entity.Outputs) do
					Outputs = Outputs .. tostring(Index) .. ", "
				end
				Outputs = string.Trim(string.Left(Outputs, string.len(Outputs) - string.len(", ")))
			end
			
		end
	end
	
	//trigger the outputs
	Wire_TriggerOutput(self, "Stage", self.Stage)
	Wire_TriggerOutput(self, "Success", self.Success)
	Wire_TriggerOutput(self, "TargetInputs", Inputs)
	Wire_TriggerOutput(self, "TargetOutputs", Outputs)
	
	if(trace.Hit and trace.Entity:IsValid() and (IsWire(trace.Entity) == true) and getOwner(self, trace.Entity) == self.pl) then
		Wire_TriggerOutput(self, "TargetEntity", trace.Entity)
	else
		Wire_TriggerOutput(self, "TargetEntity", null)
	end
end