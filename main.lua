-- Variable qui stocke la scène actuelle
local current_scene = nil

-- Variables globales
local mapData
local tilesetImage
local quads = {} -- Va stocker chaque petit morceau de l'image
local player = {}
local touch_x, touch_y = 0, 0
local is_touching = false
local is_3ds = false

-- Fonction qui vérifie si deux rectangles se touchent
function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function love.load()
    is_3ds = (love.system.getOS() == "Horizon")
    
    mapData = require("assets.lua.forest")
    
    --  loading the image but in reality the 3ds will load the file in t3x format
    tilesetImage = love.graphics.newImage("assets/tileset/forest.png")
    
    -- splitting the tileset into quads (sub-images) for easy drawing later. STI lib does this for us but its a hell of a pain to adapt to the 3DS (version and so on), so we do it ourselves!
    local tileW = mapData.tilesets[1].tilewidth
    local tileH = mapData.tilesets[1].tileheight
    local imgW = mapData.tilesets[1].imagewidth
    local imgH = mapData.tilesets[1].imageheight
    
    local columns = math.floor(imgW / tileW)
    local rows = math.floor(imgH / tileH)
    
    local id = 1
    for y = 0, rows - 1 do
        for x = 0, columns - 1 do
            quads[id] = love.graphics.newQuad(x * tileW, y * tileH, tileW, tileH, imgW, imgH)
            id = id + 1
        end
    end
    
    -- player init
    player.x = 200
    player.y = 120
    player.speed = 200
end

-- STI replacement: we draw the map ourselves, layer by layer, tile by tile
-- thanks gemini lol
function drawMap()
    local tileW = mapData.tilesets[1].tilewidth
    local tileH = mapData.tilesets[1].tileheight

    for _, layer in ipairs(mapData.layers) do
        if layer.type == "tilelayer" then
            for i, gid in ipairs(layer.data) do
                if gid > 0 and quads[gid] then
                    local x = ((i - 1) % layer.width) * tileW
                    local y = math.floor((i - 1) / layer.width) * tileH
                    love.graphics.draw(tilesetImage, quads[gid], x * 2, y * 2, 0, 2, 2)
                end
            end
        end
    end
end

function change_scene(scene_name)
    current_scene = require("states." .. scene_name)
    if current_scene.load then 
        current_scene.load() 
    end
end

function love.update(dt)
    local dx, dy = 0, 0
    
    -- for computer
    if not is_3ds then
        if love.keyboard and love.keyboard.isDown then
            if love.keyboard.isDown("right") then dx = 1 end
            if love.keyboard.isDown("left") then dx = -1 end
            if love.keyboard.isDown("down") then dy = 1 end
            if love.keyboard.isDown("up") then dy = -1 end
        end
    end
    
    -- 3ds controls
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        local joy = joysticks[1]
        if math.abs(joy:getAxis(1)) > 0.2 then dx = joy:getAxis(1) end
        if math.abs(joy:getAxis(2)) > 0.2 then dy = joy:getAxis(2) end
    end
    
    local next_x = player.x + dx * player.speed * dt
    local next_y = player.y + dy * player.speed * dt


    -- collisions
    local is_colliding = false
    local p_w, p_h = 40, 40
    local p_x = next_x - 20
    local p_y = next_y - 20

    for _, layer in ipairs(mapData.layers) do
        if layer.name == "Collisions" and layer.type == "objectgroup" then
            for _, obj in ipairs(layer.objects) do
                local m_x = obj.x * 2
                local m_y = obj.y * 2
                local m_w = obj.width * 2
                local m_h = obj.height * 2

                if checkCollision(p_x, p_y, p_w, p_h, m_x, m_y, m_w, m_h) then
                    is_colliding = true
                    break
                end
            end
        end
    end

    if not is_colliding then
        player.x = next_x
        player.y = next_y
    end

    -- the 3DS has a touch screen, so we check if the player is touching it and where
    if is_3ds then
        local touches = love.touch.getTouches()
        if #touches > 0 then
            is_touching = true
            local id = touches[1]
            touch_x, touch_y = love.touch.getPosition(id)
        else
            is_touching = false
        end
    else
        if love.mouse and love.mouse.isDown and love.mouse.isDown(1) then
            is_touching = true
            local mx, my = love.mouse.getPosition()
            touch_x = mx - 40
            touch_y = my - 260
        else
            is_touching = false
        end
    end
end

function draw_content(screen_name)
    if screen_name ~= "bottom" then
        -- "top", "left" ou "right"
        love.graphics.setColor(1, 1, 1)
        drawMap() 
        
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", player.x, player.y, 20)
        
    else
        -- bottom screen
        if is_touching then
            love.graphics.setColor(0, 0.5, 1)
            love.graphics.circle("fill", touch_x, touch_y, 10)
        end
    end
end

function love.draw(screen)
    if is_3ds then
        -- LÖVE Potion boucle tout seul sur les écrans de la console et passe le bon nom
        draw_content(screen)
    else
        -- Simulation sur ton Mac
        love.graphics.push()
            draw_content("top")
        love.graphics.pop()
        
        love.graphics.push()
            love.graphics.translate(40, 260)
            draw_content("bottom")
        love.graphics.pop()
    end
end