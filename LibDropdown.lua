local _NAME = "LibDropdown"
local _VERSION = "1.0.0"
local _LICENSE = [[
    MIT License

    Copyright (c) 2020 Jayrgo

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

assert(LibMan1, format("%s requires LibMan-1.x.x.", _NAME))
assert(LibMan1:Exists("LibMixin", 1), format("%s requires LibMixin-1.x.x.", _NAME))

local lib --[[ , oldVersion ]] = LibMan:New(_NAME, _VERSION, "_LICENSE", _LICENSE)
if not lib then return end

local IS_CLASSIC = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local MAX_BUTTONS = 10

lib.frame = lib.frame or LibMan1:Get("LibMixin", 1):CreateFrame("Frame", nil, UIParent, "VerticalLayoutFrame", nil,
                                                                IS_CLASSIC and {} or BackdropTemplateMixin)
local frame = lib.frame

frame:Hide()
frame:SetFrameStrata("DIALOG")
frame:EnableKeyboard(true)
frame:SetClampedToScreen(true)

frame.expand = true
frame.leftPadding = 5
frame.rightPadding = 5
frame.topPadding = 5
frame.bottomPadding = 5

frame.backdropInfo = {
    bgFile = [[Interface\ChatFrame\ChatFrameBackground]],
    edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
    tile = false,
    tileEdge = false,
    tileSize = 16,
    edgeSize = 8,
    insets = {left = 2, right = 2, top = 2, bottom = 2},
}
if IS_CLASSIC then
    frame:SetBackdrop(frame.backdropInfo)
else
    frame:ApplyBackdrop()
end
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

frame.gradient = frame.gradient or frame:CreateTexture(nil, "BORDER")
frame.gradient:ClearAllPoints()
frame.gradient:SetPoint("TOPLEFT", 2, -2)
frame.gradient:SetPoint("BOTTOMRIGHT", -2, 2)
frame.gradient:SetTexture([[Interface\ChatFrame\ChatFrameBackground]])
frame.gradient:SetBlendMode("ADD")
frame.gradient:SetGradientAlpha("VERTICAL", 0.1, 0.1, 0.1, 0, 0.25, 0.25, 0.25, 1)

local open = function() end

local type = type

---@param info table
---@param key string
---@vararg any
---@return any
local function getInfoValue(info, key, ...)
    if not info then return end
    local value = info[key]
    if type(value) == "function" then return value(info, info.arg, ...) end
    return value
end

local MouseIsOver = MouseIsOver

---@param self table
local function PopupButton_UpdateFont(self)
    if self:IsEnabled() then
        if MouseIsOver(self) then
            self.text:SetFontObject("GameFontHighlightSmallLeft")
        else
            self.text:SetFontObject("GameFontHighlightSmallLeft")
        end
    else
        self.text:SetFontObject(getInfoValue(self.info, "isTitle") and "GameFontNormalSmallLeft" or
                                    "GameFontDisableSmallLeft")
    end
end

---@param self table
local function PopupButton_OnEnable(self)
    self.arrow:SetDesaturated()
    PopupButton_UpdateFont(self)
end

---@param self table
local function PopupButton_OnDisable(self)
    self.arrow:SetDesaturated()
    PopupButton_UpdateFont(self)
end

---@param self table
---@param motion boolean
local function PopupButton_OnEnter(self, motion) PopupButton_UpdateFont(self) end

---@param self table
---@param motion boolean
local function PopupButton_OnLeave(self, motion) PopupButton_UpdateFont(self) end

local U_CHAT_SCROLL_BUTTON_SOUND = SOUNDKIT.U_CHAT_SCROLL_BUTTON
local PlaySound = PlaySound

---@param self table
---@param button string
---@param down boolean
local function PopupButton_OnClick(self, button, down)
    if not getInfoValue(self.info, "noClickSound") then PlaySound(U_CHAT_SCROLL_BUTTON_SOUND) end

    local menuList = getInfoValue(self.info, "menuList")

    if menuList then
        local title = getInfoValue(self.info, "text")
        if title then
            local textColor = getInfoValue(self.info, "textColor")
            if textColor then title = "|c" .. textColor .. title .. "|r" end
        end
        open(menuList, title)
        return
    end

    local checked = getInfoValue(self.info, "checked")

    if getInfoValue(self.info, "keepShownOnClick") then
        if not getInfoValue(self.info, "notCheckable") then
            if checked then
                self.check:Hide()
                self.unCheck:Show()
                checked = false
            else
                self.check:Show()
                self.unCheck:Hide()
                checked = true
            end
        end
    else
        lib:Close()
    end
    getInfoValue(self.info, "checked", checked)

    getInfoValue(self.info, "func", checked)
end

local min = math.min
local unpack = unpack
local UIParent = UIParent

---@param self table
local function PopupButton_Update(self)
    local info = self.info

    self.arrow:SetShown(getInfoValue(info, "menuList") and true)

    local disabled = getInfoValue(info, "disabled")
    self:SetEnabled(not disabled)

    local isTitle = getInfoValue(info, "isTitle")
    if isTitle then self:Disable() end

    local text = getInfoValue(info, "text")
    if text then
        local textColor = getInfoValue(info, "textColor")
        if textColor then
            self.text:SetText("|c" .. textColor .. text .. "|r")
        else
            self.text:SetText(text)
        end
    else
        self.text:SetText()
    end
    self:SetWidth(min(self.text:GetStringWidth() + 60, UIParent:GetWidth() * 0.5))

    local icon = getInfoValue(info, "icon")
    if icon then
        self.icon:SetTexture(icon)
        local texCoords = getInfoValue(info, "texCoords")
        if texCoords then
            self.icon:SetTexCoord(unpack(texCoords))
        else
            self.icon:SetTexCoord(0, 1, 0, 1)
        end
        self.icon:ClearAllPoints()
        if getInfoValue(info, "iconExpandX") then self.icon:SetPoint("LEFT") end
        self.icon:SetPoint("RIGHT")
        local iconHeight = getInfoValue(info, "iconHeight")
        iconHeight = (iconHeight and iconHeight <= 16) and iconHeight or 16
        self.icon:SetHeight(iconHeight)
        self.icon:SetDesaturated(disabled)
    end
    self.icon:SetShown(icon and true)

    if getInfoValue(info, "notCheckable") or isTitle then
        self.check:Hide()
        self.unCheck:Hide()
    else
        if getInfoValue(info, "checked") then
            self.check:Show()
            self.unCheck:Hide()
        else
            self.check:Hide()
            self.unCheck:Show()
        end
        if getInfoValue(info, "isNotRadio") then
            self.check:SetTexCoord(0, 0.5, 0, 0.5)
            self.unCheck:SetTexCoord(0.5, 1, 0, 0.5)
        else
            self.check:SetTexCoord(0, 0.5, 0.5, 1)
            self.unCheck:SetTexCoord(0.5, 1, 0.5, 1)
        end
    end

    self:GetParent():MarkDirty()
end

---@param self table
---@param elapsed number
local function PopupButton_OnUpdate(self, elapsed)
    self.lastUpdate = (self.lastUpdate or 0) + elapsed
    if self.lastUpdate >= 0.2 then
        self.lastUpdate = 0
        PopupButton_Update(self)
    end
end

---@param self table
---@param info table
---@param parentList table
---@param parentTitle string
local function PopupButton_SetInfo(self, info, parentList, parentTitle)
    self.info = info
    self.parentList = parentList
    self.parentTitle = parentTitle

    PopupButton_Update(self)
end

local PopupButtonMixin = {}

function PopupButtonMixin:OnLoad()
    self.OnLoad = nil

    self:SetHeight(16)

    self.check = self.check or self:CreateTexture(nil, "ARTWORK")
    self.check:ClearAllPoints()
    self.check:SetPoint("LEFT")
    self.check:SetTexture([[Interface\Common\UI-DropDownRadioChecks]])
    self.check:SetTexCoord(0, 0.5, 0.5, 1)
    self.check:SetSize(16, 16)

    self.unCheck = self.unCheck or self:CreateTexture(nil, "ARTWORK")
    self.unCheck:ClearAllPoints()
    self.unCheck:SetPoint("LEFT")
    self.unCheck:SetTexture([[Interface\Common\UI-DropDownRadioChecks]])
    self.unCheck:SetTexCoord(0.5, 1, 0.5, 1)
    self.unCheck:SetSize(16, 16)

    self.icon = self.icon or self:CreateTexture(nil, "ARTWORK")
    self.icon:ClearAllPoints()
    self.icon:SetPoint("RIGHT")
    self.icon:SetSize(16, 16)

    self.text = self.text or self:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallLeft")
    self.text:ClearAllPoints()
    self.text:SetPoint("LEFT", self.check, "RIGHT", 0, 0)
    self.text:SetPoint("RIGHT")

    self.arrow = self.arrow or self:CreateTexture(nil, "ARTWORK")
    self.arrow:ClearAllPoints()
    self.arrow:SetPoint("RIGHT")
    self.arrow:SetTexture([[Interface\ChatFrame\ChatFrameExpandArrow]])
    self.arrow:SetSize(16, 16)

    self:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD")

    self:SetScript("OnEnable", PopupButton_OnEnable)
    self:SetScript("OnDisable", PopupButton_OnDisable)
    self:SetScript("OnEnter", PopupButton_OnEnter)
    self:SetScript("OnLeave", PopupButton_OnLeave)
    self:SetScript("OnClick", PopupButton_OnClick)
    self:SetScript("OnUpdate", PopupButton_OnUpdate)
end

local SEPARATOR_INFO = {
    icon = [[Interface\Common\UI-TooltipDivider-Transparent]],
    texCoords = {0, 1, 0, 1},
    iconExpandX = true,
    iconHeight = 8,
    notCheckable = true,
    disabled = true,
}

local CopyTable = CopyTable

---@return info table
function lib:GetSeparatorInfo() return CopyTable(SEPARATOR_INFO) end

local TITLE_INFO = {notCheckable = true, disabled = true, textColor = "ffffd100"}

lib.titleButton = lib.titleButton or CreateFrame("Button", nil, frame)
local titleButton = lib.titleButton
titleButton:SetParent(frame)
titleButton.layoutIndex = -1
LibMan1:Get("LibMixin", 1):Mixin(titleButton, PopupButtonMixin)
PopupButton_SetInfo(titleButton, TITLE_INFO)

lib.backSepButton = lib.backSepButton or CreateFrame("Button", nil, frame)
local backSepButton = lib.backSepButton
backSepButton:SetParent(frame)
backSepButton.layoutIndex = MAX_BUTTONS + 2
LibMan1:Get("LibMixin", 1):Mixin(backSepButton, PopupButtonMixin)
PopupButton_SetInfo(backSepButton, SEPARATOR_INFO)

local BACK_INFO = {text = BACK, keepShownOnClick = true, notCheckable = true}

lib.backButton = lib.backButton or CreateFrame("Button", nil, frame)
local backButton = lib.backButton
backButton:SetParent(frame)
backButton.layoutIndex = MAX_BUTTONS + 3
backButton.expand = true
LibMan1:Get("LibMixin", 1):Mixin(backButton, PopupButtonMixin)
PopupButton_SetInfo(backButton, BACK_INFO)

lib.closeButton = lib.closeButton or CreateFrame("Button", nil, frame)
local closeButton = lib.closeButton
closeButton:SetParent(frame)
closeButton.layoutIndex = MAX_BUTTONS + 4
closeButton.expand = true
LibMan1:Get("LibMixin", 1):Mixin(closeButton, PopupButtonMixin)
PopupButton_SetInfo(closeButton, {text = CLOSE, notCheckable = true, func = function() lib:Close() end})

lib.buttons = lib.buttons or {}

local buttons = lib.buttons
for i = 1, MAX_BUTTONS do
    buttons[i] = buttons[i] or CreateFrame("Button", nil, frame)
    local button = buttons[i]
    button:SetParent(frame)
    button.layoutIndex = i
    button.expand = true
    LibMan1:Get("LibMixin", 1):Mixin(button, PopupButtonMixin)
end

---@param self table
---@param down boolean
local function PopupScrollButton_UpdateTexture(self, down)
    if self:IsEnabled() then
        self.texture:SetTexture([[Interface\Buttons\Arrow-]] .. self:GetDirection() .. (down and [[-Down]] or [[-Up]]))
    else
        self.texture:SetTexture([[Interface\Buttons\Arrow-]] .. self:GetDirection() .. [[-Disabled]])
    end
end

---@param self table
---@param direction string | "Up" | "Down"
local function PopupScrollButton_SetDirection(self, direction)
    self.direction = direction == "Up" and "Up" or "Down"
    PopupScrollButton_UpdateTexture(self, self:GetButtonState() == "PUSHED")
end

---@param self table
local function PopupScrollButton_OnEnable(self) PopupScrollButton_UpdateTexture(self) end

---@param self table
local function PopupScrollButton_OnDisable(self) PopupScrollButton_UpdateTexture(self) end

---@param self table
---@param button string
local function PopupScrollButton_OnMouseDown(self, button) PopupScrollButton_UpdateTexture(self, true) end

---@param self table
---@param button string
local function PopupScrollButton_OnMouseUp(self, button) PopupScrollButton_UpdateTexture(self) end

local PopupScrollButtonMixin = {}

function PopupScrollButtonMixin:OnLoad()
    self:SetHeight(16)

    self:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]], "ADD")

    self.texture = self.texture or self:CreateTexture(nil, "ARTWORK")
    self.texture:ClearAllPoints()
    self.texture:SetPoint("CENTER")

    self:SetScript("OnEnable", PopupScrollButton_OnEnable)
    self:SetScript("OnDisable", PopupScrollButton_OnDisable)
    self:SetScript("OnMouseDown", PopupScrollButton_OnMouseDown)
    self:SetScript("OnMouseUp", PopupScrollButton_OnMouseUp)
