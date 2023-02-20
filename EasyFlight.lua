local internal = {
    DOUBLECLICK_MAX_SECONDS = 0.2,
    DOUBLECLICK_MIN_SECONDS = 0.04,
    previousPressTime = 0
}
local druidForms = {
    783,    --travel
    768,    --cat
    5487,   --bear
    114282, --treant
    24858,  --moonkin
    197625  --moonkin astral
}
local travelFormId = 783
local catFormId = 768
local addonName = ...
local lastForm = nil
local currentForm = nil
local doubleFlight = {}
local isEnabled = nil
local debug = false

local f= CreateFrame("Frame", addonName, UIParent)
--Check if durid

local function IsTaintable()
  return (InCombatLockdown() or (UnitAffectingCombat("player") or UnitAffectingCombat("pet")))
end

local function getLocalizedSpellName(id)
    return GetSpellInfo(id)
end

local function getDruidForm(name, _,_, _, _, _, _, _, _, spellId, ...)
    for _, value in ipairs(druidForms) do
        if spellId == value then
            local spellInfo = getLocalizedSpellName(spellId)
            currentForm = spellInfo
            if debug then print("Found current Form", spellInfo, spellId) end
            return true
        end
    end
    -- print(name,spellId)
end

local function getDesiredSpell()
    if(IsFlyableArea() and IsOutdoors()) or IsSwimming() then
        return getLocalizedSpellName(travelFormId)
    elseif(IsOutdoors()) then
        return getLocalizedSpellName(travelFormId)
    end
    return getLocalizedSpellName(catFormId)
end

local function isJumpKey(key)
    -- print(GetBindingKey("JUMP"))
    local jump1, jump2 = GetBindingKey("JUMP")
    -- print("Checking if ",key,"is jump")
    if (key == jump1) or (key == jump2) then
        -- print("match")
        return true
    end
    -- print("no match")
    return false
end

local function keyHandler(_, key)
    --    print("Key press:", key)
    if not IsTaintable() then
        ClearOverrideBindings(f)
        if isJumpKey(key) then
            -- print("Key was space")
            local doubleClickTime = GetTime() - internal.previousPressTime
            -- print(doubleClickTime)
            
            if (doubleClickTime < internal.DOUBLECLICK_MAX_SECONDS and doubleClickTime > internal.DOUBLECLICK_MIN_SECONDS) or IsFalling() then
                -- print("Double Space pressed with ", string.format("%.2f",doubleClickTime), " second interval")
                currentForm = nil
                if debug then print("Last form was", lastForm) end
                AuraUtil.ForEachAura("player","HELPFUL",nil,getDruidForm)
                if debug then print("Current form is", currentForm) end
                local desiredForm = getDesiredSpell()
                if debug then print("Desired form is", desiredForm) end
                -- print(currentForm,desiredForm,lastForm)
                if desiredForm ~= currentForm then
                    if(currentForm ~= getLocalizedSpellName(travelFormId))then                        
                        if debug then print(currentForm,"saved as last form") end
                        lastForm = currentForm
                    end
                    -- print("last form saved ", lastForm)
                    if debug then print("Trying to cast", desiredForm) end
                    if(currentForm ~= nil) then CancelShapeshiftForm() end
                    SetOverrideBindingSpell(f,true,key, desiredForm)
                else
                    -- print("reverting to last form", lastForm)
                    local travelForm = getLocalizedSpellName(travelFormId)
                    if lastForm == nil then
                        if debug then print("Last form was base, trying to cancel", currentForm) end
                        CancelShapeshiftForm()
                    else
                        if debug then print("Cancelling travel Form") end
                        CancelShapeshiftForm()
                        if debug then print("Trying to cast", lastForm) end
                        SetOverrideBindingSpell(f,true,key, lastForm)
                    end
                end
                internal.previousPressTime = 0
            else
                internal.previousPressTime = GetTime()
            end
        end
    end
end

-- hooksecurefunc("AscendStop", function()
    
-- 	if IsTaintable() then return end
--     print("HEllo")
--     if IsFalling() then
--         SetOverrideBindingSpell(f,true,"SPACE","Travel Form")
--     end
-- end)

f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        f:UnregisterEvent("PLAYER_ENTERING_WORLD")
        local playerLoc = PlayerLocation:CreateFromUnit("player")
        local playerClass = C_PlayerInfo.GetClass(playerLoc)

        if playerClass ~= "Druid" then
            print("You are not durid! You cannot be birb!")
            isEnabled = false
            return
        end
        f:SetScript("OnKeyDown", keyHandler)
        f:SetPropagateKeyboardInput(true)
        isEnabled = true
        print("Druid detected. Running addon")
    end
end)


local function handleCommands(msg, editbox)
    if msg == "debug" then
        debug = not debug
        print("EasyFlight debug mode:", debug)
    end
end
SLASH_EASYFLIGHT1 = '/easyflight'
SlashCmdList["EASYFLIGHT"] = handleCommands