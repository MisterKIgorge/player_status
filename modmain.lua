-- modimport("scripts/strings.lua")
modimport("scripts/statusdatadefs.lua")
modimport("scripts/ui.lua")

AddPlayerPostInit(function(inst)
    inst:AddComponent("playerstatdisplay")
end)