AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Dupe Teleporter"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	
	self.Outputs = WireLib.CreateSpecialOutputs(self,{"Entity Scaned","Entity Serialised","Spawn Available","Deserialisable Input Available","Data Output","Sending","Blocks Sended","Receiving","Blocks Received","Serialised Output Block Count","Serialised Input Block Count"},{"NORMAL","NORMAL","NORMAL","NORMAL","STRING","NORMAL","NORMAL","NORMAL","NORMAL","NORMAL","NORMAL"})
	self.Inputs = WireLib.CreateSpecialInputs(self,{"Read Entity","Serialise Entity","Spawn Entity","Deserialise Input","Data Input","Start Data Sending","Piece Size","Clear Input","Spawn Player SteamID"},{"NORMAL","NORMAL","NORMAL","NORMAL","STRING","NORMAL","NORMAL","NORMAL","STRING"})
	
	self.OutHeadEntityIdx	= nil
	self.OutHoldAngle 		= nil
	self.OutHoldPos 		= nil
	self.OutStartPos		= nil
	self.OutEntities		= nil
	self.OutConstraints		= nil
	self.OutNumOfEnts		= 0
	self.OutNumOfConst		= 0
	
	self.OutSerialised 		= ""
	self.OutBlockCount		= 0
	self.OutBlocks			= nil
	
	self.OutBlockSendNum 	= -1
	
	self.InHeadEntityIdx	= nil
	self.InHoldAngle 		= nil
	self.InHoldPos 			= nil
	self.InStartPos			= nil
	self.InEntities			= nil
	self.InConstraints		= nil
	self.InNumOfEnts		= 0
	self.InNumOfConst		= 0
	
	self.InSerialised 		= ""
	self.InBlocks			= nil
	self.InBlockCount 		= 0
	
	self.Copied			= false
	self.SpawnData 		= false
	
	self.PieceSize = 32
	
	self.SendingData = false
	self.ReceivingData = false
	
	self.OwnerSteamID = ""
	self.SpawnSteamID = ""
	
	self:ClearClipBoard()
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if (self.SendingData) then
		if (self.OutBlockSendNum == -1) then
			self.OutBlockSendNum = 0
			
			Wire_TriggerOutput(self,"Data Output","Data:Start:"..self.OutBlockCount)
			
			Wire_TriggerOutput(self,"Sending",1)
		else
			if (self.OutBlockSendNum == self.OutBlockCount) then
				self.SendingData = false
				self.OutBlockSendNum = -1
				Wire_TriggerOutput(self,"Sending",0)
				Wire_TriggerOutput(self,"Blocks Sended",0)
				Wire_TriggerOutput(self,"Data Output","")
			else
				Wire_TriggerOutput(self,"Data Output","Data:"..self.OutBlockSendNum..":"..self.OutBlocks[self.OutBlockSendNum])
				Wire_TriggerOutput(self,"Blocks Sended",self.OutBlockSendNum+1)
				self.OutBlockSendNum = self.OutBlockSendNum + 1
			end
		end
	end
	
	self:NextThink( CurTime() + 0.1 )
end

