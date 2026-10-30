-- Random Events addon for Garry's Mod  (v8 - new HUD, kill feed, Options menu)
-- Put this file here: garrysmod/addons/random_events/lua/autorun/random_events.lua
--
-- Start an event:
--   Console:  random_event          (random event)
--             random_event 1..6     (pick an event by number)
--   Chat:     /randomevent          (also /randomevent 2 etc.)
-- Stop an event: random_event_stop  (or /stopevent in chat)
--
-- Admin panel (HOST ONLY):
--   Console:  theadminpanel
--   Bind:     bind o theadminpanel        (or: theadminpanel_bind o)
--
-- Music volume (each player, in the console):  re_music_volume 0.5
-- If something gets stuck (menu, camera, keys):  re_fix   (or /fix in chat)

-- =====================================================
-- SETTINGS (change these numbers if you want)
-- =====================================================
local MAX_WATERMELONS     = 100  -- watermelon limit
local WATERMELON_INTERVAL = 1    -- seconds between watermelons
local ZOMBIE_COUNT        = 12   -- zombies in the zombie event (total, all players)
local SURVIVE_TIME        = 60   -- seconds to survive in "Kill Everyone"
local SCARE_INTERVAL      = 4    -- seconds between jumpscares (for EACH player)
local PROP_RAIN_TIME      = 30   -- seconds of prop rain
local PROP_RAIN_INTERVAL  = 0.5  -- seconds between prop drops
local PROPS_PER_DROP      = 2    -- how many props fall every drop
local PROP_RAIN_NEAR_CHANCE = 0.2 -- chance (0..1) that a prop falls 400-1500 units
                                  -- away from a random player instead of anywhere
                                  -- on the map. 0 = always the whole map.
local HEADCRAB_COUNT      = 15   -- headcrabs in the headcrab event
local LOW_GRAVITY_TIME    = 40   -- seconds of low gravity
local LOW_GRAVITY_VALUE   = 100  -- gravity during the event (normal is 600)

local CLEANUP_DELAY       = 3    -- seconds after the event ends before cleanup
local CLEAN_WHOLE_MAP     = false -- false = remove only what the event spawned
                                  -- true  = wipe the WHOLE map (game.CleanUpMap)

-- ---------- cutscene + music ----------
local CUTSCENE_ENABLED    = true -- cinematic intro before every event
local CUTSCENE_TIME       = 10   -- length of the cutscene in seconds (max 63)
local MUSIC_ENABLED       = true -- play music during the cutscene
local MUSIC_PLAYS_DURING_EVENT = false -- false = music fades out when the round starts
                                       -- true  = music keeps playing during the round

-- Epic tracks that come with Half-Life 2 (one is picked randomly).
local MUSIC_TRACKS = {
    "music/hl2_song12_long.mp3",
    "music/hl2_song14.mp3",
    "music/hl2_song15.mp3",
    "music/hl2_song16.mp3",
    "music/hl2_song20_submix4.mp3",
    "music/hl2_song3.mp3",
}

-- YOUR OWN music. If you add files here, ONLY these will be used.
-- Put your mp3/wav in an addon at:  garrysmod/addons/my_music/sound/music/my_epic.mp3
-- and write the path WITHOUT the leading "sound/":
--   local CUSTOM_MUSIC = {
--       "music/my_epic.mp3",
--   }
local CUSTOM_MUSIC = {
    -- "music/my_epic.mp3",
}

-- ---------- intro + theme ----------
local INTRO_ENABLED         = true  -- cutscene when you join the game
local INTRO_TIME            = 12    -- length of the intro in seconds
local INTRO_ONLY_FIRST_TIME = false -- true = play it only the very first time
local INTRO_MUSIC_ENABLED   = true  -- sad Half-Life music during the intro

-- The intro plays the FIRST track from this list that exists on your computer.
-- (Dark Interval needs Half-Life 2: Episode Two content to be mounted.)
-- You can add your own, for example "music/my_sad_song.mp3"
local INTRO_MUSIC = {
    "music/vlvx_song3.mp3",  -- Dark Interval (the saddest one)
    "music/Ravenholm_1.mp3", -- Requiem for Ravenholm
}
-- Theme switches are console commands (each player can use them):
--   re_dark_theme 0/1   dark gray-green menus (Q menu, context menu...)
--   re_dark_world 0/1   dark green tint on the game picture
-- Replay the intro any time:  re_intro

-- ---------- weapon selection ----------
local WEAPON_SELECT_TIME  = 15   -- seconds players have to choose a weapon
local DEFAULT_WEAPON      = "weapon_smg1" -- given if a player does not choose

-- Which events show the weapon menu before the round starts.
-- Numbers = event numbers (1 watermelon, 2 zombie, 3 kill everyone,
-- 4 prop rain, 5 headcrab, 6 low gravity). Set to false to turn it off.
local WEAPON_EVENTS = { [2] = true, [3] = true, [5] = true, [6] = true }

-- ---------- CUSTOM WEAPONS ----------
-- Add the class names of your weapons here (the "Custom" button in the menu).
-- How to find a class name: open the spawn menu (Q) -> Weapons tab ->
-- right click a weapon -> "Copy to clipboard". Paste it between quotes.
-- Example:
--   local CUSTOM_WEAPONS = {
--       "weapon_mp5",
--       "tfa_ak47",
--   }
local CUSTOM_WEAPONS = {
    -- "weapon_mp5",
}

-- =====================================================
-- SHARED (server + client)
-- =====================================================
local EVENT_LIST = {
    { name = "Watermelon Event", desc = "Watermelons keep spawning",   color = Color(60, 200, 90)  },
    { name = "Zombie Event",     desc = "Kill all the zombies",        color = Color(120, 160, 60) },
    { name = "Kill Everyone",    desc = "Survive the jumpscares",      color = Color(200, 50, 50)  },
    { name = "Prop Rain",        desc = "Props fall all over the map", color = Color(230, 150, 40) },
    { name = "Headcrab Swarm",   desc = "Kill all the headcrabs",      color = Color(170, 90, 200) },
    { name = "Low Gravity",      desc = "Everything floats. Survive!", color = Color(70, 150, 230) },
}

local HL2_WEAPONS = {
    { class = "weapon_crowbar",  name = "Crowbar"      },
    { class = "weapon_stunstick", name = "Stunstick"   },
    { class = "weapon_pistol",   name = "Pistol"       },
    { class = "weapon_357",      name = ".357 Magnum"  },
    { class = "weapon_smg1",     name = "SMG"          },
    { class = "weapon_ar2",      name = "Pulse Rifle"  },
    { class = "weapon_shotgun",  name = "Shotgun"      },
    { class = "weapon_crossbow", name = "Crossbow"     },
    { class = "weapon_rpg",      name = "RPG"          },
    { class = "weapon_frag",     name = "Grenades"     },
    { class = "weapon_slam",     name = "SLAM"         },
}

local RANDOM_ACTION = 15 -- special value sent by the panel: "random event"

-- The list of tracks that can be played (your own music wins if you added any).
local function GetMusicPool()
    if #CUSTOM_MUSIC > 0 then return CUSTOM_MUSIC end
    return MUSIC_TRACKS
end

-- Who is allowed to use the admin panel: the host (the one who created the lobby).
-- On a dedicated server (no host) a superadmin can use it instead.
local function IsHost(ply)
    if not IsValid(ply) then return false end
    if game.SinglePlayer() then return true end
    if ply:IsListenServerHost() then return true end
    return game.IsDedicated() and ply:IsSuperAdmin()
end

-- During the cutscene nobody can move or shoot.
-- The lock EXPIRES BY ITSELF (it is just a time stamp), so a player can never
-- stay stuck, even if something goes wrong.
local introLockUntil = 0 -- (client only) movement lock for the intro cutscene

hook.Add("StartCommand", "RE_CutsceneLock", function(ply, cmd)
    local untilTime = GetGlobalFloat("RE_CutsceneUntil", 0)
    local locked = untilTime > 0 and CurTime() < untilTime

    if CLIENT and CurTime() < introLockUntil then locked = true end

    if locked then
        cmd:ClearMovement()
        cmd:ClearButtons()
    end
end)

-- =====================================================
-- Q-MENU ENTITIES   (press Q -> "Entities" tab -> "Random Events")
-- =====================================================
local function RegisterFunEntity(class, name, ENT)
    ENT.Type = "anim"
    ENT.Base = "base_anim"
    ENT.PrintName = name
    ENT.Author = "Random Events"
    ENT.Category = "Random Events"
    ENT.Spawnable = true
    ENT.AdminOnly = false

    scripted_ents.Register(ENT, class)

    list.Set("SpawnableEntities", class, {
        PrintName = name,
        ClassName = class,
        Category = "Random Events",
        NormalOffset = 24,
        DropToFloor = true,
        AdminOnly = false,
    })
end

local function InitPhysicsProp(ent, model)
    ent:SetModel(model)
    ent:PhysicsInit(SOLID_VPHYSICS)
    ent:SetMoveType(MOVETYPE_VPHYSICS)
    ent:SetSolid(SOLID_VPHYSICS)
    ent:SetUseType(SIMPLE_USE)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then phys:Wake() end
    return phys
end

