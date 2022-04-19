-- written by groverbuger for g3d
-- september 2021
-- MIT license

local g3d = require "g3d"
require "loadLevel"
local Vector = require "g3d/vectors"

require "controlls"
require "loadLevel"

-- Player
faceOffset = 5
playerPos = { x = 0, y = 0, z = 30 }
playerRot = { x = 0, y = 0, z = 0 }
moveSpeed = 20
local rotSpeed = 2

-- jump
jumpStrength = 20
jumpTimer = 0
maxJumpTimer = 0.4

cameraZoom = 1
mY = 0

gravity = 1
zVel = 0

-- Settings
local fullscreen = false
local oldFKey = love.keyboard.isDown('f')
local oldLKey = love.keyboard.isDown('l')
local lodOn = true
local lodArea = 60
local fpsTimer = 0
local fps = 0
local fpsFinal = 0

-- Debug
local debugStr = ""

function love.load()
    love.window.setMode(800, 600, { depth = 1, minwidth = 800, minheight = 600, resizable = true })

    love.mouse.setRelativeMode(true)
    love.mouse.setGrabbed(true)

    gameSetup()
end

function DebugWrite(str)
    love.filesystem.setIdentity("Debug")
    success, message = love.filesystem.write("Debug.txt", "3D TEST \n" .. str)
end

function love.update(dt)
    debugStr = ""

    debugStr = debugStr .. "DeltaTime: " .. dt

    if fpsTimer > 1 then
        fpsTimer = 0
        fpsFinal = fps
        fps = 0
    else
        fpsTimer = fpsTimer + dt
        fps = fps + 1
    end

    if love.keyboard.isDown('f') and not oldFKey then
        if fullscreen then fullscreen = false else fullscreen = true end
        love.window.setFullscreen(fullscreen)
    end
    if love.keyboard.isDown('l') and not oldLKey then
        if lodOn then lodOn = false else lodOn = true end
    end

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

    timer = timer + dt * 0.05

    if love.keyboard.isDown "escape" then
        love.event.push "quit"
    end

    debugStr = debugStr .. "\n Player pos: " .. playerPos.x .. " " .. playerPos.y .. " " .. playerPos.z

    --playerPos.z = playerPos.z - 0.01

    checkSphereCollision()
    checkCubeCollision(dt)

    -- Controlls
    controlls(dt)

    playerPos.z = playerPos.z + zVel
    if playerPos.z < -50 then gameSetup() end

    oldFKey = love.keyboard.isDown('f')
    oldLKey = love.keyboard.isDown('l')
end

function checkSphereCollision()
    local mag = Vector.magnitude(playerPos.x - goal:getX(), playerPos.y - goal:getY(), playerPos.z - goal:getZ())
    if mag < player.scale[1] + goal.scale[1] then
        noiseThreshold = noiseThreshold - 0.05
        goalIndex = love.math.random(1, 100 * 100)
    end
end

