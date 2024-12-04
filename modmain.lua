local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local StatusDefs = require ("statusdefs")
local AddStatusData = StatusDefs.AddStatusData
local PowersDamageCalc = StatusDefs.PowersDamageCalc

local list_spacing = 40
local icon_scale = 0.85
local text_scale = 1
local icon_opacity = 1
local text_opacity = 1

AddStatusData(
    "icons_ftf/inventory_weapon_hammer", --Image
    {"activate_skill", "add_state_tag", "attack_end", "attack_start", "death", "do_damage", "dodge", "dodge_cancel", "dying", "enter_room", "exit_room", "foley_footstep", "hammer_thumped", "healthchanged", "heavy_attack", "hitboxcollided_invincible", "hitboxtriggered", "hitstreak", "hitstreak_killed", "juggernaut_force_remove", "kill", "light_attack", "parry", "power_charged_damage", "power_stacks_changed", "projectile_launched", "remove_state_tag", "revive", "shotput_landed", "start_gameplay", "take_damage", "take_heal", "timerdone",}, --Event
    "Damage mult", --tooltip text
    function(inst) return PowersDamageCalc(inst) end, -- Value
    true) -- Percent


AddStatusData(
    "icons_ftf/stat_crit_chance",
    {"speed_mult_changed", "crit_chance_changed", "hitboxcollided_invincible", "light_attack", "heavy_attack"},
    "Critical Chance",
    function(inst) return (math.min(1, PowersDamageCalc(inst, true))) * 100 end,
    true) 

AddStatusData(
    "icons_ftf/inventory_head",
    {"loadout_changed"},
    "Armor",
    function(inst) 
        local dungeon_tier_damage_mult = math.max(TUNING.GEAR.MINIMUM_DUNGEONTIER_DAMAGE_MULT, 1.15 - inst.components.combat.dungeontierdamagereductionmult:Get())
        return (1 - dungeon_tier_damage_mult) * 100 
    end,
    true)

AddStatusData(
    "icons_ftf/inventory_legs", 
    {"speed_mult_changed"}, 
    "Speed mult", 
    function(inst) return (inst.components.locomotor.total_speed_mult - 1) * 100 end, 
    true)  

local function MakeText(stats, data)
    return stats .. (data.ispercent and "%" or "")
end

local function PlayerStatus(self)    
    self.list_stats = self.root:AddChild(Widget("Gear Stats List"))

    function self:stats_list_Rebuild()
        self.list_stats:RemoveAllChildren()
        for _, data in pairs(StatusDefs.GetStatusData()) do
            local textfn = data.textfn or MakeText

            local item = self.list_stats:AddChild(Widget("Item"))
            item.icon = item:AddChild(Image("images/".. data.image ..".tex"))
                :SetToolTip(data.tooltip)
                :SetMultColor(1, 1, 1, icon_opacity)
                :SetScale(icon_scale)
                
            item.info = item:AddChild(Text(GLOBAL.FONTFACE.CODE, 65, textfn(data.fn(self.owner), data), GLOBAL.UICOLORS.SUBTITLE))
                :EnableShadow()
                :SetShadowColor(GLOBAL.UICOLORS.BLACK)
                :SetShadowOffset(1, -1)
                :EnableOutline()
                :SetOutlineColor(GLOBAL.UICOLORS.BLACK)
                :SetBlocksMouse(false)
                :SetMultColor(1, 1, 1, text_opacity)
                :SetScale(text_scale)
                :LayoutBounds("center", "center", item.icon)

            local function UpdateText(inst, remove_data)
                if remove_data.name == data.tooltip then
                    item.info:SetText(textfn(remove_data.stats, data))
                end
            end

            for _, event in pairs(data.events) do
                self.owner:RemoveEventCallback("net_" .. event, UpdateText)
                self.owner:ListenForEvent("net_" .. event, UpdateText)
            end
        end
    end

    -- change the loot stack position (loot picked up popups)
    local original_Layout = self._Layout
    function self:_Layout(...)
        original_Layout(self, ...)

        if self.layout_mode == self.LAYOUT_MODES.s.TOP_LEFT then
            self.list_stats:SetAnchors("left", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("left", "bottom", self.bg_container)
                :Offset(200, 0)
        elseif self.layout_mode == self.LAYOUT_MODES.s.TOP_RIGHT then
            self.list_stats:SetAnchors("right", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("right", "bottom", self.bg_container)
                :Offset(-200, 0)
        elseif self.layout_mode == self.LAYOUT_MODES.s.BOTTOM_LEFT then
            self.list_stats:SetAnchors("left", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("left", "top", self.bg_container)
                :Offset(200, 0)
        elseif self.layout_mode == self.LAYOUT_MODES.s.BOTTOM_RIGHT then
            self.list_stats:SetAnchors("right", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("right", "top", self.bg_container)
                :Offset(-200, 0)
        end
    end

    self:stats_list_Rebuild()
    self.owner:ListenForEvent("new_statdata", function() self:stats_list_Rebuild() end, GLOBAL.TheGlobalInstance)
end
AddClassPostConstruct("widgets/ftf/playerstatuswidget", PlayerStatus)

AddPlayerPostInit(function(inst)
    inst:AddComponent("player_status")
end)