-- ---------- 1) Mystery Box: press E, get a random surprise ----------
do
    local ENT = {}

    if SERVER then
        local function SpawnNear(class, pos, spread, model)
            local ent = ents.Create(class)
            if not IsValid(ent) then return nil end

            if model then ent:SetModel(model) end
            ent:SetPos(pos + Vector(math.random(-spread, spread),
                math.random(-spread, spread), math.random(0, 40)))
            ent:SetAngles(Angle(0, math.random(0, 360), 0))
            ent:Spawn()
            ent:Activate()
            return ent
        end

        -- each surprise = { text, function(player, position) [returns extra text] }
        local surprises = {
            { "Heal! +50 health.", function(ply, pos)
                ply:SetHealth(math.min(ply:GetMaxHealth(), ply:Health() + 50))
            end },

            { "Watermelon shower!", function(ply, pos)
                for i = 1, 10 do
                    SpawnNear("prop_physics", pos + Vector(0, 0, 60), 40,
                        "models/props_junk/watermelon01.mdl")
                end
            end },

            { "A zombie appeared! Run!", function(ply, pos)
                SpawnNear("npc_zombie", pos, 90)
            end },

            { "Headcrabs!", function(ply, pos)
                for i = 1, 3 do SpawnNear("npc_headcrab", pos, 90) end
            end },

            { "Super jump!", function(ply, pos)
                ply:SetVelocity(Vector(0, 0, 700))
            end },

            { "Free weapon:", function(ply, pos)
                local w = HL2_WEAPONS[math.random(#HL2_WEAPONS)]
                ply:Give(w.class)
                return w.name .. "!"
            end },

            { "Bouncy watermelon party!", function(ply, pos)
                for i = 1, 4 do
                    SpawnNear("re_bouncy_watermelon", pos + Vector(0, 0, 40), 50)
                end
            end },

            { "It was a BOMB! Run!", function(ply, pos)
                local bomb = SpawnNear("re_watermelon_bomb", pos + Vector(0, 0, 40), 10)
                if IsValid(bomb) then bomb:Use(ply) end
            end },
        }

        function ENT:Initialize()
            InitPhysicsProp(self, "models/props_junk/wood_crate001a.mdl")
            self:SetColor(Color(255, 215, 90))
        end

        function ENT:Use(activator)
            if self.Opened then return end
            if not IsValid(activator) or not activator:IsPlayer() then return end
            self.Opened = true

            local pos = self:GetPos()

            local fx = EffectData()
            fx:SetOrigin(pos)
            util.Effect("ManhackSparks", fx)
            self:EmitSound("physics/wood/wood_box_break1.wav")

            local pick = surprises[math.random(#surprises)]
            local extra = pick[2](activator, pos)
            activator:ChatPrint("Mystery Box: " .. pick[1] .. (extra and (" " .. extra) or ""))

            self:Remove()
        end
    end

    RegisterFunEntity("re_mystery_box", "Mystery Box", ENT)
end

-- ---------- 2) Bouncy Watermelon: bounces everywhere, press E to launch it ----------
do
    local ENT = {}

    if SERVER then
        function ENT:Initialize()
            local phys = InitPhysicsProp(self, "models/props_junk/watermelon01.mdl")
            if IsValid(phys) then phys:SetMaterial("gmod_bouncy") end
        end

        function ENT:Use(activator)
            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(Vector(math.random(-250, 250), math.random(-250, 250), 600))
            end
        end
    end

    RegisterFunEntity("re_bouncy_watermelon", "Bouncy Watermelon", ENT)
end

-- ---------- 3) Watermelon Bomb: press E, it explodes in 3 seconds ----------
do
    local ENT = {}

    if SERVER then
        local chunks = {
            "models/props_junk/watermelon01_chunk01a.mdl",
            "models/props_junk/watermelon01_chunk01b.mdl",
            "models/props_junk/watermelon01_chunk01c.mdl",
        }

        function ENT:Initialize()
            InitPhysicsProp(self, "models/props_junk/watermelon01.mdl")
            self:SetColor(Color(255, 130, 130))
            self.Armed = false
        end

        function ENT:Explode(attacker)
            local pos = self:GetPos()

            local fx = EffectData()
            fx:SetOrigin(pos)
            util.Effect("Explosion", fx, true, true)
            sound.Play("ambient/explosions/explode_4.wav", pos, 100, 100)

            util.BlastDamage(self, IsValid(attacker) and attacker or self, pos, 250, 60)

            -- watermelon pieces fly everywhere
            for i = 1, 6 do
                local piece = ents.Create("prop_physics")
                if IsValid(piece) then
                    piece:SetModel(chunks[math.random(#chunks)])
                    piece:SetPos(pos + Vector(0, 0, 20))
                    piece:Spawn()

                    local phys = piece:GetPhysicsObject()
                    if IsValid(phys) then
                        phys:SetVelocity(VectorRand() * 400 + Vector(0, 0, 250))
                    end

                    SafeRemoveEntityDelayed(piece, 15)
                end
            end

            self:Remove()
        end

        function ENT:Use(activator)
            if self.Armed then return end
            self.Armed = true

            local attacker = IsValid(activator) and activator or self
            local left = 3

            self:SetColor(Color(255, 40, 40))
            self:EmitSound("buttons/blip1.wav")

            timer.Create("RE_Bomb_" .. self:EntIndex(), 1, 3, function()
                if not IsValid(self) then return end

                left = left - 1
                self:EmitSound("buttons/blip1.wav")

                if left <= 0 then self:Explode(attacker) end
            end)
        end
    end

    RegisterFunEntity("re_watermelon_bomb", "Watermelon Bomb", ENT)
end

-- =====================================================
-- SERVER
-- =====================================================
if SERVER then
    util.AddNetworkString("RE_HUD")
    util.AddNetworkString("RE_Admin")
    util.AddNetworkString("RE_WeaponMenu")
    util.AddNetworkString("RE_WeaponPick")
    util.AddNetworkString("RE_Cutscene")

    local eventActive = false
    local spawned = {}        -- everything the current event created
    local savedGravity = nil  -- original gravity (for the Low Gravity event)
    local lastHUD = { active = false, title = "", sub = "" }

    -- weapon selection state
    local selecting = false
    local selectIndex = 0
    local choices = {}        -- [player] = weapon class
    local givenWeapons = {}   -- [player] = { classes the event gave }

    -- allowed weapon classes (so players cannot send random classes)
    local allowedWeapons, weaponNames = {}, {}
    for _, w in ipairs(HL2_WEAPONS) do
        allowedWeapons[w.class] = true
        weaponNames[w.class] = w.name
    end
    for _, class in ipairs(CUSTOM_WEAPONS) do
        allowedWeapons[class] = true
    end

    -- ---------- helpers ----------
    local function SendHUD(active, title, subtitle, target)
        lastHUD = { active = active, title = title or "", sub = subtitle or "" }

        net.Start("RE_HUD")
        net.WriteBool(active)
        net.WriteString(title or "")
        net.WriteString(subtitle or "")
        if target then net.Send(target) else net.Broadcast() end
    end

    -- players who join in the middle of an event still see the text
    hook.Add("PlayerInitialSpawn", "RE_SyncHUD", function(ply)
        timer.Simple(3, function()
            if IsValid(ply) and lastHUD.active then
                net.Start("RE_HUD")
                net.WriteBool(true)
                net.WriteString(lastHUD.title)
                net.WriteString(lastHUD.sub)
                net.Send(ply)
            end
        end)
    end)

    local function StopTimers()
        timer.Remove("RE_Watermelon")
        timer.Remove("RE_HuntCheck")
        timer.Remove("RE_Survive")
        timer.Remove("RE_Scare")
        timer.Remove("RE_PropDrop")
        timer.Remove("RE_WeaponSelect")
        timer.Remove("RE_Cutscene")
    end

    local function Track(ent)
        table.insert(spawned, ent)
    end

    local function RemoveList(list)
        for _, ent in ipairs(list) do
            if IsValid(ent) then ent:Remove() end
        end
    end

    -- ---------- players ----------
    local function AlivePlayers()
        local list = {}
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and p:Alive() and p:Team() ~= TEAM_SPECTATOR then
                table.insert(list, p)
            end
        end
        return list
    end

    local function RandomAlivePlayer()
        local list = AlivePlayers()
        if #list == 0 then return nil end
        return list[math.random(#list)]
    end

    local function UnfreezeAll()
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) then p:Freeze(false) end
        end
    end

    -- ---------- cutscene messages ----------
    -- action: 0 = stop cutscene + music, 1 = start cutscene, 2 = fade the music out
    local function SendCutsceneMsg(action, index, trackIdx)
        net.Start("RE_Cutscene")
        net.WriteUInt(action, 2)
        if action == 1 then
            net.WriteUInt(index, 4)
            net.WriteUInt(trackIdx or 0, 6)
            net.WriteUInt(CUTSCENE_TIME, 6)
        end
        net.Broadcast()
    end

    -- ---------- weapon menu ----------
    local function CloseWeaponMenus()
        net.Start("RE_WeaponMenu")
        net.WriteBool(false)
        net.WriteUInt(0, 8)
        net.Broadcast()
    end

    local function CancelSelection()
        if selecting then
            selecting = false
            choices = {}
            CloseWeaponMenus()
        end
    end

    local function GiveEventWeapon(ply, class)
        if not IsValid(ply) or not ply:Alive() then return end

        local had = ply:HasWeapon(class)
        local wep = ply:Give(class)
        if not IsValid(wep) then wep = ply:GetWeapon(class) end

        if not IsValid(wep) then
            ply:ChatPrint("Could not give the weapon '" .. class .. "'. Check the class name!")
            return
        end

        -- remember it so we can take it back after the event
        if not had then
            givenWeapons[ply] = givenWeapons[ply] or {}
            table.insert(givenWeapons[ply], class)
        end

        -- ammo
        local primary = wep:GetPrimaryAmmoType()
        if primary and primary >= 0 then
            local clip = wep:GetMaxClip1()
            local amount = (clip and clip > 0) and (clip * 6) or 10
            ply:GiveAmmo(amount, primary, true)
        end

        local secondary = wep:GetSecondaryAmmoType()
        if secondary and secondary >= 0 then
            ply:GiveAmmo(3, secondary, true)
        end

        ply:SelectWeapon(class)
    end

    -- Ends the event, shows an optional message, and cleans up everything.
    -- instant = true -> clean immediately (no delay)
    local function EndEvent(title, subtitle, instant)
        StopTimers()
        eventActive = false
        CancelSelection()
        SetGlobalFloat("RE_CutsceneUntil", 0)
        UnfreezeAll()
        SendCutsceneMsg(0)

        -- restore gravity if the Low Gravity event changed it
        if savedGravity then
            RunConsoleCommand("sv_gravity", tostring(savedGravity))
            savedGravity = nil
        end

        -- cleanup (lists are copied, so a new event can start safely)
        local list = spawned
        spawned = {}
        local weaponsGiven = givenWeapons
        givenWeapons = {}

        local function DoCleanup()
            -- take back the weapons the event gave
            for ply, classes in pairs(weaponsGiven) do
                if IsValid(ply) then
                    for _, class in ipairs(classes) do
                        ply:StripWeapon(class)
                    end
                end
            end

            if CLEAN_WHOLE_MAP and not eventActive then
                game.CleanUpMap()
            else
                RemoveList(list)
            end
        end

        if instant then
            DoCleanup()
        else
            timer.Simple(CLEANUP_DELAY, DoCleanup)
        end

        -- message on screen
        if title then
            SendHUD(true, title, subtitle)
            timer.Create("RE_HideHUD", 5, 1, function()
                SendHUD(false)
            end)
        else
            SendHUD(false)
        end
    end

    -- ---------- positions ----------
    -- A free spot on the ground around a player.
    -- yaw (optional) = fixed direction, otherwise random direction.
    local function FindSpawnPos(ply, minDist, maxDist, yaw)
        for i = 1, 15 do
            local ang = yaw or math.Rand(0, 360)
            local dist = math.Rand(minDist, maxDist)
            local dir = Angle(0, ang, 0):Forward()
            local start = ply:GetPos() + Vector(0, 0, 50)
            local target = start + dir * dist

            -- no wall between the player and the spot
            local wall = util.TraceLine({
                start = start,
                endpos = target,
                mask = MASK_SOLID_BRUSHONLY
            })

            if not wall.Hit then
                local down = util.TraceLine({
                    start = target,
                    endpos = target - Vector(0, 0, 300),
                    mask = MASK_SOLID_BRUSHONLY
                })
                if down.Hit and not down.StartSolid then
                    return down.HitPos + Vector(0, 0, 10)
                end
            end
        end
        return nil
    end

    -- A random ground spot ANYWHERE on the map (not tied to a player).
    local function RandomMapGroundPos()
        local ok, mins, maxs = pcall(function()
            return game.GetWorld():GetModelBounds()
        end)

        if not ok or not mins or not maxs or mins:Distance(maxs) < 100 then
            mins = Vector(-4096, -4096, -4096)
            maxs = Vector(4096, 4096, 4096)
        end

        local ref = RandomAlivePlayer()
        local baseZ = ref and ref:GetPos().z or 0

        for i = 1, 25 do
            local pos = Vector(math.Rand(mins.x, maxs.x), math.Rand(mins.y, maxs.y), baseZ + 50)

            if util.IsInWorld(pos) then
                local down = util.TraceLine({
                    start = pos,
                    endpos = pos - Vector(0, 0, 300),
                    mask = MASK_SOLID_BRUSHONLY
                })
                if down.Hit and not down.StartSolid then
                    return down.HitPos + Vector(0, 0, 10)
                end
            end
        end
        return nil
    end

    -- A point just under the ceiling/sky above a ground spot (props fall from here).
    local function CeilingDropPos(ground)
        local start = ground + Vector(0, 0, 10)
        local tr = util.TraceLine({
            start = start,
            endpos = start + Vector(0, 0, 1000),
            mask = MASK_SOLID_BRUSHONLY
        })
        if tr.StartSolid then return nil end
        if tr.HitPos.z - start.z < 80 then return nil end -- ceiling too low
        return tr.HitPos - Vector(0, 0, 40)
    end

    -- ---------- spawning ----------
    local function SpawnNPC(class, pos)
        local npc = ents.Create(class)
        if not IsValid(npc) then return nil end

        npc:SetPos(pos)
        npc:SetAngles(Angle(0, math.random(0, 360), 0))
        if class == "npc_combine_s" then
            npc:SetKeyValue("additionalequipment", "weapon_smg1")
        end
        npc:Spawn()
        npc:Activate()

        -- hate every player
        for _, p in ipairs(player.GetAll()) do
            npc:AddEntityRelationship(p, D_HT, 99)
        end

        Track(npc)
        return npc
    end

    local function SpawnProp(model, pos)
        local prop = ents.Create("prop_physics")
        if not IsValid(prop) then return nil end

        prop:SetModel(model)
        prop:SetPos(pos)
        prop:SetAngles(AngleRand())
        prop:Spawn()

        Track(prop)
        return prop
    end

    -- ---------- shared event logic ----------
    -- Countdown that ends with a win. If every player is dead, the event is lost.
    -- extra (optional) = function returning extra text for the HUD
    local function StartCountdown(seconds, title, extra)
        local timeLeft = seconds

        local function Show()
            local sub = "Time left: " .. timeLeft
            if extra then sub = sub .. "   |   " .. extra() end
            SendHUD(true, title, sub)
        end

        Show()

        timer.Create("RE_Survive", 1, 0, function()
            if #AlivePlayers() == 0 then
                EndEvent("EVERYONE DIED", "Nobody survived...")
                return
            end

            timeLeft = timeLeft - 1

            if timeLeft <= 0 then
                EndEvent("YOU SURVIVED!", "Well done!")
                return
            end

            Show()
        end)
    end

    -- "Kill all the X" event (zombies, headcrabs...)
    local function StartHuntEvent(cfg)
        local list = {}
        local attempts = 0

        while #list < cfg.count and attempts < 100 do
            attempts = attempts + 1
            local target = RandomAlivePlayer()
            if not target then break end

            local pos = FindSpawnPos(target, cfg.minDist, cfg.maxDist)
            if pos then
                local npc = SpawnNPC(cfg.class, pos)
                if npc then table.insert(list, npc) end
            end
        end

        if #list == 0 then
            EndEvent(cfg.title, "Could not find a place to spawn.")
            return
        end

        SendHUD(true, cfg.title, cfg.label .. #list)
        local lastLeft = #list

        timer.Create("RE_HuntCheck", 0.5, 0, function()
            if #AlivePlayers() == 0 then
                EndEvent("EVERYONE DIED", cfg.deathText)
                return
            end

            local left = 0
            for _, npc in ipairs(list) do
                if IsValid(npc) and npc:Health() > 0 then left = left + 1 end
            end

            if left == 0 then
                EndEvent(cfg.title, cfg.winText)
                return
            end

            if left ~= lastLeft then
                lastLeft = left
                SendHUD(true, cfg.title, cfg.label .. left)
            end
        end)
    end

    -- ---------- EVENT 1: Watermelons ----------
    local function StartWatermelonEvent()
        local count = 0

        local function SpawnOne()
            local target = RandomAlivePlayer()
            if not target then return end

            local pos = FindSpawnPos(target, 100, 400)
            if not pos then return end

            SpawnProp("models/props_junk/watermelon01.mdl", pos + Vector(0, 0, 40))

            count = count + 1
            SendHUD(true, "WATERMELON EVENT",
                "Watermelons spawned: " .. count .. " / " .. MAX_WATERMELONS)
        end

        SendHUD(true, "WATERMELON EVENT", "Watermelons spawned: 0 / " .. MAX_WATERMELONS)
        SpawnOne() -- the first one right away

        timer.Create("RE_Watermelon", WATERMELON_INTERVAL, 0, function()
            if #player.GetAll() == 0 then EndEvent(nil, nil, true) return end

            SpawnOne()

            if count >= MAX_WATERMELONS then
                EndEvent("WATERMELON EVENT",
                    "Limit reached: " .. MAX_WATERMELONS .. " watermelons!")
            end
        end)
    end

    -- ---------- EVENT 2: Zombies ----------
    local function StartZombieEvent()
        StartHuntEvent({
            class = "npc_zombie",
            count = ZOMBIE_COUNT,
            minDist = 500, maxDist = 1500,
            title = "KILL ALL THE ZOMBIES!",
            label = "Zombies left: ",
            winText = "All zombies are dead! You win!",
            deathText = "The zombies got you...",
        })
    end

    -- ---------- EVENT 3: Kill Everyone ----------
    local function StartKillEveryoneEvent()
        StartCountdown(SURVIVE_TIME, "SURVIVE FOR ONE MINUTE!")

        -- jumpscares: for EACH alive player a zombie or combine appears
        -- in front of or behind them
        timer.Create("RE_Scare", SCARE_INTERVAL, 0, function()
            for _, ply in ipairs(AlivePlayers()) do
                local eyeYaw = ply:EyeAngles().yaw
                local behind = math.random(0, 1) == 1
                local yaw = eyeYaw + (behind and 180 or 0) + math.random(-20, 20)

                local pos = FindSpawnPos(ply, 150, 250, yaw)
                if pos then
                    if math.random(0, 1) == 0 then
                        SpawnNPC("npc_zombie", pos)
                        ply:EmitSound("npc/zombie/zombie_alert.wav")
                    else
                        SpawnNPC("npc_combine_s", pos)
                        ply:EmitSound("npc/combine_soldier/vo/contactconfirmprosecuting.wav")
                    end
                end
            end
        end)
    end

    -- ---------- EVENT 4: Prop Rain ----------
    local function StartPropRainEvent()
        local models = {
            "models/props_c17/oildrum001.mdl",
            "models/props_junk/wood_crate001a.mdl",
            "models/props_junk/cinderblock01a.mdl",
            "models/props_c17/FurnitureChair001a.mdl",
        }
        local dropped = 0

        StartCountdown(PROP_RAIN_TIME, "PROP RAIN - DODGE!", function()
            return "Props dropped: " .. dropped
        end)

        timer.Create("RE_PropDrop", PROP_RAIN_INTERVAL, 0, function()
            for i = 1, PROPS_PER_DROP do
                local ground

                if math.Rand(0, 1) < PROP_RAIN_NEAR_CHANCE then
                    -- near (but never right above) a random player
                    local target = RandomAlivePlayer()
                    if target then ground = FindSpawnPos(target, 400, 1500) end
                else
                    -- anywhere on the map
                    ground = RandomMapGroundPos()
                end

                if ground then
                    local pos = CeilingDropPos(ground)
                    if pos then
                        local prop = SpawnProp(models[math.random(#models)], pos)
                        if prop then dropped = dropped + 1 end
                    end
                end
            end
        end)
    end

    -- ---------- EVENT 5: Headcrab Swarm ----------
    local function StartHeadcrabEvent()
        StartHuntEvent({
            class = "npc_headcrab",
            count = HEADCRAB_COUNT,
            minDist = 300, maxDist = 1200,
            title = "KILL ALL THE HEADCRABS!",
            label = "Headcrabs left: ",
            winText = "All headcrabs are dead! You win!",
            deathText = "The headcrabs got you...",
        })
    end

    -- ---------- EVENT 6: Low Gravity ----------
    local function StartLowGravityEvent()
        local cvar = GetConVar("sv_gravity")
        savedGravity = cvar and cvar:GetFloat() or 600
        RunConsoleCommand("sv_gravity", tostring(LOW_GRAVITY_VALUE))

        local models = {
            "models/props_c17/oildrum001.mdl",
            "models/props_junk/wood_crate001a.mdl",
            "models/props_c17/FurnitureChair001a.mdl",
        }

        -- floating props around random players
        for i = 1, 20 do
            local target = RandomAlivePlayer()
            if target then
                local pos = FindSpawnPos(target, 150, 600)
                if pos then
                    local prop = SpawnProp(models[math.random(#models)], pos + Vector(0, 0, 30))
                    if prop then
                        local phys = prop:GetPhysicsObject()
                        if IsValid(phys) then
                            phys:Wake()
                            phys:SetVelocity(Vector(0, 0, math.random(100, 300)))
                        end
                    end
                end
            end
        end

        -- a few zombies so there is something to survive
        for i = 1, 6 do
            local target = RandomAlivePlayer()
            if target then
                local pos = FindSpawnPos(target, 400, 900)
                if pos then SpawnNPC("npc_zombie", pos) end
            end
        end

        StartCountdown(LOW_GRAVITY_TIME, "LOW GRAVITY - SURVIVE!")
    end

    -- ---------- list of events ----------
    local events = {
        StartWatermelonEvent,   -- 1
        StartZombieEvent,       -- 2
        StartKillEveryoneEvent, -- 3
        StartPropRainEvent,     -- 4
        StartHeadcrabEvent,     -- 5
        StartLowGravityEvent,   -- 6
    }

    local names = {
        watermelon = 1, melon = 1,
        zombie = 2, zombies = 2,
        kill = 3, killeveryone = 3,
        prop = 4, props = 4, proprain = 4,
        headcrab = 5, headcrabs = 5,
        gravity = 6, lowgravity = 6,
    }

    -- The round really begins here (after the cutscene and the weapon menu).
    local function StartRound(index)
        if not MUSIC_PLAYS_DURING_EVENT then
            SendCutsceneMsg(2) -- fade the music out
        end
        events[index]()
    end

    -- ---------- weapon selection before the round ----------
    local function AllChosen()
        local all = player.GetAll()
        if #all == 0 then return false end
        for _, p in ipairs(all) do
            if not choices[p] then return false end
        end
        return true
    end

    local function FinishSelection()
        if not selecting then return end
        selecting = false
        timer.Remove("RE_WeaponSelect")
        CloseWeaponMenus()

        for _, p in ipairs(player.GetAll()) do
            GiveEventWeapon(p, choices[p] or DEFAULT_WEAPON)
        end
        choices = {}

        StartRound(selectIndex) -- NOW the real event starts
    end

    local function StartWeaponSelection(index)
        selecting = true
        selectIndex = index
        choices = {}

        local timeLeft = WEAPON_SELECT_TIME

        net.Start("RE_WeaponMenu")
        net.WriteBool(true)
        net.WriteUInt(timeLeft, 8)
        net.Broadcast()

        SendHUD(true, "GET READY!", "Choose your weapon!   Round starts in: " .. timeLeft)

        timer.Create("RE_WeaponSelect", 1, 0, function()
            timeLeft = timeLeft - 1

            if timeLeft <= 0 then
                FinishSelection()
                return
            end

            SendHUD(true, "GET READY!", "Choose your weapon!   Round starts in: " .. timeLeft)
        end)
    end

    net.Receive("RE_WeaponPick", function(len, ply)
        if not selecting then return end

        local class = net.ReadString()
        if not allowedWeapons[class] then return end

        choices[ply] = class
        ply:ChatPrint("You chose: " .. (weaponNames[class] or class))

        if AllChosen() then FinishSelection() end
    end)

    -- after the cutscene: weapon menu (if the event uses it) or straight to the round
    local function BeginEvent(index)
        if WEAPON_EVENTS[index] then
            StartWeaponSelection(index)
        else
            StartRound(index)
        end
    end

    -- ---------- cutscene ----------
    local function StartCutscene(index)
        local pool = GetMusicPool()
        local track = 0
        if MUSIC_ENABLED and #pool > 0 then
            track = math.random(#pool) -- same track for every player
        end

        -- nobody can move or shoot while the camera is busy.
        -- (no hard Freeze anymore - this lock expires by itself)
        SetGlobalFloat("RE_CutsceneUntil", CurTime() + CUTSCENE_TIME)

        SendCutsceneMsg(1, index, track)

        timer.Create("RE_Cutscene", CUTSCENE_TIME, 1, function()
            SetGlobalFloat("RE_CutsceneUntil", 0)
            UnfreezeAll()
            BeginEvent(index)
        end)
    end

    -- ---------- starting / stopping ----------
    -- permission for random_event / random_event_stop
    local function CanUse(ply)
        return IsValid(ply) and (game.SinglePlayer() or ply:IsAdmin())
    end

    -- launches an event (permission must be checked before calling)
    local function LaunchEvent(caller, index)
        if eventActive then
            caller:ChatPrint("An event is already running! Stop it first (random_event_stop).")
            return
        end

        if not events[index] then index = math.random(1, #events) end

        timer.Remove("RE_HideHUD")
        SendHUD(false)
        spawned = {}
        givenWeapons = {}
        eventActive = true

        if CUTSCENE_ENABLED then
            StartCutscene(index)
        else
            BeginEvent(index)
        end
    end

    local function StopEvent(ply)
        if not eventActive then
            if IsValid(ply) then ply:ChatPrint("No event is running.") end
            return
        end
        EndEvent(nil, nil, true)
        if IsValid(ply) then ply:ChatPrint("Event stopped.") end
    end

    local function RunEvent(ply, arg)
        if not IsValid(ply) then return end

        if not CanUse(ply) then
            ply:ChatPrint("Only admins can start events.")
            return
        end

        arg = string.lower(arg or "")
        LaunchEvent(ply, tonumber(arg) or names[arg])
    end

    -- console commands
    concommand.Add("random_event", function(ply, cmd, args)
        RunEvent(ply, args[1])
    end)

    concommand.Add("random_event_stop", function(ply)
        if not CanUse(ply) then return end
        StopEvent(ply)
    end)

    -- admin panel requests (HOST ONLY)
    net.Receive("RE_Admin", function(len, ply)
        local action = net.ReadUInt(4)

        if not IsHost(ply) then
            ply:ChatPrint("Only the host can use the admin panel.")
            return
        end

        if action == 0 then
            StopEvent(ply)
        elseif action == RANDOM_ACTION then
            LaunchEvent(ply, math.random(1, #events))
        elseif events[action] then
            LaunchEvent(ply, action)
        end
    end)

    -- chat commands: /randomevent, /random event, !randomevent, /randomevent 2,
    -- /stopevent, /theadminpanel
    hook.Add("PlayerSay", "RE_ChatCommands", function(ply, text)
        local lower = string.lower(string.Trim(text))

        if lower == "/theadminpanel" or lower == "!theadminpanel" then
            ply:ConCommand("theadminpanel")
            return ""
        end

        -- emergency unstuck: /fix
        if lower == "/fix" or lower == "!fix" then
            SetGlobalFloat("RE_CutsceneUntil", 0)
            ply:Freeze(false)
            ply:ConCommand("re_fix")
            return ""
        end

        if lower == "/stopevent" or lower == "!stopevent" then
            if CanUse(ply) then StopEvent(ply) end
            return ""
        end

        local arg = string.match(lower, "^[/!]random[_ ]?event%s*(%S*)$")
        if arg then
            RunEvent(ply, arg)
            return ""
        end
    end)

    print("[RandomEvents] Loaded on server!")
end

-- =====================================================
-- CLIENT (text on screen, cutscene, menus)
-- =====================================================
if CLIENT then
    surface.CreateFont("RE_Title", {
        font = "Trebuchet MS", size = 52, weight = 900, antialias = true
    })
    surface.CreateFont("RE_Sub", {
        font = "Trebuchet MS", size = 34, weight = 700, antialias = true
    })
    surface.CreateFont("RE_PanelTitle", {
        font = "Trebuchet MS", size = 30, weight = 900, antialias = true
    })
    surface.CreateFont("RE_PanelBtn", {
        font = "Trebuchet MS", size = 24, weight = 800, antialias = true
    })
    surface.CreateFont("RE_PanelSmall", {
        font = "Trebuchet MS", size = 16, weight = 600, antialias = true
    })
    surface.CreateFont("RE_CutBig", {
        font = "Trebuchet MS", size = 110, weight = 900, antialias = true
    })
    surface.CreateFont("RE_CutSmall", {
        font = "Trebuchet MS", size = 36, weight = 700, antialias = true
    })
    surface.CreateFont("RE_CutMid", {
        font = "Trebuchet MS", size = 72, weight = 900, antialias = true
    })
    surface.CreateFont("RE_EscTitle", {
        font = "Trebuchet MS", size = 64, weight = 900, antialias = true
    })
    surface.CreateFont("RE_HudBig", {
        font = "Trebuchet MS", size = 52, weight = 900, antialias = true
    })
    surface.CreateFont("RE_HudMid", {
        font = "Trebuchet MS", size = 28, weight = 800, antialias = true
    })
    surface.CreateFont("RE_KillText", {
        font = "Trebuchet MS", size = 20, weight = 700, antialias = true
    })

    CreateClientConVar("re_music_volume", "0.8", true, false,
        "Volume of the event music (0 to 1)")

    -- colours of all our menus (dark gray with a little green)
    local THEME = {
        back    = Color(24, 28, 26, 250),
        panel   = Color(32, 38, 35, 245),
        header  = Color(36, 52, 42, 255),
        button  = Color(40, 50, 44, 255),
        hover   = Color(56, 78, 64, 255),
        down    = Color(70, 125, 88, 255),
        border  = Color(70, 105, 80, 255),
        accent  = Color(110, 210, 135, 255),
        text    = Color(215, 232, 220, 255),
        textDim = Color(150, 170, 156, 255),
    }

    local cutscene = nil -- the cutscene that is playing right now (or nil)
    local music = nil    -- the music that is playing right now (or nil)

    local function Ease(x)
        x = math.Clamp(x, 0, 1)
        return x * x * (3 - 2 * x)
    end

    -- ---------- text on screen ----------
    local hud = { active = false, title = "", sub = "" }

    net.Receive("RE_HUD", function()
        hud.active = net.ReadBool()
        hud.title = net.ReadString()
        hud.sub = net.ReadString()
    end)

    hook.Add("HUDPaint", "RE_HUD", function()
        if not hud.active or cutscene then return end

        local x = ScrW() / 2
        local y = ScrH() * 0.08

        draw.SimpleTextOutlined(hud.title, "RE_Title", x, y,
            Color(255, 60, 60), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0))

        draw.SimpleTextOutlined(hud.sub, "RE_Sub", x, y + 60,
            Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, Color(0, 0, 0))
    end)

    -- ---------- music ----------
    local function StopMusic(fade)
        if music then
            if fade and fade > 0 then
                music:FadeOut(fade)
            else
                music:Stop()
            end
            music = nil
        end
    end

    -- fadeIn (optional) = seconds for the music to slowly get louder
    local function PlayMusic(path, fadeIn)
        StopMusic()

        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local vol = GetConVar("re_music_volume"):GetFloat()
        music = CreateSound(ply, path)
        if music then
            music:SetSoundLevel(0) -- plays everywhere, not from a point
            if fadeIn and fadeIn > 0 then
                music:PlayEx(0, 100)
                music:ChangeVolume(vol, fadeIn)
            else
                music:PlayEx(vol, 100)
            end
        end
    end

    -- ---------- cinematic cutscene ----------
    local function StartCutscene(index, trackIdx, duration, kind)
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local me = {
            start = CurTime(),
            duration = duration,
            index = index,
            baseYaw = ply:EyeAngles().yaw,
            slamTime = nil,
            kind = kind or "event", -- "event" or "intro"
        }
        cutscene = me

        -- music
        local pool = GetMusicPool()
        if trackIdx > 0 and pool[trackIdx] then
            PlayMusic(pool[trackIdx])
        end

        -- the big hit when the event name appears
        -- (the calm intro has no big hit, no flash and no shake)
        timer.Simple(duration * 0.45, function()
            if cutscene ~= me or me.kind == "intro" then return end
            me.slamTime = CurTime()
            surface.PlaySound("ambient/explosions/explode_4.wav")
            surface.PlaySound("weapons/physcannon/energy_sing_explosion2.wav")
        end)
    end

    net.Receive("RE_Cutscene", function()
        local action = net.ReadUInt(2)

        if action == 1 then
            local index = net.ReadUInt(4)
            local trackIdx = net.ReadUInt(6)
            local duration = net.ReadUInt(6)
            StartCutscene(index, trackIdx, duration)
        elseif action == 2 then
            StopMusic(2) -- round starts: fade out
        else
            cutscene = nil
            StopMusic(0.5)
        end
    end)

    -- the camera: starts wide and high, circles around you, then flies into your eyes
    hook.Add("CalcView", "RE_CutsceneView", function(ply, origin, angles, fov)
        if not cutscene then return end

        local t = (CurTime() - cutscene.start) / cutscene.duration
        if t >= 1 then return end

        local center = ply:GetPos() + Vector(0, 0, 50)
        local e = Ease(t)

        -- the intro is slower: the camera starts very high and far away and
        -- slowly sinks down to you, like a sad memory
        local isIntro = cutscene.kind == "intro"
        local yaw = cutscene.baseYaw + 180 + t * (isIntro and 45 or 90)
        local dist = isIntro and Lerp(e, 650, 160) or Lerp(e, 430, 130)
        local height = isIntro and Lerp(e, 330, 30) or Lerp(e, 200, 25)
        local wanted = center + Angle(0, yaw, 0):Forward() * dist + Vector(0, 0, height)

        -- do not let the camera go through walls
        local tr = util.TraceHull({
            start = center,
            endpos = wanted,
            mins = Vector(-8, -8, -8),
            maxs = Vector(8, 8, 8),
            mask = MASK_SOLID_BRUSHONLY
        })

        local camPos = tr.HitPos
        local camAng = (center - camPos):Angle()

        -- camera shake after the hit
        if cutscene.slamTime then
            local k = math.max(0, 1 - (CurTime() - cutscene.slamTime) * 1.5)
            local power = (cutscene.kind == "intro") and 0.4 or 3
            camAng.p = camAng.p + math.Rand(-1, 1) * k * power
            camAng.y = camAng.y + math.Rand(-1, 1) * k * power
        end
        camAng.r = isIntro and 0 or math.sin(t * 3) * 2

        -- smoothly return to the normal first-person view at the end
        if t > 0.88 then
            local b = Ease((t - 0.88) / 0.12)
            camPos = LerpVector(b, camPos, origin)
            camAng = LerpAngle(b, camAng, angles)
        end

        return {
            origin = camPos,
            angles = camAng,
            fov = Lerp(e, 80, fov),
            drawviewer = t < 0.9
        }
    end)

    hook.Add("ShouldDrawLocalPlayer", "RE_CutsceneDraw", function()
        if cutscene and (CurTime() - cutscene.start) / cutscene.duration < 0.9 then
            return true
        end
    end)

    hook.Add("PreDrawViewModel", "RE_CutsceneHideVM", function()
        if cutscene then return true end
    end)

    hook.Add("HUDShouldDraw", "RE_CutsceneHideHUD", function(name)
        if cutscene and name ~= "CHudGMod" then return false end
    end)

    hook.Add("Think", "RE_CutsceneThink", function()
        if cutscene and CurTime() - cutscene.start > cutscene.duration + 0.1 then
            -- the intro music slowly fades away when the intro ends
            if cutscene.kind == "intro" then StopMusic(3) end
            cutscene = nil
        end
    end)

    -- black bars, fade-in, flash and the big event title
    hook.Add("HUDPaint", "RE_CutscenePaint", function()
        if not cutscene then return end

        local now = CurTime()
        local elapsed = now - cutscene.start
        local t = elapsed / cutscene.duration
        if t >= 1 then return end

        local sw, sh = ScrW(), ScrH()
        local ev = EVENT_LIST[cutscene.index] or
            { name = "Random Event", desc = "", color = Color(255, 60, 60) }

        -- what the cutscene writes on the screen
        local warnText = "RANDOM EVENT INCOMING"
        local bigText, bigFont, bigColor = string.upper(ev.name), "RE_CutBig", ev.color
        local subText = ev.desc

        if cutscene.kind == "intro" then
            local name = IsValid(LocalPlayer()) and LocalPlayer():Nick() or "PLAYER"
            warnText = "WELCOME, " .. string.upper(name)
            bigText = "THANK YOU FOR DOWNLOADING THE MOD"
            bigFont = "RE_CutMid"
            bigColor = Color(120, 230, 150)
            subText = "Random Events  -  have fun!"
        end

        -- cinematic black bars (slide in, slide out)
        local barIn = Ease(elapsed / 0.8)
        local barOut = 1 - Ease((elapsed - (cutscene.duration - 0.8)) / 0.8)
        local barH = sh * 0.13 * barIn * barOut

        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, sw, barH)
        surface.DrawRect(0, sh - barH, sw, barH)

        -- the INTRO is calm: soft text that slowly fades in, no flicker, no flash
        if cutscene.kind == "intro" then
            surface.SetDrawColor(0, 0, 0, 70)
            surface.DrawRect(0, 0, sw, sh)

            local cx, ty = sw / 2, sh * 0.30
            local soft = Color(150, 215, 165)

            -- line 1: welcome (fades in, then out)
            local a1 = Ease((t - 0.08) / 0.10) * (1 - Ease((t - 0.36) / 0.08))
            if a1 > 0 then
                draw.SimpleTextOutlined(warnText, "RE_CutSmall", cx, ty,
                    ColorAlpha(soft, 255 * a1), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                    2, Color(0, 0, 0, 255 * a1))
            end

            -- line 2: the thank-you text fades in slowly and stays
            local a2 = Ease((t - 0.46) / 0.16)
            if a2 > 0 then
                draw.SimpleTextOutlined(bigText, bigFont, cx, ty,
                    ColorAlpha(bigColor, 255 * a2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                    2, Color(0, 0, 0, 255 * a2))
            end

            -- line 3: small text
            local a3 = Ease((t - 0.62) / 0.14)
            if a3 > 0 then
                draw.SimpleTextOutlined(subText, "RE_CutSmall", cx, ty + 70,
                    Color(220, 235, 225, 255 * a3), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                    2, Color(0, 0, 0, 255 * a3))
            end

            -- very slow fade in from black at the start
            if elapsed < 1.6 then
                surface.SetDrawColor(0, 0, 0, 255 * (1 - Ease(elapsed / 1.6)))
                surface.DrawRect(0, 0, sw, sh)
            end

            return
        end

        -- part 1: flickering warning
        if t > 0.08 and t < 0.45 then
            local alpha = math.min(255, (t - 0.08) * 2500)
            if math.floor(elapsed * 12) % 7 == 0 then alpha = alpha * 0.4 end

            draw.SimpleTextOutlined(warnText, "RE_CutSmall",
                sw / 2, sh * 0.80, Color(255, 255, 255, alpha),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, alpha))
        end

        -- part 2: the event name slams onto the screen
        local st = cutscene.slamTime
        if st then
            local since = now - st
            local scale = Lerp(Ease(since / 0.35), 2.2, 1)
            local alpha = math.min(255, since * 700)
            local cx, cy = sw / 2, sh * 0.28

            local m = Matrix()
            m:Translate(Vector(cx, cy, 0))
            m:Scale(Vector(scale, scale, 1))
            m:Translate(Vector(-cx, -cy, 0))

            -- pcall: even if drawing fails, the matrix is ALWAYS popped,
            -- so the rest of the screen can never get broken
            cam.PushModelMatrix(m)
            pcall(draw.SimpleTextOutlined, bigText, bigFont, cx, cy,
                ColorAlpha(bigColor, alpha), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                3, Color(0, 0, 0, alpha))
            cam.PopModelMatrix()

            if since > 0.5 then
                local a2 = math.min(255, (since - 0.5) * 400)
                draw.SimpleTextOutlined(subText, "RE_CutSmall", cx, cy + 85,
                    Color(255, 255, 255, a2), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER,
                    2, Color(0, 0, 0, a2))
            end

            -- white flash on impact
            local flash = (cutscene.kind == "intro") and 0
                or 255 * math.max(0, 1 - since * 4)
            if flash > 0 then
                surface.SetDrawColor(255, 255, 255, flash)
                surface.DrawRect(0, 0, sw, sh)
            end
        end

        -- fade in from black at the very start
        if elapsed < 0.8 then
            surface.SetDrawColor(0, 0, 0, 255 * (1 - Ease(elapsed / 0.8)))
            surface.DrawRect(0, 0, sw, sh)
        end
    end)

    -- ---------- button helper ----------
    local function DimColor(c, k)
        return Color(c.r * k, c.g * k, c.b * k, 255)
    end

    local function MakeButton(parent, x, y, w, h, color, title, desc, onClick)
        local btn = vgui.Create("DButton", parent)
        btn:SetText("")
        btn:SetPos(x, y)
        btn:SetSize(w, h)

        -- dark green button with a coloured stripe on the left
        -- (title can be text or a function that returns text)
        btn.Paint = function(self, bw, bh)
            local bg = THEME.button
            if self.Depressed then
                bg = THEME.down
            elseif self:IsHovered() then
                bg = THEME.hover
            end

            draw.RoundedBox(6, 0, 0, bw, bh, bg)
            surface.SetDrawColor(THEME.border)
            surface.DrawOutlinedRect(0, 0, bw, bh)
            draw.RoundedBoxEx(6, 0, 0, 6, bh, color, true, false, true, false)

            local titleText = isfunction(title) and title() or title
            draw.SimpleText(titleText, "RE_PanelBtn", 20, desc and 26 or bh / 2,
                THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            if desc then
                draw.SimpleText(desc, "RE_PanelSmall", 20, 54,
                    THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
        end

        btn.DoClick = onClick
        return btn
    end

    -- ---------- menu animations ----------
    -- opening: the panel fades in and slides up
    local function AnimateOpen(pnl, slide)
        if not IsValid(pnl) then return end
        slide = slide or 40

        local x, y = pnl:GetPos()
        pnl:SetAlpha(0)
        pnl:SetPos(x, y + slide)
        pnl:AlphaTo(255, 0.25, 0)
        pnl:MoveTo(x, y, 0.3, 0, 0.35)
    end

    -- closing: the panel fades out (and sinks a little), then it is removed
    local function CloseAnimated(pnl, noMove)
        if not IsValid(pnl) or pnl.Closing then return end
        pnl.Closing = true

        if not noMove then
            local x, y = pnl:GetPos()
            pnl:MoveTo(x, y + 20, 0.15, 0, 1)
        end

        pnl:AlphaTo(0, 0.15, 0, function(_, p)
            if IsValid(p) then p:Remove() end
        end)
    end

    -- buttons fly in one after another
    local function StaggerIn(buttons, step, slide)
        step = step or 0.05
        slide = slide or 60

        for i, btn in ipairs(buttons) do
            if IsValid(btn) then
                local x, y = btn:GetPos()
                local delay = 0.1 + (i - 1) * step

                btn:SetAlpha(0)
                btn:SetPos(x - slide, y)
                btn:AlphaTo(255, 0.3, delay)
                btn:MoveTo(x, y, 0.35, delay, 0.35)
            end
        end
    end

    -- ---------- weapon menu (before the round) ----------
    local weaponPanel

    local function OpenWeaponMenu(seconds)
        if IsValid(weaponPanel) then weaponPanel:Remove() end

        local endTime = CurTime() + seconds
        local tab = "hl2"

        weaponPanel = vgui.Create("DFrame")
        weaponPanel:SetSize(620, 450)
        weaponPanel:Center()
        weaponPanel:SetTitle("")
        weaponPanel:ShowCloseButton(false)
        weaponPanel:MakePopup()
        -- mouse only! If the menu grabs the keyboard, held keys can get stuck.
        weaponPanel:SetKeyboardInputEnabled(false)

        weaponPanel.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, THEME.back)
            draw.RoundedBoxEx(10, 0, 0, w, 50, THEME.header, true, true, false, false)
            surface.SetDrawColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, 140)
            surface.DrawRect(0, 50, w, 2)
            surface.SetDrawColor(THEME.border)
            surface.DrawOutlinedRect(0, 0, w, h)
            draw.SimpleText("CHOOSE YOUR WEAPON", "RE_PanelTitle", 16, 25,
                color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            local left = math.max(0, math.ceil(endTime - CurTime()))
            draw.SimpleText("Round starts in: " .. left, "RE_PanelBtn", w - 56, 25,
                color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

            draw.SimpleText("No choice = default weapon.  Use X to close this menu.",
                "RE_PanelSmall", w / 2, h - 14,
                Color(255, 255, 255, 120), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- close button
        local wclose = vgui.Create("DButton", weaponPanel)
        wclose:SetText("")
        wclose:SetPos(620 - 42, 10)
        wclose:SetSize(30, 30)
        wclose.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(255, 255, 255, 60) or Color(0, 0, 0, 60))
            draw.SimpleText("X", "RE_PanelBtn", w / 2, h / 2, color_white,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        wclose.DoClick = function()
            if IsValid(weaponPanel) then weaponPanel:Remove() end
        end

        -- list with the weapon buttons
        local list = vgui.Create("DScrollPanel", weaponPanel)
        list:SetPos(15, 112)
        list:SetSize(590, 300)

        local function Pick(class)
            net.Start("RE_WeaponPick")
            net.WriteString(class)
            net.SendToServer()
            surface.PlaySound("buttons/button14.wav")
            if IsValid(weaponPanel) then weaponPanel:Remove() end
        end

        local function Build()
            list:Clear()
            local canvas = list:GetCanvas()

            if tab == "hl2" then
                for i, wep in ipairs(HL2_WEAPONS) do
                    local col = (i - 1) % 3
                    local row = math.floor((i - 1) / 3)
                    MakeButton(canvas, col * 195, row * 66, 185, 56,
                        Color(60, 130, 210), wep.name, nil, function() Pick(wep.class) end)
                end
            elseif #CUSTOM_WEAPONS == 0 then
                local hint = vgui.Create("DPanel", canvas)
                hint:SetPos(0, 0)
                hint:SetSize(565, 230)
                hint.Paint = function(self, w, h)
                    draw.RoundedBox(8, 0, 0, w, h, Color(0, 0, 0, 90))
                    local lines = {
                        "No custom weapons yet.",
                        "",
                        "1. Open random_events.lua in VS Code",
                        "2. Find CUSTOM_WEAPONS near the top of the file",
                        "3. Add weapon class names, for example:  \"weapon_mp5\",",
                        "4. Save the file and reload the map",
                        "",
                        "Class name: spawn menu (Q) > Weapons > right click > Copy to clipboard",
                    }
                    for i, line in ipairs(lines) do
                        draw.SimpleText(line, "RE_PanelSmall", 16, 20 + (i - 1) * 24,
                            Color(255, 255, 255, 220), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end
                end
            else
                for i, class in ipairs(CUSTOM_WEAPONS) do
                    local col = (i - 1) % 3
                    local row = math.floor((i - 1) / 3)
                    MakeButton(canvas, col * 195, row * 66, 185, 56,
                        Color(200, 120, 40), class, nil, function() Pick(class) end)
                end
            end
        end

        -- tabs: Half-Life 2 / Custom
        local function MakeTab(x, label, id)
            local btn = vgui.Create("DButton", weaponPanel)
            btn:SetText("")
            btn:SetPos(x, 62)
            btn:SetSize(290, 38)
            btn.Paint = function(self, w, h)
                local active = (tab == id)
                local bg = active and THEME.down or
                    (self:IsHovered() and THEME.hover or THEME.button)
                draw.RoundedBox(6, 0, 0, w, h, bg)
                draw.SimpleText(label, "RE_PanelBtn", w / 2, h / 2,
                    color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            btn.DoClick = function()
                tab = id
                Build()
            end
        end

        MakeTab(15, "Half-Life 2", "hl2")
        MakeTab(315, "Custom", "custom")

        Build()

        AnimateOpen(weaponPanel, 40)
    end

    net.Receive("RE_WeaponMenu", function()
        local open = net.ReadBool()
        local seconds = net.ReadUInt(8)

        if IsValid(weaponPanel) then weaponPanel:Remove() end
        if open then OpenWeaponMenu(seconds) end
    end)

    -- ---------- admin panel ----------
    local panel

    local function SendAction(action)
        net.Start("RE_Admin")
        net.WriteUInt(action, 4)
        net.SendToServer()
        surface.PlaySound("buttons/button14.wav")
    end

    local function OpenAdminPanel()
        -- same command again = close the panel
        if IsValid(panel) then CloseAnimated(panel) return end

        if not IsHost(LocalPlayer()) then
            chat.AddText(Color(255, 80, 80), "[Admin Panel] ",
                Color(255, 255, 255), "Only the host can use this panel.")
            return
        end

        panel = vgui.Create("DFrame")
        panel:SetSize(560, 470)
        panel:Center()
        panel:SetTitle("")
        panel:ShowCloseButton(false)
        panel:SetDraggable(true)
        panel:MakePopup()
        -- mouse only! If the menu grabs the keyboard, held keys can get stuck.
        panel:SetKeyboardInputEnabled(false)

        panel.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, THEME.back)
            draw.RoundedBoxEx(10, 0, 0, w, 50, THEME.header, true, true, false, false)
            surface.SetDrawColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, 140)
            surface.DrawRect(0, 50, w, 2)
            surface.SetDrawColor(THEME.border)
            surface.DrawOutlinedRect(0, 0, w, h)
            draw.SimpleText("ADMIN PANEL", "RE_PanelTitle", 16, 25,
                color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Host only  -  choose an event", "RE_PanelSmall", w - 60, 25,
                Color(255, 255, 255, 220), TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Tip: bind a key in the console:  bind o theadminpanel",
                "RE_PanelSmall", w / 2, h - 18,
                Color(255, 255, 255, 130), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        -- (the panel closes with the X button, it does not use the keyboard)

        -- close button
        local close = vgui.Create("DButton", panel)
        close:SetText("")
        close:SetPos(560 - 42, 10)
        close:SetSize(30, 30)
        close.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(255, 255, 255, 60) or Color(0, 0, 0, 60))
            draw.SimpleText("X", "RE_PanelBtn", w / 2, h / 2, color_white,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        close.DoClick = function() CloseAnimated(panel) end

        local btns = {}

        -- event buttons (2 columns x 3 rows)
        for i, ev in ipairs(EVENT_LIST) do
            local col = (i - 1) % 2
            local row = math.floor((i - 1) / 2)

            btns[#btns + 1] = MakeButton(panel, 15 + col * 265, 70 + row * 92, 250, 80,
                ev.color, ev.name, ev.desc, function()
                    SendAction(i)
                    CloseAnimated(panel)
                end)
        end

        -- bottom row: random + stop
        btns[#btns + 1] = MakeButton(panel, 15, 358, 250, 56, Color(230, 200, 60), "Random Event", nil, function()
            SendAction(RANDOM_ACTION)
            CloseAnimated(panel)
        end)

        btns[#btns + 1] = MakeButton(panel, 280, 358, 265, 56, Color(200, 50, 50), "Stop Event", nil, function()
            SendAction(0)
        end)

        -- animation: the window slides up and the buttons fly in one by one
        AnimateOpen(panel, 40)
        StaggerIn(btns, 0.045, 50)
    end

    concommand.Add("theadminpanel", function()
        OpenAdminPanel()
    end)

    -- helper: theadminpanel_bind o   ->   bind o theadminpanel
    concommand.Add("theadminpanel_bind", function(ply, cmd, args)
        local key = args[1]
        if not key or not string.match(key, "^[%w_]+$") then
            chat.AddText(Color(255, 80, 80), "[Admin Panel] ",
                Color(255, 255, 255), "Usage: theadminpanel_bind <key>   (example: theadminpanel_bind o)")
            return
        end

        LocalPlayer():ConCommand("bind " .. key .. " theadminpanel")
        chat.AddText(Color(80, 220, 120), "[Admin Panel] ",
            Color(255, 255, 255), "Key '" .. key .. "' is now bound to the admin panel.")
    end)

    -- ---------- custom Escape menu: "Random Event Mode" ----------
    -- Safety: hold SHIFT while pressing ESC for the normal menu,
    -- or type  re_escape_menu 0  in the console to turn this menu off.
    local cvEscMenu = CreateClientConVar("re_escape_menu", "1", true, false,
        "1 = Random Event Mode escape menu, 0 = standard Garry's Mod menu")

    -- (the Options menu is built further down in the file)
    local optPanel
    local OpenOptions

    local escPanel
    local allowStandard = false -- true while the normal menu is allowed to stay open
    local allowGrace = 0
    local escWasDown = false

    -- instant = true removes it at once, otherwise it fades out
    local function CloseEscMenu(instant)
        if not IsValid(escPanel) then return end

        if instant then
            escPanel:Remove()
        else
            CloseAnimated(escPanel, true)
        end
    end

    -- opens the normal Garry's Mod escape menu
    local function OpenStandardMenu()
        CloseEscMenu(true)
        allowStandard = true
        allowGrace = CurTime() + 0.6
        timer.Simple(0, function() gui.ActivateGameUI() end)
    end

    local function OpenEscMenu()
        CloseEscMenu(true)

        local sw, sh = ScrW(), ScrH()
        local confirmUntil = 0
        local isHost = IsHost(LocalPlayer())

        escPanel = vgui.Create("DPanel")
        escPanel:SetPos(0, 0)
        escPanel:SetSize(sw, sh)
        escPanel:MakePopup()
        -- mouse only (keys can never get stuck)
        escPanel:SetKeyboardInputEnabled(false)

        -- { title (text or function), description, stripe colour, click function }
        local items = {
            { "Resume", "Back to the game", THEME.accent, function()
                CloseEscMenu()
            end },

            { isHost and "Admin Panel" or "Admin Panel (host only)",
              "Start any event", isHost and THEME.accent or Color(90, 90, 90), function()
                if isHost then
                    CloseEscMenu()
                    OpenAdminPanel()
                end
            end },

            { "Replay Intro", "Watch the intro again", Color(150, 215, 165), function()
                CloseEscMenu()
                RunConsoleCommand("re_intro")
            end },

            { "Options", "Sound, FOV, HUD, menus", Color(120, 160, 140), function()
                CloseEscMenu()
                if OpenOptions then OpenOptions() end
            end },

            { "Go to Standard Escape Menu", "The normal Garry's Mod menu",
              Color(230, 200, 60), OpenStandardMenu },

            { function()
                return CurTime() < confirmUntil and "Click again to disconnect" or "Disconnect"
              end, "Leave this game", Color(200, 60, 60), function()
                if CurTime() < confirmUntil then
                    RunConsoleCommand("disconnect")
                else
                    confirmUntil = CurTime() + 3
                end
            end },
        }

        local colW, btnH, gap, titleH = 440, 70, 10, 130
        local total = titleH + #items * (btnH + gap)
        local x0 = (sw - colW) / 2
        local y0 = math.max(20, (sh - total) / 2)

        escPanel.Paint = function(self, w, h)
            surface.SetDrawColor(10, 14, 12, 220)
            surface.DrawRect(0, 0, w, h)

            draw.SimpleTextOutlined("RANDOM EVENT MODE", "RE_EscTitle", w / 2, y0 + 36,
                THEME.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 2, Color(0, 0, 0))

            draw.SimpleText(game.GetMap() .. "   |   Players: " .. #player.GetAll(),
                "RE_PanelSmall", w / 2, y0 + 82, THEME.textDim,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            surface.SetDrawColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, 120)
            surface.DrawRect(x0, y0 + 104, colW, 2)

            draw.SimpleText("ESC closes this menu   |   SHIFT + ESC = standard menu   |   re_escape_menu 0 = turn it off",
                "RE_PanelSmall", w / 2, h - 24, Color(255, 255, 255, 110),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end

        local btns = {}
        for i, item in ipairs(items) do
            btns[#btns + 1] = MakeButton(escPanel, x0, y0 + titleH + (i - 1) * (btnH + gap),
                colW, btnH, item[3], item[1], item[2], item[4])
        end

        -- animation: the dark background fades in, the buttons fly in one by one
        escPanel:SetAlpha(0)
        escPanel:AlphaTo(255, 0.2, 0)
        StaggerIn(btns, 0.06, 70)
    end

    -- catch ESC in the game: hide the normal menu, show ours
    hook.Add("PreRender", "RE_EscapeMenu", function()
        local down = input.IsKeyDown(KEY_ESCAPE)
        local pressed = down and not escWasDown
        escWasDown = down

        -- the normal menu was closed: the next ESC press is ours again
        if allowStandard and CurTime() > allowGrace and not gui.IsGameUIVisible() then
            allowStandard = false
        end

        if not pressed then return end
        if not cvEscMenu:GetBool() then return end
        if allowStandard or input.IsShiftDown() then return end
        if not gui.IsGameUIVisible() then return end
        if not IsValid(LocalPlayer()) then return end

        gui.HideGameUI()

        if IsValid(optPanel) and not optPanel.Closing then
            CloseAnimated(optPanel)           -- ESC closes the Options menu
        elseif IsValid(escPanel) and not escPanel.Closing then
            CloseEscMenu()
        else
            OpenEscMenu()
        end
    end)

    -- ---------- helper: cut a text so it fits into a width ----------
    local function FitText(text, font, maxW)
        surface.SetFont(font)
        if surface.GetTextSize(text) <= maxW then return text end

        while #text > 1 and surface.GetTextSize(text .. "...") > maxW do
            text = string.sub(text, 1, #text - 1)
        end
        return text .. "..."
    end

    -- ---------- scoreboard (TAB menu) ----------
    -- Turn it off with  re_scoreboard 0  (then the normal TAB menu is used)
    local cvScoreboard = CreateClientConVar("re_scoreboard", "1", true, false,
        "1 = Random Event Mode scoreboard (TAB), 0 = standard scoreboard")

    local sbPanel
    local SB_W, SB_ROW = 780, 38

    local function SB_Players()
        local list = player.GetAll()
        table.sort(list, function(a, b)
            if a:Frags() ~= b:Frags() then return a:Frags() > b:Frags() end
            return a:Nick() < b:Nick()
        end)
        return list
    end

    local function SB_MaxRows()
        return math.max(1, math.floor((ScrH() - 50 - 104 - 40) / SB_ROW))
    end

    local function PingColour(ping)
        if ping < 80 then return Color(110, 210, 135) end
        if ping < 160 then return Color(230, 200, 60) end
        return Color(220, 80, 80)
    end

    local function SB_Create()
        sbPanel = vgui.Create("DPanel")
        sbPanel:SetMouseInputEnabled(false)
        sbPanel:SetKeyboardInputEnabled(false)
        sbPanel:SetVisible(false)
        sbPanel.anim = 0
        sbPanel.open = false
        sbPanel.openTime = 0

        -- size, position and the open/close animation
        sbPanel.Think = function(self)
            self.anim = math.Approach(self.anim, self.open and 1 or 0, FrameTime() * 7)

            if self.anim <= 0 and not self.open then
                self:SetVisible(false)
                return
            end

            local rows = math.min(#player.GetAll(), SB_MaxRows())
            local a = Ease(self.anim)

            self:SetSize(SB_W, 104 + rows * SB_ROW + 24)
            self:SetPos((ScrW() - SB_W) / 2, 50 - (1 - a) * 30)
        end

        sbPanel.Paint = function(self, w, h)
            local a = Ease(self.anim)
            surface.SetAlphaMultiplier(a)

            draw.RoundedBox(10, 0, 0, w, h, THEME.back)
            draw.RoundedBoxEx(10, 0, 0, w, 70, THEME.header, true, true, false, false)
            surface.SetDrawColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, 140)
            surface.DrawRect(0, 70, w, 2)
            surface.SetDrawColor(THEME.border)
            surface.DrawOutlinedRect(0, 0, w, h)

            -- title
            draw.SimpleText("RANDOM EVENT MODE", "RE_PanelTitle", 20, 24,
                THEME.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText(FitText(GetHostName(), "RE_PanelSmall", 380) .. "   |   " .. game.GetMap(),
                "RE_PanelSmall", 20, 52, THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

            draw.SimpleText("Players: " .. #player.GetAll() .. " / " .. game.MaxPlayers(),
                "RE_PanelBtn", w - 20, 24, THEME.text, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

            -- the running event
            if hud.active and hud.title ~= "" then
                draw.SimpleText(FitText("EVENT: " .. hud.title, "RE_PanelSmall", 340),
                    "RE_PanelSmall", w - 20, 52, THEME.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
            end

            -- column titles
            local cx1, cx2, cx3 = w - 250, w - 170, w - 70
            draw.SimpleText("PLAYER", "RE_PanelSmall", 72, 90, THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("KILLS", "RE_PanelSmall", cx1, 90, THEME.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("DEATHS", "RE_PanelSmall", cx2, 90, THEME.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("PING", "RE_PanelSmall", cx3, 90, THEME.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- players (every row slides in one after another)
            local list = SB_Players()
            local rows = math.min(#list, SB_MaxRows())
            local me = LocalPlayer()

            for i = 1, rows do
                local ply = list[i]

                if IsValid(ply) then
                    local y = 104 + (i - 1) * SB_ROW
                    local k = Ease((CurTime() - self.openTime - (i - 1) * 0.03) / 0.2)
                    local dx = (1 - k) * -40
                    surface.SetAlphaMultiplier(a * k)

                    local isMe = (ply == me)
                    local alive = ply:Alive()
                    local mid = y + (SB_ROW - 4) / 2
                    local bg = isMe and THEME.hover or ((i % 2 == 0) and THEME.panel or THEME.button)

                    draw.RoundedBox(5, 12 + dx, y, w - 24, SB_ROW - 4, bg)
                    if isMe then
                        draw.RoundedBoxEx(5, 12 + dx, y, 5, SB_ROW - 4, THEME.accent, true, false, true, false)
                    end

                    draw.SimpleText(tostring(i), "RE_PanelSmall", 34 + dx, mid,
                        THEME.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.RoundedBox(4, 50 + dx, mid - 4, 8, 8,
                        alive and THEME.accent or Color(150, 60, 60))

                    local name = FitText(ply:Nick(), "RE_PanelBtn", w - 72 - 280)
                    draw.SimpleText(name, "RE_PanelBtn", 72 + dx, mid,
                        alive and THEME.text or THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

                    -- HOST / ADMIN badge
                    surface.SetFont("RE_PanelBtn")
                    local nameW = surface.GetTextSize(name)
                    local badge
                    if ply:IsListenServerHost() then
                        badge = "HOST"
                    elseif ply:IsAdmin() then
                        badge = "ADMIN"
                    end
                    if badge then
                        draw.SimpleText(badge, "RE_PanelSmall", 72 + nameW + 10 + dx, mid,
                            THEME.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end

                    draw.SimpleText(tostring(ply:Frags()), "RE_PanelBtn", cx1 + dx, mid,
                        THEME.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    draw.SimpleText(tostring(ply:Deaths()), "RE_PanelBtn", cx2 + dx, mid,
                        THEME.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                    if ply:IsBot() then
                        draw.SimpleText("BOT", "RE_PanelBtn", cx3 + dx, mid,
                            THEME.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    else
                        draw.SimpleText(tostring(ply:Ping()), "RE_PanelBtn", cx3 + dx, mid,
                            PingColour(ply:Ping()), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end
            end

            surface.SetAlphaMultiplier(a)
            if #list > rows then
                draw.SimpleText("+ " .. (#list - rows) .. " more players", "RE_PanelSmall",
                    w / 2, 104 + rows * SB_ROW + 10, THEME.textDim,
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            surface.SetAlphaMultiplier(1)
        end
    end

    hook.Add("ScoreboardShow", "RE_Scoreboard", function()
        if not cvScoreboard:GetBool() then return end

        if not IsValid(sbPanel) then SB_Create() end
        sbPanel.open = true
        sbPanel.openTime = CurTime()
        sbPanel:SetVisible(true)

        return true -- do not show the normal scoreboard
    end)

    hook.Add("ScoreboardHide", "RE_Scoreboard", function()
        if not cvScoreboard:GetBool() then return end

        if IsValid(sbPanel) then sbPanel.open = false end

        return true
    end)

    -- ---------- weapon selector (keys 1-9 and the mouse wheel) ----------
    -- Turn it off with  re_weapon_selector 0  (then the normal selector is used)
    local cvWepSel = CreateClientConVar("re_weapon_selector", "1", true, false,
        "1 = Random Event Mode weapon selector, 0 = standard selector")

    local WS_PAD, WS_ROW, WS_HEAD, WS_MODEL_W, WS_TIMEOUT = 12, 30, 34, 240, 2.5

    local wsPanel, wsModel
    local wsSlots = {}          -- { { slot = 0, weapons = { ... } }, ... }
    local wsSelected = nil      -- the highlighted weapon
    local wsOpen = false
    local wsAnim = 0            -- 0 = closed ... 1 = fully open
    local wsLast = 0            -- last time you pressed something
    local wsChangeTime = 0      -- when the highlight last moved
    local wsModelPath = nil
    local wsBroken = false      -- if our code ever fails, the normal selector comes back
    local wsGeo = { colW = 120, W = 600, H = 210, x = 0 }
    local wsHigh = { x = 0, y = 0, snap = true }
    local nameCache = {}

    local function WeaponName(wep)
        local class = wep:GetClass()
        if nameCache[class] then return nameCache[class] end

        local name = wep:GetPrintName() or class
        if string.sub(name, 1, 1) == "#" then
            local key = string.sub(name, 2)
            local phrase = language.GetPhrase(key)

            if phrase and phrase ~= key then
                name = phrase
            else
                name = string.upper(string.gsub(string.gsub(class, "^weapon_", ""), "_", " "))
            end
        end

        nameCache[class] = name
        return name
    end

    local function WS_Rebuild()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local slots, bySlot = {}, {}

        for _, wep in ipairs(ply:GetWeapons()) do
            local s = wep:GetSlot()
            if not bySlot[s] then
                bySlot[s] = { slot = s, weapons = {} }
                table.insert(slots, bySlot[s])
            end
            table.insert(bySlot[s].weapons, wep)
        end

        table.sort(slots, function(a, b) return a.slot < b.slot end)

        for _, g in ipairs(slots) do
            table.sort(g.weapons, function(a, b)
                local pa, pb = a:GetSlotPos(), b:GetSlotPos()
                if pa == pb then return a:GetClass() < b:GetClass() end
                return pa < pb
            end)
        end

        wsSlots = slots
    end

    -- returns the column number and the row number of a weapon
    local function WS_Locate(wep)
        if not IsValid(wep) then return nil end

        for si, g in ipairs(wsSlots) do
            for wi, w in ipairs(g.weapons) do
                if w == wep then return si, wi end
            end
        end
        return nil
    end

    local function WS_FitModel()
        if not IsValid(wsModel) then return end
        local ent = wsModel:GetEntity()
        if not IsValid(ent) then return end

        local mn, mx = ent:GetRenderBounds()
        local size = math.max(
            math.abs(mn.x) + math.abs(mx.x),
            math.abs(mn.y) + math.abs(mx.y),
            math.abs(mn.z) + math.abs(mx.z)
        )

        wsModel:SetFOV(40)
        wsModel:SetCamPos(Vector(size, size, size * 0.6))
        wsModel:SetLookAt((mn + mx) * 0.5)
    end

    local function WS_Layout()
        if not IsValid(wsPanel) then return end

        local n = math.max(#wsSlots, 1)
        local sw = ScrW()
        local colW = math.Clamp((sw * 0.92 - WS_MODEL_W - 3 * WS_PAD) / n, 90, 130)

        local maxRows = 1
        for _, g in ipairs(wsSlots) do maxRows = math.max(maxRows, #g.weapons) end

        local W = WS_PAD * 2 + n * colW + 16 + WS_MODEL_W
        local H = math.max(WS_PAD * 2 + WS_HEAD + maxRows * WS_ROW, 210)

        wsGeo.colW, wsGeo.W, wsGeo.H, wsGeo.x = colW, W, H, (sw - W) / 2
        wsPanel:SetSize(W, H)

        if IsValid(wsModel) then
            wsModel:SetPos(W - WS_PAD - WS_MODEL_W + 6, WS_PAD + 6)
            wsModel:SetSize(WS_MODEL_W - 12, 116)
        end
    end

    local function WS_ModelFor(wep)
        local path = wep:GetWeaponWorldModel()
        if not path or path == "" then path = wep.WorldModel end
        if not path or path == "" then path = wep:GetModel() end
        return path
    end

    -- highlight a weapon: the model "pops" and starts spinning
    local function WS_Select(wep, silent)
        if not IsValid(wep) then return end
        if wsSelected == wep then return end

        wsSelected = wep
        wsChangeTime = CurTime()
        if not silent then surface.PlaySound("common/wpn_moveselect.wav") end

        if IsValid(wsModel) then
            local path = WS_ModelFor(wep)

            if path and path ~= "" and util.IsValidModel(path) then
                if path ~= wsModelPath then
                    wsModel:SetModel(path)
                    wsModelPath = path
                    WS_FitModel()
                end
                wsModel:SetVisible(true)
            else
                wsModel:SetVisible(false)
            end
        end
    end

    local function WS_Ensure()
        if IsValid(wsPanel) then return end

        wsPanel = vgui.Create("DPanel")
        wsPanel:SetMouseInputEnabled(false)
        wsPanel:SetKeyboardInputEnabled(false)
        wsPanel:SetVisible(false)

        -- the spinning 3D model of the highlighted weapon
        wsModel = vgui.Create("DModelPanel", wsPanel)
        wsModel:SetMouseInputEnabled(false)
        wsModel.LayoutEntity = function(self, ent)
            local k = Ease((CurTime() - wsChangeTime) / 0.3)
            ent:SetModelScale(0.55 + 0.45 * k, 0)                -- grows when selected
            ent:SetAngles(Angle(0, (CurTime() * 70) % 360, 0))  -- spins all the time
        end

        wsPanel.Think = function(self)
            wsAnim = math.Approach(wsAnim, wsOpen and 1 or 0, FrameTime() * 7)
            local a = Ease(wsAnim)

            if wsAnim <= 0 and not wsOpen then
                self:SetVisible(false)
                return
            end

            self:SetPos(wsGeo.x, 36 - (1 - a) * 40)
            if IsValid(wsModel) then wsModel:SetAlpha(255 * a) end

            if wsOpen then
                local ply = LocalPlayer()
                if not IsValid(ply) or not ply:Alive() or CurTime() - wsLast > WS_TIMEOUT then
                    wsOpen = false
                    return
                end

                -- picked up or dropped a weapon: keep the list fresh
                if CurTime() > (self.nextRebuild or 0) then
                    self.nextRebuild = CurTime() + 0.4
                    WS_Rebuild()
                    WS_Layout()

                    if not WS_Locate(wsSelected) and wsSlots[1] then
                        WS_Select(wsSlots[1].weapons[1], true)
                    end
                end
            end
        end

        wsPanel.Paint = function(self, w, h)
            local a = Ease(wsAnim)
            surface.SetAlphaMultiplier(a)

            draw.RoundedBox(10, 0, 0, w, h, THEME.back)
            surface.SetDrawColor(THEME.border)
            surface.DrawOutlinedRect(0, 0, w, h)
            surface.SetDrawColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, 160)
            surface.DrawRect(10, 0, w - 20, 2)

            local selSlot, selIdx = WS_Locate(wsSelected)
            local colW = wsGeo.colW

            -- the highlight slides smoothly from weapon to weapon
            if selSlot then
                local tx = WS_PAD + (selSlot - 1) * colW + 4
                local ty = WS_PAD + WS_HEAD + (selIdx - 1) * WS_ROW

                if wsHigh.snap then
                    wsHigh.x, wsHigh.y, wsHigh.snap = tx, ty, false
                else
                    local f = math.min(1, FrameTime() * 18)
                    wsHigh.x = Lerp(f, wsHigh.x, tx)
                    wsHigh.y = Lerp(f, wsHigh.y, ty)
                end

                draw.RoundedBox(5, wsHigh.x, wsHigh.y, colW - 8, WS_ROW - 3, THEME.down)
                draw.RoundedBox(2, wsHigh.x, wsHigh.y + 3, 3, WS_ROW - 9, THEME.accent)
            end

            -- columns: slot number on top, the weapons under it
            for ci, g in ipairs(wsSlots) do
                local x = WS_PAD + (ci - 1) * colW
                local isSel = (ci == selSlot)

                draw.RoundedBox(6, x + 4, WS_PAD, colW - 8, WS_HEAD - 6,
                    isSel and THEME.header or THEME.button)
                draw.SimpleText(tostring(g.slot + 1), "RE_PanelBtn", x + colW / 2,
                    WS_PAD + (WS_HEAD - 6) / 2, isSel and THEME.accent or THEME.textDim,
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                for wi, wep in ipairs(g.weapons) do
                    if IsValid(wep) then
                        local y = WS_PAD + WS_HEAD + (wi - 1) * WS_ROW
                        local chosen = (wep == wsSelected)

                        draw.SimpleText(FitText(WeaponName(wep), "RE_PanelSmall", colW - 22),
                            "RE_PanelSmall", x + 14, y + (WS_ROW - 3) / 2,
                            chosen and color_white or THEME.textDim,
                            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end
                end
            end

            -- the model area on the right
            local mx = w - WS_PAD - WS_MODEL_W
            draw.RoundedBox(8, mx, WS_PAD, WS_MODEL_W, 128, THEME.panel)

            local flash = 1 - Ease((CurTime() - wsChangeTime) / 0.35)
            if flash > 0 then
                draw.RoundedBox(8, mx, WS_PAD, WS_MODEL_W, 128,
                    Color(THEME.accent.r, THEME.accent.g, THEME.accent.b, 70 * flash))
            end

            if IsValid(wsSelected) then
                draw.SimpleText(FitText(WeaponName(wsSelected), "RE_PanelBtn", WS_MODEL_W - 10),
                    "RE_PanelBtn", mx + WS_MODEL_W / 2, WS_PAD + 148,
                    THEME.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

                local ply = LocalPlayer()
                local clip = wsSelected:Clip1()
                local ammoType = wsSelected:GetPrimaryAmmoType()
                local reserve = (ammoType and ammoType >= 0) and ply:GetAmmoCount(ammoType) or nil

                local ammoText = "-"
                if clip and clip >= 0 then
                    ammoText = clip .. (reserve and (" / " .. reserve) or "")
                elseif reserve then
                    ammoText = tostring(reserve)
                end

                draw.SimpleText("Ammo: " .. ammoText, "RE_PanelSmall",
                    mx + WS_MODEL_W / 2, WS_PAD + 172, THEME.textDim,
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end

            draw.SimpleText("1-9 / scroll: browse  |  LMB: equip", "RE_PanelSmall",
                mx + WS_MODEL_W / 2, h - 8, Color(255, 255, 255, 100),
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            surface.SetAlphaMultiplier(1)
        end
    end

    local function WS_Show(wep)
        WS_Ensure()

        local wasOpen = wsOpen
        if not wasOpen then
            surface.PlaySound("common/wpn_hudon.wav")
            wsHigh.snap = true
            wsPanel:SetVisible(true)
        end

        wsOpen = true
        wsLast = CurTime()

        WS_Rebuild()
        WS_Layout()
        wsPanel:SetPos(wsGeo.x, 36 - (1 - Ease(wsAnim)) * 40)
        WS_Select(wep, not wasOpen)
    end

    -- keys 1-9
    local function WS_PressSlot(n)
        WS_Ensure()
        WS_Rebuild()

        local group
        for _, g in ipairs(wsSlots) do
            if g.slot == n - 1 then group = g break end
        end
        if not group then return end -- nothing in this slot

        local target = group.weapons[1]
        local current = wsOpen and wsSelected or LocalPlayer():GetActiveWeapon()

        for i, w in ipairs(group.weapons) do
            if w == current then
                -- same slot again: next weapon. (If the selector is closed we just
                -- highlight the weapon you are holding.)
                target = wsOpen and group.weapons[(i % #group.weapons) + 1] or w
                break
            end
        end

        WS_Show(target)
    end

    -- mouse wheel: through all weapons in order
    local function WS_Move(dir)
        WS_Ensure()
        WS_Rebuild()

        local flat = {}
        for _, g in ipairs(wsSlots) do
            for _, w in ipairs(g.weapons) do flat[#flat + 1] = w end
        end
        if #flat == 0 then return end

        local current = wsOpen and wsSelected or LocalPlayer():GetActiveWeapon()
        local idx = 0
        for i, w in ipairs(flat) do
            if w == current then idx = i break end
        end

        idx = ((idx - 1 + dir) % #flat) + 1
        WS_Show(flat[idx])
    end

    -- left click: equip the highlighted weapon
    local function WS_Confirm()
        if IsValid(wsSelected) then
            input.SelectWeapon(wsSelected)
            surface.PlaySound("common/wpn_select.wav")
        end
        wsOpen = false
    end

    hook.Add("PlayerBindPress", "RE_WeaponSelector", function(ply, bind, pressed)
        if wsBroken or not cvWepSel:GetBool() then return end
        if not pressed then return end
        if not IsValid(ply) or not ply:Alive() or ply:InVehicle() then return end

        local b = string.lower(bind)
        local slot = string.match(b, "^slot(%d)$")

        local ok, handled = pcall(function()
            if slot then
                WS_PressSlot(tonumber(slot))
                return true
            elseif b == "invnext" then
                WS_Move(1)
                return true
            elseif b == "invprev" then
                WS_Move(-1)
                return true
            elseif wsOpen and b == "+attack" then
                WS_Confirm()
                return true
            end
        end)

        if not ok then
            -- something went wrong: give the normal selector back
            wsBroken = true
            wsOpen = false
            print("[RandomEvents] Weapon selector failed, using the normal one: " .. tostring(handled))
            return
        end

        return handled
    end)

    -- hide the normal selector while ours is active
    hook.Add("HUDShouldDraw", "RE_HideWeaponSelection", function(name)
        if name == "CHudWeaponSelection" and cvWepSel:GetBool() and not wsBroken then
            return false
        end
    end)

    -- ---------- custom HUD: health, armor and ammo (bottom of the screen) ----------
    -- Turn it off with  re_hud 0  (then the normal HUD is used)
    local cvHud = CreateClientConVar("re_hud", "1", true, false,
        "1 = Random Event Mode HUD (health, armor, ammo), 0 = standard HUD")

    local hudBroken = false -- if our HUD ever fails, the normal one comes back
    local hs = {
        health = 0, trail = 0, armor = 0, lastHealth = 0,
        flash = 0, flashGood = false, trailHold = 0,
        ammoPop = 0, lastShown = -1, lastWep = nil,
    }
    local hudRed, hudArmor = Color(220, 70, 70), Color(90, 175, 225)

    local function LerpColour(t, a, b)
        return Color(Lerp(t, a.r, b.r), Lerp(t, a.g, b.g), Lerp(t, a.b, b.b))
    end

    local function HudBar(x, y, w, h, frac, trailFrac, col)
        draw.RoundedBox(h / 2, x, y, w, h, Color(10, 14, 12, 230))

        -- the red "trail" shows how much health you just lost
        if trailFrac and trailFrac > frac then
            draw.RoundedBox(h / 2, x, y, math.max(h, w * trailFrac), h, Color(235, 120, 100, 170))
        end

        if frac > 0 then
            draw.RoundedBox(h / 2, x, y, math.max(h, w * frac), h, col)
        end
    end

    local function DrawHUD()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local ft = FrameTime()

        if not ply:Alive() then
            hs.health, hs.trail, hs.armor, hs.lastHealth = 0, 0, 0, 0
            return
        end

        local sw, sh = ScrW(), ScrH()
        local hp = math.max(ply:Health(), 0)
        local maxHp = math.max(ply:GetMaxHealth(), 1)
        local armor = math.max(ply:Armor(), 0)
        local maxArmor = math.max(ply:GetMaxArmor(), 100)

        -- flash when you get hurt (red) or healed (green)
        if hp < hs.lastHealth then
            hs.flash, hs.flashGood, hs.trailHold = 1, false, CurTime() + 0.5
        elseif hp > hs.lastHealth and hs.lastHealth > 0 then
            hs.flash, hs.flashGood = 1, true
        end
        hs.lastHealth = hp
        hs.flash = math.max(0, hs.flash - ft * 3)

        -- the bars move smoothly
        local k = math.min(1, ft * 10)
        hs.health = Lerp(k, hs.health, hp)
        hs.armor = Lerp(k, hs.armor, armor)
        if hs.trail < hs.health then
            hs.trail = hs.health
        elseif CurTime() > hs.trailHold then
            hs.trail = Lerp(math.min(1, ft * 3), hs.trail, hs.health)
        end

        -- ===== health + armor (bottom left) =====
        local bx, bw, bh = 24, 336, 92
        local by = sh - 24 - bh
        local frac = math.Clamp(hs.health / maxHp, 0, 1)
        local low = frac <= 0.25
        local pulse = low and (0.5 + 0.5 * math.sin(CurTime() * 7)) or 0
        local hpCol = LerpColour(math.min(1, frac * 1.4), hudRed, THEME.accent)

        draw.RoundedBox(10, bx, by, bw, bh, THEME.back)
        surface.SetDrawColor(THEME.border)
        surface.DrawOutlinedRect(bx, by, bw, bh)
        draw.RoundedBoxEx(10, bx, by, 6, bh, hpCol, true, false, true, false)

        if hs.flash > 0 then
            local c = hs.flashGood and THEME.accent or hudRed
            draw.RoundedBox(10, bx, by, bw, bh, Color(c.r, c.g, c.b, 80 * hs.flash))
        end
        if low then
            draw.RoundedBox(10, bx, by, bw, bh, Color(220, 60, 60, 40 * pulse))
        end

        draw.SimpleText(tostring(math.Round(hs.health)), "RE_HudBig", bx + 20, by + bh / 2,
            low and LerpColour(pulse, hpCol, color_white) or THEME.text,
            TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local barX, barW = bx + 118, bw - 118 - 18

        draw.SimpleText("HEALTH", "RE_PanelSmall", barX, by + 15,
            THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        HudBar(barX, by + 26, barW, 18, frac, math.Clamp(hs.trail / maxHp, 0, 1), hpCol)

        draw.SimpleText("SUIT", "RE_PanelSmall", barX, by + 55,
            THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        HudBar(barX, by + 66, barW, 10, math.Clamp(hs.armor / maxArmor, 0, 1), nil, hudArmor)
        if hs.armor > 0.5 then
            draw.SimpleText(tostring(math.Round(hs.armor)), "RE_PanelSmall", barX + barW, by + 55,
                hudArmor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        -- ===== ammo (bottom right) =====
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) then return end

        local clip = wep:Clip1()
        local maxClip = wep:GetMaxClip1()
        local aType = wep:GetPrimaryAmmoType()
        local reserve = (aType and aType >= 0) and ply:GetAmmoCount(aType) or nil
        local sType = wep:GetSecondaryAmmoType()
        local alt = (sType and sType >= 0) and ply:GetAmmoCount(sType) or nil

        if not ((clip and clip >= 0) or reserve) then return end -- crowbar etc.

        local hasClip = clip and clip >= 0
        local shown = hasClip and clip or reserve

        -- the number "pops" when it changes
        if wep ~= hs.lastWep then hs.lastWep, hs.lastShown = wep, shown end
        if shown ~= hs.lastShown then hs.ammoPop, hs.lastShown = 1, shown end
        hs.ammoPop = math.max(0, hs.ammoPop - ft * 6)

        local aw, ah = 270, 92
        local ax, ay = sw - 24 - aw, sh - 24 - ah
        local lowAmmo = hasClip and maxClip and maxClip > 0 and clip <= maxClip * 0.25

        draw.RoundedBox(10, ax, ay, aw, ah, THEME.back)
        surface.SetDrawColor(THEME.border)
        surface.DrawOutlinedRect(ax, ay, aw, ah)
        draw.RoundedBoxEx(10, ax + aw - 6, ay, 6, ah, lowAmmo and hudRed or THEME.accent,
            false, true, false, true)

        draw.SimpleText(FitText(WeaponName(wep), "RE_PanelSmall", aw - 40), "RE_PanelSmall",
            ax + 20, ay + 15, THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)

        local numX, numY = ax + 20, ay + 54
        local s = 1 + 0.18 * hs.ammoPop
        local m = Matrix()
        m:Translate(Vector(numX, numY, 0))
        m:Scale(Vector(s, s, 1))
        m:Translate(Vector(-numX, -numY, 0))

        cam.PushModelMatrix(m)
        pcall(draw.SimpleText, tostring(shown), "RE_HudBig", numX, numY,
            lowAmmo and hudRed or THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        cam.PopModelMatrix()

        if hasClip and reserve then
            draw.SimpleText("/ " .. reserve, "RE_HudMid", ax + aw - 22, ay + 58,
                THEME.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        if alt and alt > 0 then
            draw.SimpleText("ALT  " .. alt, "RE_PanelSmall", ax + aw - 22, ay + ah - 14,
                THEME.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end
    end

    hook.Add("HUDPaint", "RE_CustomHUD", function()
        if hudBroken or not cvHud:GetBool() or cutscene then return end

        local ok, err = pcall(DrawHUD)
        if not ok then
            hudBroken = true
            surface.SetAlphaMultiplier(1)
            print("[RandomEvents] HUD failed, using the normal one: " .. tostring(err))
        end
    end)

    -- hide the normal health / armor / ammo while ours is active
    hook.Add("HUDShouldDraw", "RE_HideDefaultHUD", function(name)
        if hudBroken or not cvHud:GetBool() then return end

        if name == "CHudHealth" or name == "CHudBattery"
            or name == "CHudAmmo" or name == "CHudSecondaryAmmo" then
            return false
        end
    end)

    -- ---------- kill feed: who died, from what, and who killed them ----------
    -- Turn it off with  re_killfeed 0  (then the normal kill feed is used)
    local cvKillFeed = CreateClientConVar("re_killfeed", "1", true, false,
        "1 = Random Event Mode kill feed, 0 = standard kill feed")

    local kfEntries = {}
    local kfBroken = false
    local KF_LIFE, KF_MAX, KF_H, KF_GAP = 8, 6, 36, 6
    local oldAddDeathNotice, oldDrawDeathNotice

    -- names for things that are not weapons
    local CAUSE_NAMES = {
        suicide = "Suicide", worldspawn = "The world", world = "The world",
        trigger_hurt = "Hazard", point_hurt = "Hazard",
        prop_physics = "Prop", prop_physics_multiplayer = "Prop", func_physbox = "Crushed",
        entityflame = "Fire", env_fire = "Fire", env_explosion = "Explosion",
        npc_grenade_frag = "Grenade", crossbow_bolt = "Crossbow bolt",
        rpg_missile = "RPG rocket", grenade_ar2 = "Pulse grenade",
        prop_combine_ball = "Energy ball", npc_satchel = "SLAM", player = "Fists",
    }

    local function KF_Prettify(class)
        local s = string.gsub(string.gsub(class, "^npc_", ""), "^weapon_", "")
        s = string.gsub(s, "_", " ")
        return string.upper(string.sub(s, 1, 1)) .. string.sub(s, 2)
    end

    -- "#npc_zombie" -> "Zombie"
    local function KF_Name(str)
        if not str or str == "" then return "Unknown" end

        if string.sub(str, 1, 1) == "#" then
            local key = string.sub(str, 2)
            if key == "worldspawn" or key == "world" then return "The world" end

            local phrase = language.GetPhrase(key)
            if phrase and phrase ~= key then return phrase end
            return KF_Prettify(key)
        end

        return str
    end

    -- weapon / thing that killed: "weapon_smg1" -> "SMG"
    local function KF_Cause(class)
        if not class or class == "" then return "Unknown" end

        local key = string.lower(class)
        if CAUSE_NAMES[key] then return CAUSE_NAMES[key] end

        for _, w in ipairs(HL2_WEAPONS) do
            if w.class == key then return w.name end
        end

        local swep = weapons.GetStored(class)
        if swep and swep.PrintName and swep.PrintName ~= "" then
            local n = swep.PrintName
            if string.sub(n, 1, 1) == "#" then n = language.GetPhrase(string.sub(n, 2)) end
            return n
        end

        return KF_Prettify(class)
    end

    local function KF_Add(attacker, attackerTeam, inflictor, victim, victimTeam)
        local me = LocalPlayer()
        local myName = IsValid(me) and me:Nick() or ""

        local victimName = KF_Name(victim)
        local killer = (attacker and attacker ~= "") and KF_Name(attacker) or nil
        if killer == victimName then killer = nil end -- killed yourself

        local cause = KF_Cause(inflictor)
        if killer and string.lower(cause) == string.lower(killer) then
            cause = "Killed" -- "Zombie [Zombie] You" would look silly
        end

        table.insert(kfEntries, 1, {
            killer = killer,
            victim = victimName,
            cause = cause,
            mine = (victimName == myName),
            byMe = (killer ~= nil and killer == myName),
            born = CurTime(),
            y = nil,
        })

        while #kfEntries > KF_MAX do
            table.remove(kfEntries)
        end
    end

    local function KF_Draw()
        local sw = ScrW()
        local now = CurTime()
        local rightX, topY = sw - 24, 28

        for i = #kfEntries, 1, -1 do
            if now - kfEntries[i].born > KF_LIFE then table.remove(kfEntries, i) end
        end

        for i, e in ipairs(kfEntries) do
            local age = now - e.born
            local a = Ease(age / 0.2) * (1 - Ease((age - (KF_LIFE - 0.6)) / 0.6))
            local slide = (1 - Ease(age / 0.3)) * 90

            -- every entry slides smoothly to its place in the list
            local targetY = topY + (i - 1) * (KF_H + KF_GAP)
            if not e.y then e.y = targetY - 24 end
            e.y = Lerp(math.min(1, FrameTime() * 12), e.y, targetY)

            surface.SetFont("RE_KillText")
            local kw = e.killer and surface.GetTextSize(e.killer) or 0
            local vw = surface.GetTextSize(e.victim)
            surface.SetFont("RE_PanelSmall")
            local pw = surface.GetTextSize(e.cause) + 20

            local total = 16 + (e.killer and (kw + 12) or 0) + pw + 12 + vw + 16
            local x, y = rightX - total + slide, e.y
            local mid = y + KF_H / 2

            surface.SetAlphaMultiplier(a)

            local border = e.mine and hudRed or (e.byMe and THEME.accent or THEME.border)
            draw.RoundedBox(8, x, y, total, KF_H, THEME.back)
            surface.SetDrawColor(border)
            surface.DrawOutlinedRect(x, y, total, KF_H)
            draw.RoundedBoxEx(8, x, y, 5, KF_H, border, true, false, true, false)

            local victimCol = e.mine and Color(240, 110, 110) or THEME.text
            local cx = x + 16

            if e.killer then
                -- Killer  [weapon]  Victim
                draw.SimpleText(e.killer, "RE_KillText", cx, mid,
                    e.byMe and THEME.accent or THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                cx = cx + kw + 12

                draw.RoundedBox(6, cx, y + 6, pw, KF_H - 12, THEME.button)
                draw.SimpleText(e.cause, "RE_PanelSmall", cx + pw / 2, mid,
                    THEME.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                cx = cx + pw + 12

                draw.SimpleText(e.victim, "RE_KillText", cx, mid,
                    victimCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                -- Victim  [cause]   (suicide, fall, fire...)
                draw.SimpleText(e.victim, "RE_KillText", cx, mid,
                    victimCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                cx = cx + vw + 12

                draw.RoundedBox(6, cx, y + 6, pw, KF_H - 12, THEME.button)
                draw.SimpleText(e.cause, "RE_PanelSmall", cx + pw / 2, mid,
                    THEME.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end

        surface.SetAlphaMultiplier(1)
    end

    hook.Add("HUDPaint", "RE_KillFeed", function()
        if kfBroken or not cvKillFeed:GetBool() or cutscene then return end

        local ok, err = pcall(KF_Draw)
        if not ok then
            kfBroken = true
            surface.SetAlphaMultiplier(1)
            print("[RandomEvents] Kill feed failed, using the normal one: " .. tostring(err))
        end
    end)

    -- take over the gamemode's kill feed (keeping the old one as a backup)
    local function KF_Install()
        if not GAMEMODE or GAMEMODE.RE_KillFeed then return end
        GAMEMODE.RE_KillFeed = true

        oldAddDeathNotice = GAMEMODE.AddDeathNotice
        oldDrawDeathNotice = GAMEMODE.DrawDeathNotice

        GAMEMODE.AddDeathNotice = function(self, ...)
            if kfBroken or not cvKillFeed:GetBool() then
                if oldAddDeathNotice then return oldAddDeathNotice(self, ...) end
                return
            end

            local ok, err = pcall(KF_Add, ...)
            if not ok then
                kfBroken = true
                print("[RandomEvents] Kill feed failed, using the normal one: " .. tostring(err))
                if oldAddDeathNotice then return oldAddDeathNotice(self, ...) end
            end
        end

        GAMEMODE.DrawDeathNotice = function(self, x, y)
            if kfBroken or not cvKillFeed:GetBool() then
                if oldDrawDeathNotice then return oldDrawDeathNotice(self, x, y) end
            end
            -- otherwise our own feed is drawn in HUDPaint
        end
    end

    hook.Add("Initialize", "RE_KillFeed", KF_Install)
    KF_Install()

    -- ---------- Options menu (Escape menu -> Options) ----------
    OpenOptions = function()
        if IsValid(optPanel) then optPanel:Remove() end

        local sw, sh = ScrW(), ScrH()
        local W, H = 640, math.min(600, sh - 60)

        optPanel = vgui.Create("DPanel")
        optPanel:SetSize(W, H)
        optPanel:SetPos((sw - W) / 2, (sh - H) / 2)
        optPanel:MakePopup()
        optPanel:SetKeyboardInputEnabled(false) -- mouse only (keys can never get stuck)

        optPanel.Paint = function(self, w, h)
            draw.RoundedBox(10, 0, 0, w, h, THEME.back)
            draw.RoundedBoxEx(10, 0, 0, w, 56, THEME.header, true, true, false, false)
            surface.SetDrawColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, 140)
            surface.DrawRect(0, 56, w, 2)
            surface.SetDrawColor(THEME.border)
            surface.DrawOutlinedRect(0, 0, w, h)

            draw.SimpleText("OPTIONS", "RE_PanelTitle", 20, 28,
                THEME.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            draw.SimpleText("Random Event Mode", "RE_PanelSmall", w - 64, 28,
                THEME.textDim, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
        end

        -- close button
        local close = vgui.Create("DButton", optPanel)
        close:SetText("")
        close:SetPos(W - 44, 13)
        close:SetSize(30, 30)
        close.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and Color(255, 255, 255, 60) or Color(0, 0, 0, 60))
            draw.SimpleText("X", "RE_PanelBtn", w / 2, h / 2, color_white,
                TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
        close.DoClick = function() CloseAnimated(optPanel) end

        -- scrolling list with all the settings
        local list = vgui.Create("DScrollPanel", optPanel)
        list:SetPos(14, 68)
        list:SetSize(W - 28, H - 68 - 76)

        local canvas = list:GetCanvas()
        local cw = W - 28 - 22
        local y = 0
        local rows = {}

        local function Section(title)
            local p = vgui.Create("DPanel", canvas)
            p:SetPos(0, y)
            p:SetSize(cw, 30)
            p.Paint = function(self, w, h)
                draw.SimpleText(title, "RE_PanelBtn", 4, h / 2,
                    THEME.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                surface.SetDrawColor(THEME.accent.r, THEME.accent.g, THEME.accent.b, 90)
                surface.DrawRect(0, h - 2, w, 1)
            end
            rows[#rows + 1] = p
            y = y + 38
        end

        -- a slider that changes a console variable
        local function Slider(label, cvarName, minV, maxV, step, fmt)
            local p = vgui.Create("DPanel", canvas)
            p:SetPos(0, y)
            p:SetSize(cw, 54)

            local function Get()
                local cv = GetConVar(cvarName)
                return cv and cv:GetFloat() or minV
            end

            p.Paint = function(self, w, h)
                local v = Get()
                local frac = math.Clamp((v - minV) / (maxV - minV), 0, 1)
                local tx, tw = 14, w - 28

                draw.RoundedBox(6, 0, 0, w, h, THEME.panel)
                draw.SimpleText(label, "RE_PanelSmall", 14, 16,
                    THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                draw.SimpleText(fmt and fmt(v) or tostring(v), "RE_PanelSmall", w - 14, 16,
                    THEME.accent, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

                draw.RoundedBox(3, tx, 36, tw, 6, THEME.back)
                draw.RoundedBox(3, tx, 36, math.max(6, tw * frac), 6, THEME.down)
                draw.RoundedBox(8, tx + tw * frac - 8, 31, 16, 16,
                    (self.dragging or self:IsHovered()) and THEME.accent or THEME.text)
            end

            local function SetFromCursor(self)
                local cx = self:CursorPos()
                local frac = math.Clamp((cx - 14) / (self:GetWide() - 28), 0, 1)
                local v = minV + frac * (maxV - minV)
                if step then v = math.Round(v / step) * step end
                v = math.Clamp(v, minV, maxV)

                local text = (step and step >= 1) and tostring(math.floor(v + 0.5))
                    or string.format("%.2f", v)
                RunConsoleCommand(cvarName, text)
            end

            p.OnMousePressed = function(self, mc)
                if mc == MOUSE_LEFT then
                    self.dragging = true
                    self:MouseCapture(true)
                    SetFromCursor(self)
                end
            end
            p.OnMouseReleased = function(self)
                self.dragging = false
                self:MouseCapture(false)
            end
            p.OnCursorMoved = function(self)
                if self.dragging then SetFromCursor(self) end
            end

            rows[#rows + 1] = p
            y = y + 62
        end

        -- an on/off switch for a console variable
        local function Toggle(label, cvarName, hint)
            local btn = vgui.Create("DButton", canvas)
            btn:SetText("")
            btn:SetPos(0, y)
            btn:SetSize(cw, 48)

            local cv0 = GetConVar(cvarName)
            btn.anim = (cv0 and cv0:GetBool()) and 1 or 0

            btn.Paint = function(self, w, h)
                local cv = GetConVar(cvarName)
                local on = cv and cv:GetBool() or false
                self.anim = math.Approach(self.anim, on and 1 or 0, FrameTime() * 8)

                draw.RoundedBox(6, 0, 0, w, h, self:IsHovered() and THEME.hover or THEME.panel)
                draw.SimpleText(label, "RE_PanelSmall", 14, hint and 16 or h / 2,
                    THEME.text, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                if hint then
                    draw.SimpleText(hint, "RE_PanelSmall", 14, 34,
                        THEME.textDim, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                end

                -- the switch
                local sx, sy = w - 14 - 46, h / 2 - 11
                draw.RoundedBox(11, sx, sy, 46, 22, LerpColour(self.anim, THEME.back, THEME.down))
                surface.SetDrawColor(THEME.border)
                surface.DrawOutlinedRect(sx, sy, 46, 22)
                draw.RoundedBox(8, sx + 3 + (46 - 22) * self.anim, sy + 3, 16, 16,
                    LerpColour(self.anim, THEME.textDim, THEME.accent))
            end

            btn.DoClick = function()
                local cv = GetConVar(cvarName)
                RunConsoleCommand(cvarName, (cv and cv:GetBool()) and "0" or "1")
                surface.PlaySound("buttons/button14.wav")
            end

            rows[#rows + 1] = btn
            y = y + 56
        end

        local function Percent(v) return math.Round(v * 100) .. "%" end

        Section("AUDIO")
        Slider("Master volume", "volume", 0, 1, 0.05, Percent)
        Slider("Event & intro music volume", "re_music_volume", 0, 1, 0.05, Percent)

        Section("GAMEPLAY")
        Slider("Field of view", "fov_desired", 75, 100, 1, function(v) return tostring(math.Round(v)) end)
        Slider("Mouse sensitivity", "sensitivity", 0.1, 10, 0.1, function(v) return string.format("%.1f", v) end)
        Toggle("Show FPS", "cl_showfps")

        Section("INTERFACE")
        Toggle("Custom HUD", "re_hud", "Health, armor and ammo")
        Toggle("Kill feed", "re_killfeed", "Who died, from what, and who killed them")
        Toggle("Scoreboard (TAB)", "re_scoreboard", "The player list")
        Toggle("Weapon selector (1-9)", "re_weapon_selector", "With the spinning 3D model")
        Toggle("Dark menus", "re_dark_theme", "Dark gray-green Q menu and context menu")
        Toggle("Dark green picture", "re_dark_world", "Color tint on the whole game")
        Toggle("Random Event Mode Escape menu", "re_escape_menu", "Turn off to always use the standard menu")

        -- bottom buttons
        MakeButton(optPanel, 14, H - 64, 300, 48, Color(230, 200, 60),
            "Standard GMod options", nil, function()
                CloseAnimated(optPanel)
                RunConsoleCommand("gamemenucommand", "OpenOptionsDialog")
            end)

        MakeButton(optPanel, W - 14 - 300, H - 64, 300, 48, THEME.accent,
            "Back", nil, function()
                CloseAnimated(optPanel)
                OpenEscMenu()
            end)

        -- animation: the window slides up and the rows fly in one by one
        AnimateOpen(optPanel, 40)
        StaggerIn(rows, 0.03, 40)
    end

    -- ---------- intro when you join the game ----------
    local function StartIntro(force)
        if cutscene then return end

        if not force then
            if not INTRO_ENABLED then return end
            if INTRO_ONLY_FIRST_TIME and cookie.GetNumber("re_intro_seen", 0) == 1 then return end
        end

        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then return end

        cookie.Set("re_intro_seen", "1")
        introLockUntil = CurTime() + INTRO_TIME -- expires by itself
        StartCutscene(0, 0, INTRO_TIME, "intro")

        -- sad Half-Life music: the first track that exists on this computer
        if INTRO_MUSIC_ENABLED then
            for _, path in ipairs(INTRO_MUSIC) do
                if file.Exists("sound/" .. path, "GAME") then
                    PlayMusic(path, 3) -- slowly gets louder
                    break
                end
            end
        end
    end

    hook.Add("InitPostEntity", "RE_Intro", function()
        timer.Simple(2, function() StartIntro(false) end)
    end)

    concommand.Add("re_intro", function() StartIntro(true) end)

    -- ---------- dark theme (Q menu, context menu, our menus...) ----------
    local cvDarkTheme = CreateClientConVar("re_dark_theme", "1", true, false,
        "1 = dark gray/green menus, 0 = normal GMod look")
    local cvDarkWorld = CreateClientConVar("re_dark_world", "1", true, false,
        "1 = dark green tint on the game picture, 0 = off")

    -- sets SKIN.Colours.A.B.C = col, silently skips paths that do not exist
    local function SetColour(root, path, col)
        local node = root
        for i = 1, #path - 1 do
            if type(node) ~= "table" then return end
            node = node[path[i]]
        end
        if type(node) == "table" then node[path[#path]] = col end
    end

    local function BuildDarkSkin(base)
        local SKIN = table.Copy(base)
        SKIN.PrintName = "Random Events Dark"
        SKIN.Author = "Random Events"

        -- palette: dark gray with a little green
        local cBack     = Color(24, 28, 26, 250)
        local cPanel    = Color(32, 38, 35, 245)
        local cHeader   = Color(36, 52, 42, 255)
        local cButton   = Color(40, 50, 44, 255)
        local cHover    = Color(56, 78, 64, 255)
        local cDown     = Color(70, 125, 88, 255)
        local cDisabled = Color(30, 34, 32, 255)
        local cBorder   = Color(70, 105, 80, 255)
        local cAccent   = Color(110, 210, 135, 255)
        local cText     = Color(215, 232, 220, 255)
        local cTextDim  = Color(150, 170, 156, 255)
        local cEntry    = Color(18, 22, 20, 255)
        local cSelect   = Color(110, 210, 135, 60)

        -- ----- text colours -----
        local c = SKIN.Colours
        SetColour(c, { "Window", "TitleActive" }, Color(190, 235, 205))
        SetColour(c, { "Window", "TitleInactive" }, Color(130, 160, 138))
        SetColour(c, { "Button", "Normal" }, cText)
        SetColour(c, { "Button", "Hover" }, Color(255, 255, 255))
        SetColour(c, { "Button", "Down" }, Color(255, 255, 255))
        SetColour(c, { "Button", "Disabled" }, Color(105, 120, 110))
        SetColour(c, { "Label", "Default" }, cText)
        SetColour(c, { "Label", "Bright" }, Color(255, 255, 255))
        SetColour(c, { "Label", "Dark" }, cTextDim)
        SetColour(c, { "Label", "Highlight" }, cAccent)
        SetColour(c, { "TooltipText" }, cText)

        for _, group in ipairs({ "Active", "Inactive" }) do
            for _, state in ipairs({ "Normal", "Hover", "Down", "Disabled" }) do
                SetColour(c, { "Tab", group, state }, group == "Active" and Color(255, 255, 255) or cTextDim)
            end
        end

        SetColour(c, { "Category", "Header" }, Color(255, 255, 255))
        SetColour(c, { "Category", "Header_Closed" }, cText)
        for _, group in ipairs({ "Line", "LineAlt" }) do
            SetColour(c, { "Category", group, "Text" }, cText)
            SetColour(c, { "Category", group, "Text_Hover" }, Color(255, 255, 255))
            SetColour(c, { "Category", group, "Text_Selected" }, Color(255, 255, 255))
        end

        SKIN.colTextEntryText            = cText
        SKIN.colTextEntryTextHighlight   = Color(60, 140, 80)
        SKIN.colTextEntryTextCursor      = cText
        SKIN.colTextEntryTextPlaceholder = Color(120, 140, 126)
        SKIN.colPropertySheet            = cPanel
        SKIN.colTab                      = cHeader
        SKIN.colTabInactive              = cButton
        SKIN.colTabText                  = Color(255, 255, 255)
        SKIN.colTabTextInactive          = cTextDim
        SKIN.bg_color                    = cBack
        SKIN.bg_color_dark               = cEntry
        SKIN.bg_color_bright             = cPanel
        SKIN.control_color               = cButton
        SKIN.control_color_highlight     = cHover
        SKIN.control_color_active        = cDown
        SKIN.control_color_dark          = cEntry
        SKIN.listview_hover              = cHover
        SKIN.listview_selected           = cDown
        SKIN.text_normal                 = cText
        SKIN.text_bright                 = Color(255, 255, 255)
        SKIN.text_dark                   = cTextDim

        -- ----- windows -----
        function SKIN:PaintFrame(panel, w, h)
            draw.RoundedBox(6, 0, 0, w, h, cBack)
            draw.RoundedBoxEx(6, 0, 0, w, 24, cHeader, true, true, false, false)
            surface.SetDrawColor(cBorder)
            surface.DrawOutlinedRect(0, 0, w, h)
            surface.SetDrawColor(cAccent.r, cAccent.g, cAccent.b, 120)
            surface.DrawRect(0, 24, w, 1)
        end

        function SKIN:PaintPanel(panel, w, h)
            if not panel.m_bBackground then return end
            draw.RoundedBox(4, 0, 0, w, h, cPanel)
        end

        function SKIN:PaintPanelList(panel, w, h)
            if not panel.m_bBackground then return end
            draw.RoundedBox(4, 0, 0, w, h, cBack)
        end

        function SKIN:PaintListBox(panel, w, h)
            draw.RoundedBox(4, 0, 0, w, h, cEntry)
        end

        local function WindowButton(symbol)
            return function(self, panel, w, h)
                if not panel.m_bBackground then return end
                if panel.Hovered then
                    draw.RoundedBox(4, 0, 0, w, h, cDown)
                end
                draw.SimpleText(symbol, "Marlett", w / 2, h / 2, cText,
                    TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        SKIN.PaintWindowCloseButton    = WindowButton("r")
        SKIN.PaintWindowMaximizeButton = WindowButton("1")
        SKIN.PaintWindowMinimizeButton = WindowButton("0")

        -- ----- buttons -----
        function SKIN:PaintButton(panel, w, h)
            if not panel.m_bBackground then return end

            local col = cButton
            if panel.GetDisabled and panel:GetDisabled() then
                col = cDisabled
            elseif panel.Depressed then
                col = cDown
            elseif panel.Hovered then
                col = cHover
            end

            draw.RoundedBox(4, 0, 0, w, h, col)
            surface.SetDrawColor(cBorder)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        function SKIN:PaintCheckBox(panel, w, h)
            draw.RoundedBox(3, 0, 0, w, h, cEntry)
            surface.SetDrawColor(cBorder)
            surface.DrawOutlinedRect(0, 0, w, h)
            if panel:GetChecked() then
                draw.RoundedBox(2, 3, 3, w - 6, h - 6, cAccent)
            end
        end

        function SKIN:PaintSliderKnob(panel, w, h)
            draw.RoundedBox(4, 0, 0, w, h, panel.Hovered and cAccent or cDown)
        end

        function SKIN:PaintNumSlider(panel, w, h)
            surface.SetDrawColor(cBorder)
            surface.DrawRect(8, h / 2 - 1, w - 16, 2)
        end

        -- ----- text boxes / combo -----
        local oldTextEntry = base.PaintTextEntry

        function SKIN:PaintTextEntry(panel, w, h)
            if panel.m_bBackground then
                draw.RoundedBox(4, 0, 0, w, h, cEntry)
                surface.SetDrawColor(cBorder)
                surface.DrawOutlinedRect(0, 0, w, h)
            end

            if oldTextEntry then
                -- the default code draws the text (and the placeholder);
                -- we only hide its light background
                local had = panel.m_bBackground
                panel.m_bBackground = false
                oldTextEntry(self, panel, w, h)
                panel.m_bBackground = had
            else
                panel:DrawTextEntryText(cText, cAccent, cText)
            end
        end

        function SKIN:PaintComboBox(panel, w, h)
            local col = cButton
            if panel.GetDisabled and panel:GetDisabled() then
                col = cDisabled
            elseif panel.Hovered or panel.Depressed then
                col = cHover
            end
            draw.RoundedBox(4, 0, 0, w, h, col)
            surface.SetDrawColor(cBorder)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        function SKIN:PaintComboDownArrow(panel, w, h)
            local cx, cy, s = w / 2, h / 2, math.min(w, h) * 0.22
            draw.NoTexture()
            surface.SetDrawColor(cText)
            surface.DrawPoly({
                { x = cx - s, y = cy - s * 0.5 },
                { x = cx + s, y = cy - s * 0.5 },
                { x = cx,     y = cy + s * 0.7 },
            })
        end

        -- ----- menus (right click, C menu...) -----
        function SKIN:PaintMenu(panel, w, h)
            draw.RoundedBox(0, 0, 0, w, h, cBack)
            surface.SetDrawColor(cBorder)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        function SKIN:PaintMenuOption(panel, w, h)
            if panel.m_bBackground and (panel.Hovered or panel.Highlight) then
                draw.RoundedBox(0, 0, 0, w, h, cDown)
            end
            if panel.GetChecked and panel:GetChecked() then
                draw.RoundedBox(2, 6, h / 2 - 3, 6, 6, cAccent)
            end
        end

        function SKIN:PaintMenuSpacer(panel, w, h)
            surface.SetDrawColor(cBorder)
            surface.DrawRect(0, 0, w, h)
        end

        function SKIN:PaintTooltip(panel, w, h)
            draw.RoundedBox(4, 0, 0, w, h, cBack)
            surface.SetDrawColor(cBorder)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        -- ----- tabs (the Q menu tabs) -----
        function SKIN:PaintTab(panel, w, h)
            if panel:IsActive() then
                draw.RoundedBoxEx(4, 0, 0, w, h, cHeader, true, true, false, false)
                surface.SetDrawColor(cAccent)
                surface.DrawRect(2, 0, w - 4, 2)
            else
                draw.RoundedBoxEx(4, 0, 2, w, h - 2, cButton, true, true, false, false)
            end
        end

        function SKIN:PaintPropertySheet(panel, w, h)
            local active = panel:GetActiveTab()
            local offset = 0
            if active then offset = active:GetTall() - 8 end
            draw.RoundedBox(4, 0, offset, w, h - offset, cPanel)
        end

        -- ----- lists, trees, categories -----
        function SKIN:PaintListView(panel, w, h)
            if not panel.m_bBackground then return end
            draw.RoundedBox(0, 0, 0, w, h, cEntry)
        end

        function SKIN:PaintListViewLine(panel, w, h)
            local col = cBack
            if panel:IsSelected() then
                col = cDown
            elseif panel.Hovered then
                col = cHover
            elseif panel.m_bAlt then
                col = cPanel
            end
            draw.RoundedBox(0, 0, 0, w, h, col)
        end

        function SKIN:PaintSelection(panel, w, h)
            draw.RoundedBox(4, 0, 0, w, h, cSelect)
        end

        function SKIN:PaintTree(panel, w, h)
            if not panel.m_bBackground then return end
            draw.RoundedBox(4, 0, 0, w, h, cEntry)
        end

        function SKIN:PaintTreeNodeButton(panel, w, h)
            if panel.m_bSelected then
                draw.RoundedBox(0, 0, 0, w, h, cDown)
            elseif panel.Hovered then
                draw.RoundedBox(0, 0, 0, w, h, cHover)
            end
        end

        function SKIN:PaintCategoryList(panel, w, h)
            draw.RoundedBox(4, 0, 0, w, h, cBack)
        end

        function SKIN:PaintCollapsibleCategory(panel, w, h)
            if h < 21 then
                draw.RoundedBox(4, 0, 0, w, h, cHeader)
                return
            end
            draw.RoundedBoxEx(4, 0, 0, w, 21, cHeader, true, true, false, false)
            surface.SetDrawColor(cPanel)
            surface.DrawRect(0, 21, w, h - 21)
        end

        function SKIN:PaintCategoryButton(panel, w, h)
            local col = panel.AltLine and cPanel or cBack
            if panel.Depressed or panel.m_bSelected then
                col = cDown
            elseif panel.Hovered then
                col = cHover
            end
            draw.RoundedBox(0, 0, 0, w, h, col)
        end

        -- ----- scroll bars -----
        function SKIN:PaintVScrollBar(panel, w, h)
            draw.RoundedBox(0, 0, 0, w, h, cEntry)
        end

        function SKIN:PaintScrollBarGrip(panel, w, h)
            local col = cButton
            if panel.Depressed then
                col = cDown
            elseif panel.Hovered then
                col = cHover
            end
            draw.RoundedBox(4, 0, 0, w, h, col)
        end

        local function ScrollArrow(dir)
            return function(self, panel, w, h)
                draw.RoundedBox(0, 0, 0, w, h,
                    panel.Depressed and cDown or (panel.Hovered and cHover or cButton))

                local cx, cy, s = w / 2, h / 2, math.min(w, h) * 0.22
                local pts
                if dir == "up" then
                    pts = { { x = cx, y = cy - s }, { x = cx + s, y = cy + s }, { x = cx - s, y = cy + s } }
                elseif dir == "down" then
                    pts = { { x = cx - s, y = cy - s }, { x = cx + s, y = cy - s }, { x = cx, y = cy + s } }
                elseif dir == "left" then
                    pts = { { x = cx - s, y = cy }, { x = cx + s, y = cy - s }, { x = cx + s, y = cy + s } }
                else
                    pts = { { x = cx + s, y = cy }, { x = cx - s, y = cy + s }, { x = cx - s, y = cy - s } }
                end

                draw.NoTexture()
                surface.SetDrawColor(cText)
                surface.DrawPoly(pts)
            end
        end
        SKIN.PaintButtonUp    = ScrollArrow("up")
        SKIN.PaintButtonDown  = ScrollArrow("down")
        SKIN.PaintButtonLeft  = ScrollArrow("left")
        SKIN.PaintButtonRight = ScrollArrow("right")

        derma.DefineSkin("RandomEventsDark", "Dark gray with a green tint", SKIN)
    end

    local darkSkinState = nil -- nil = not built yet, true = ready, false = failed

    local function EnsureDarkSkin()
        if darkSkinState ~= nil then return darkSkinState end
        if not (derma and derma.GetNamedSkin and derma.DefineSkin) then return false end

        local base = derma.GetNamedSkin("Default")
        if not base then return false end -- too early, try again later

        darkSkinState = true -- set early so nothing can loop
        local ok, err = pcall(BuildDarkSkin, base)
        if not ok then
            darkSkinState = false
            print("[RandomEvents] Dark theme failed: " .. tostring(err))
        end
        return darkSkinState
    end

    -- tell Garry's Mod to use our skin
    hook.Add("ForceDermaSkin", "RE_DarkSkin", function()
        if cvDarkTheme:GetBool() and EnsureDarkSkin() then
            return "RandomEventsDark"
        end
    end)

    -- (second way, in case the hook above is not used by the game)
    if derma and derma.GetDefaultSkin and not derma.RE_Patched then
        derma.RE_Patched = true
        local oldGetDefaultSkin = derma.GetDefaultSkin

        derma.GetDefaultSkin = function(...)
            if cvDarkTheme:GetBool() and EnsureDarkSkin() then
                local skin = derma.GetNamedSkin("RandomEventsDark")
                if skin then return skin end
            end
            return oldGetDefaultSkin(...)
        end
    end

    local function RefreshSkins()
        if derma and derma.RefreshSkins then derma.RefreshSkins() end
    end

    cvars.AddChangeCallback("re_dark_theme", function() RefreshSkins() end, "RE_DarkTheme")

    hook.Add("InitPostEntity", "RE_RefreshSkins", function()
        timer.Simple(1, RefreshSkins)
    end)

    -- ---------- dark green tint on the whole game picture ----------
    hook.Add("RenderScreenspaceEffects", "RE_DarkWorld", function()
        if not cvDarkWorld:GetBool() then return end

        DrawColorModify({
            ["$pp_colour_addr"] = -0.01,
            ["$pp_colour_addg"] = 0.01,
            ["$pp_colour_addb"] = -0.005,
            ["$pp_colour_brightness"] = -0.05,
            ["$pp_colour_contrast"] = 1.1,
            ["$pp_colour_colour"] = 0.7,
            ["$pp_colour_mulr"] = 0,
            ["$pp_colour_mulg"] = 0.02,
            ["$pp_colour_mulb"] = 0,
        })
    end)

    -- EMERGENCY BUTTON: if anything ever gets stuck, type  re_fix  in the console
    -- (or /fix in chat). It closes every menu, ends the cutscene, stops the music
    -- and releases all held keys.
    concommand.Add("re_fix", function()
        cutscene = nil
        introLockUntil = 0
        allowStandard = false
        CloseEscMenu(true)
        if IsValid(optPanel) then optPanel:Remove() end
        wsOpen = false
        if IsValid(sbPanel) then
            sbPanel.open = false
            sbPanel:SetVisible(false)
        end
        StopMusic(0)

        if IsValid(weaponPanel) then weaponPanel:Remove() end
        if IsValid(panel) then panel:Remove() end

        gui.EnableScreenClicker(false)

        local ply = LocalPlayer()
        if IsValid(ply) then
            for _, cmd in ipairs({
                "-forward", "-back", "-moveleft", "-moveright", "-jump",
                "-duck", "-speed", "-walk", "-attack", "-attack2", "-use"
            }) do
                ply:ConCommand(cmd)
            end
        end

        chat.AddText(Color(80, 220, 120), "[RandomEvents] ",
            Color(255, 255, 255), "Everything was reset.")
    end)

    print("[RandomEvents] Loaded on client!")
end
