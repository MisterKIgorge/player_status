local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Image = require "widgets/image"

local PlayerStatItem = Class(Widget, function(self, tex, tooltip)
    Widget._ctor(self, "PlayerStatItem")
    self:SetBlocksMouse(false)

    self.icon = self:AddChild(Image(tex))
        :SetToolTip(tooltip)
    self.info = self:AddChild(Text(FONTFACE.CODE, 65, nil, UICOLORS.SUBTITLE))
        :EnableShadow()
        :SetShadowColor(UICOLORS.BLACK)
        :SetShadowOffset(1, -1)
        :EnableOutline()
        :SetOutlineColor(UICOLORS.BLACK)

    self.info:LayoutBounds("center", "center", self.icon)
end)

function PlayerStatItem:SetIconScale(scale)
    self.icon:SetScale(scale)
    return self
end
function PlayerStatItem:SetIconOpacity(alpha)
    self.icon:SetMultColor(1, 1, 1, alpha)
    return self
end
function PlayerStatItem:SetTextScale(scale)
    self.info:SetScale(scale)
    return self
end
function PlayerStatItem:SetTextOpacity(alpha)
    self.info:SetMultColor(1, 1, 1, alpha)
    return self
end

function PlayerStatItem:SetText(text)
    self.info:SetText(text)

    return self
end

return PlayerStatItem
