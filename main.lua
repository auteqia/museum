-- state manager for managing different rooms/scenes in the game

-- global variable to hold the current state
player = { x = 00, y = 0, speed = 200 }
touch_x, touch_y = 0, 0
is_touching = false
is_3ds = false

-- Notre variable qui contiendra la scène active
current_state = nil

-- La fonction magique pour changer de pièce
function change_scene(scene_name, spawn_x, spawn_y)
    -- 1. On charge le nouveau fichier (ex: "states.museum")
    local new_state = require("states." .. scene_name)
    
    -- 2. On exécute sa fonction load() pour préparer sa carte et ses images
    if new_state.load then
        new_state.load()
    end
    
    -- 3. On place le joueur à son point d'apparition spécifique
    if spawn_x and spawn_y then
        player.x = spawn_x
        player.y = spawn_y
    end
    
    -- 4. On remplace officiellement la scène active
    current_state = new_state
end

function love.load()
    is_3ds = (love.system.getOS() == "Horizon")
    if not is_3ds then
        -- 400 de large, 500 de haut (240 pour l'écran du haut + 260 pour le bas)
        love.window.setMode(400, 500)
    end
    -- On démarre le jeu dans le train !
    change_scene("train", 400, 120)
end

function love.update(dt)
    -- On passe le relais à la scène active
    if current_state and current_state.update then
        current_state.update(dt)
    end
end

function draw_content(screen_name)
    -- On passe le relais à la scène active
    if current_state and current_state.draw then
        current_state.draw(screen_name)
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

-- Fonction utilitaire globale (pratique pour toutes les scènes)
function checkCollision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 < x2 + w2 and x2 < x1 + w1 and y1 < y2 + h2 and y2 < y1 + h1
end