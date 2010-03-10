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
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )  
	self.Entity:SetSolid( SOLID_VPHYSICS )        

	self.Entity:DrawShadow(false)

	/* Set wire I/O */
	self.Entity.Inputs = WireLib.CreateSpecialInputs(self.Entity, {"Wire", "Input", "Output", "SkewX", "SkewY", "TargetAssist", "ClearWire", "CreateWirelink"}, {"NORMAL", "STRING", "STRING", "NORMAL", "NORMAL", "NORMAL", "NORMAL", "NORMAL"})
	self.Entity.Outputs = WireLib.CreateSpecialOutputs(self.Entity, { "Stage", "Success", "TargetInputs", "TargetOutputs", "TargetEntity" }, {"NORMAL", "NORMAL", "STRING", "STRING", "ENTITY"})

	/* Initialize values */
	self.Entity.Owner = self.Entity.pl
	
	self.Entity.SkewX = 0
	self.Entity.SkewY = 0
	self.Entity.WireInSkewX = 0
	self.Entity.WireInSkewY = 0
	self.Entity.WireFire = 0
	self.Entity.PreviousWireFire = 0
	self.Entity.Range = 2
	self.Entity.Stage = 0
	self.Entity.Success = 0
	self.Entity.ClearLink = 0
	self.Entity.TargetAssist = 0
	self.Entity.TargetAssistTimer = 0
	self.Entity.LastLaserLineUpdate = CurTime()
	self.Entity.TargetEntity = nil
	self.Entity.CreateWirelink = 0
	self.Entity.PreviousCreateWirelink = 0
	self.Entity.TargetPos = Vector(0,0,0)
	self.Entity.DefaultColor = {255,255,255,255}
	self.Entity.TargetPos_Input = 0
	
	
	self.Entity.InputName = ""
	self.Entity.OutputName = ""
	self.Entity.Ents = {}
	
	self.Entity.WireWidth = 1
	self.Entity.WireMaterial = "cable/rope"
	self.Entity.WireColor = Vector(255,255,255)
	
	self:SetBeamRange(250)
	self:SetOverlayText( "Wired Wirer" )
end

function ENT:Setup(Range, WireWidth, WireMaterial, WireColor, Wiretype_Input, TargetPos_Input)
    self:SetBeamRange(math.Clamp(math.abs(Range), 2, math.abs(Range)+10))
	self.Entity.Range = math.Clamp(math.abs(Range), 2, math.abs(Range)+10)
	
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
	
	WireLib.AdjustSpecialInputs(self.Entity, Inputs, InputTypes)
	
	self.Entity.WireWidth = WireWidth
	self.Entity.WireMaterial = WireMaterial
	self.Entity.WireColor = WireColor
	
	self.Entity.TargetPos_Input = TargetPos_Input
	
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:Think()
	self.Entity.BaseClass.Think(self)
	
	/* Make sure the gate updates even if we don't receive any input */
	self:TriggerInput()
	
	//update the overlay
	local Txt = "Wired Wirer"
	if(self.Entity.Success == 1) then
		Txt = Txt.." - Target is wire"
	elseif(self.Entity.Success == 2) then
		Txt = Txt.." - Target is wire and has the corect input/output"
	elseif(self.Entity.Success == 3) then
		Txt = Txt.." - In process of wiring"
	end
	self:SetOverlayText( Txt )
	
	self.Entity:NextThink(CurTime()+0.5)
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
		self.Entity.WireInSkewX = math.max(-100, math.min(value, 100))
	elseif (iname == "SkewY") then
		self.Entity.WireInSkewY = math.max(-100, math.min(value, 100))
	elseif (iname == "Input") then
		self.Entity.InputName = value
	elseif (iname == "Output") then
		self.Entity.OutputName = value
	elseif (iname == "Wire") then
		self.Entity.WireFire = value
	elseif (iname == "TargetAssist") then
		if(value != 0) then 
			self.Entity.TargetAssist = 1 
		else 
			self.Entity.TargetAssist = 0
		end
	elseif (iname == "ClearWire") then
		self.Entity.ClearLink = value
	elseif (iname == "CreateWirelink") then
		self.Entity.CreateWirelink = value
	elseif (iname == "WireWidth" and value != self.Entity.WireWidth) then
		self.Entity.WireWidth = math.Clamp(math.abs(value),0,15)
	elseif (iname == "WireMaterial" and value != "" and value != FixMaterialName(self.Entity.WireMaterial)) then
		self.Entity.WireMaterial = FixMaterialName(value)
	elseif (iname == "WireColor" and value != self.Entity.WireColor) then
		self.Entity.WireColor = Vector(math.Clamp(math.abs(value.x),0,255),math.Clamp(math.abs(value.x),0,255),math.Clamp(math.abs(value.x),0,255))
	elseif (iname == "TargetPos") then
		self.Entity.TargetPos = Vector(value[1],value[2],value[3])
	elseif (iname == "TargetX") then
		self.Entity.TargetPos = Vector(value,self.Entity.TargetPos.y,self.Entity.TargetPos.z)
	elseif (iname == "TargetY") then
		self.Entity.TargetPos = Vector(self.Entity.TargetPos.x,value,self.Entity.TargetPos.z)
	elseif (iname == "TargetZ") then
		self.Entity.TargetPos = Vector(self.Entity.TargetPos.x,self.Entity.TargetPos.y,value)
	end
	
	
