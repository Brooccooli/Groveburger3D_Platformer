local g3d = require "g3d"
-- g3d.newModel(MODEL, PNG, {(Back and forth),(Left and Right),(up and down)}, Rotation, size)
-- Spheres
earth = g3d.newModel("assets/sphere.obj", "assets/earth.png", {4,0,0})
moon = g3d.newModel("assets/sphere.obj", "assets/moon.png", {4,5,0}, {0, 1, 0}, 0.5)
background = g3d.newModel("assets/sphere.obj", "assets/starfield.png", nil, nil, 500)
goal = g3d.newModel("assets/sphere.obj", "assets/Point.png", nil, nil, 1.5)
player = g3d.newModel("assets/sphere.obj", "assets/YellowFace.png", {-8, 0, 0}, {0, 0, 0}, 0.2)

-- Cubes
ground = g3d.newModel("assets/cube.obj", "assets/Ground.png", {0, 0, -3}, nil, 1)
crate = g3d.newModel("assets/cube.obj", "assets/Crate.png", {0, 10, 0}, nil, 1)
lava = g3d.newModel("assets/cube.obj", "assets/Lava.png", {1, 11, 0}, nil, 1)
border = g3d.newModel("assets/cube.obj", "assets/Colors.png", {100, 100, 0}, nil, 100)

timer = 0.1

-- for collisions
allShperes = {}
allShperes.len = 2
allShperes[1] = moon
allShperes[2] = earth

-- For noise
floorHeightDifference = 8
zoom = 0.08
noiseSpawn = {x = -100, y = -100}
noiseOffset = love.math.random(1, 20)
noiseThreshold = 0.9

-- goal
goalPos = {x = 0, y = 0, z = 0}
goalIndex = love.math.random(1, 100 * 100)