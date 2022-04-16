-- written by groverbuger for g3d
-- september 2021
-- MIT license

local g3d = require "g3d"
require "loadLevel"
local Vector = require "g3d/vectors"

-- Player
local faceOffset = 5
local playerPos = { x = 0, y = 0, z = 30 }
local playerRot = { x = 0, y = 0, z = 0 }
local moveSpeed = 5
local rotSpeed = 2

-- jump
local jumpStrength = 20
local jumpTimer = 0
local maxJumpTimer = 0.4

local cameraZoom = 1

local gravity = 0.5
local zVel = 0

-- Settings
local fullscreen = false
local oldFKey = love.keyboard.isDown('f')

-- Debug
local debugStr = ""

function love.load()
    love.window.setMode(800, 600, {depth=1, minwidth=800, minheight=600, resizable=true})

    love.mouse.setRelativeMode(true)
    love.mouse.setGrabbed(true)
    my = 0

    gameSetup()
end

function gameSetup()
    zVel = 0
    playerPos = { x = 0, y = 0, z = 30 }
    noiseOffset = love.math.random(1, 20)
    noiseSpawn = { x = -100, y = -100 }
    noiseThreshold = 0.9
    goalIndex = love.math.random(1, 100 * 100)
    timer = 0
    local foundSpanw = false
    while (true) do
        for X = 100, 1, -1 do
            for Y = 100, 1, -1 do
                local Z = getNoise(X, Y)
                if Z >= noiseThreshold then
                    noiseSpawn.x, noiseSpawn.y = -(X * 2), -(Y * 2)
                    if love.math.random(1, 10000) == 5 then
                        return
                    end
                end
            end
        end
    end
end

function DebugWrite(str)
    love.filesystem.setIdentity("Debug")
    success, message = love.filesystem.write("Debug.txt", "3D TEST \n" .. str)
end

function love.update(dt)
    debugStr = ""

    if love.keyboard.isDown('f') and not oldFKey then
        if fullscreen then fullscreen = false else fullscreen = true end
        love.window.setFullscreen(fullscreen)
    end

    local fullscreenState = "false"
    if fullscreen then fullscreenState = "true" end
    debugStr = debugStr .. "\n Fullscreen: " .. fullscreenState 

    -- Free look
    if love.keyboard.isDown('lctrl') then
        g3d.camera.firstPersonMovement(dt)
        return
    end

    if noiseThreshold < 0.6 then
        noiseThreshold = 0.6
    else
        noiseThreshold = noiseThreshold + (dt * 0.005)
    end

    debugStr = debugStr .. "\n Threshold: " .. noiseThreshold


    if zVel == 0 then
        jumpTimer = maxJumpTimer
    else
        jumpTimer = jumpTimer - dt
    end

    zVel = zVel - (gravity * dt)

    timer = timer + dt * 0.05

    moon:setTranslation(math.cos(timer) * 5 + 4, math.sin(timer) * 5, 0)
    moon:setRotation(0, 0, timer - math.pi / 2)
    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end

    debugStr = debugStr .. "\n Player pos: " .. playerPos.x .. " " .. playerPos.y .. " " .. playerPos.z

    --playerPos.z = playerPos.z - 0.01

    checkSphereCollision()
    checkCubeCollision()

    controls(dt)

    playerPos.z = playerPos.z + zVel
    if playerPos.z < -50 then gameSetup() end

    oldFKey = love.keyboard.isDown('f')
end

