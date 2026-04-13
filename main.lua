-- Variable qui stocke la scène actuelle
local current_scene = nil
local sti = require("libs.sti") -- Attention : Utilise un point au lieu d'un slash !

local map

-- Fonction qui vérifie si deux rectangles se touchent
function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end

function love.load()
    is_3ds = (love.system.getOS() == "Horizon")
    
    -- On charge la carte !
    map = sti("assets/lua/forest.lua")
    
    player = {}
    player.x = 200
    player.y = 120
    player.speed = 200

    -- On garde ça désactivé pour l'instant
    -- player.sprite = love.graphics.newImage("sprites/jeanne.png")
    
    touch_x, touch_y = 0, 0
    is_touching = false
end

function change_scene(scene_name)
    current_scene = require("states." .. scene_name)
    if current_scene.load then 
        current_scene.load() 
    end
end

function love.update(dt)
    -- 1. Mise à jour de la map (indispensable pour STI)
    if map then map:update(dt) end

    -- 2. Récupération des directions (Clavier + Circle Pad)
    local dx, dy = 0, 0
    
    -- Clavier (Mac)
    if love.keyboard.isDown("right") then dx = 1 end
    if love.keyboard.isDown("left") then dx = -1 end
    if love.keyboard.isDown("down") then dy = 1 end
    if love.keyboard.isDown("up") then dy = -1 end
    
    -- Circle Pad (3DS)
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        local joy = joysticks[1]
        -- On ne prend en compte le joystick que s'il sort de la "deadzone" (0.2)
        if math.abs(joy:getAxis(1)) > 0.2 then dx = joy:getAxis(1) end
        if math.abs(joy:getAxis(2)) > 0.2 then dy = joy:getAxis(2) end
    end
    
    -- 3. Calcul de la position théorique (où le joueur veut aller)
    local next_x = player.x + dx * player.speed * dt
    local next_y = player.y + dy * player.speed * dt
    
    -- 4. Gestion des collisions
    local is_colliding = false
    
    -- Taille de la "boîte" de notre joueur (notre cercle fait 20 de rayon, donc 40x40)
    local p_w, p_h = 40, 40
    local p_x = next_x - 20
    local p_y = next_y - 20

    -- On boucle sur les objets du calque "Collisions" de Tiled
    if map.layers["Collisions"] then
        for i, obj in ipairs(map.layers["Collisions"].objects) do
            -- On multiplie les coordonnées de Tiled par 2 
            -- parce qu'on dessine la map avec un zoom de 2 dans love.draw
            local m_x = obj.x * 2
            local m_y = obj.y * 2
            local m_w = obj.width * 2
            local m_h = obj.height * 2

            -- Si la future position du joueur touche ce rectangle
            if checkCollision(p_x, p_y, p_w, p_h, m_x, m_y, m_w, m_h) then
                is_colliding = true
                break -- On s'arrête dès qu'on touche un mur
            end
        end
    end

    -- 5. Application du mouvement seulement si le chemin est libre
    if not is_colliding then
        player.x = next_x
        player.y = next_y
    end

    -- 6. Gestion du tactile (Ecran du bas)
    if love.mouse.isDown(1) then
        is_touching = true
        local mx, my = love.mouse.getPosition()
        
        -- Si on est sur Mac, on adapte les coordonnées du simulateur
        if not is_3ds then
            touch_x = mx - 40
            touch_y = my - 260
        else
            touch_x, touch_y = mx, my
        end
    else
        is_touching = false
    end
end

function draw_content(screen_name)
    if screen_name == "top" then
        -- 1. ON REMET EN BLANC POUR LES VRAIES COULEURS DE LA FORÊT
        love.graphics.setColor(1, 1, 1)
        
        -- 2. ON DESSINE LA CARTE (zoomée x2 pour le style rétro)
        if map then map:draw(0, 0, 2, 2) end
        
        -- 3. On dessine ton personnage (le cercle vert pour l'instant)
        love.graphics.setColor(0, 1, 0)
        love.graphics.circle("fill", player.x, player.y, 20)
        
        -- 4. Le texte par-dessus
        love.graphics.setColor(1, 1, 1)
        
    else
        love.graphics.setColor(1, 0, 0)
        
        -- CORRECTION : J'ai désactivé cette ligne car player.sprite est vide (nil) !
        -- love.graphics.draw(player.sprite, player.x, player.y)
        
        if is_touching then
            love.graphics.setColor(0, 0.5, 1)
            love.graphics.circle("fill", touch_x, touch_y, 10)
        end

    end
end

function love.draw(screen)
    if is_3ds then
        draw_content(screen)
    else
        love.graphics.push()
            draw_content("top")
        love.graphics.pop()
        
        love.graphics.push()
            love.graphics.translate(40, 260)
            draw_content("bottom")
        love.graphics.pop()
    end
end