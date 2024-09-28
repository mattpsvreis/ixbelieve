PLUGIN.name = "Event Characters"
PLUGIN.author = "Xalphox"
PLUGIN.description = "Facilitates event characters"

ix.eventCharacters = ix.eventCharacters or {}

ix.char.RegisterVar("event", {
	field = "event",
	fieldType = ix.type.number,
	default = 0,
	isLocal = true,
	bNoDisplay = true,
  bNoNetworking = true
})

CAMI.RegisterPrivilege({
  Name = "Helix - Event Character Tool",
  MinAccess = "admin",
  Description = "Allows to use the event character tool to store and switch between characters."
})
net.Receive("ix.eventcharacters.apply", function (len, ply)
  if (!CAMI.PlayerHasAccess(ply, "Helix - Event Character Tool")) then return end
  --name, description, model, steamID, faction
  local name = net.ReadString()
  local model = net.ReadString()
  local faction = net.ReadString()
  local desc = net.ReadString()


  local query = mysql:Select("ix_characters")
  query:Select("id")

  query:Where("schema", Schema.folder)
  query:Where("name", name)

  query:Callback(function(result)
    if table.Count(result) == 0 then
      -- create a new character and then load it
      ix.eventCharacters.Create({name = name, description = desc, model = model, steamID = -1, faction = faction},
      function (id)
        timer.Simple(3.0, function ()
          ix.eventCharacters.forceCharacter(ply, tonumber(id), {model = model, description = desc, faction = faction})
        end)
      end, ply)
    else
      -- load the existing character
      ix.eventCharacters.forceCharacter(ply, tonumber(result[1].id), {model = model, description = desc, faction = faction})
    end
  end)
  query:Execute()

end)

function ix.eventCharacters.Create(data, callback, client)
  local timeStamp = math.floor(os.time())

  data.money = data.money or ix.config.Get("defaultMoney", 0)
  data.schema = Schema and Schema.folder or "helix"
  data.createTime = timeStamp
  data.lastJoinTime = timeStamp
  data.data = data.data or {}

  local query = mysql:Insert("ix_characters")
    query:Insert("name", data.name or "")
    query:Insert("description", data.description or "")
    query:Insert("model", data.model or "models/error.mdl")
    query:Insert("schema", Schema and Schema.folder or "helix")
    query:Insert("create_time", data.createTime)
    query:Insert("last_join_time", data.lastJoinTime)
    query:Insert("steamid", data.steamID)
    query:Insert("faction", data.faction or "Unknown")
    query:Insert("money", data.money)
    query:Insert("data", util.TableToJSON(data.data))
    query:Insert("event", 1)
    query:Callback(function(result, status, lastID)
      local invQuery = mysql:Insert("ix_inventories")
        invQuery:Insert("character_id", lastID)
        invQuery:Callback(function(invResult, invStats, invLastID)
          ix.char.RestoreVars(data, data)

          local w, h = ix.config.Get("inventoryWidth"), ix.config.Get("inventoryHeight")
          local character = ix.char.New(data, lastID, client, data.steamID)
          local inventory = ix.item.CreateInv(w, h, invLastID)

          character.vars.inv = {inventory}
          inventory:SetOwner(lastID)

          ix.char.loaded[lastID] = character
          --table.insert(ix.char.cache[data.steamID], lastID)

          if (callback) then
            callback(lastID)
          end
        end)
      invQuery:Execute()
    end)
  query:Execute()
end

