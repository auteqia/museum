-- Variable qui stocke la scène actuelle
local current_scene = nil

function love.load()
    is_3ds = (love.system.getOS() == "Horizon")
    
    player = {}
    -- Position de notre balle
    player.x = 200
    player.y = 120
    player.speed = 200 -- Vitesse en pixels par seconde

   -- player.sprite = love.graphics.newImage("sprites/jeanne.png")
    
    -- Couleur de fond pour l'écran du bas
    touch_x, touch_y = 0, 0
    is_touching = false
end



-- Fonction magique pour changer de pièce
function change_scene(scene_name)
    -- On charge le fichier correspondant dans le dossier 'states'
    current_scene = require("states." .. scene_name)
    -- Si la scène a besoin de charger des trucs (images, positions), on le fait
    if current_scene.load then 
        current_scene.load() 
    end
end


function love.update(dt)
    local dx, dy = 0, 0
    
    if love.keyboard.isDown("right") then 
        dx = 1 
    end

    if love.keyboard.isDown("left") then 
        dx = -1    
    end


    if love.keyboard.isDown("down") then
         dy = 1
    end


    if love.keyboard.isDown("up") then 
        dy = -1 
    end
    
    local joysticks = love.joystick.getJoysticks()
    if #joysticks > 0 then
        local joy = joysticks[1]
        -- L'axe 1 est horizontal, l'axe 2 est vertical
        dx = joy:getAxis(1)
        dy = joy:getAxis(2)
    end
    
    player.x = player.x + dx * player.speed * dt
    player.y = player.y + dy * player.speed * dt

    -- 2. GESTION DU TACTILE (Stylet / Souris)
    if love.mouse.isDown(1) then
        is_touching = true
        local mx, my = love.mouse.getPosition()
        
        -- Sur Mac, on doit soustraire le décalage de notre simulateur
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
        love.graphics.setColor(0, 1, 0)
        love.graphics.print("Utilise les fleches ou le Circle Pad !", 10, 10)
        love.graphics.circle("fill", player.x, player.y, 20)
    else
        love.graphics.setColor(1, 0, 0)
        love.graphics.print("Touche l'ecran avec le stylet !", 10, 10)
        love.graphics.draw(player.sprite, player.x, player.y)
        -- Si on touche l'écran, on dessine un petit point bleu
        if is_touching then
            love.graphics.setColor(0, 0.5, 1)
            love.graphics.circle("fill", touch_x, touch_y, 10)
        end
        love.graphics.rectangle("line", 0, 0, 320, 240)
    end
end

function love.draw(screen)
    if is_3ds then
        draw_content(screen)
    else
        -- Affichage simulé sur Mac
        love.graphics.push()
            draw_content("top")
        love.graphics.pop()
        
        love.graphics.push()
            love.graphics.translate(40, 260)
            draw_content("bottom")
        love.graphics.pop()
    end
end