//============= Start of Target Assist ===============================================
	
	/*if the timer is past 0.7 seconds, do a target find to help the Target Assist*/
	if(CurTime()-0.7 >= self.Entity.TargetAssistTimer) then
		self.Entity.TargetEntity = nil
		self.Entity.TargetAssistTimer = CurTime()
		if(self.Entity.TargetAssist == 1) then
			//find the end position of the trace so that it can sort them corectly, but don't do it
			local Endpos = Vector(0,0,0)
			if(self.Entity.WireInSkewX == 0 and self.Entity.WireInSkewY == 0) then
				//find the end of the line
				Endpos = Vector(0,0,0)
				local MidSphere = self.Entity:GetPos() + self.Entity:GetUp()*self.Entity.Range
				if (self.Entity.SkewX == 0 and self.Entity.SkewY == 0) then
					Endpos = MidSphere
				else
					local skew = Vector(self.Entity.SkewX, self.Entity.SkewY, 1)
					skew = skew*(self.Entity.Range/skew:Length())
					local beam_x = self.Entity:GetRight()*skew.x
					local beam_y = self.Entity:GetForward()*skew.y
					local beam_z = self.Entity:GetUp()*skew.z
					Endpos = self.Entity:GetPos() + beam_x + beam_y + beam_z
				end
			else
				//find the end of the line
				Endpos = Vector(0,0,0)
				local MidSphere = self.Entity:GetPos() + self.Entity:GetUp()*self.Entity.Range
				if (self.Entity.SkewX == 0 and self.Entity.SkewY == 0) then
					Endpos = MidSphere
				else
					local skew = Vector(self.Entity.WireInSkewX, self.Entity.WireInSkewY, 1)
					skew = skew*(self.Entity.Range/skew:Length())
					local beam_x = self.Entity:GetRight()*skew.x
					local beam_y = self.Entity:GetForward()*skew.y
					local beam_z = self.Entity:GetUp()*skew.z
					Endpos = self.Entity:GetPos() + beam_x + beam_y + beam_z
				end
			end
			
			//find all of the ents in the sphere centerd at the pos of the wirer and with a radius of the trace lenth
			local PreFilterEnts = ents.FindInSphere(self.Entity:GetPos(), self.Entity.Range)
			self.Entity.Ents = {}
			
			//clip them to just wire things owned by you
			self.Entity.TargetEntity = nil
			local i = 1
			for i, CurrentEnt in pairs(PreFilterEnts) do
				if(CurrentEnt and CurrentEnt:IsValid() and CurrentEnt != self.Entity and IsWire(CurrentEnt) and getOwner(self.Entity, CurrentEnt) == self.Entity.pl) then
					if(!self.Entity.TargetEntity) then self.Entity.TargetEntity = CurrentEnt end
					table.insert(self.Entity.Ents,CurrentEnt)
				end
			end
			i = 1
			
			//clip the entities that are not in front of the wirer
			PreFilterEnts = self.Entity.Ents
			self.Entity.Ents = {}
			self.Entity.TargetEntity = nil
			local planeVec = self.Entity:GetUp()
			local relPos = self.Entity:GetPos():Dot(planeVec)
			for i, CurrentEnt in pairs(PreFilterEnts) do
				if(CurrentEnt and (CurrentEnt:GetPos():Dot(planeVec) - relPos) >= 0) then
					if(!self.Entity.TargetEntity) then self.Entity.TargetEntity = CurrentEnt end
					table.insert(self.Entity.Ents,CurrentEnt)
				end
			end
			
			//sort them by distance to the trace
			local selfEnt = self.Entity
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
					if(self.Entity.Stage == 1) then
						if(a.Outputs and self.Entity.OutputName != "" and a.Outputs[self.Entity.OutputName]) then 
							return true //if a has the correct output do nothing
						elseif(b.Outputs and self.Entity.OutputName != "" and b.Outputs[self.Entity.OutputName]) then 
							return false //if b has the correct output switch a and b
						else
							return true //else do nothing
						end
					else
						if(a.Inputs and self.Entity.InputName != "" and a.Inputs[self.Entity.InputName]) then 
							return true //if a has the correct do nothing
						elseif(b.Inputs and self.Entity.InputName != "" and b.Inputs[self.Entity.InputName]) then
							return false //if b has the correct input switch a and b
						else
							return true //else do nothing
						end
					end
					return true //else do nothing
				end
			)
			
			
			//get the first entity
			self.Entity.TargetEntity = nil
			for i, CurrentEnt in pairs(self.Entity.Ents) do 
				if(!self.Entity.TargetEntity) then 
					self.Entity.TargetEntity = CurrentEnt 
					break
				end 
			end
			
		end
	end
	