function ENT:TriggerInput(iname, value)
	if (iname == "Read Entity") then
		if (value > 0 && !self.SendingData) then
			self:ClearClipBoard()
						
			if ( CLIENT ) then return true end
			
			local StartPos = self:GetPos()
			
			local tr = {}
			tr.start = StartPos
			tr.endpos = StartPos + self:GetUp() * 100
			tr.filter = { self }
			local trace = util.TraceLine( tr )
			
			if (trace.Entity && trace.Entity:IsValid()) then
				self.OutEntities = {}
				self.OutConstraints = {}
				
				AdvDupe.Copy( trace.Entity, self.OutEntities, self.OutConstraints, StartPos )
				
				local angle  = self:GetAngles()
					
				self.OutHeadEntityIdx	= trace.Entity:EntIndex()
				self.OutHoldAngle 		= angle
				self.OutHoldPos 		= trace.Entity:WorldToLocal( StartPos )
				self.OutStartPos		= StartPos

				self.OrgStartPos	= StartPos
				
				self.OutNumOfEnts		= table.Count(self.OutEntities)	or 0
				self.OutNumOfConst		= table.Count(self.OutConstraints)	or 0
				
				self.Copied	= true
				Wire_TriggerOutput(self, "Entity Scaned", 1)
			end
		end
	elseif (iname == "Spawn Entity") then
		if (value > 0 && !self.SendingData) then
			if ( CLIENT ) then	return true	end
			if ( self.SpawnData ) then
				local ply = self:GetUserEntity(self.SpawnSteamID)
				local angle  = self:GetAngles()
				if (ply) then
					AdvDupe.StartPaste( ply, self.InEntities, self.InConstraints, self.InHeadEntityIdx, self:GetPos(), self:GetAngles()-self.InHoldAngle, self.InNumOfEnts, self.InNumOfConst, false, false, nil, true, self, true )
				end
			end
		end
	elseif (iname == "Serialise Entity") then
		if (value > 0 && self.Copied && !self.SendingData) then
			local Header = {}
			Header[1] = "Type:"			.."AdvDupe File"
			Header[2] =	"Creator:"		..string.format('%q', self:GetUserEntity(self.OwnerSteamID):GetName())
			Header[3] =	"Date:"			..os.date("%m/%d/%y")
			Header[4] =	"Description:"	..string.format('%q', "none")
			Header[5] =	"Entities:"		..self.OutNumOfEnts
			Header[6] =	"Constraints:"	..self.OutNumOfConst
			
			local ExtraHeader = {}
			ExtraHeader[1] = "FileVersion:"				..AdvDupe.FileVersion
			ExtraHeader[2] = "AdvDupeVersion:"			..AdvDupe.Version
			ExtraHeader[3] = "AdvDupeToolVersion:"		..AdvDupe.ToolVersion
			ExtraHeader[4] = "AdvDupeSharedVersion:"	..dupeshare.Version
			ExtraHeader[5] = "SerialiserVersion:"		..Serialiser.Version
			ExtraHeader[6] = "WireVersion:"				..(WireVersion or "Not Installed")
			ExtraHeader[7] = "Time:"					..os.date("%I:%M %p")
			ExtraHeader[8] = "Head:"					..self.OutHeadEntityIdx
			ExtraHeader[9] = "HoldAngle:"				..string.format( "%g,%g,%g", self.OutHoldAngle.pitch, self.OutHoldAngle.yaw, self.OutHoldAngle.roll )
			ExtraHeader[10] = "HoldPos:"				..string.format( "%g,%g,%g", self.OutHoldPos.x, self.OutHoldPos.y, self.OutHoldPos.z )
			ExtraHeader[11] = "StartPos:"				..string.format( "%g,%g,%g", self.OutStartPos.x, self.OutStartPos.y, self.OutStartPos.z )
			
			ConstsTable				= {}
			for k, v in pairs(self.OutConstraints) do
				table.insert( ConstsTable, v )
			end
			
			local StrTbl = {}
			StrTbl.Strings = {} --keyed with string indexes
			StrTbl.StringIndx = {} --keyed with strings
			StrTbl.LastIndx = 0 --the index last used
			StrTbl.Saved = 0 --number of strings we didn't have to save
			
			local EntsStr = Serialiser.SingleTable( self.OutEntities, StrTbl, false )
			local ConstsStr = Serialiser.SingleTable( ConstsTable, StrTbl, false )
				
			local Dict = {}
			for idx,cstr in pairs(StrTbl.Strings) do
				table.insert(Dict, table.concat( {idx, ":", cstr} ))
			end
			local DictStr = table.concat( Dict, "\n" ) .. "\nSaved:" .. StrTbl.Saved
			
			self.OutSerialised = table.concat(
				{
				"[Info]",
				table.concat( Header, "\n" ),
				"[More Information]",
				table.concat( ExtraHeader, "\n" ),
				"[Save]",
				"Entities:"..EntsStr,
				"Constraints:"..ConstsStr,
				"[Dict]",
				DictStr
				}, "\n")
				
			Wire_TriggerOutput(self, "Entity Serialised", 1)
			
			local length = string.len(self.OutSerialised)
			self.OutBlocks = {}
			self.OutBlockCount = math.ceil(length/self.PieceSize)
			for i = 1,length,self.PieceSize do
				if ((length - i) >= (self.PieceSize - 1)) then
					self.OutBlocks[(i-1)/self.PieceSize] = string.sub(self.OutSerialised,i,i + self.PieceSize - 1)
				else
					self.OutBlocks[(i-1)/self.PieceSize] = string.sub(self.OutSerialised,i,length)
				end
			end
			Wire_TriggerOutput(self,"Serialised Output Block Count",self.OutBlockCount)
		end
	elseif (iname == "Deserialise Input") then
		if (value > 0 && self.InSerialised != "" && !self.SendingData) then
			if ( string.Left(self.InSerialised, 5) != "\"Out\"") then
				local function DupePortLoad(ply, filepath, ent, HeaderTbl, ExtraHeaderTbl, Data)
					if ( HeaderTbl.Type ) and ( HeaderTbl.Type == "AdvDupe File" ) then
						ExtraHeaderTbl.FileVersion = tonumber(ExtraHeaderTbl.FileVersion)
						
						if (ExtraHeaderTbl.FileVersion > AdvDupe.FileVersion) then
							Msg("AdvDupeINFO:File is newer than installed version, failure may occure, you should update.")
						end
						
						if ( ExtraHeaderTbl.FileVersion >= 0.82 ) and ( ExtraHeaderTbl.FileVersion < 0.9 )then
							local a,b,c = ExtraHeaderTbl.HoldAngle:match("(.-),(.-),(.+)")
							local HoldAngle = Angle( tonumber(a), tonumber(b), tonumber(c) )
							
							ent:DupeLoadCallBack(Data.Entities,Data.Constraints,tonumber(ExtraHeaderTbl.Head),tonumber(HeaderTbl.Entities),tonumber(HeaderTbl.Constraints),HoldAngle)
						elseif ( ExtraHeaderTbl.FileVersion <= 0.81 ) then
							ent:DupeLoadCallBack(Data.Entities,Data.Constraints,Data.HeadEntityIdx,ata.HoldAngle,tonumber(HeaderTbl.Entities),tonumber(HeaderTbl.Constraints),Data.HoldAngle)
						end
					elseif ( HeaderTbl.Type ) and ( HeaderTbl.Type == "Contraption Saver File" ) then
						ent:DupeLoadCallBack(Data.Entities,Data.Constraints,Data.Head,tonumber(HeaderTbl.Entities),tonumber(HeaderTbl.Constraints),Angle(0,0,0))
					elseif (Data.Information) then
						local head,low
						for k,v in pairs(Data.Entities) do
							if (!head) or (v.Pos.z < low) then
								head = k
								low = v.Pos.z
							end
						end
						
						AdvDupe.ConvertPositionsToLocal( Data.Entities, Data.Constraints, Data.Entities[head].Pos + Vector(0,0,-15), Angle(0,0,0) )
						
						ent:DupeLoadCallBack( Data.Entities, Data.Constraints,Data.head,Data.Information.Entities,Data.Information.Constraints,Angle(0,0,0))
					else
						Msg("AdvDupeERROR: Unknown File Type or Bad File\n")
						return false
					end
					return true
				end
			
				Serialiser.DeserialiseWithHeaders( self.InSerialised, DupePortLoad, nil, "", self )
			end
		end
	elseif (iname == "Piece Size") then
		if (value >= 8 && !self.SendingData) then
			self.PieceSize = value
		elseif (value < 8 && self.SendingData) then
			self.PieceSize = 8
		end
	elseif (iname == "Start Data Sending") then
		if (value > 0 && !self.SendingData && (self.OutSerialised != "")) then
			self.SendingData = true
		end
	elseif (iname == "Data Input") then
		if (value != "") then
			if (string.sub(value,1,5) == "Data:") then
				if (string.sub(value,6,10) == "Start") then
					self:ClearInputClipBoard()
					
					self.ReceivingData = true
					
					self.InBlocks = {}
					self.InBlockCount = tonumber(string.sub(value,12,string.len(value)))
					Wire_TriggerOutput(self,"Serialised Input Block Count",self.InBlockCount)
					Wire_TriggerOutput(self,"Receiving",1)
				elseif (self.ReceivingData) then
					pos = string.instr(value,":",6)
					BlockNum = tonumber(string.sub(value,6,pos-1))
					
					self.InBlocks[BlockNum] = string.sub(value,pos+1,string.len(value))
					
					if (BlockNum == (self.InBlockCount - 1)) then
						self.ReceivingData = false
						
						self.InSerialised = ""
						for i = 0,(self.InBlockCount-1) do
							self.InSerialised = self.InSerialised .. self.InBlocks[i]
						end
						
						self.ReceivingData = false
						Wire_TriggerOutput(self,"Blocks Received",self.InBlockCount)
						Wire_TriggerOutput(self,"Deserialisable Input Available",1)
						Wire_TriggerOutput(self,"Receiving",0)
					else
						Wire_TriggerOutput(self,"Blocks Received",BlockNum+1)
					end
				end
			end
		end
	elseif (iname == "Clear Input") then
		if (value > 0 && !self.ReceivingData) then
			self:ClearInputClipBoard()
		end
	elseif (iname == "Spawn Player SteamID") then
		if (SinglePlayer()) then
			self.SpawnSteamID = self.OwnerSteamID
		else
			if (value != "") then
				self.SpawnSteamID = value
			else
				self.SpawnSteamID = self.OwnerSteamID
			end
		end
	end
