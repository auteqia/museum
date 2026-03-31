function love.load()
    -- Détection : sommes-nous sur une vraie 3DS ou sur PC/Mac ?
    -- Sur 3DS, la variable 'screen' est passée à love.draw, sur Mac non.
    is_3ds = (love.system.getOS() == "Horizon") -- Horizon est l'OS de la 3DS
    
    -- Variables de notre jeu
    ball_x, ball_y = 200, 120
end

function love.update(dt)
    -- On pourra ajouter du code ici plus tard
end

-- Cette fonction dessine le contenu d'un écran spécifique
function draw_content(screen_name)
    if screen_name == "top" then
        love.graphics.setColor(0, 1, 0) -- Vert pour le haut
        love.graphics.print("ECRAN DU HAUT (400x240)", 10, 10)
        love.graphics.circle("fill", ball_x, ball_y, 30)
    else
        love.graphics.setColor(1, 0, 0) -- Rouge pour le bas
        love.graphics.print("ECRAN DU BAS (320x240)", 10, 10)
        love.graphics.rectangle("line", 20, 40, 280, 180)
    end
end

function love.draw(screen)
    if is_3ds then
        -- SUR LA VRAIE 3DS : On utilise le paramètre 'screen' fourni par la console
        draw_content(screen)
    else
        -- SUR LE MAC : On simule l'affichage des deux écrans
        
        -- 1. Dessiner l'écran du haut
        love.graphics.push()
            draw_content("top")
        love.graphics.pop()
        
        -- 2. Dessiner l'écran du bas (décalé vers le bas de 260 pixels)
        love.graphics.push()
            love.graphics.translate(40, 260) -- On décale un peu pour centrer
            draw_content("bottom")
        love.graphics.pop()
        
        -- Dessiner une ligne de séparation pour faire propre
        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.line(0, 250, 400, 250)
    end
end