//===================end of target assist find========================
	
	//set the trace to the correct pos
	if(self.Entity.TargetEntity and self.Entity.TargetEntity:IsValid() and self.Entity.TargetAssist == 1) then //Target Assist Trace
		self.Entity.SkewX = -1*self.Entity:WorldToLocal(self.Entity.TargetEntity:GetPos()).y/self.Entity:WorldToLocal(self.Entity.TargetEntity:GetPos()).z
		self.Entity.SkewY = self.Entity:WorldToLocal(self.Entity.TargetEntity:GetPos()).x/self.Entity:WorldToLocal(self.Entity.TargetEntity:GetPos()).z
	elseif(self.Entity.TargetAssist == 0 and self.Entity.TargetPos != Vector(0,0,0) and self.Entity.TargetPos_Input == 1) then //Using Target Vector Position Trace
		//is the point within reach
		if(self.Entity.TargetPos:Distance(self.Entity:GetPos()) < self.Entity.Range) then
			local planeVec = self.Entity:GetUp()
			local relPos = self.Entity:GetPos():Dot(planeVec)
			//and in front
			if((self.Entity.TargetPos:Dot(planeVec) - relPos) >= 0) then
				//set skew
				self.Entity.SkewX = -1*self.Entity:WorldToLocal(self.Entity.TargetPos).y/self.Entity:WorldToLocal(self.Entity.TargetPos).z
				self.Entity.SkewY = self.Entity:WorldToLocal(self.Entity.TargetPos).x/self.Entity:WorldToLocal(self.Entity.TargetPos).z
			else //else default to the front
				self.Entity.SkewX = 0
				self.Entity.SkewY = 0
			end
		else
			self.Entity.SkewX = 0
			self.Entity.SkewY = 0
		end
	else //using skew trace
		self.Entity.SkewX = self.Entity.WireInSkewX
		self.Entity.SkewY = self.Entity.WireInSkewY
	end
	
	//set the skews of the visual ranger (not the trace) only every 0.1 seconds
	if((self.Entity.LastLaserLineUpdate+0.1) < CurTime()) then
		self:SetSkewX(self.Entity.SkewX)
		self:SetSkewY(self.Entity.SkewY)
		self.Entity.LastLaserLineUpdate = CurTime()
	end
	
