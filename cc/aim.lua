local math = require("math")

local drag = 0.99
local gravity = 0.05
local speed = 16
local cannonLength = 20

local function tick(speedVec, posVec)
    local uel = {speedVec[1], speedVec[2]}
    local vel = {uel[1], uel[2]}
    local oldPos = {posVec[1], posVec[2]}
    local newPos = {oldPos[1] + vel[1], oldPos[2] + vel[2]}
    vel[1] = vel[1] * drag
    vel[2] = vel[2] - gravity
    vel[2] = vel[2] * drag
    speedVec[1], speedVec[2] = vel[1], vel[2]
    newPos[1] = newPos[1] + (vel[1] - uel[1]) * 0.5
    newPos[2] = newPos[2] + (vel[2] - uel[2]) * 0.5
    posVec[1], posVec[2] = newPos[1], newPos[2]
end

local function simulateShot(angle, target)
    angle = math.rad(angle)
    local speedVec = {speed * math.cos(angle), speed * math.sin(angle)}
    local posVec = {0, 0}
    local delta = math.sqrt((posVec[1] - target[1]) ^ 2 + (posVec[2] - target[2]) ^ 2)
    local closestDelta = delta
    local closestDeltaVec = {0, 0}
    local ticks = 0
    for i = 1, 400 do
        tick(speedVec, posVec)
        delta = math.sqrt((posVec[1] - target[1]) ^ 2 + (posVec[2] - target[2]) ^ 2)
        if delta < closestDelta then
            closestDelta = delta
            closestDeltaVec[1] = posVec[1] - target[1]
            closestDeltaVec[2] = posVec[2] - target[2]
            ticks = i
        end
    end
    return closestDeltaVec, ticks
end

local function adjustTargetDistance(target, yaw, pitch)
    local dx = cannonLength * math.sin(math.rad(-yaw)) * math.cos(math.rad(pitch))
    local dy = cannonLength * math.sin(math.rad(pitch))
    local dz = cannonLength * math.cos(math.rad(-yaw)) * math.cos(math.rad(pitch))
    return {target[1] - math.sqrt(dx ^ 2 + dz ^ 2), target[2] - dy}
end

local function getPitch(target, yaw, shootHigh)
    local angle = 30
    local step = 15
    local adjustedTarget = adjustTargetDistance(target, yaw, angle)
    local deltaVec, ticks
    while step >= 0.001 do
        deltaVec, ticks = simulateShot(angle, adjustedTarget)
        if shootHigh then
            angle = angle + (deltaVec[1] > 0 and step or -step)
        else
            angle = angle + (deltaVec[2] < 0 and step or -step)
        end
        adjustedTarget = adjustTargetDistance(target, yaw, angle)
        step = step / 2
    end
    return angle, deltaVec, ticks
end

local function getYaw(startPos, destPos)
    local dx = destPos[1] - startPos[1]
    local dz = destPos[3] - startPos[3]
    local angle = math.atan2(dx, dz)
    local deg = math.deg(angle)
    return -deg
end

local function get2DtargetDistance(startPos, destPos)
    local dx = destPos[1] - startPos[1]
    local dy = destPos[2] - startPos[2]
    local dz = destPos[3] - startPos[3]
    return {math.sqrt(dx ^ 2 + dz ^ 2), dy}
end

local function main()
    local startPos = {tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3])}
    local destPos = {tonumber(arg[4]), tonumber(arg[5]), tonumber(arg[6])}
    local target = get2DtargetDistance(startPos, destPos)
    local yaw = getYaw(startPos, destPos)
    print("Yaw: " .. yaw)
    local pitch, accuracy, ticks = getPitch(target, yaw, target[1] > 800)
    print("Pitch: " .. pitch)
    print("Accuracy: " .. math.sqrt(accuracy[1] ^ 2 + accuracy[2] ^ 2))
    print("Estimated arrival time: " .. math.floor(ticks / 20) .. " seconds and " .. ticks % 20 .. " ticks")
end

if #arg >= 6 then
    main()
end

