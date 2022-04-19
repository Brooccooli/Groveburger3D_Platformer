local g3d = require "g3d"

function applyGravity(dt)
    if zVel == 0 then
        jumpTimer = maxJumpTimer
    else
        jumpTimer = jumpTimer - dt
    end

    zVel = zVel - (gravity * dt)
end

function controlls(dt)
    applyGravity(dt)


    local newPos = {x = 0, y = 0, z = 0}

    if love.keyboard.isDown('w') then
        newPos.x, newPos.y = newPos.x - (math.cos(playerRot.z) * moveSpeed), newPos.y - (math.sin(playerRot.z) * moveSpeed)
    elseif love.keyboard.isDown('s') then
        newPos.x, newPos.y = newPos.x + (math.cos(playerRot.z) * moveSpeed), newPos.y + (math.sin(playerRot.z) * moveSpeed)
    end

    if love.keyboard.isDown('a') then
        newPos.x, newPos.y = newPos.x + (math.sin(playerRot.z) * moveSpeed), newPos.y - (math.cos(playerRot.z) * moveSpeed)
    elseif love.keyboard.isDown('d') then
        newPos.x, newPos.y = newPos.x - (math.sin(playerRot.z) * moveSpeed), newPos.y + (math.cos(playerRot.z) * moveSpeed)
    end
    local speedMod = 20

    if zVel <= 0.01 then speedMod = speedMod * math.max(1.1, math.min(math.abs(zVel * 5), 3)) end

    newPos.x, newPos.y = newPos.x * (speedMod  * dt), newPos.y * (speedMod * dt)

    playerPos.x, playerPos.y, playerPos.z = playerPos.x + newPos.x * dt, playerPos.y + newPos.y * dt, playerPos.z + newPos.z * dt

    if love.keyboard.isDown('space') and jumpTimer > 0 then
        zVel = jumpStrength * dt
        jumpTimer = 0
    end

    -- Rotation
    playerRot.z, mY = playerRot.z - ((love.mouse.getX() - 100) * 0.01), math.max(0, math.min((love.mouse.getY() - 200) * 0.05, 100)) * 0.1

    player:setTranslation(playerPos.x, playerPos.y, playerPos.z)
    player:setRotation(playerRot.x, playerRot.y, playerRot.z + faceOffset)
    g3d.camera.lookAt(playerPos.x + math.cos(playerRot.z) * ((5 - mY) + (2 * cameraZoom)), playerPos.y + math.sin(playerRot.z) * ((5 - mY) + (2 * cameraZoom)), playerPos.z + ((mY * 2) * cameraZoom * 3), playerPos.x, playerPos.y, playerPos.z)

    -- Reset mouse x
    love.mouse.setX(100)
end