//===============Start the Wirings======================
	
	//start the trace
	local trace = {}
	trace.start = self.Entity:GetPos()
	if (self.Entity.SkewX == 0 and self.Entity.SkewY == 0) then
		trace.endpos = trace.start + self.Entity:GetUp()*self.Entity.Range
	else
		local skew = Vector(self.Entity.SkewX, self.Entity.SkewY, 1)
		skew = skew*(self.Entity.Range/skew:Length())
		local beam_x = self.Entity:GetRight()*skew.x
		local beam_y = self.Entity:GetForward()*skew.y
		local beam_z = self.Entity:GetUp()*skew.z
		trace.endpos = trace.start + beam_x + beam_y + beam_z
	end
	trace.filter = { self.Entity }
	if (self.Entity.trace_water) then trace.mask = -1 end
	trace = util.TraceLine(trace)
	
	//save the color
	local StartColor = {self.Entity:GetColor()}
	local UsedColors = { {255,181,26,StartColor[4]},
						 {0,255,0,StartColor[4]},
						 {0,0,255,StartColor[4]} }
	local DefaultToStartColor = true
	local IsAUsedColor = false
	for i,v in ipairs(UsedColors) do
		if(   StartColor[1] == v[1] and 
		      StartColor[2] == v[2] and 
		      StartColor[3] == v[3] and 
		      StartColor[4] == v[4]   ) then
			  
			IsAUsedColor = true
			break
		end
	end
	if( IsAUsedColor == true ) then
		StartColor = self.Entity.DefaultColor 
		local TempCol = {self.Entity:GetColor()}
		StartColor = {StartColor[1],StartColor[2],StartColor[3],TempCol[4]}
	else
		StartColor = {self.Entity:GetColor()}
		self.Entity.DefaultColor = {self.Entity:GetColor()}
	end
	
	//color the ranger based on the pos and set the sucsess num
	self.Entity.Success = 0
	if(trace.Hit) then
		//if it is wire, owned by you, and a valid entity
		if(trace.Entity:IsValid() and (IsWire(trace.Entity) == true) and getOwner(self.Entity, trace.Entity) == self.Entity.pl) then
			//set the target entity
			Wire_TriggerOutput(self.Entity, "Stage", self.Entity.Stage)
			//color it yellow
			self.Entity:SetColor(255,181,26,StartColor[4])
			DefaultToStartColor = false
			self.Entity.Success = 1
			//if it is an input
			if( trace.Entity.Inputs and self.Entity.Stage == 0 ) then
				//check the wire
				if(self.Entity.InputName != "" and trace.Entity.Inputs[self.Entity.InputName]) then
					//color it green
					self.Entity:SetColor(0,255,0,StartColor[4])
					DefaultToStartColor = false
					self.Entity.Success = 2
					//check for the goahead to wire
					if(self.Entity.WireFire != 0 and self.Entity.PreviousWireFire == 0) then
						//start the wire
						Wire_Link_Start(self.Entity.pl:UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos), self.Entity.InputName, self.Entity.WireMaterial, self.Entity.WireColor, self.Entity.WireWidth)
						self.Entity.Stage = 1
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
			elseif( trace.Entity.Outputs and self.Entity.Stage == 1 ) then
				//check the wire
				if(self.Entity.OutputName != "" and trace.Entity.Outputs[self.Entity.OutputName]) then
					//color it green
					self.Entity:SetColor(0,255,0,StartColor[4])
					DefaultToStartColor = false
					self.Entity.Success = 2
					//check for the goahead to wire
					if(self.Entity.WireFire != 0 and self.Entity.PreviousWireFire == 0) then
						//end the wire
						Wire_Link_End(self.Entity.pl:UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos), self.Entity.OutputName, self.Entity.pl)
						self.Entity.Stage = 0
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
			if(self.Entity.CreateWirelink != 0 and self.Entity.PreviousCreateWirelink == 0 and !trace.Entity.extended) then
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
		elseif(	self.Entity.Stage == 1 ) then
			self.Entity:SetColor(0,0,255,StartColor[4])
			DefaultToStartColor = false
			self.Entity.Success = 3
		end
		
		//create a wire node for "Preaty Wiring"
		if(trace.Entity:IsValid() and !trace.Entity:IsWorld() and self.Entity.Stage == 1 and self.Entity.WireFire != 0 and self.Entity.PreviousWireFire == 0 and getOwner(self.Entity, trace.Entity) == self.Entity.pl) then
					//effect on node
					local effectdata = EffectData()
						effectdata:SetOrigin( trace.HitPos )
						effectdata:SetNormal( trace.HitNormal )
						effectdata:SetMagnitude( 2 )
						effectdata:SetScale( 0.5 )
						effectdata:SetRadius( 2 )
					util.Effect( "Sparks", effectdata )
					Wire_Link_Node(self.Entity.pl:UniqueID(), trace.Entity, trace.Entity:WorldToLocal(trace.HitPos+trace.HitNormal))
		end
	elseif(	self.Entity.Stage == 1 ) then
		self.Entity:SetColor(0,0,255,StartColor[4])
		DefaultToStartColor = false
		self.Entity.Success = 3
	end
	
	if(DefaultToStartColor == true) then
		self.Entity:SetColor(StartColor[1],StartColor[2],StartColor[3],StartColor[4])
	end
	
	//set self.PreviousWireFire and self.PreviousCreateWirelink so that there isn't a never ending cycle
	self.Entity.PreviousWireFire = self.Entity.WireFire
	self.Entity.PreviousCreateWirelink = self.Entity.CreateWirelink
	
	//if clear wire is equal to one, calcel the current link if one is started, or delete the wire leading to the current input if it exists, also display a little effect
	if(self.Entity.ClearLink == 1) then
		if(self.Entity.Stage == 1) then
			Wire_Link_Cancel(self.Entity.pl:UniqueID())
			self.Entity.Stage = 0
			//effect on cancel
			local effectdata = EffectData()
				effectdata:SetOrigin( self.Entity:GetPos()+5*self.Entity:GetUp() )
				effectdata:SetNormal( self.Entity:GetUp() )
				effectdata:SetMagnitude( 2 )
				effectdata:SetScale( 0.5 )
				effectdata:SetRadius( 2 )
			util.Effect( "Sparks", effectdata )
		elseif(self.Entity.Stage == 0)then
			if(trace.Hit and trace.Entity:IsValid() and (IsWire(trace.Entity) == true) and getOwner(self.Entity, trace.Entity) == self.Entity.pl
				and trace.Entity.Inputs and self.Entity.InputName != "" and trace.Entity.Inputs[self.Entity.InputName]
				and	trace.Entity.Inputs[self.Entity.InputName].Src  and trace.Entity.Inputs[self.Entity.InputName].Src:IsValid()) then
				
				Wire_Link_Clear(trace.Entity, self.Entity.InputName)
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
		if(trace.Entity:IsValid() and getOwner(self.Entity, trace.Entity) == self.Entity.pl) then
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
	Wire_TriggerOutput(self.Entity, "Stage", self.Entity.Stage)
	Wire_TriggerOutput(self.Entity, "Success", self.Entity.Success)
	Wire_TriggerOutput(self.Entity, "TargetInputs", Inputs)
	Wire_TriggerOutput(self.Entity, "TargetOutputs", Outputs)
	
	if(trace.Hit and trace.Entity:IsValid() and (IsWire(trace.Entity) == true) and getOwner(self, trace.Entity) == self.pl) then
		Wire_TriggerOutput(self, "TargetEntity", trace.Entity)
	else
		Wire_TriggerOutput(self, "TargetEntity", null)
	end
end