function controls(dt)

    local newPos = {x = 0, y = 0, z = 0}

    if love.keyboard.isDown('w') then
        newPos.x, newPos.y = newPos.x - (math.cos(playerRot.z) * moveSpeed * dt), newPos.y - (math.sin(playerRot.z) * moveSpeed * dt)
    elseif love.keyboard.isDown('s') then
        newPos.x, newPos.y = newPos.x + (math.cos(playerRot.z) * moveSpeed * dt), newPos.y + (math.sin(playerRot.z) * moveSpeed * dt)
    end

    if love.keyboard.isDown('a') then
        newPos.x, newPos.y = newPos.x + (math.sin(playerRot.z) * moveSpeed * dt), newPos.y - (math.cos(playerRot.z) * moveSpeed * dt)
    elseif love.keyboard.isDown('d') then
        newPos.x, newPos.y = newPos.x - (math.sin(playerRot.z) * moveSpeed * dt), newPos.y + (math.cos(playerRot.z) * moveSpeed * dt)
    end
    local speedMod = 1

    if zVel <= 0.01 then speedMod = math.max(1.1, math.min(math.abs(zVel * 5), 3)) end

    debugStr = debugStr .. "\n Speed boost: " .. speedMod

    newPos.x, newPos.y = newPos.x * speedMod, newPos.y * speedMod

    playerPos.x, playerPos.y, playerPos.z = playerPos.x + newPos.x, playerPos.y + newPos.y, playerPos.z + newPos.z

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

function checkSphereCollision()
    local mag = Vector.magnitude(playerPos.x - goal:getX(), playerPos.y - goal:getY(), playerPos.z - goal:getZ())
    if mag < player.scale[1] + goal.scale[1] then
        noiseThreshold = noiseThreshold - 0.05
        goalIndex = love.math.random(1, 100 * 100)
    end
end

function checkCubeCollision()
    local newPos = {}
    newPos[1] = playerPos.x
    newPos[2] = playerPos.y
    newPos[3] = playerPos.z
    for d = 100, 1, -1 do
        for i = 100, 1, -1 do
            local Z = getNoise(d, i)
            if zVel > 0.5 then
                ground:setTranslation((d * 2) + noiseSpawn.x, (i * 2) + noiseSpawn.y, (Z * floorHeightDifference) + zVel)
            else
                ground:setTranslation((d * 2) + noiseSpawn.x, (i * 2) + noiseSpawn.y, Z * floorHeightDifference)
            end



            local mag = {}
            mag[1] = newPos[1] - ground:getX()
            mag[2] = newPos[2] - ground:getY()
            mag[3] = newPos[3] - ground:getZ()

            local cubePos = {}
            cubePos[1] = ground:getX()
            cubePos[2] = ground:getY()
            cubePos[3] = ground:getZ()

            local size = player.scale[1] + ground.scale[1]

            local lowestValue = 1000
            local ChangeIndex = 1
            local PositiveOrNegative = 0

            for j = 3, 1, -1 do

                local n1, n2 = 0, 0
                if j == 1 then n1, n2 = 1, 2
                elseif j == 2 then n1, n2 = 1, -1
                else n1, n2 = -1, -2 end

                if math.abs(mag[j]) < size and math.abs(mag[j + n1]) < size and math.abs(mag[j + n2]) < size then
                    if Z >= noiseThreshold then
                        local pushForce = player.scale[1] + ground.scale[1] - math.abs(mag[j])
                        newPos[j] = newPos[j] + ((newPos[j] - cubePos[j]) * pushForce)

                        if pushForce < lowestValue then
                            ChangeIndex = j
                            lowestValue = pushForce
                            if mag[j] > 0 then PositiveOrNegative = 1 else PositiveOrNegative = -1 end
                        end
                    else
                        gameSetup()
                    end
                end
            end

            if lowestValue == 1000 then
            elseif ChangeIndex == 1 then
                playerPos.x = playerPos.x + (math.abs(newPos[1] - playerPos.x) * PositiveOrNegative)
                zVel = 0.1

            elseif ChangeIndex == 2 then
                playerPos.y = playerPos.y + (math.abs(newPos[2] - playerPos.y) * PositiveOrNegative)
                zVel = 0.1

            else playerPos.z = playerPos.z + (math.abs(newPos[3] - playerPos.z) * PositiveOrNegative);
                zVel = 0
            end
        end
    end
end

function love.mousemoved(x, y, dx, dy)

    if love.keyboard.isDown('lctrl') then
        g3d.camera.firstPersonLook(dx, dy)
    end
