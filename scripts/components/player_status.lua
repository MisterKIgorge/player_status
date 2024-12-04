local StatusDefs = require ("statusdefs")
local DataDumper = require "util.datadumper"

local PlayerInformation = nil
PlayerInformation = Class(function(self, inst)
    self.inst = inst
    self.stats = {}

    self:InitEventListeners()
end)

function PlayerInformation:InitEventListeners()
    for i, data in pairs(StatusDefs.GetStatusData()) do
        if not self.stats[data.tooltip] then
            self.stats[data.tooltip] = {}
        end

        local function UpdatePlayerStats()
            self.stats[data.tooltip] = data.fn(self.inst)
        end
        
        for i, event in pairs(data.events) do
            self.inst:RemoveEventCallback(event, UpdatePlayerStats)
            self.inst:ListenForEvent(event, UpdatePlayerStats)
        end
        UpdatePlayerStats()
    end
end

function PlayerInformation:OnNetSerialize()
	local e = self.inst.entity

    e:SerializeString(DataDumper(self.stats, nil, true))
end

function PlayerInformation:OnNetDeserialize()
	local e = self.inst.entity

	self.stats = e:DeserializeString()
end

return PlayerInformation