function checkCubeCollision(dt)
    local newPos = {}
    newPos[1] = playerPos.x
    newPos[2] = playerPos.y
    newPos[3] = playerPos.z

    -- All cubes on the map
    for d = 100, 1, -1 do
        for i = 100, 1, -1 do
            local Z = getNoise(d, i)

            local current = { x = (d * 2) + noiseSpawn.x, y = (i * 2) + noiseSpawn.y, z = Z * floorHeightDifference }

            local mag = Vector.magnitude(newPos[1] - ((d * 2) + noiseSpawn.x), newPos[2] - ((i * 2) + noiseSpawn.y), 0)
            if mag < 5 then
                current = { x = (d * 2) + noiseSpawn.x, y = (i * 2) + noiseSpawn.y, z = Z * floorHeightDifference }

                local mag = {}
                mag[1] = newPos[1] - current.x
                mag[2] = newPos[2] - current.y
                mag[3] = newPos[3] - current.z

                local cubePos = {}
                cubePos[1] = current.x
                cubePos[2] = current.y
                cubePos[3] = current.z

                local size = player.scale[1] + 1

                local lowestValue = 1000
                local ChangeIndex = 1
                local PositiveOrNegative = 0

                
                ground:setTranslation(current.x, current.y, current.z)
                if ground:closestPoint(playerPos.x, playerPos.y, playerPos.z) < 0.05 then
                    if Z >= noiseThreshold then
                        debugStr = debugStr .. "\n Rock"
                    else
                        debugStr = debugStr .. "\n Lava"
                    end
                end
                


                -- Check all sides on current cube
                for j = 3, 1, -1 do

                    local n1, n2 = 0, 0
                    if j == 1 then n1, n2 = 1, 2
                    elseif j == 2 then n1, n2 = 1, -1
                    else n1, n2 = -1, -2 end

                    
                    
                    -- Check all three axis for the current side
                    if math.abs(mag[j]) < size and math.abs(mag[j + n1]) < size and math.abs(mag[j + n2]) < size then
                    --if  ground:closestPoint(playerPos.x, playerPos.y, playerPos.z) <  then
                        debugStr = debugStr .. "\n test: " .. ground:closestPoint(playerPos.x, playerPos.y, playerPos.z)
                        
                        if Z >= noiseThreshold then
                            local pushForce = player.scale[1] + 1 - math.abs(mag[j])
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
                    zVel = (jumpStrength * 0.1) * dt

                elseif ChangeIndex == 2 then
                    playerPos.y = playerPos.y + (math.abs(newPos[2] - playerPos.y) * PositiveOrNegative)
                    zVel = (jumpStrength * 0.1) * dt

                else playerPos.z = playerPos.z + (math.abs(newPos[3] - playerPos.z) * PositiveOrNegative);
                    zVel = 0
                end
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
            local current = { x = (X * 2) + noiseSpawn.x, y = (Y * 2) + noiseSpawn.y, z = (Z * floorHeightDifference) }
            if Z < noiseThreshold then
                drawLava(current.x, current.y, current.z, Z)
            else
                drawStone(current.x, current.y, current.z, Z)
            end

            -- Place border
            if X == 50 and Y == 50 then
                border:setTranslation(current.x, current.y, 0)
            end

            -- place goal
            if goalIndex == X * Y then
                foundGoal = true
                goal:setTranslation(current.x, current.y, current.z + 5)
                crate:setTranslation(current.x, current.y, current.z + 5)
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
    love.graphics.print("FPS: " .. fpsFinal, 10, 10)
    love.graphics.print("Love FPS: " .. love.timer.getFPS(), 10, 20)
    love.graphics.setColor(0.5, 0.5, 0.5)

    DebugWrite(debugStr)
end

function drawLava(x, y, z, noiseZ)
    -- LOD test
    local mag = Vector.magnitude(playerPos.x - x, playerPos.y - y, 0)
    if mag > lodArea and lodOn then
        -- Extract and solve math
        if x * y % math.floor(lodArea * (mag * 0.005)) == 0 then
            local noiseZ = getNoise(x, y)
            love.graphics.setColor(1 - (mag * 0.01), 1 - (mag * 0.01), 1 - (mag * 0.01))
            lava:setTranslation(x, y, z)
            lava:setScale(mag * 0.1, mag * 0.1, 1)
            lava:draw()
            love.graphics.setColor(0.5, 0.5, 0.5)
            return
        else
            return
        end
    end

    -- Lava
    lava:setScale(1, 1, 1)
    love.graphics.setColor(1 - (1 - noiseZ), 1 - (1 - noiseZ), 1 - (1 - noiseZ))
    lava:setTranslation(x, y, z)
    lava:draw()
    love.graphics.setColor(0.5, 0.5, 0.5)
end

function drawStone(x, y, z, noiseZ)
    local mag = Vector.magnitude(playerPos.x - x, playerPos.y - y, 0)
    if mag > lodArea and lodOn then
        if x * y % math.floor(lodArea * (mag * 0.005)) == 0 then
            love.graphics.setColor(1 - (mag * 0.01), 1 - (mag * 0.01), 1 -(mag * 0.01))
            ground:setTranslation(x, y, z)
            ground:setScale(mag * 0.05, mag * 0.05, 1)
            ground:draw()
            love.graphics.setColor(0.5, 0.5, 0.5)
            return
        else
            return
        end
    else
        -- Stone
        ground:setScale(1, 1, 1)
        ground:setTranslation(x, y, z)

        -- lighting
        local lightmag = Vector.magnitude(playerPos.x - x, playerPos.y - y, 0)
        local light = 0.5 + (0.5 - (math.max(0, math.min(lightmag * 0.1, 0.5)))) + (1 - noiseZ)
        love.graphics.setColor(light, light, light)
        ground:draw()
        love.graphics.setColor(0.5, 0.5, 0.5)

    end
end

function getNoise(x, y)
    local Z = love.math.noise((x + playerPos.x) * zoom + noiseOffset, (y + playerPos.y) * zoom + noiseOffset, timer * 2)
    tempZoom = zoom * 2
    Z = Z + (love.math.noise((x + playerPos.x) * tempZoom + noiseOffset, (y + playerPos.y) * tempZoom + noiseOffset, timer * 2) * 0.5)
    tempZoom = zoom * 4
    Z = Z + (love.math.noise((x + playerPos.x) * tempZoom + noiseOffset, (y + playerPos.y) * tempZoom + noiseOffset, timer * 2) * 0.25)

    return Z
end
