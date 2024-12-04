local StatusDefs = require ("statusdefs")

local PlayerInformation = nil
PlayerInformation = Class(function(self, inst)
    self.inst = inst

    self:InitEventListeners()
end)

function PlayerInformation:InitEventListeners()
    for i, data in pairs(StatusDefs.GetStatusData()) do
        for i, event in pairs(data.events) do
            local function UpdateServerData()
                local remove_data = {
                    stats = data.fn(self.inst),
                    name = data.tooltip,
                    owner = self.inst,
                }

                for i, player in ipairs(AllPlayers) do
                    if self.inst ~= player then
                        TheNetEvent:PushEventOnOwnerEntity(player.GUID, self.inst.GUID, "net_" .. event, remove_data)
                    else
                        self.inst:PushEvent("net_" .. event, remove_data)
                    end
                end
            end

            self.inst:RemoveEventCallback(event, UpdateServerData)
            self.inst:ListenForEvent(event, UpdateServerData)
        end
    end
end

return PlayerInformation