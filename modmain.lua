-- modimport("scripts/strings.lua")
modimport("scripts/statusdatadefs.lua")
modimport("scripts/ui.lua")

AddPlayerPostInit(function(inst)
    inst:AddComponent("playerstatdisplay")

    -- im not sure
    inst:ListenForEvent("new_statdata", function()
        if inst.components.playerstatdisplay then
            inst.components.playerstatdisplay:InitEventListeners() 
        end 
    end, GLOBAL.TheGlobalInstance)
end)