end

---@return string direction
function PopupScrollButtonMixin:GetDirection() return self.direction or "Up" end

lib.scrollUpButton = lib.scrollUpButton or CreateFrame("Button", nil, frame)
lib.scrollDownButton = lib.scrollDownButton or CreateFrame("Button", nil, frame)

local scrollUpButton = lib.scrollUpButton
local scrollDownButton = lib.scrollDownButton

LibMan1:Get("LibMixin", 1):Mixin(scrollUpButton, PopupScrollButtonMixin)
LibMan1:Get("LibMixin", 1):Mixin(scrollDownButton, PopupScrollButtonMixin)

PopupScrollButton_SetDirection(scrollDownButton, "Down")

scrollUpButton.layoutIndex = 0
scrollDownButton.layoutIndex = MAX_BUTTONS + 1

scrollUpButton.expand = true
scrollDownButton.expand = true

local ANCHORS = {
    ANCHOR_TOP = {"BOTTOM", "TOP"},
    ANCHOR_RIGHT = {"BOTTOMLEFT", "TOPRIGHT"},
    ANCHOR_BOTTOM = {"TOP", "BOTTOM"},
    ANCHOR_LEFT = {"BOTTOMRIGHT", "TOPLEFT"},
    ANCHOR_TOPRIGHT = {"BOTTOMRIGHT", "TOPRIGHT"},
    ANCHOR_BOTTOMRIGHT = {"TOPRIGHT", "BOTTOMRIGHT"},
    ANCHOR_TOPLEFT = {"BOTTOMLEFT", "TOPLEFT"},
    ANCHOR_BOTTOMLEFT = {"TOPLEFT", "BOTTOMLEFT"},
}