end

function love.wheelmoved(x, y)
    cameraZoom = math.max(0.5, math.min(cameraZoom - y, 2))
end

function love.draw()
    local foundGoal = false

    for i = allShperes.len, 1, -1 do
        allShperes[i]:draw()
    end

    for X = 100, 1, -1 do
        for Y = 100, 1, -1 do
            local Z = getNoise(X, Y)
            if Z < noiseThreshold then
                -- Lava
                love.graphics.setColor(1, 1, 1)
                lava:setTranslation((X * 2) + noiseSpawn.x, (Y * 2) + noiseSpawn.y, (Z * floorHeightDifference))
                lava:draw()
                love.graphics.setColor(0.5, 0.5, 0.5)
            else
                -- Stone
                local current = {x = (X * 2) + noiseSpawn.x, y = (Y * 2) + noiseSpawn.y, z =  (Z * floorHeightDifference)}
                ground:setTranslation(current.x, current.y, current.z)

                -- lighting
                local lightmag = Vector.magnitude(playerPos.x - current.x, playerPos.y - current.y, 0)
                local light = 0.5 + (0.5 - (math.max(0, math.min(lightmag * 0.1, 0.5))))
                love.graphics.setColor(light, light, light)
                ground:draw()
                love.graphics.setColor(0.5, 0.5, 0.5)
            end

            -- Place border
            if X == 50 and Y == 50 then
                border:setTranslation((X * 2) + noiseSpawn.x, (Y * 2) + noiseSpawn.y, 0)
            end

            -- place goal
            if goalIndex == X * Y then
                foundGoal = true
                goal:setTranslation((X * 2) + noiseSpawn.x, (Y * 2) + noiseSpawn.y, (Z * floorHeightDifference) + 5)
                crate:setTranslation((X * 2) + noiseSpawn.x, (Y * 2) + noiseSpawn.y, (Z * floorHeightDifference) + 5)
                crate:setRotation(0, 0, timer * 4)
            end
        end
    end
    
    -- goal
    love.graphics.setColor(0.6, 1, 0.6)
    crate:draw()
    love.graphics.setColor(0.5, 0.5, 0.5)

    --goal:draw()

    --earth:draw()
    --moon:draw()
    background:draw()
    player:draw()
    --ground:draw()
    border:draw()

    if not foundGoal then
        goalIndex = love.math.random(1, 100 * 100)
    end

    -- UI
    local screenX, screenY = love.window.getMode()
    love.graphics.setColor(0, 1, 0)
    love.graphics.print("Survival Time: " .. timer, screenX / 2, 10)
    love.graphics.setColor(0.5, 0.5, 0.5)

    DebugWrite(debugStr)
end

function getNoise(x, y)
    local Z = love.math.noise((x + playerPos.x) * zoom + noiseOffset, (y + playerPos.y) * zoom + noiseOffset, timer * 2)
    tempZoom = zoom * 2
    Z = Z + (love.math.noise((x + playerPos.x) * tempZoom + noiseOffset, (y + playerPos.y) * tempZoom + noiseOffset, timer * 2) * 0.5)
    tempZoom = zoom * 4
    Z = Z + (love.math.noise((x + playerPos.x) * tempZoom + noiseOffset, (y + playerPos.y) * tempZoom + noiseOffset, timer * 2) * 0.25)

    -- Reverse, cursed
    --[[local Z = love.math.noise((x - playerPos.x) * zoom + noiseOffset, (y - playerPos.y) * zoom + noiseOffset, timer * 2)
    tempZoom = zoom * 2
    Z = Z + (love.math.noise((x - playerPos.x) * tempZoom + noiseOffset, (y - playerPos.y) * tempZoom + noiseOffset, timer * 2) * 0.5)
    tempZoom = zoom * 4
    Z = Z + (love.math.noise((x - playerPos.x) * tempZoom + noiseOffset, (y - playerPos.y) * tempZoom + noiseOffset, timer * 2) * 0.25)]]--

    return Z
end