--- Loads all of a player's characters into memory.
-- @realm server
-- @player client Player to load the characters for
-- @func[opt=nil] callback Function to call when the characters have been loaded
-- @bool[opt=false] bNoCache Whether or not to skip the cache; players that leave and join again later will already have
-- their characters loaded which will skip the database query and load quicker
-- @number[opt=nil] id The ID of a specific character to load instead of all of the player's characters
function ix.eventCharacters.restoreEventCharacter(client, callback, id)
  local steamID64 = -1
  local cache = ix.char.cache[steamID64]
  local bNoCache = true

  if (cache and !bNoCache) then
    for _, v in ipairs(cache) do
      local character = ix.char.loaded[v]

      if (character and !IsValid(character.client)) then
        character.player = client
      end
    end

    if (callback) then
      callback(cache)
    end

    return
  end

  local query = mysql:Select("ix_characters")
    query:Select("id")

    ix.char.RestoreVars(query)

    query:Where("schema", Schema.folder)
    query:Where("id", id)

    query:Callback(function(result)
      local characters = {}

      for _, v in ipairs(result or {}) do
        local charID = tonumber(v.id)

        if (charID) then
          local data = {
            steamID = steamID64
          }

          ix.char.RestoreVars(data, v)

          characters[#characters + 1] = charID
          local character = ix.char.New(data, charID, client)

          hook.Run("CharacterRestored", character)
          character.vars.inv = {
            [1] = -1,
          }

          local invQuery = mysql:Select("ix_inventories")
            invQuery:Select("inventory_id")
            invQuery:Select("inventory_type")
            invQuery:Where("character_id", charID)
            invQuery:Callback(function(info)
              if (istable(info) and #info > 0) then
                local inventories = {}

                for _, v2 in pairs(info) do
                  if (v2.inventory_type and isstring(v2.inventory_type) and v2.inventory_type == "NULL") then
                    v2.inventory_type = nil
                  end

                  if (hook.Run("ShouldRestoreInventory", charID, v2.inventory_id, v2.inventory_type) != false) then
                    local w, h = ix.config.Get("inventoryWidth"), ix.config.Get("inventoryHeight")
                    local invType

                    if (v2.inventory_type) then
                      invType = ix.item.inventoryTypes[v2.inventory_type]

                      if (invType) then
                        w, h = invType.w, invType.h
                      end
                    end

                    inventories[tonumber(v2.inventory_id)] = {w, h, v2.inventory_type}
                  end
                end

                ix.item.RestoreInv(inventories, nil, nil, function(inventory)
                  local inventoryType = inventories[inventory:GetID()][3]

                  if (inventoryType) then
                    inventory.vars.isBag = inventoryType
                    table.insert(character.vars.inv, inventory)
                  else
                    character.vars.inv[1] = inventory
                  end

                  inventory:SetOwner(charID)

                  if (callback) then
                    callback(characters)
                  end
                end, true)
              else
                local insertQuery = mysql:Insert("ix_inventories")
                  insertQuery:Insert("character_id", charID)
                  insertQuery:Callback(function(_, status, lastID)
                    local w, h = ix.config.Get("inventoryWidth"), ix.config.Get("inventoryHeight")
                    local inventory = ix.item.CreateInv(w, h, lastID)
                    inventory:SetOwner(charID)

                    character.vars.inv = {
                      inventory
                    }

                    if (callback) then
                      callback(characters)
                    end
                  end)
                insertQuery:Execute()
              end
            end)
          invQuery:Execute()

          ix.char.loaded[charID] = character
        else
          ErrorNoHalt("[Helix] Attempt to load character with invalid ID '" .. tostring(id) .. "'!")
        end
      end

      ix.char.cache[steamID64] = characters
    end)
  query:Execute()
end

if SERVER then
  function ix.eventCharacters.forceCharacter(client, id, data)
    data = data or {}
    local pos = client:GetPos()
    ix.eventCharacters.restoreEventCharacter(client, function (character)
      local character = ix.char.loaded[id]

      if (character) then
        local currentChar = client:GetCharacter()

        if (currentChar) then
          currentChar:Save()

          for _, v in ipairs(currentChar:GetInventory(true)) do
            if (istable(v)) then
              v:RemoveReceiver(client)
            end
          end
        end

        hook.Run("PrePlayerLoadedCharacter", client, character, currentChar)
        character.player = client

        character:Setup()

        if data.description then
          character:SetDescription(data.description)
        end

        if data.model then
          character:SetModel(data.model)
        end

        if data.faction then
          character:SetFaction(ix.faction.teams[data.faction].index)
        end

        client:Spawn()
        client:SetPos(pos)


        hook.Run("PlayerLoadedCharacter", client, character, currentChar)
      else
        net.Start("ixCharacterLoadFailure")
          net.WriteString("@unknownError")
        net.Send(client)

        ErrorNoHalt("[Helix] Attempt to load invalid character '" .. id .. "'\n")
      end
    end,
    id)
  end

  concommand.Add("ix_forcechar", function (client, cmd, args)
    if (!IsValid(client) or !CAMI.PlayerHasAccess(client, "Helix - Event Character Tool")) then return end

    local id = tonumber(args[1])
    ix.eventCharacters.forceCharacter(client, id)
  end)

--[[
  hook.Add("PlayerLoadedCharacter", "ix.eventcharacters.PlayerLoadedCharacter", function (ply, chr, oldchr)
    if oldChr.singleUse then
      local id = oldChr.id
      ix.char.loaded[id] = nil

      net.Start("ixCharacterDelete")
        net.WriteUInt(id, 32)
      net.Broadcast()

      -- remove character from database
      local query = mysql:Delete("ix_characters")
        query:Where("id", id)
        query:Where("steamid", -1)
      query:Execute()

      -- DBTODO: setup relations instead
      -- remove inventory from database
      query = mysql:Select("ix_inventories")
        query:Select("inventory_id")
        query:Where("character_id", id)
        query:Callback(function(result)
          if (istable(result)) then
            -- remove associated items from database
            for _, v in ipairs(result) do
              local itemQuery = mysql:Delete("ix_items")
                itemQuery:Where("inventory_id", v.inventory_id)
              itemQuery:Execute()

              ix.item.inventories[tonumber(v.inventory_id)] = nil
            end
          end

          local invQuery = mysql:Delete("ix_inventories")
            invQuery:Where("character_id", id)
          invQuery:Execute()
        end)
      query:Execute()
    end
  end)--]]

  util.AddNetworkString("ix.eventcharacters.apply")
end
