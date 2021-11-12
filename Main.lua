-- title:  Main.lua
-- author(s): ReptitceFnct
-- desc:  
-- script: lua
-- input:
-- saveid: Platformer v3

--=========--
-- H E A D --
--=========--

-- This line make mark in the console during the excution 
io.stdout:setvbuf('no')

-- Stop love filters when we re-size image, it's essential for pixel art
love.graphics.setDefaultFilter("nearest")

-- with this line we can debugg step with step in Zerobrain
--if arg[#arg] == "-debug" then require("mobdebug").start() end

--===================--
-- V A R I A B L E S --
--===================--

------------
-- images --
------------

local imgTiles = {}
imgTiles["1"] = love.graphics.newImage("_Resources_/images/tile1.png")
imgTiles["2"] = love.graphics.newImage("_Resources_/images/tile2.png")
imgTiles["3"] = love.graphics.newImage("_Resources_/images/tile3.png")
imgTiles["4"] = love.graphics.newImage("_Resources_/images/tile4.png")
imgTiles["5"] = love.graphics.newImage("_Resources_/images/tile5.png")
imgTiles["="] = love.graphics.newImage("_Resources_/images/tile=.png")
imgTiles["["] = love.graphics.newImage("_Resources_/images/tile[.png")
imgTiles["]"] = love.graphics.newImage("_Resources_/images/tile].png")
imgTiles["H"] = love.graphics.newImage("_Resources_/images/tileH.png")
imgTiles["#"] = love.graphics.newImage("_Resources_/images/tile#.png")
imgTiles["g"] = love.graphics.newImage("_Resources_/images/tileg.png")

imgPlayer = love.graphics.newImage("_Resources_/images/player/idle1.png")

-- Map and levels

local map = {}
local level = {}

--------------
-- constant --
--------------

-- tilesize

local TILESIZE = 16
local GRAVITY = 500

--===================--
-- F U N C T I O N S --
--===================--

function LoadLevel(pNum)
  
  map = {}
  local filename = "_Resources_/levels/level"..tonumber(pNum)..".txt"
  
  for line in love.filesystem.lines(filename) do
    
    map[#map + 1] = line
  end
  
  -- Look for the player in the map
  level = {}
  level.playerStart = {}
  level.playerStart.col = 2
  level.playerStart.lin = 14
  
  for l=1,#map do
    
    for c=1,#map[1] do
      
      local char = string.sub(map[l],c,c)
      
      if char == "P" then
        
        level.playerStart.col = c
        level.playerStart.lin = l
      end
    end
  end
end

function InitGame(pLevel)
  
  listSprites = {}
  LoadLevel(pLevel)
  
  local player = CreateSprite("player", (2 - 1) * TILESIZE, (14 - 1) * TILESIZE)
  player.AddAnimation("_Resources_/images/player", "idle", { "idle1", "idle2", "idle3", "idle4" })
  player.AddAnimation("_Resources_/images/player", "run", { "run1", "run2", "run3", "run4", "run5", "run6", "run7", "run8", "run9", "run10" })
  player.AddAnimation("_Resources_/images/player", "climb", { "climb1", "climb2" })
  player.AddAnimation("_Resources_/images/player", "climb_idle", { "climb1" })
  player.PlayAnimation("idle")
  bJumpReady = true
  player.gravity = GRAVITY
end


function love.load()
  
  love.window.setMode(1200, 900)
  love.window.setTitle("Platformer")
  InitGame(1)
end

function getTileAt(pX, pY)
  
  local col = math.floor(pX / TILESIZE) + 1
  local lin = math.floor(pY / TILESIZE) + 1
  
  if col > 0 and col <= #map[1] and lin > 0 and lin <= #map then
    
    local id = string.sub(map[lin], col, col)
    return id
  end
  return 0
end

function CreateSprite(pType, pX, pY)
  
  mySprite = {}
  
  mySprite.x = pX
  mySprite.y = pY
  mySprite.vx = 0
  mySprite.vy = 0
  mySprite.gravity = 0
  mySprite.isJumping = false
  mySprite.type = pType
  mySprite.standing = false
  mySprite.flip = false
  
  mySprite.currentAnimation = ""
  mySprite.frame = 0
  mySprite.animationSpeed = 1/8
  mySprite.animationTimer = mySprite.animationSpeed
  mySprite.animations = {}
  mySprite.images = {}
  
  mySprite.AddImages = function(psDir, plstImage)
    
    for k,v in pairs(plstImage) do
      
      local fileName = psDir.."/"..v..".png"
      mySprite.images[v] = love.graphics.newImage(fileName)
    end
  end
  
  mySprite.AddAnimation = function(psDir, psName, plstImages)
    
    mySprite.AddImages(psDir, plstImages)
    mySprite.animations[psName] = plstImages
  end
  
  mySprite.PlayAnimation = function(psName)
    
    if mySprite.currentAnimation ~= psName then
      
      mySprite.currentAnimation = psName
      mySprite.frame = 1
    end
  end
  
  table.insert(listSprites, mySprite)
  
  return mySprite, listSprites
end

function isSolid(pID)
  
  if pID == "0" then
    
    return false
  end
  
  if pID == "1" then
    
    return true
  end
  
  if pID == "4" then
    
    return true
  end
  
  if pID == "5" then
    
    return true
  end
  
  if pID == "=" then
    
    return true
  end
  
  if pID == "]" then
    
    return true
  end
  
  if pID == "[" then
    
    return true
  end
  
  return false
end

function isLadder(pID)
  
  if pID == "H" then
    
    return true
  end
  
  if pID == "#" then
    
    return true
  end
  
  return false
end

function isJumpThrough(pID)
  
  if pID == "g" then
    
    return true
  end
  
  return false
end

function updatePlayer(pPlayer, dt)
  
  -- locals for Physics
  local accel = 350
  local friction = 120
  local maxSpeed = 100
  local jumpVelocity = -190
  
  -- Tile under the player
  local idUnder = getTileAt(pPlayer.x + TILESIZE / 2, pPlayer.y + TILESIZE)
  
  local idOverlap = getTileAt(pPlayer.x + TILESIZE / 2, pPlayer.y + TILESIZE - 1)
  
  -- stop Jump?
  if pPlayer.isJumping and (CollideBelow(pPlayer) or isLadder(idUnder)) then
    
    pPlayer.isJumping = false
    pPlayer.standing = true
    AlignOnLine(pPlayer)
  end

  -- Friction
  if pPlayer.vx > 0 then
    
    pPlayer.vx = pPlayer.vx - friction * dt
    
    if pPlayer.vx < 0 then
      
      pPlayer.vx = 0
    end
  end
  
  if pPlayer.vx < 0 then
    
    pPlayer.vx = pPlayer.vx + friction * dt
    
    if pPlayer.vx > 0 then
      
      pPlayer.vx = 0 
    end
  end
  
  local newAnimation = "idle"
  
  -- Check if the player overlap a ladder
  local isOnLadder = isLadder(idUnder) or isLadder(idOverlap)
  
  if isLadder(idOverlap) == false and isLadder(isUnder) then
    
    pPlayer.standing = true
  end
  
  -- Climb
  if isOnLadder and pPlayer.isJumping == false then
    
    
    pPlayer.gravity = 0
    pPlayer.vy = 0
    bJumpReady = false
  end
  
  if isLadder(idUnder) and isLadder(idOverlap) then
    
    newAnimation = "climb_idle"
  end
  
  if love.keyboard.isDown("up") and isOnLadder == true and pPlayer.isJumping == false then
    
    pPlayer.vy = -50
    newAnimation = "climb"
  end
  
  if love.keyboard.isDown("down") and isOnLadder == true then
    
    pPlayer.vy = 50
    newAnimation = "climb"
  end
  
  -- Not climbing
  if isOnLadder == false and pPlayer.gravity == 0 and pPlayer.isJumping == false then
    
    pPlayer.gravity = 500
  end
  
  --Keyboard
  
  if love.keyboard.isDown("right") then
    
    pPlayer.vx = pPlayer.vx + accel * dt
    
    if pPlayer.vx > maxSpeed then
      
      pPlayer.vx = maxSpeed
    end
    
    pPlayer.flip = false
    newAnimation = "run"
  end
  
  if love.keyboard.isDown("left") then
    
    pPlayer.vx = pPlayer.vx - accel  *dt
    
    if pPlayer.vx < -maxSpeed then
      
      pPlayer.vx = -maxSpeed 
    end
    
    pPlayer.flip = true
    newAnimation = "run"
  end
 
  
  if love.keyboard.isDown("up") and pPlayer.standing and bJumpReady then
    
    pPlayer.isJumping = true
    pPlayer.gravity = GRAVITY
    pPlayer.vy = jumpVelocity
    pPlayer.standing = false
    bJumpReady = false
  end
  
  if love.keyboard.isDown("up") == false and bJumpReady == false and pPlayer.standing == true then
    
    bJumpReady = true
  end
  
  pPlayer.PlayAnimation(newAnimation)
  --move
  
  pPlayer.x = pPlayer.x + pPlayer.vx * dt
  pPlayer.y = pPlayer.y + pPlayer.vy * dt
end

function CollideRight(pSprite)
  
  local id1 = getTileAt(pSprite.x + TILESIZE, pSprite.y + 3)
  local id2 = getTileAt(pSprite.x + TILESIZE, pSprite.y + (TILESIZE - 2))
  
  if isSolid(id1) or isSolid(id2) then
    
    return true
  end
  
  return false
end

function CollideLeft(pSprite)
  
  local id1 = getTileAt(pSprite.x - 1, pSprite.y + 3)
  local id2 = getTileAt(pSprite.x - 1, pSprite.y + (TILESIZE - 2))
  
  if isSolid(id1) or isSolid(id2) then
    
    return true
  end
  
  return false
end

function CollideBelow(pSprite)
  
  local id1 = getTileAt(pSprite.x + 1, pSprite.y + TILESIZE)
  local id2 = getTileAt(pSprite.x + (TILESIZE - 2), pSprite.y + TILESIZE)
  
  if isJumpThrough(id1) or isJumpThrough(id2) then
    
    local line = math.floor((pSprite.y + (TILESIZE / 2)) / TILESIZE) + 1
    local yLine = (line - 1) * TILESIZE
    local distance = pSprite.y - yLine
    
    if distance >= 0 and distance < 10 then
      
      return true
    end
  end
  
  if isSolid(id1) or isSolid(id2) then
    
    return true
  end
  
  return false
end

function CollideAbove(pSprite)
  
  local id1 = getTileAt(pSprite.x + 1, pSprite.y - 1)
  local id2 = getTileAt(pSprite.x + TILESIZE - 2, pSprite.y - 1)
  
  if isSolid(id1) or isSolid(id2) then
    
    return true
  end
  
  return false
end

function AlignOnLine(pSprite)
  
  local lin = math.floor((pSprite.y + TILESIZE / 2) / TILESIZE) + 1
  pSprite.y = (lin - 1) * TILESIZE
end

function AlignOnColumn(pSprite)
  
  
  local col = math.floor((pSprite.x + TILESIZE / 2) / TILESIZE) + 1
  pSprite.x = (col - 1) * TILESIZE
end

function updateSprite(pSprite, dt)
  
  --locals for collisions
  local oldX = pSprite.x
  local oldY = pSprite.y
  

  
  --Collision dtection
  local collide = false
  
  --on the right
  if pSprite.vx > 0 then
    
    collide = CollideRight(pSprite)
  end
  
  -- on the left
  if pSprite.vx < 0 then
    
    collide = CollideLeft(pSprite)
  end
  
  -- stop!
  if collide then
    
    pSprite.vx = 0
    local col = math.floor((pSprite.x + (TILESIZE / 2)) / TILESIZE) + 1
    pSprite.x = (col - 1) * TILESIZE
    AlignOnColumn(pSprite)
  end
  
  collide = false
  
  -- above
  if pSprite.vy < 0 then
    
    collide = CollideAbove(pSprite)
    if collide then
      
      print("collide above")
      pSprite.vy = 0
      local lin = math.floor((pSprite.y + (TILESIZE) / 2) / TILESIZE) + 1
      pSprite.y = (lin - 1) * TILESIZE
    end
  end
  
  collide = false
  
  -- Below
  if pSprite.standing or pSprite.vy > 0 then
    
    collide = CollideBelow(pSprite)
    
    if collide then
      
      pSprite.standing = true
      pSprite.vy = 0
      local lin = math.floor((pSprite.y + (TILESIZE / 2)) / TILESIZE) + 1
      pSprite.y = (lin - 1) * TILESIZE
      AlignOnLine(pSprite)
      
    else
      
      pSprite.standing = false
    end
  end
  
  --Sprite falling
  if pSprite.standing == false then 
    
    pSprite.vy = pSprite.vy + pSprite.gravity * dt
  end
  
  -- Animation
  if pSprite.animations ~= "" then
    
    pSprite.animationTimer = pSprite.animationTimer - dt
    
    if pSprite.animationTimer <= 0 then
      
      pSprite.frame = pSprite.frame + 1
      pSprite.animationTimer = pSprite.animationSpeed
      
      if pSprite.frame > #pSprite.animations[pSprite.currentAnimation] then
        
        pSprite.frame = 1
      end
    end
  end
  
  --Specific behavior for player
  if pSprite.type == "player" then
    
    updatePlayer(pSprite, dt)
  end
end

function love.update(dt)
  
  for nSprite = #listSprites, 1, -1 do
    
    
    local sprite = listSprites[nSprite]
    updateSprite(sprite, dt)
  end
end




function drawSprite(pSprite)
  local imgName = pSprite.animations[pSprite.currentAnimation][pSprite.frame]
  local img = pSprite.images[imgName]
  local halfw = img:getWidth()  / 2
  local halfh = img:getHeight() / 2
  local flipCoef = 1
  
  if pSprite.flip then flipCoef = -1 end
  love.graphics.draw(
    img, -- Image
    pSprite.x + halfw, -- horizontal position
    pSprite.y + halfh, -- vertical position
    0, -- rotation (none = 0)
    1 * flipCoef, -- horizontal scale
    1, -- vertical scale (normal size = 1)
    halfw, halfh -- horizontal and vertical offset
  )
  
  
end


function love.draw()
  
  
  love.graphics.scale(3, 3)
 for l=1,#map do
   
    for c=1,#map[1] do
      
      local char = string.sub(map[l],c,c)
      if tonumber(char) ~= 0 then
        
        if imgTiles[char] ~= nil then
          
          love.graphics.draw(imgTiles[char], (c - 1) * TILESIZE, (l - 1) * TILESIZE)
        end
      end
    end
  end
  
  local id = getTileAt(love.mouse.getX(), love.mouse.getY())
  love.graphics.print(id, 0, 0)
  
  
  for nSprite = #listSprites, 1, -1 do
    
    
    local sprite = listSprites[nSprite]
    drawSprite(sprite)
  end
  
  --love.graphics.draw(imgPlayer, 250, 250)
end


--function love.keypressed(key)
  
  --print(key)
--end
