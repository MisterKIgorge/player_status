local StatusDefs = require ("statusdata")
local DataDumper = require "util.datadumper"

local StatsNrBits <const> = 16

local PlayerStatDisplay = nil
PlayerStatDisplay = Class(function(self, inst)
    self.inst = inst

    self.statusdata = {}
    self.stats = {}
    self.id_update = 0

    self:InitEventListeners()
end)

function PlayerStatDisplay:InitEventListeners()
    self.statusdata = StatusDefs.GetStatusData()
    for i, data in pairs(self.statusdata) do
        local function UpdatePlayerStats()
            local new_stats = math.floor(data.fn(self.inst) * (data.accuracy and 10 ^ data.accuracy or 100))

            if new_stats ~= self.stats[data.id] then
                self.id_update = i
                self.stats[data.id] = new_stats

                if self.inst:IsLocal() then
                    self.inst:PushEvent("statusupdated_" .. data.id)
                end
            end
        end
        
        for i, event in pairs(data.events) do
            self.inst:RemoveEventCallback(event, UpdatePlayerStats)
            self.inst:ListenForEvent(event, UpdatePlayerStats)
        end
        UpdatePlayerStats()
    end
end

function PlayerStatDisplay:GetStats(id)
    return self.stats[id]
end

function PlayerStatDisplay:OnNetSerialize()
	local e = self.inst.entity

    if self.id_update > 0 and self.statusdata[self.id_update] then
        local id = self.statusdata[self.id_update].id
        local stats = self:GetStats(id)

        e:SerializeBoolean(stats >= 0)
        e:SerializeInt(math.abs(stats), StatsNrBits)
        e:SerializeUInt(self.id_update, 8)

        self.id_update = 0
    end
end

function PlayerStatDisplay:OnNetDeserialize()
	local e = self.inst.entity

    local ispositive = e:DeserializeBoolean(StatsNrBits)
    local stats = e:DeserializeInt(StatsNrBits)
    local id = e:DeserializeUInt(8)

    local statusdata = StatusDefs.GetStatusData()
    
    if statusdata[id] and statusdata[id].id then
        self.stats[statusdata[id].id] = ispositive and stats or -stats

        self.inst:PushEvent("statusupdated_" .. statusdata[id].id)
    end
end

return PlayerStatDisplay
