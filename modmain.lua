local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local PlayerStatItemWidget = require "player_status.widgets.playerstatitemwidget"

local StatusDefs = require ("statusdefs")
local AddStatusData = StatusDefs.AddStatusData
local PowersDamageCalc = StatusDefs.PowersDamageCalc

local list_spacing = 40
local icon_scale = 0.85
local text_scale = 1
local icon_opacity = 1
local text_opacity = 1

AddStatusData(
    "images/icons_ftf/inventory_weapon_hammer.tex", --Image
    {"activate_skill", "add_state_tag", "attack_end", "attack_start", "death", "do_damage", "dodge", "dodge_cancel", "dying", "enter_room", "exit_room", "foley_footstep", "hammer_thumped", "healthchanged", "heavy_attack", "hitboxcollided_invincible", "hitboxtriggered", "hitstreak", "hitstreak_killed", "juggernaut_force_remove", "kill", "light_attack", "parry", "power_charged_damage", "power_stacks_changed", "projectile_launched", "remove_state_tag", "revive", "shotput_landed", "start_gameplay", "take_damage", "take_heal", "timerdone",}, --Event
    "Damage mult", --tooltip text
    function(inst) return PowersDamageCalc(inst) end, -- Value
    true) -- Percent


AddStatusData(
    "images/icons_ftf/stat_crit_chance.tex",
    {"speed_mult_changed", "crit_chance_changed", "hitboxcollided_invincible", "light_attack", "heavy_attack"},
    "Critical Chance",
    function(inst) return (math.min(1, PowersDamageCalc(inst, true))) * 100 end,
    true) 

AddStatusData(
    "images/icons_ftf/inventory_head.tex",
    {"loadout_changed"},
    "Armor",
    function(inst) 
        local dungeon_tier_damage_mult = math.max(TUNING.GEAR.MINIMUM_DUNGEONTIER_DAMAGE_MULT, 1.15 - inst.components.combat.dungeontierdamagereductionmult:Get())
        return (1 - dungeon_tier_damage_mult) * 100 
    end,
    true)

AddStatusData(
    "images/icons_ftf/inventory_legs.tex", 
    {"speed_mult_changed"}, 
    "Speed mult", 
    function(inst) return (inst.components.locomotor.total_speed_mult - 1) * 100 end, 
    true)  

local function MakeText(stats, data)
    return stats .. (data.ispercent and "%" or "")
end

local function PlayerStatus(self)
    self.player_stats_widgets = self.root:AddChild(Widget("Player Status Widgets Container"))

    function self:player_stats_widgets_Rebuild()
        self.player_stats_widgets:RemoveAllChildren()
        for _, data in pairs(StatusDefs.GetStatusData()) do
            local textfn = data.textfn or MakeText

            local item = self.player_stats_widgets:AddChild(PlayerStatItemWidget(data.image, data.tooltip))
                :SetIconScale(icon_scale)
                :SetTextScale(text_scale)
                :SetIconOpacity(icon_opacity)
                :SetTextOpacity(text_opacity)

            local function UpdateText()
                local player_status = self.owner and self.owner.components.player_status 
                if player_status and player_status.stats and player_status.stats[data.tooltip] then
                    item:SetText(textfn(player_status.stats[data.tooltip], data))
                end
            end

            for _, event in pairs(data.events) do
                self.owner:RemoveEventCallback(event, UpdateText)
                self.owner:ListenForEvent(event, UpdateText)
                UpdateText()
            end
        end
    end

    -- change the loot stack position (loot picked up popups)
    local original_Layout = self._Layout
    function self:_Layout(...)
        original_Layout(self, ...)

        if self.layout_mode == self.LAYOUT_MODES.s.TOP_LEFT then
            self.player_stats_widgets:SetAnchors("left", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("left", "bottom", self.bg_container)
                :Offset(200, 0)
        elseif self.layout_mode == self.LAYOUT_MODES.s.TOP_RIGHT then
            self.player_stats_widgets:SetAnchors("right", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("right", "bottom", self.bg_container)
                :Offset(-200, 0)
        elseif self.layout_mode == self.LAYOUT_MODES.s.BOTTOM_LEFT then
            self.player_stats_widgets:SetAnchors("left", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("left", "top", self.bg_container)
                :Offset(200, 0)
        elseif self.layout_mode == self.LAYOUT_MODES.s.BOTTOM_RIGHT then
            self.player_stats_widgets:SetAnchors("right", "center")
                :LayoutChildrenInRow(list_spacing)
                :LayoutBounds("right", "top", self.bg_container)
                :Offset(-200, 0)
        end
    end

    self:player_stats_widgets_Rebuild()
    self.owner:ListenForEvent("new_statdata", function() self:stats_list_Rebuild() end, GLOBAL.TheGlobalInstance)
end
AddClassPostConstruct("widgets/ftf/playerstatuswidget", PlayerStatus)

AddPlayerPostInit(function(inst)
    inst:AddComponent("player_status")
end)
