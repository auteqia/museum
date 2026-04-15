local state = {}

-- Variables spécifiques à cette salle
local mapData
local tilesetImage
local quads = {}

-- ==========================================
-- FONCTION LOCALE DE DESSIN
-- ==========================================
local function drawMap()
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

-- ==========================================
-- CHARGEMENT DE LA SALLE
-- ==========================================
function state.load()
    -- 1. On charge la carte du musée et son tileset 
    mapData = require("assets.lua.museum") 
    tilesetImage = love.graphics.newImage("assets/tileset/interiors_free_16x16.png")
    
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
end

-- ==========================================
-- LOGIQUE DE LA SALLE (60 FPS)
-- ==========================================
function state.update(dt)
    local dx, dy = 0, 0
    
    -- Contrôles PC (Mac)
    if not is_3ds then
        if love.keyboard and love.keyboard.isDown then
            if love.keyboard.isDown("right") then dx = 1 end
            if love.keyboard.isDown("left") then dx = -1 end
            if love.keyboard.isDown("down") then dy = 1 end
            if love.keyboard.isDown("up") then dy = -1 end
        end
    end
    
    -- Contrôles 3DS (Circle Pad)
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        local joy = joysticks[1]
        if math.abs(joy:getAxis(1)) > 0.2 then dx = joy:getAxis(1) end
        if math.abs(joy:getAxis(2)) > 0.2 then dy = joy:getAxis(2) end
    end
    
    local next_x = player.x + dx * player.speed * dt
    local next_y = player.y + dy * player.speed * dt

-- ==========================================
    -- GESTION DES COLLISIONS ET DES PORTES
    -- ==========================================
    local is_colliding = false
    local p_w, p_h = 40, 40 -- Taille réelle du joueur à l'écran
    local p_x = next_x - 20
    local p_y = next_y - 20

    for _, layer in ipairs(mapData.layers) do
        if layer.name == "Collisions" and layer.type == "objectgroup" then
            for _, obj in ipairs(layer.objects) do
                -- ON MULTIPLIE ICI POUR CORRESPONDRE AU DESSIN (Zoom x2)
                local m_x = obj.x * 2 
                local m_y = obj.y * 2
                local m_w = obj.width * 2
                local m_h = obj.height * 2

                if checkCollision(p_x, p_y, p_w, p_h, m_x, m_y, m_w, m_h) then
                    if obj.name == "vers_train" then
                        -- On te téléporte dans le train (Coordonnées RÉELLES)
                        change_scene("train", 400, 240) 
                        return -- On arrête tout de suite pour éviter les bugs
                    else
                        is_colliding = true
                    end
                end
            end
        end
    end

    if not is_colliding then
        player.x = next_x
        player.y = next_y
    end
end


function state.draw(screen_name)
    if screen_name ~= "bottom" then
        local cam_x = player.x - 200
        local cam_y = player.y - 120

        love.graphics.push()
        love.graphics.translate(-math.floor(cam_x), -math.floor(cam_y))

        -- Dessin de la carte et du joueur
        love.graphics.setColor(1, 1, 1)
        drawMap() 
        
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", player.x, player.y, 20)
        love.graphics.pop()
        
    else
        -- Écran du bas : Interface spécifique au musée
        love.graphics.setColor(0.15, 0.15, 0.2)
        love.graphics.rectangle("fill", 0, 0, 320, 240)

        love.graphics.setColor(1, 1, 1)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle("line", 5, 5, 310, 230)

        love.graphics.print("Lieu : Le Musee", 20, 20)
        love.graphics.print("Inventaire :", 20, 60)
        love.graphics.setColor(0.6, 0.6, 0.6)
        love.graphics.print("- Billet d'entree", 40, 80)



        -- debug
        love.graphics.setColor(1, 1, 0) -- Texte en jaune
        love.graphics.print("--- DEBUG ---", 20, 110)
        love.graphics.print("X Joueur : " .. math.floor(player.x), 20, 130)
        love.graphics.print("Y Joueur : " .. math.floor(player.y), 20, 150)



        -- Gestion du tactile
        if is_touching then
            love.graphics.setColor(0, 0.5, 1)
            love.graphics.circle("fill", touch_x, touch_y, 10)
        end
    end
end

return state