local error = error
local format = format
local tostring = tostring
local GetCursorPosition = GetCursorPosition

---@param owner table
---@param anchor string
---@param ofsX number
---@param ofsY number
function lib:SetOwner(owner, anchor, ofsX, ofsY)
    if type(owner) ~= "table" then
        error(format("Usage: %s:SetOwner(owner, anchor[, ofsX, ofsY]): 'owner' - table expected got %s", tostring(lib),
                     type(owner), 2))
    end
    if type(anchor) ~= "string" then
        error(format("Usage: %s:SetOwner(owner, anchor[, ofsX, ofsY]): 'anchor' - string expected got %s",
                     tostring(lib), type(anchor), 2))
    end
    ofsX = ofsX or 0
    if type(ofsX) ~= "number" then
        error(format("Usage: %s:SetOwner(owner, anchor[, ofsX, ofsY]): 'ofsX' - number expected got %s", tostring(lib),
                     type(ofsX), 2))
    end
    ofsY = ofsY or 0
    if type(ofsY) ~= "number" then
        error(format("Usage: %s:SetOwner(owner, anchor[, ofsX, ofsY]): 'ofsY' - number expected got %s", tostring(lib),
                     type(ofsY), 2))
    end
    self.owner = owner

    local relativeTo = owner
    local point, relativePoint
    if anchor == "ANCHOR_CURSOR" then
        point = "TOPLEFT"
        relativeTo = UIParent
        relativePoint = "BOTTOMLEFT"
        local x, y = GetCursorPosition()
        local effectiveScale = frame:GetEffectiveScale()
        ofsX = (x + ofsX) / effectiveScale
        ofsY = (y + ofsY) / effectiveScale
    elseif ANCHORS[anchor] then
        point, relativePoint = unpack(ANCHORS[anchor])
    end
    if point then
        frame:ClearAllPoints()
        frame:SetPoint(point, relativeTo, relativePoint, ofsX, ofsY)
    end
