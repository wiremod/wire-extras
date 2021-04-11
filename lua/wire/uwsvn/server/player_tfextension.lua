//-----------------------------------------------------------------------------
// Player Extension - Target Lock for Wire Target Finder
//-----------------------------------------------------------------------------

local meta = FindMetaTable ("Player")
if (!meta) then
    Msg ("Failed to load Wire Player Extension for Target Finder!")
    return
end

// Variable to track lock count
meta.m_TargetLocks = {}


//-----------------------------------------------------------------------------
// Name: Player:TargetFinderLock()
// Desc: Called by target finder when it locks onto this player.
//-----------------------------------------------------------------------------

function meta:TargetFinderLock (ent)
    if (!table.HasValue (self.m_TargetLocks, ent)) then
        table.insert (self.m_TargetLocks, ent)
    end
end


//-----------------------------------------------------------------------------
// Name: Player:TargetFinderUnlock()
// Desc: Called by target finder when it unlocks this player
//-----------------------------------------------------------------------------

function meta:TargetFinderUnlock (ent)
    if (table.HasValue (self.m_TargetLocks, ent)) then
        for k,v in ipairs (self.m_TargetLocks) do
            if (v == ent) then
                table.remove (self.m_TargetLocks, k)
                return
            end
        end
    end
end


//-----------------------------------------------------------------------------
// Name: Player:IsLockedOnto ()
// Desc: Returns true if this player is a target, false otherwise.
//-----------------------------------------------------------------------------

function meta:IsLockedOnto ()
    return #self.m_TargetLocks > 0
end

