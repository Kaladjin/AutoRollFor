-- ==========================================================
-- 1. INITIALISATION ET VARIABLES
-- ==========================================================
if not AutoRollPrefs then AutoRollPrefs = {} end
if not AutoRollPrefs.Config then AutoRollPrefs.Config = {} end

local currentItemID = nil
local AutoRollQueue = {}

-- Scanner invisible pour forcer le serveur à envoyer les noms d'objets
local Scanner = CreateFrame("GameTooltip", "AutoRollScanner", nil, "GameTooltipTemplate")
Scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

-- ==========================================================
-- 2. CRÉATION DE L'INTERFACE (Ultra Compacte)
-- ==========================================================
local alert = CreateFrame("Frame", "AutoRollAlert", UIParent)
alert:SetWidth(280); alert:SetHeight(100)
alert:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=12, edgeSize=12, insets={4,4,4,4}})
alert:SetBackdropColor(0,0,0,0.9); alert:Hide()

if AutoRollPrefs.Config and AutoRollPrefs.Config.pos then
    local p = AutoRollPrefs.Config.pos
    alert:SetPoint(p.point, "UIParent", p.relativePoint, p.xOfs, p.yOfs)
else
    alert:SetPoint("CENTER", 0, 150)
end

alert:SetMovable(true); alert:EnableMouse(true); alert:RegisterForDrag("LeftButton")
alert:SetScript("OnMouseDown", function() if arg1 == "LeftButton" then this:StartMoving() end end)
alert:SetScript("OnMouseUp", function() 
    this:StopMovingOrSizing()
    local point, _, rel, x, y = this:GetPoint()
    AutoRollPrefs.Config.pos = { point=point, relativePoint=rel, xOfs=x, yOfs=y }
end)

local alertT = alert:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
alertT:SetPoint("TOP", 0, -10); alertT:SetText("Objet Réservé !")

AutoRollAlertItem = alert:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
AutoRollAlertItem:SetPoint("CENTER", 0, 12)

AutoRollAlertCount = alert:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
AutoRollAlertCount:SetPoint("BOTTOM", 0, 36)
AutoRollAlertCount:SetTextColor(0.5, 0.5, 0.5)

-- ==========================================================
-- 3. LOGIQUE D'AFFICHAGE ET BOUTONS
-- ==========================================================
local function ShowNextAutoRollAlert()
    local count = table.getn(AutoRollQueue)
    if count > 0 then
        local itemID = table.remove(AutoRollQueue, 1)
        alert.currentID = itemID 
        
        local itemName, _, itemQuality = GetItemInfo(itemID)
        if itemName then
            local _, _, _, hex = GetItemQualityColor(itemQuality)
            AutoRollAlertItem:SetText(hex .. "[" .. itemName .. "]|r")
        else
            AutoRollAlertItem:SetText("|cffaaaaaaChargement de l'objet #" .. itemID .. "...|r")
            Scanner:ClearLines()
            Scanner:SetHyperlink("item:"..itemID..":0:0:0")
        end
        
        if count > 1 then AutoRollAlertCount:SetText("Objets en attente : " .. (count - 1))
        else AutoRollAlertCount:SetText("") end
        
        alert:Show()
        PlaySound("RaidWarning")
    else
        alert.currentID = nil
        alert:Hide()
    end
end

local function CreateRollBtn(text, v, xOff)
    local b = CreateFrame("Button", nil, alert, "UIPanelButtonTemplate")
    b:SetWidth(55); b:SetHeight(20); b:SetPoint("BOTTOMLEFT", xOff, 12); b:SetText(text)
    local btnText = b:GetFontString(); btnText:SetFont("Fonts\\FRIZQT__.TTF", 9) 
    b:SetScript("OnClick", function() RandomRoll(1, v); ShowNextAutoRollAlert() end)
    return b
end

CreateRollBtn("MS", 100, 12); CreateRollBtn("OS", 99, 79); CreateRollBtn("TMOG", 98, 146)
local bPass = CreateFrame("Button", nil, alert, "UIPanelButtonTemplate")
bPass:SetWidth(55); bPass:SetHeight(20); bPass:SetPoint("BOTTOMLEFT", 213, 12); bPass:SetText("Passer")
local bPassText = bPass:GetFontString(); bPassText:SetFont("Fonts\\FRIZQT__.TTF", 9)
bPass:SetScript("OnClick", function() ShowNextAutoRollAlert() end)

-- ==========================================================
-- 4. DÉTECTION CHAT
-- ==========================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_RAID"); eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_RAID_WARNING"); eventFrame:RegisterEvent("CHAT_MSG_PARTY")

local function GetIDFromLink(link)
    if not link then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    return tonumber(id)
end

eventFrame:SetScript("OnEvent", function()
    if arg1 then
        local _, _, itemLink = string.find(arg1, "(|c%x+|Hitem:%d+.-|h%[.-%]|h|r)")
        local msgLower = string.lower(arg1)
        if itemLink and (string.find(msgLower, "roll for") or string.find(msgLower, "jet pour") or string.find(msgLower, "random")) then
            local itemID = GetIDFromLink(itemLink)
            if itemID and AutoRollPrefs[itemID] then
                table.insert(AutoRollQueue, itemID)
                if not alert:IsVisible() then ShowNextAutoRollAlert() end
            end
        end
    end
end)

