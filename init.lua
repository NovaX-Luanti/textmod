local SAVE_FILE = minetest.get_worldpath() .. "/textmod_data.ft"
local MAX_TEXTS = tonumber(minetest.settings:get("textmod_max_texts") or 100)
local DEFAULT_RANGE = tonumber(minetest.settings:get("textmod_default_range") or 200)
local text_entities = {}

-- Only accept HEX color codes
local function parse_color(c)
    if c and c:match("^#%x%x%x%x%x%x$") then
        return c
    end
    return "#FFFFFF"
end

local function parse_pos(x, y, z)
    return {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
end

-- Save all active texts
local function save_texts()
    local file = io.open(SAVE_FILE, "w")
    if not file then return end
    for id, data in pairs(text_entities) do
        if data and data.obj and data.obj:get_luaentity() then
            local pos = data.pos
            local txt = data.obj:get_luaentity().last_text or ""
            local color = data.obj:get_luaentity().last_color or "#FFFFFF"
            txt = txt:gsub("\n", "\\n") -- escape newlines
            file:write(id .. "|" .. pos.x .. "|" .. pos.y .. "|" .. pos.z .. "|" .. color .. "|" .. txt .. "\n")
        end
    end
    file:close()
end

-- Load texts from file
local function load_texts()
    local file = io.open(SAVE_FILE, "r")
    if not file then return end
    for line in file:lines() do
        local id, x, y, z, color, txt = line:match("^(%d+)|(-?%d+%.?%d*)|(-?%d+%.?%d*)|(-?%d+%.?%d*)|(#[0-9A-Fa-f]+)|(.+)$")
        if id and x and y and z and color and txt then
            txt = txt:gsub("\\n", "\n")
            local pos = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
            local entity = minetest.add_entity(pos, "textmod:floating_text")
            if entity then
                entity:get_luaentity():set_text(txt, color)
                text_entities[tonumber(id)] = {obj = entity, pos = pos}
            end
        end
    end
    file:close()
end

minetest.register_entity("textmod:floating_text", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        pointable = false,
        visual = "cube",
        textures = {"blank.png", "blank.png", "blank.png", "blank.png", "blank.png", "blank.png"},
        visual_size = {x = 0, y = 0},
        static_save = false,
        nametag = "",
        nametag_color = "#FFFFFF",
        show_on_minimap = false,
    },

    on_activate = function(self)
        self.object:set_armor_groups({immortal = 1})
    end,

    set_text = function(self, txt, color)
        self.object:set_nametag_attributes({
            text = txt,
            color = color,
            bgcolor = "#00000000"
        })
        self.last_text = txt
        self.last_color = color
    end,
})

minetest.register_chatcommand("text", {
    params = "<x y z> <#color> [range] \"text\"",
    description = "Spawn floating text at coordinates or above yourself",
    privs = {shout = true},
    func = function(name, param)
        local text = param:match("\"(.-)\"")
        if not text then
            return false, "Text must be in quotes."
        end

        text = text:gsub("\\n", "\n")
        local args = {}
        for token in param:gmatch("%S+") do table.insert(args, token) end

        if #text_entities >= MAX_TEXTS then
            return false, "Text limit reached (" .. MAX_TEXTS .. ")"
        end

        local pos
        local color
        local range

        if tonumber(args[1]) and tonumber(args[2]) and tonumber(args[3]) then
            -- coordinates given
            pos = parse_pos(args[1], args[2], args[3])
            color = parse_color(args[4])
            range = tonumber(args[5]) or DEFAULT_RANGE
        else
            -- no coordinates: spawn above self
            local player = minetest.get_player_by_name(name)
            if not player then return false, "You are not a valid player." end
            pos = vector.add(player:get_pos(), {x = 0, y = 2, z = 0})
            color = parse_color(args[1])
            range = tonumber(args[2]) or DEFAULT_RANGE
        end

        local entity = minetest.add_entity(pos, "textmod:floating_text")
        if entity then
            local id = #text_entities + 1
            entity:get_luaentity():set_text(text, color)
            text_entities[id] = {obj = entity, pos = pos}
            save_texts()
            return true, "Text spawned with ID #" .. id
        end

        return false, "Failed to spawn text."
    end
})

minetest.register_chatcommand("remove_text", {
    params = "<x y z | ID>",
    description = "Remove text by position or ID",
    privs = {shout = true},
    func = function(name, param)
        local args = {}
        for token in param:gmatch("%S+") do table.insert(args, token) end

        if #args == 1 and tonumber(args[1]) then
            local id = tonumber(args[1])
            local data = text_entities[id]
            if data and data.obj and data.obj:get_luaentity() then
                data.obj:remove()
                text_entities[id] = nil
                save_texts()
                return true, "Text ID #" .. id .. " removed"
            end
            return false, "ID not found"
        elseif #args == 3 then
            local pos = parse_pos(args[1], args[2], args[3])
            local removed = 0
            for id, data in pairs(text_entities) do
                if vector.equals(vector.round(data.pos), vector.round(pos)) then
                    data.obj:remove()
                    text_entities[id] = nil
                    removed = removed + 1
                end
            end
            save_texts()
            return true, removed .. " text(s) removed at position"
        end

        return false, "Usage: /remove_text <ID> or /remove_text <x y z>"
    end
})

-- Auto-load at startup
minetest.register_on_mods_loaded(function()
    minetest.after(1, load_texts)
end)

-- Save on shutdown
minetest.register_on_shutdown(function()
    save_texts()
end)
