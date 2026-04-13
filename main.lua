-- Variable qui stocke la scène actuelle
local current_scene = nil
local sti = require("libs.sti") -- Attention : Utilise un point au lieu d'un slash !

local map

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
    -- Important pour la librairie STI
    if map then map:update(dt) end

    local dx, dy = 0, 0
    
    if love.keyboard.isDown("right") then dx = 1 end
    if love.keyboard.isDown("left") then dx = -1 end
    if love.keyboard.isDown("down") then dy = 1 end
    if love.keyboard.isDown("up") then dy = -1 end
    
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        local joy = joysticks[1]
        dx = joy:getAxis(1)
        dy = joy:getAxis(2)
    end
    
    player.x = player.x + dx * player.speed * dt
    player.y = player.y + dy * player.speed * dt

    if love.mouse.isDown(1) then
        is_touching = true
        local mx, my = love.mouse.getPosition()
        
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
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("line", 0, 0, 320, 240)
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