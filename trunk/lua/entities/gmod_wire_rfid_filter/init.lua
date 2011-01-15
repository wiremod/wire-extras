
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "RFID Target Filter"

local MODEL = Model("models/jaanus/wiretool/wiretool_siren.mdl")

function ___comp___(a,o,b)
		if o==0 then return a==b
	elseif o==1 then return a~=b
	elseif o==2 then return a<b
	elseif o==3 then return a>b
	elseif o==4 then return a<=b
	elseif o==5 then return a>=b
	            else return true
	end
end

function ENT:Initialize()
	self:SetModel( MODEL )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	
	self.A=0
	self.B=0
	self.C=0
	self.D=0
	self.cA=0
	self.cB=0
	self.cC=0
	self.cD=0
	self.filtertype=0
	
	self:ShowOutput()
end

function ENT:OnRemove()
	local Target = self:GetLinkedTargetFinder()
	if(Target and Target.Think_OMGRFIDBACKUPLOL) then -- Restore the default "Think" function, and delete the backup
		Target.Think = self.Target.Think_OMGRFIDBACKUPLOL
		Target.Think_OMGRFIDBACKUPLOL = nil
		Target.RFID_FILTER_LINKED = nil
	end
	Wire_Remove(self)
end

function ENT:Setup(a,b,c,d,ca,cb,cc,cd,typ,ent_target)
	if a then
		self.A=a
		self.B=b
		self.C=c
		self.D=d
		self.cA=ca
		self.cB=cb
		self.cC=cc
		self.cD=cd
		self.filtertype=typ
	end
	
	if !ent_target or ent_target:GetClass() != "gmod_wire_target_finder" then return end
	
	if ent_target.RFID_FILTER_LINKED then -- Already have a linked filter ?
		ent_target.RFID_FILTER_LINKED:SetLinkedTargetFinder(nil)
		ent_target.Think = ent_target.Think_OMGRFIDBACKUPLOL
		ent_target.Think_OMGRFIDBACKUPLOL = nil
	end -- Cleaned up !
	
	ent_target.RFID_FILTER_LINKED = self
	
	ent_target.Think_OMGRFIDBACKUPLOL = ent_target.Think -- Create a OMG BACKUP OF TEH THINK FUNCTION
	
	ent_target.Think = function(this)
		this.BaseClass.Think(this)
		local link = this.RFID_FILTER_LINKED

		if (this.Inputs.Hold) and (this.Inputs.Hold.Value > 0) then
		else
			if (this.NextTargetTime) and (CurTime() < this.NextTargetTime) then return end
			this.NextTargetTime = CurTime()+1
		
			local mypos = this.Entity:GetPos()
			local bogeys,dists = {},{}
			for _,contact in pairs(ents.FindInSphere(this.Entity:GetPos(), this.MaxRange or 10)) do
				local class = contact:GetClass()
				if (not this.NoTargetOwnersStuff or (class == "player") or (contact:GetOwner() ~= this:GetPlayer() and not this:checkOwnership(contact))) and (((this.TargetNPC) and (string.find(class, "^npc_.*")) and (class ~= "npc_heli_avoidsphere") and (this:FindInValue(class,this.NPCName))) or ((this.TargetPlayer) and (class == "player") and (!this.NoTargetOwner or this:GetPlayer() != contact) and this:FindInValue(contact:GetName(),this.PlayerName,this.CaseSen) and this:FindInValue(contact:SteamID(),this.SteamName) and this:FindColor(contact) and this:CheckTheBuddyList(contact)) or ((this.TargetBeacon) and (class == "gmod_wire_locator")) or ((this.TargetRPGs) and (class == "rpg_missile")) or ((this.TargetHoverballs) and (class == "gmod_hoverball" or class == "gmod_wire_hoverball")) or ((this.TargetThrusters)	and (class == "gmod_thruster" or class == "gmod_wire_thruster" or class == "gmod_wire_vectorthruster")) or ((this.TargetProps) and (class == "prop_physics") and (this:FindInValue(contact:GetModel(),this.PropModel))) or ((this.TargetVehicles) and (string.find(class, "prop_vehicle"))) or (this.EntFil ~= "" and this:FindInValue(class,this.EntFil))) then
					-- This is the only modification performed in the Think() function from the target finder
					-- Yes, I suck, and can't find any easier way, duh
					if ((link.filtertype==0 and (not(contact.__RFID_HASRFID)
											or not(___comp___(contact.__RFID_A,link.cA,link.A))
											or not(___comp___(contact.__RFID_B,link.cB,link.B))
											or not(___comp___(contact.__RFID_C,link.cC,link.C))
											or not(___comp___(contact.__RFID_D,link.cD,link.D)))) or
						(link.filtertype==1 and contact.__RFID_HASRFID
											and (___comp___(contact.__RFID_A,link.cA,link.A))
											and (___comp___(contact.__RFID_B,link.cB,link.B))
											and (___comp___(contact.__RFID_C,link.cC,link.C))
											and (___comp___(contact.__RFID_D,link.cD,link.D))) or
						(link.filtertype==2 and not(contact.__RFID_HASRFID)) or
						(link.filtertype==3 and contact.__RFID_HASRFID)) then
						local dist = (contact:GetPos() - mypos):Length()
						if (dist >= this.MinRange) then
							bogeys[dist] = contact
							table.insert(dists,dist)
						end
					end
					-- TEH END
				end
			end
		
			this.Bogeys = {}
			this.InRange = {}
			table.sort(dists)
			local k = 1
			for i,d in pairs(dists) do
				if !this:IsTargeted(bogeys[d], i) then
					this.Bogeys[k] = bogeys[d]
					k = k + 1
					if (k > this.MaxBogeys) then break end
				end
			end
			
			for i = 1, this.MaxTargets do
				if (this:IsOnHold(i)) then
					this.InRange[i] = true
				end
			
				if (!this.InRange[i]) or (!this.SelectedTargets[i]) or (this.SelectedTargets[i] == nil) or (!this.SelectedTargets[i]:IsValid()) then
					if (this.PaintTarget) then this:TargetPainter(this.SelectedTargets[i], false) end
					if (#this.Bogeys > 0) then
						this.SelectedTargets[i] = table.remove(this.Bogeys, 1)
						if (this.PaintTarget) then this:TargetPainter(this.SelectedTargets[i], true) end
						Wire_TriggerOutput(this.Entity, tostring(i), 1)
						Wire_TriggerOutput(this.Entity, tostring(i).."_Ent", this.SelectedTargets[i])
					else
						this.SelectedTargets[i] = nil
						Wire_TriggerOutput(this.Entity, tostring(i), 0)
						Wire_TriggerOutput(this.Entity, tostring(i).."_Ent", NULL)
					end
				end
			end
		end
	
		if this.SelectedTargets[1] then this:ShowOutput(true)
		else this:ShowOutput(false) end
	end
	
	self:SetLinkedTargetFinder(ent_target)
end

function ENT:ShowOutput()
	self:SetOverlayText( "RFID Target Filter" )
end

function ENT:OnRestore()
    Wire_Restored(self)
end
