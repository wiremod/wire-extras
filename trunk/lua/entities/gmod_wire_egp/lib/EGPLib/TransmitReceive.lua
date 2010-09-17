--------------------------------------------------------
-- Queue Functions
--------------------------------------------------------
local EGP = EGP


if (SERVER) then
	umsg.PoolString( "EGP_Transmit_Data" ) -- Don't know if this helps, but I'll do it anyway just in case.
	
	----------------------------
	-- Umsgs per second check
	----------------------------
	EGP.IntervalCheck = {}

	function EGP:PlayerDisconnect( ply ) EGP.IntervalCheck[ply] = nil EGP.Queue[ply] = nil EGP:StopQueueTimer( ply ) end
	hook.Add("PlayerDisconnect","EGP_PlayerDisconnect",function( ply ) EGP:PlayerDisconnect( ply ) end)


	function EGP:CheckInterval( ply, bool )
		if (!self.IntervalCheck[ply]) then self.IntervalCheck[ply] = { umsgs = 0, time = 0 } end
		
		local maxcount = self.ConVars.MaxPerSec:GetInt()
		
		local tbl = self.IntervalCheck[ply]
		
		if (bool==true) then
			return (tbl.umsgs <= maxcount or tbl.time < CurTime())
		else
			if (tbl.time < CurTime()) then
				tbl.umsgs = 1
				tbl.time = CurTime() + 1
			else
				tbl.umsgs = tbl.umsgs + 1
				if (tbl.umsgs > maxcount) then
					return false
				end
			end
			
		end
		
		return true
	end
	
	----------------------------
	-- Queue functions
	----------------------------
	
	umsg.PoolString( "ClearScreen" )
	local function ClearScreen( Ent, ply )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then 
			if (EGP:CheckInterval( ply ) == false) then 
				EGP:InsertQueue( Ent, ply, ClearScreen, "ClearScreen" )
				return
			end
		end
		
		Ent.RenderTable = {}
		Ent.OldRenderTable = {}
		if (!EGP.umsg.Start( "EGP_Transmit_Data" )) then return end
			EGP.umsg.Entity( Ent )
			EGP.umsg.String( "ClearScreen" )
		EGP.umsg.End()
		
		EGP:SendQueueItem( ply )
	end
	
	umsg.PoolString( "SaveFrame" )
	local function SaveFrame( Ent, ply, FrameName )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then 
			if (EGP:CheckInterval( ply ) == false) then 
				EGP:InsertQueue( Ent, ply, SaveFrame, "SaveFrame", FrameName )
				return
			end
		end
		
		umsg.PoolString( FrameName )
		if (!EGP.umsg.Start( "EGP_Transmit_Data" )) then return end
			EGP.umsg.Entity( Ent )
			EGP.umsg.String( "SaveFrame" )
			EGP.umsg.Entity( ply )
			EGP.umsg.String( FrameName )
		EGP.umsg.End()
		
		EGP:SaveFrame( ply, Ent, FrameName )
		EGP:SendQueueItem( ply )
	end
	
	umsg.PoolString( "LoadFrame" )
	local function LoadFrame( Ent, ply, FrameName )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then 
			if (EGP:CheckInterval( ply ) == false) then 
				EGP:InsertQueue( Ent, ply, LoadFrame, "LoadFrame", FrameName )
				return
			end
		end
		
		local Frame = EGP:LoadFrame( ply, Ent, FrameName )
		if (!Frame) then return end

		if (!EGP.umsg.Start( "EGP_Transmit_Data" )) then return end
			EGP.umsg.Entity( Ent )
			EGP.umsg.String( "LoadFrame" )
			EGP.umsg.Entity( ply )
			EGP.umsg.String( FrameName )
		EGP.umsg.End()
		
		EGP:SendQueueItem( ply )
	end
	
	-- Extra Add Text queue item, used by text objects with a lot of text in them
	umsg.PoolString( "AddText" )
	local function AddText( Ent, ply, index, text )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then 
			if (EGP:CheckInterval( ply ) == false) then 
				EGP:InsertQueue( Ent, ply, AddText, "AddText", index, text )
				return
			end
		end
		
		local bool, k, v = EGP:HasObject( Ent, index )
		if (bool) then
			if (!EGP.umsg.Start("EGP_Transmit_Data")) then return end
				EGP.umsg.Entity( Ent )
				EGP.umsg.String( "AddText" )
				EGP.umsg.Short( index )
				EGP.umsg.String( text )
			EGP.umsg.End()
		end
		
		EGP:SendQueueItem( ply )
	end
	
	-- Extra Set Text queue item, used by text objects with a lot of text in them
	umsg.PoolString( "SetText" )
	function EGP._SetText( Ent, ply, index, text )
		-- Check interval
		if (ply and ply:IsValid() and ply:IsPlayer()) then 
			if (EGP:CheckInterval( ply ) == false) then 
				EGP:InsertQueue( Ent, ply, EGP._SetText, "SetText", index, text )
				return
			end
		end
		local bool, k, v = EGP:HasObject( Ent, index )
		if (bool) then
			if (#text > 220) then
				local DataToSend = {}
				local temp = ""
				for i=1,#text do
					temp = temp .. text:sub(i,i)
					if (#temp >= 220) then
						table.insert( DataToSend, 1, {index, temp} )
						temp = ""
					end
				end
				if (temp != "") then
					table.insert( DataToSend, 1, {index, temp} )
				end
				
				-- This step is required because otherwise it adds the strings backwards to the queue.
				for i=1,#DataToSend do
					EGP:InsertQueue( Ent, ply, AddText, "AddText", unpack(DataToSend[i]) )
				end
			else
				if (!EGP.umsg.Start("EGP_Transmit_Data")) then return end
					EGP.umsg.Entity( Ent )
					EGP.umsg.String( "SetText" )
					EGP.umsg.Short( index )
					EGP.umsg.String( text )
				EGP.umsg.End()
			end
		end
		
		EGP:SendQueueItem( ply )
	end
	
	local function removetbl( tbl, Ent )
		for k,v in ipairs( tbl ) do
			if (Ent.RenderTable[k]) then table.remove( Ent.RenderTable, k ) end
		end
	end
	
	umsg.PoolString( "ReceiveObjects" )
	local function SendObjects( Ent, ply, DataToSend )
		if (!Ent or !Ent:IsValid() or !ply or !ply:IsValid() or !DataToSend) then return end
		
		local Done = 0
		
		-- Check duped
		if (Ent.EGP_Duplicated) then
			EGP:InsertQueueObjects( Ent, ply, SendObjects, DataToSend )
			return
		end
		
		-- Check interval
		if (ply:IsValid() and ply:IsPlayer()) then 
			if (EGP:CheckInterval( ply ) == false) then 
				EGP:InsertQueueObjects( Ent, ply, SendObjects, DataToSend )
				return
			end
		end
		
		local removetable = {}
		
		if (!EGP.umsg.Start( "EGP_Transmit_Data" )) then return end
			EGP.umsg.Entity( Ent )
			EGP.umsg.String( "ReceiveObjects" )
			
			EGP.umsg.Short( #DataToSend ) -- Send estimated number of objects to be sent
			for k,v in ipairs( DataToSend ) do
				
				-- Check if the object doesn't exist serverside anymore (It may have been removed by a command in the queue before this, like egpClear or egpRemove)
				if (!EGP:HasObject( Ent, v.index )) then
					EGP:CreateObject( Ent, v.ID, v )
				end
			
				EGP.umsg.Short( v.index ) -- Send index of object
				
				if (v.remove == true) then
					EGP.umsg.Char( -128 ) -- Object is to be removed, send a 0
					if (Ent.RenderTable[k]) then
						table.insert( removetable, k )
					end
				else
					EGP.umsg.Char( v.ID - 128 ) -- Else send the ID of the object
				
					if (v.ChangeOrder) then -- We want to change the order of this object, send the index to where we wish to move it
						local from = v.ChangeOrder[1]
						local to = v.ChangeOrder[2]
						if (Ent.RenderTable[to]) then
							Ent.RenderTable[to].ChangeOrder = nil
						end
						EGP.umsg.Short( from )
						EGP.umsg.Short( to )
					else
						EGP.umsg.Short( 0 ) -- Don't change order
					end
					
					 -- Object-specific data
					if (v.text != nil) then
						v:Transmit( Ent, ply )
					else
						v:Transmit()
					end
				end
				
				Done = Done + 1
				if (EGP.umsg.CurrentCost() > 200) then -- Getting close to the max size! Start over
					if (Done == 1 and EGP.umsg.CurrentCost() > 256) then -- The object was too big
						ErrorNoHalt("[EGP] Umsg error. An object was too big to send!")
						--table.remove( DataToSend, 1 )
					end
					EGP.umsg.End()
					for i=1,Done do table.remove( DataToSend, 1 ) end
					removetbl( removetable, Ent )
					EGP:InsertQueueObjects( Ent, ply, SendObjects, DataToSend )
					EGP:SendQueueItem( ply )
					return
				end
			end
		EGP.umsg.End()
		
		removetbl( removetable, Ent )
	end
	
	----------------------------
	-- DoAction
	----------------------------

	function EGP:DoAction( Ent, E2, Action, ... )
		if (Action == "SendObject") then
			local Data = {...}
			if (!Data[1]) then return end
			self:AddQueueObject( Ent, E2.player, SendObjects, Data[1] )
			
			if (E1 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
			end
		elseif (Action == "RemoveObject") then
			local Data = {...}
			if (!Data[1]) then return end
			self:AddQueueObject( Ent, E2.player, SendObjects, { index = Data[1], remove = true } )
			
			if (E1 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
			end
		elseif (Action == "Send") then -- This isn't used at the moment, but I left it here in case I need it
			local DataToSend = {}

			for k,v in ipairs( Ent.RenderTable ) do
				if (!Ent.OldRenderTable[k] or Ent.OldRenderTable[k].ID != v.ID) then -- Check for differences
					table.insert( DataToSend, v )
				else
					for k2,v2 in pairs( v ) do
						if (k2 != "BaseClass") then
							if (!Ent.OldRenderTable[k][k2] or Ent.OldRenderTable[k][k2] != v2) then -- Check for differences
								table.insert( DataToSend, v )
							end
						end
					end
				end
			end
			
			-- Check if any object was removed
			for k,v in ipairs( Ent.OldRenderTable ) do
				if (!Ent.RenderTable[k]) then
					table.insert( DataToSend, { index = v.index, remove = true} )
				end
			end
			
			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + #DataToSend * 100
			end
			
			self:AddQueue( Ent, E2.player, SendObjects, "Send", DataToSend )
			
			for k,v in ipairs( Ent.RenderTable ) do
				if (v.ChangeOrder) then v.ChangeOrder = nil end
			end
		elseif (Action == "ClearScreen") then
			Ent.OldRenderTable = {}
			Ent.RenderTable = {}
			
			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
			end
			
			self:AddQueue( Ent, E2.player, ClearScreen, "ClearScreen" )
		elseif (Action == "SaveFrame") then
			local Data = {...}
			if (!Data[1]) then return end
			
			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
			end
			
			self:AddQueue( Ent, E2.player, SaveFrame, "SaveFrame", Data[1] )
		elseif (Action == "LoadFrame") then
			local Data = {...}
			if (!Data[1]) then return end
			
			if (E2 and E2.entity and E2.entity:IsValid()) then
				E2.prf = E2.prf + 100
			end
			
			self:AddQueue( Ent, E2.player, LoadFrame, "LoadFrame", Data[1] )
		end
	end
else -- SERVER/CLIENT
	function EGP:Receive( um )
		local Ent = um:ReadEntity()
		if (!Ent or !Ent:IsValid()) then return end
		
		local Action = um:ReadString()
		if (Action == "ClearScreen") then
			Ent.RenderTable = {}
			Ent:EGP_Update()
		elseif (Action == "SaveFrame") then
			local ply = um:ReadEntity()
			local FrameName = um:ReadString()
			EGP:SaveFrame( ply, Ent, FrameName )
		elseif (Action == "LoadFrame") then
			local ply = um:ReadEntity()
			local FrameName = um:ReadString()
			EGP:LoadFrame( ply, Ent, FrameName )
			Ent:EGP_Update()
		elseif (Action == "SetText") then
			local index = um:ReadShort()
			local text = um:ReadString()
			local bool,k,v = EGP:HasObject( Ent, index )
			if (bool) then
				if (EGP:EditObject( v, { text = text } )) then Ent:EGP_Update() end
			end
		elseif (Action == "AddText") then
			local index = um:ReadShort()
			local text = um:ReadString()
			local bool,k,v = EGP:HasObject( Ent, index )
			if (bool) then
				if (EGP:EditObject( v, { text = v.text .. text } )) then Ent:EGP_Update() end
			end
		elseif (Action == "ReceiveObjects") then
			local Nr = um:ReadShort() -- Estimated amount
			for i=1,Nr do
				local index = um:ReadShort()
				if (index == 0) then break end -- In case the umsg had to abort early
				
				local ID = um:ReadChar()
				
				if (ID == -128) then -- Remove object
					local bool, k, v = EGP:HasObject( Ent, index )
					if (bool) then
						if (v.OnRemove) then v:OnRemove() end
						table.remove( Ent.RenderTable, k )
					end
				else
				
					-- Change Order
					local ChangeOrder_From = um:ReadShort()
					local ChangeOrder_To
					if (ChangeOrder_From != 0) then
						ChangeOrder_To = um:ReadShort()
					end
				
					ID = ID + 128
					local bool, k, v = self:HasObject( Ent, index )
					if (bool) then -- Object already exists
						if (v.ID != ID) then -- Not the same kind of object, create new
							if (v.OnRemove) then v:OnRemove() end
							local Obj = self:GetObjectByID( ID )
							local data = Obj:Receive( um )
							self:EditObject( Obj, data )
							Obj.index = index
							Ent.RenderTable[k] = Obj
							if (Obj.OnCreate) then Obj:OnCreate() end
						else -- Edit
							self:EditObject( v, v:Receive( um ) )
							
							-- If parented, reset the parent indexes
							if (v.parent and v.parent != 0) then
								EGP:AddParentIndexes( v )
							end
						end
					else -- Object does not exist. Create new
						local Obj = self:GetObjectByID( ID )
						self:EditObject( Obj, Obj:Receive( um ) )
						Obj.index = index
						if (Obj.OnCreate) then Obj:OnCreate() end
						table.insert( Ent.RenderTable, Obj )
					end
					
					-- Change Order
					if (ChangeOrder_From and ChangeOrder_To) then
						local b = self:SetOrder( Ent, ChangeOrder_From, ChangeOrder_To )
					end
				end
			end
			
			Ent:EGP_Update()	
		end	
	end
	usermessage.Hook( "EGP_Transmit_Data", function(um) EGP:Receive( um ) end )

end
	
require("datastream")

if (SERVER) then

	EGP.DataStream = {}

	concommand.Add("EGP_Request_Reload",function(ply,cmd,args)
		if (!EGP.DataStream[ply]) then EGP.DataStream[ply] = {} end
		local tbl = EGP.DataStream[ply]
		if (!tbl.SingleTime) then tbl.SingleTime = 0 end
		if (!tbl.AllTime) then tbl.AllTime = 0 end
		if (args[1]) then
			if (tbl.SingleTime > CurTime()) then 
				ply:ChatPrint("[EGP] This command has anti-spam protection. Try again after 10 seconds.")
			else
				tbl.SingleTime = CurTime() + 10
				ply:ChatPrint("[EGP] Request accepted for single screen. Sending...")
				EGP:SendDataStream( ply, args[1] )
			end
		else
			if (tbl.AllTime > CurTime()) then 
				ply:ChatPrint("[EGP] This command has anti-spam protection. Try again after 30 seconds.")
			else
				tbl.AllTime = CurTime() + 30
				ply:ChatPrint("[EGP] Request accepted for all screens. Sending...")
				EGP:SendDataStream( ply, args[1] )
			end
		end
	end)
	
	function EGP:SendDataStream( ply, entid )
		if (!ply or !ply:IsValid()) then return false end
		local targets
		if (entid) then
			local tempent = Entity(entid)
			if (EGP:ValidEGP( tempent )) then
				targets = { tempent }
			else
				ply:ChatPrint("[EGP] Invalid screen.")
			end
		end
		if (!targets) then
			targets = ents.FindByClass("gmod_wire_egp")
			table.Add( targets, ents.FindByClass("gmod_wire_egp_hud") )
			table.Add( targets, ents.FindByClass("gmod_wire_egp_emitter") )
			
			if (#targets == 0) then ply:ChatPrint("[EGP] There are no EGP screens on the map.") return false end
		end
		
		local DataToSend = {}
		for k,v in ipairs( targets ) do
			if (v.RenderTable and #v.RenderTable>0) then
				local DataToSend2 = {}
				for k2, v2 in ipairs( v.RenderTable ) do
					table.insert( DataToSend2, { ID = v2.ID, index = v2.index, Settings = v2:DataStreamInfo() } )
				end
				table.insert( DataToSend, { Ent = v, Objects = DataToSend2 } )
			end
		end
		if (DataToSend and #DataToSend>0) then
			datastream.StreamToClients( ply, "EGP_Request_Transmit", DataToSend )
			return true
		end
		return false
	end
	
	local function recheck(ply)
		timer.Simple(10,function(ply)
			if (ply and ply:IsValid()) then
				EGP:SendDataStream( ply )
			end
		end,ply)
	end
	
	hook.Add("PlayerInitialSpawn","EGP_SpawnFunc",recheck)

else

	function EGP:ReceiveDataStream( decoded )
		for k,v in ipairs( decoded ) do
			local Ent = v.Ent
			if (EGP:ValidEGP( Ent )) then
				for k2,v2 in pairs( v.Objects ) do
					local Obj = EGP:GetObjectByID(v2.ID)
					EGP:EditObject( Obj, v2.Settings )
					Obj.index = v2.index
					table.insert( Ent.RenderTable, Obj )
				end
				Ent:EGP_Update()
			end
		end
		LocalPlayer():ChatPrint("[EGP] Received EGP object reload. " .. #decoded .. " screen's objects were reloaded.")
	end
	datastream.Hook("EGP_Request_Transmit", function(_,_,_,decoded) EGP:ReceiveDataStream( decoded ) end )

end
