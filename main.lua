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
    
    -- 1. On charge la carte directement comme un simple fichier LUA
    mapData = require("assets.lua.forest")
    
    -- 2. On charge l'image (LÖVE Potion chargera le .t3x en cachette sur 3DS)
    tilesetImage = love.graphics.newImage("assets/tileset/forest.png")
    
    -- 3. LA MAGIE : On découpe le Tileset en petits carrés (Quads)
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
    
    -- Initialisation du joueur
    player.x = 200
    player.y = 120
    player.speed = 200
end

-- Notre propre fonction d'affichage ultra-optimisée
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
    
    -- 1. CONTRÔLES MAC (Clavier) - Protégé pour la 3DS !
    if not is_3ds then
        if love.keyboard and love.keyboard.isDown then
            if love.keyboard.isDown("right") then dx = 1 end
            if love.keyboard.isDown("left") then dx = -1 end
            if love.keyboard.isDown("down") then dy = 1 end
            if love.keyboard.isDown("up") then dy = -1 end
        end
    end
    
    -- 2. CONTRÔLES 3DS (Circle Pad)
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        local joy = joysticks[1]
        if math.abs(joy:getAxis(1)) > 0.2 then dx = joy:getAxis(1) end
        if math.abs(joy:getAxis(2)) > 0.2 then dy = joy:getAxis(2) end
    end
    
    local next_x = player.x + dx * player.speed * dt
    local next_y = player.y + dy * player.speed * dt
    
    -- 3. GESTION DES COLLISIONS (Adaptée pour notre code maison)
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

    -- 4. GESTION DE L'ÉCRAN TACTILE
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
    -- Astuce : On ne cherche plus "top", on dit "tout ce qui n'est pas le bas" !
    if screen_name ~= "bottom" then
        -- 1. Écran du haut (que la 3DS l'appelle "top", "left" ou "right")
        love.graphics.setColor(1, 1, 1)
        drawMap() 
        
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", player.x, player.y, 20)
        
    else
        -- 2. Écran du bas ("bottom")
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