end

---@param owner table
---@return boolean
function lib:IsOwned(owner)
    if type(owner) ~= "table" then
        error(format("Usage: %s:IsOwned(owner): 'owner' - table expected got %s", tostring(lib), type(owner), 2))
    end
    return self.owner == owner
end

---@return table
function lib:GetOwner() return self.owner end

local currentList, currentTitle
local offset = 0

local function updateButtons()
    if not currentList then
        lib:Close()
        return
    end
    local infoCount = #currentList

    for i = 1, MAX_BUTTONS do
        local index = i + offset
        local button = buttons[i]
        local info = currentList[index]

        PopupButton_SetInfo(button, info)
        button:SetShown(info and true)
    end

    if currentTitle then
        TITLE_INFO.text = currentTitle
        titleButton:Show()
    else
        titleButton:Hide()
    end

    if currentList ~= lib.menuList then
        BACK_INFO.func = function() open(lib.menuList, lib.title) end
        backButton:Show()
        backSepButton:Show()
    else
        backButton:Hide()
        backSepButton:Hide()
    end

    scrollUpButton:SetEnabled(offset > 0)
    scrollDownButton:SetEnabled(infoCount - MAX_BUTTONS > offset)

    scrollUpButton:SetShown(infoCount > MAX_BUTTONS)
    scrollDownButton:SetShown(infoCount > MAX_BUTTONS)

    scrollUpButton:SetWidth(26)
    scrollDownButton:SetWidth(26)

    frame:MarkDirty()
    --[[ frame:SetShown(infoCount > 0) ]]
    frame:Show()