--- ==========================================================
-- 5. PIRATAGE ATLASLOOT DYNAMIQUE (Fix Définitif)
-- ==========================================================
local menuFrame = CreateFrame("Frame", "AutoRollContextMenu", UIParent, "UIDropDownMenuTemplate")
UIDropDownMenu_Initialize(menuFrame, function()
    if not currentItemID then return end
    local prefs = AutoRollPrefs[currentItemID] or { ms=false, os=false, tmog=false }
    UIDropDownMenu_AddButton({ text = "Réserver pour AutoRoll", isTitle = 1, notCheckable = 1 })
    
    local options = { {k="ms", t="Main Spec (MS)"}, {k="os", t="Off Spec (OS)"}, {k="tmog", t="Transmog (TMOG)"} }
    for _, opt in ipairs(options) do
        -- LA CORRECTION EST LÀ : On mémorise la clé localement pour le clic
        local key = opt.k 
        UIDropDownMenu_AddButton({ 
            text = opt.t, 
            func = function() AutoRollPrefs[currentItemID] = { [key] = true }; CloseDropDownMenus() end, 
            checked = prefs[key] 
        })
    end
    UIDropDownMenu_AddButton({ text = "|cffff0000Annuler|r", func = function() AutoRollPrefs[currentItemID] = nil; CloseDropDownMenus() end, notCheckable = 1 })
end, "MENU")

-- Création de 30 "calques" indépendants pour afficher MS/OS sans toucher à l'interface d'AtlasLoot
local arIndicators = {}
for i = 1, 30 do
    arIndicators[i] = CreateFrame("Frame", nil, UIParent)
    arIndicators[i]:SetWidth(30); arIndicators[i]:SetHeight(15)
    arIndicators[i]:SetFrameStrata("TOOLTIP") -- Toujours au-dessus
    arIndicators[i].text = arIndicators[i]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    arIndicators[i].text:SetPoint("BOTTOMRIGHT", 0, 0)
    arIndicators[i]:Hide()
end

local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function()
    -- Scanner AtlasLoot
    if getglobal("AtlasLootItemsFrame") and getglobal("AtlasLootItemsFrame"):IsVisible() then
        for i = 1, 30 do
            local b = getglobal("AtlasLootItem_"..i)
            if b and b:IsVisible() then
                
                -- 1. Hook Clic Droit
                if not b.arHooked then
                    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                    local oldClick = b:GetScript("OnClick")
                    b:SetScript("OnClick", function()
                        if arg1 == "RightButton" and this.itemID then
                            currentItemID = tonumber(this.itemID)
                            ToggleDropDownMenu(1, nil, menuFrame, this:GetName(), 0, 0)
                        elseif oldClick then oldClick() end
                    end)
                    b.arHooked = true
                end
                
                -- 2. Affichage MS/OS avec nos propres cadres
                if b.itemID then
                    local id = tonumber(b.itemID)
                    local p = AutoRollPrefs[id]
                    if type(p) == "table" and (p.ms or p.os or p.tmog) then
                        arIndicators[i]:SetParent(b)
                        arIndicators[i]:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -2, 2)
                        arIndicators[i].text:SetText((p.ms and "|cff00ff00MS|r") or (p.os and "|cff00ccffOS|r") or (p.tmog and "|cffff00ffTM|r"))
                        arIndicators[i]:Show()
                    else
                        arIndicators[i]:Hide()
                    end
                else
                    arIndicators[i]:Hide()
                end
            else
                arIndicators[i]:Hide()
            end
        end
    else
        -- Si AtlasLoot est fermé, on cache tout
        for i = 1, 30 do arIndicators[i]:Hide() end
    end
    
    -- Rafraîchissement automatique de la fenêtre d'alerte
    if alert:IsVisible() and alert.currentID then
        local itemName, _, itemQuality = GetItemInfo(alert.currentID)
        if itemName then
            local currentTxt = AutoRollAlertItem:GetText() or ""
            if string.find(currentTxt, "Chargement") then
                local _, _, _, hex = GetItemQualityColor(itemQuality)
                AutoRollAlertItem:SetText(hex .. "[" .. itemName .. "]|r")
            end
        end
    end
end)

-- ==========================================================
-- 6. COMMANDE TEST
-- ==========================================================
SLASH_AUTOROLL1 = "/ar"
SlashCmdList["AUTOROLL"] = function(msg)
    if msg == "test" then
        local count = 0
        for id, _ in pairs(AutoRollPrefs) do
            if id ~= "Config" then table.insert(AutoRollQueue, id); count = count + 1 end
        end
        if count > 0 then 
            if not alert:IsVisible() then ShowNextAutoRollAlert() end
        else 
            DEFAULT_CHAT_FRAME:AddMessage("|cffff0000AutoRoll : Aucune réservation trouvée.|r") 
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffAutoRollFor|r: /ar test pour tester.")
    end
end