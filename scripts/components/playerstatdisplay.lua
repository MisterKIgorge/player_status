local StatusDefs = require ("statusdata")
local DataDumper = require "util.datadumper"

local PlayerStatDisplay = nil
PlayerStatDisplay = Class(function(self, inst)
    self.inst = inst
    self.stats = {}

    self:InitEventListeners()
end)

function PlayerStatDisplay:InitEventListeners()
    for i, data in pairs(StatusDefs.GetStatusData()) do
        if not self.stats[data.id] then
            self.stats[data.id] = {}
        end

        local function UpdatePlayerStats()
            self.stats[data.id] = data.fn(self.inst)
        end
        
        for i, event in pairs(data.events) do
            self.inst:RemoveEventCallback(event, UpdatePlayerStats)
            self.inst:ListenForEvent(event, UpdatePlayerStats)
        end
        UpdatePlayerStats()
    end
end

function PlayerStatDisplay:OnNetSerialize()
	local e = self.inst.entity

    e:SerializeString(DataDumper(self.stats, nil, true))
end

function PlayerStatDisplay:OnNetDeserialize()
	local e = self.inst.entity

	self.stats = e:DeserializeString()
end

return PlayerStatDisplay
