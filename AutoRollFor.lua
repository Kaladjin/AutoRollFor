-- ==========================================================
-- 1. INITIALISATION ET VARIABLES
-- ==========================================================
-- On s'assure que la table existe immédiatement
if not AutoRollPrefs then AutoRollPrefs = {} end
local currentItemID = nil

-- ==========================================================
-- 2. LE MENU CLIC-DROIT (Intégration AtlasLoot)
-- ==========================================================
local menuFrame = CreateFrame("Frame", "AutoRollContextMenu", UIParent, "UIDropDownMenuTemplate")

UIDropDownMenu_Initialize(menuFrame, function()
    -- Sécurité : on recharge les préférences si besoin
    if not AutoRollPrefs then AutoRollPrefs = {} end
    if not currentItemID then return end
    
    local prefs = AutoRollPrefs[currentItemID] or { ms=false, os=false, tmog=false, auto=false }
    local info = {}
    
    info.text = "Réserver pour AutoRoll"
    info.isTitle = 1; info.notCheckable = 1
    UIDropDownMenu_AddButton(info)
    
    -- Options MS, OS, TMOG
    local options = { 
        {k="ms", t="Main Spec (MS)"}, 
        {k="os", t="Off Spec (OS)"}, 
        {k="tmog", t="Transmog (TMOG)"} 
    }

    for _, opt in ipairs(options) do
        -- On crée une variable locale pour "capturer" la clé correctement dans WoW 1.12
        local selectionKey = opt.k 
        info = {}
        info.text = opt.t
        info.func = function() 
            -- Sécurités anti-crash (Nil checks)
            if not currentItemID then return end
            if not AutoRollPrefs then AutoRollPrefs = {} end
            
            local oldAuto = false
            if AutoRollPrefs[currentItemID] then oldAuto = AutoRollPrefs[currentItemID].auto end
            
            -- Mise à jour de la préférence
            AutoRollPrefs[currentItemID] = { [selectionKey] = true, auto = oldAuto } 
            CloseDropDownMenus()
        end
        info.checked = prefs[opt.k]
        UIDropDownMenu_AddButton(info)
    end
    
    -- Option ROLL AUTOMATIQUE
    info = {}
    info.text = "|cffffff00Lancer le dé automatiquement|r"
    info.func = function() 
        if not currentItemID then return end
        if not AutoRollPrefs then AutoRollPrefs = {} end
        if not AutoRollPrefs[currentItemID] then AutoRollPrefs[currentItemID] = {} end
        
        AutoRollPrefs[currentItemID].auto = not AutoRollPrefs[currentItemID].auto 
    end
    info.checked = prefs.auto; info.keepShownOnClick = 1
    UIDropDownMenu_AddButton(info)

    -- ANNULER
    info = {}
    info.text = "|cffff0000Annuler la réservation|r"
    info.func = function() 
        if not currentItemID then return end
        AutoRollPrefs[currentItemID] = nil 
        CloseDropDownMenus()
    end
    info.notCheckable = 1
    UIDropDownMenu_AddButton(info)
end, "MENU")

-- ==========================================================
-- 3. LOGIQUE DE DÉTECTION (Master Loot & Group Loot)
-- ==========================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("CHAT_MSG_RAID")
eventFrame:RegisterEvent("CHAT_MSG_RAID_LEADER")
eventFrame:RegisterEvent("CHAT_MSG_PARTY")
eventFrame:RegisterEvent("START_LOOT_ROLL")

local function GetIDFromLink(link)
    if not link then return nil end
    local _, _, id = string.find(link, "item:(%d+)")
    return tonumber(id)
end

-- On utilise les paramètres officiels de l'événement (event, arg1...)
eventFrame:SetScript("OnEvent", function()
    -- CAS A : MODE GROUPE (Besoin / Cupidité)
    if event == "START_LOOT_ROLL" then
        local rollID = arg1
        local itemLink = GetLootRollItemLink(rollID)
        local itemID = GetIDFromLink(itemLink)
        
        if itemID and AutoRollPrefs and AutoRollPrefs[itemID] and AutoRollPrefs[itemID].auto then
            local pref = AutoRollPrefs[itemID]
            if pref.ms then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AutoRollFor]|r: Mode Groupe - [MS] détecté. Roll |cff00ff00BESOIN|r sur " .. itemLink)
                RollOnLoot(rollID, 1) -- 1 = Besoin
            elseif pref.os or pref.tmog then
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AutoRollFor]|r: Mode Groupe - [OS/TMOG] détecté. Roll |cff00ccffCUPIDITÉ|r sur " .. itemLink)
                RollOnLoot(rollID, 2) -- 2 = Cupidité
            end
        end
        return
    end

    -- CAS B : MODE MASTER LOOT (Détection RollFor)
    if arg1 then
        local _, _, itemLink = string.find(arg1, "Roll for (.*): /roll %(MS%)")
        if itemLink then
            local itemID = GetIDFromLink(itemLink)
            if not AutoRollPrefs then AutoRollPrefs = {} end
            local pref = AutoRollPrefs[itemID]
            if pref then
                local v = (pref.ms and 100) or (pref.os and 99) or (pref.tmog and 98) or 0
                if v > 0 then
                    if pref.auto then
                        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[AutoRollFor]|r: Annonce RollFor détectée. Auto-Roll /roll " .. v)
                        RandomRoll(1, v) 
                    else
                        AutoRollAlertItem:SetText(itemLink)
                        AutoRollAlert:Show()
                        PlaySound("RaidWarning")
                    end
                end
            end
        end
    end