end

function ENT:OnRemove()
	self.BaseClass.OnRemove(self)
end

function ENT:ClearClipBoard()
	self.OutHeadEntityIdx	= nil
	self.OutHoldAngle 		= nil
	self.OutHoldPos 		= nil
	self.OutStartPos		= nil
	self.OutEntities		= nil
	self.OutConstraints		= nil
	self.OutNumOfEnts		= 0
	self.OutNumOfConst		= 0
	self.OutSerialised 		= ""
	self.OutBlockCount		= 0
	self.OutBlocks			= nil
	self.Copied				= false
	
	Wire_TriggerOutput(self, "Entity Scaned", 0)
	Wire_TriggerOutput(self, "Entity Serialised", 0)
	Wire_TriggerOutput(self, "Serialised Output Block Count",0)
end

function ENT:ClearInputClipBoard()
	self.InHeadEntityIdx	= nil
	self.InHoldAngle 		= nil
	self.InHoldPos 			= nil
	self.InStartPos			= nil
	self.InEntities			= nil
	self.InConstraints		= nil
	self.InNumOfEnts		= 0
	self.InNumOfConst		= 0
	self.InSerialised		= ""
	
	self.InBlocks 			= nil
	self.InBlockCount 		= 0
	self.ReceivingData		= false
	self.SpawnData			= false
	
	Wire_TriggerOutput(self,"Spawn Available",0)
	Wire_TriggerOutput(self,"Deserialisable Input Available",0)
	Wire_TriggerOutput(self,"Serialised Input Block Count",0)
	Wire_TriggerOutput(self,"Blocks Received",0)
end

function ENT:DupeLoadCallBack( Entities, Constraints, HeadEntityIdx, NumOfEnts, NumOfConst, HoldAngle )
	if ( CLIENT ) then return end
	if (Entities) then
		
		self.InHeadEntityIdx	= HeadEntityIdx

		self.InEntities			= Entities
		self.InConstraints		= Constraints or {}
		
		self.InHoldAngle 		= HoldAngle
		
		self.InNumOfEnts		= NumOfEnts
		self.InNumOfConst		= NumOfConst
		
		self.SpawnData			= true
		Wire_TriggerOutput(self, "Spawn Available", 1)
		
	end
end

function ENT:GetUserEntity(SteamID)
	if (SinglePlayer()) then
		return self.OwnerSteamID
	else
		for k, v in pairs(player.GetAll()) do
			if (v:SteamID() == SteamID) then return v end
		end
	end
	return nil
end