end

---@param menuList table
---@param title string
open = function(menuList, title)
    currentList = menuList
    currentTitle = title
    offset = 0
    updateButtons()
end

local max = math.max

---@param delta number
local function updateOffset(delta)
    if not currentList then
        lib:Close()
        return
    end

    offset = offset + (delta * -1)
    offset = max(0, min(offset, #currentList - MAX_BUTTONS))
    updateButtons()
end

---@param menuList table
---@param title string
---@param parentList table
---@param parentTitle string
function lib:Open(menuList, title)
    if type(menuList) ~= "table" then
        error(format("Usage: %s:Open(menuList[, title]): 'menuList' - table expected got %s", tostring(lib),
                     type(menuList), 2))
    end
    if type(self:GetOwner()) ~= "table" then
        error(format("Usage: %s:Open(menuList[, title]): Owner not set.", tostring(lib), 2))
    end

    self.menuList = menuList
    self.title = title

    open(menuList, title)
end

function lib:Close()
    self.owner = nil
    frame:ClearAllPoints()
    frame:Hide()
end

---@return boolean
function lib:IsOpen() return frame:IsShown() end

---@param self table
frame:SetScript("OnHide", function(self) self.owner = nil end)

local IsShiftKeyDown = IsShiftKeyDown

---@param self table
---@param delta number
frame:SetScript("OnMouseWheel", function(self, delta) updateOffset(delta * (IsShiftKeyDown() and 10 or 1)) end)

---@param self table
---@param key string
frame:SetScript("OnKeyDown", function(self, key)
    self:SetPropagateKeyboardInput(false)
    if key == "ESCAPE" or key == "ENTER" then
        lib:Close()
    elseif key == "DOWN" then
        updateOffset(-1 * (IsShiftKeyDown() and 10 or 1))
    elseif key == "UP" then
        updateOffset(1 * (IsShiftKeyDown() and 10 or 1))
    elseif key == "SPACE" then
        for i = 1, #buttons do
            local button = buttons[i]
            if button:IsVisible() and button:IsMouseOver() then
                button:Click()
                break
            end
        end
    else
        self:SetPropagateKeyboardInput(true)
    end
end)

---@param self table
---@param elapsed number
frame:SetScript("OnUpdate", function(self, elapsed)
    if self:IsDirty() then
        scrollUpButton:SetWidth(26)
        scrollDownButton:SetWidth(26)
        self:Layout()
    end
end)

---@param self table
---@param button string
---@param down boolean
scrollUpButton:SetScript("OnClick", function(self, button, down) updateOffset(1) end)

---@param self table
---@param button string
---@param down boolean
scrollDownButton:SetScript("OnClick", function(self, button, down) updateOffset(-1) end)