end)

-- ==========================================================
-- 4. PIRATAGE VISUEL D'ATLASLOOT
-- ==========================================================
local atlasLootHooked = false
local function HookAtlasLoot()
    if atlasLootHooked or not getglobal("AtlasLootItem_1") then return end
    for i = 1, 30 do
        local btn = getglobal("AtlasLootItem_"..i)
        if btn then
            btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            local oldClick = btn:GetScript("OnClick")
            btn:SetScript("OnClick", function()
                if arg1 == "RightButton" and this.itemID and tonumber(this.itemID) > 0 then
                    currentItemID = tonumber(this.itemID)
                    ToggleDropDownMenu(1, nil, menuFrame, this:GetName(), 0, 0)
                elseif oldClick then oldClick() end
            end)
            btn.arInd = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            btn.arInd:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
        end
    end
    atlasLootHooked = true
end

local updateFrame = CreateFrame("Frame")
updateFrame:SetScript("OnUpdate", function()
    if not atlasLootHooked and getglobal("AtlasLootItemsFrame") and getglobal("AtlasLootItemsFrame"):IsVisible() then HookAtlasLoot() end
    if atlasLootHooked and getglobal("AtlasLootItemsFrame") and getglobal("AtlasLootItemsFrame"):IsVisible() then
        for i = 1, 30 do
            local b = getglobal("AtlasLootItem_"..i)
            if b and b:IsVisible() and b.itemID then
                if not AutoRollPrefs then AutoRollPrefs = {} end
                local p = AutoRollPrefs[tonumber(b.itemID)]
                if p then
                    local t = (p.ms and "|cff00ff00MS|r") or (p.os and "|cff00ccffOS|r") or (p.tmog and "|cffff00ffTM|r") or ""
                    if p.auto then t = t.."|cffffff00*|r" end
                    b.arInd:SetText(t)
                else b.arInd:SetText("") end
            end
        end
    end
end)

-- ==========================================================
-- 5. FENÊTRE D'ALERTE (Mode Manuel)
-- ==========================================================
local alert = CreateFrame("Frame", "AutoRollAlert", UIParent)
alert:SetWidth(340); alert:SetHeight(110); alert:SetPoint("CENTER", 0, 150)
alert:SetBackdrop({bgFile="Interface\\ChatFrame\\ChatFrameBackground", edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", tile=true, tileSize=16, edgeSize=16, insets={5,5,5,5}})
alert:SetBackdropColor(0,0,0,1); alert:Hide()

local alertT = alert:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
alertT:SetPoint("TOP", 0, -15); alertT:SetText("Objet Réservé !")

AutoRollAlertItem = alert:CreateFontString(nil, "OVERLAY", "GameFontNormal")
AutoRollAlertItem:SetPoint("CENTER", 0, 10)

local function CreateRollBtn(text, v, xOff)
    local b = CreateFrame("Button", nil, alert, "UIPanelButtonTemplate")
    b:SetWidth(70); b:SetHeight(24); b:SetPoint("BOTTOMLEFT", xOff, 15); b:SetText(text)
    b:SetScript("OnClick", function() RandomRoll(1, v); alert:Hide() end)
    return b
end

local bMS   = CreateRollBtn("MS", 100, 15)
local bOS   = CreateRollBtn("OS", 99, 90)
local bTMOG = CreateRollBtn("TMOG", 98, 165)

local bPass = CreateFrame("Button", nil, alert, "UIPanelButtonTemplate")
bPass:SetWidth(70); bPass:SetHeight(24); bPass:SetPoint("BOTTOMRIGHT", -15, 15); bPass:SetText("Passer")
bPass:SetScript("OnClick", function() alert:Hide() end)

-- ==========================================================
-- 6. COMMANDE TEST
-- ==========================================================
SLASH_AUTOROLL1 = "/ar"
SlashCmdList["AUTOROLL"] = function(msg)
    if msg == "test" then
        if not AutoRollPrefs then AutoRollPrefs = {} end
        for id, pref in pairs(AutoRollPrefs) do
            local name, str, qual = GetItemInfo(id)
            if name then
                local _, _, _, hex = GetItemQualityColor(qual or 4)
                local link = hex.."|H"..str.."|h["..name.."]|h|r"
                local fakeMsg = "Roll for " .. link .. ": /roll (MS) or /roll 99 (OS) or /roll 98 (TMOG)"
                DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[RollFor]|r: " .. fakeMsg)
                arg1 = fakeMsg
                eventFrame:GetScript("OnEvent")()
                return
            end
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000AutoRoll : Réserve un objet dans AtlasLoot pour tester.|r")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffAutoRollFor v3.2|r: Clic-droit sur AtlasLoot. /ar test pour simuler.")
    end
end