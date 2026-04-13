-- states/arrivance.lua
local scene = {}

-- Variables spécifiques au train
local position_x = 0

function scene.load()
    -- On charge les images du train ici
    position_x = 50
end

function scene.update(dt)
    -- On fait bouger le joueur ou le décor
    if love.keyboard.isDown("right") then
        position_x = position_x + 100 * dt
    end
    
    -- CONDITION DE CHANGEMENT DE PIÈCE :
    -- Si le joueur arrive au bout de l'écran, on entre dans le musée !
    if position_x > 350 then
        change_scene("hall") -- On appelle la fonction du main.lua
    end
end

function scene.draw(screen_name)
    if screen_name == "top" then
        love.graphics.setColor(0.2, 0.5, 0.8) -- Bleu ciel
        love.graphics.print("TCHOU TCHOU ! (Fleche droite pour sortir)", 10, 10)
        
        -- Notre "joueur" pour l'instant
        love.graphics.setColor(1, 0, 0)
        love.graphics.rectangle("fill", position_x, 100, 30, 50)
    else
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("Inventaire ou carte du train ici", 10, 10)
    end
end

return scene