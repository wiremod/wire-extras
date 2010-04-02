local ExitPoints = {}

function AddExitPoint( entity )
	table.insert( ExitPoints, entity )
end

local function CheckRemovedEnt( ent )
	for index, e in pairs( ExitPoints ) do
		if (e:IsValid()) then
			if (e == ent) then
				table.remove( ExitPoints, index )
			end
		end
	end
end
hook.Add( "EntityRemoved", "ExitPointEntRemoved", CheckRemovedEnt )

local function CheckAllowed( ply, exitpoint, vehicle )
	-- if SPP exists
	if (CPPI) then
		-- get the owner
		local exitpointowner = exitpoint:CPPIGetOwner()
		local vehicleowner = vehicle:CPPIGetOwner()
		
		-- if the owner of the vehicle is equal to the owner of the exit point
		if ( exitpointowner == vehicleowner ) then
			return true
		end
		
		-- if the exiting player has the owner of the exit point in SPP Friends
		for _, friend in pairs( ply:CPPIGetFriends() ) do
			if ( exitpointowner == friend ) then
				return true
			end
		end
		
		-- if the owner of the vehicle has the owner of the exit point in SPP Friends
		for _, friend in pairs( vehicleowner:CPPIGetFriends() ) do
			if ( exitpointowner == friend ) then
				return true
			end
		end
		
		-- else return false
		return false
	else
		-- if SPP doesn't exist, check the distance between the exit point and the vehicle
		if ( vehicle:GetPos():Distance( exitpoint:GetPos() ) < 1000 ) then
			return true
		end
		return false
	end
	-- else return false
	return false
end

local function LeaveVehicle( ply, vehicle )
	local found = false
	
	-- Loop through all Exit Points
	for _, ent in pairs( ExitPoints ) do
		if (ent:IsValid()) then

			-- Loop through all entities of that exit point
			if (ent.Entities and #ent.Entities > 0) then
				for _, e in pairs( ent.Entities ) do
					if (e:IsValid()) then
						
						-- Check if the owner of the exit point controller is allowed to teleport ply
						if (CheckAllowed( ply, ent, vehicle )) then
							-- If that exit point is linked to the vehicle
							if (e == vehicle) then
								found = true
								
								-- Teleport ply
								if (ent.Global) then
									ply:SetPos( ent.Position )
								else
									ply:SetPos( e:LocalToWorld( ent.Position ) )
								end
								break
							end
						end
					end
				end
			end
			if (found) then break end
		end
	end
end
hook.Add("PlayerLeaveVehicle", "LeaveVehicle", LeaveVehicle )

