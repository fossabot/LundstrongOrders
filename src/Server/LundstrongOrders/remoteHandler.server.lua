-- Remote event handler
local Order = require(game.ServerScriptService.LundstrongOrders.order)
local DataStore2 = require(game.ServerScriptService.LundstrongOrders.DataStore2)
local config = require(workspace.LundstrongOrders.Configuration)
local Players = game:GetService("Players")
local runService = game:GetService("RunService")
local debounce = {}

DataStore2.Combine("DATA", "points")

game.ReplicatedStorage:WaitForChild("LundstrongOrders"):WaitForChild("Events"):WaitForChild("createOrder").OnServerInvoke = function(creator: Player, receiver: string, items: {[number]: string})
    if (not debounce[creator.Name] or debounce[creator.Name] == false) then
        debounce[creator.Name] = true
        local newOrder = Order.new(creator, receiver, items)
        print("NEW ORDER:", newOrder.id)
        game.ReplicatedStorage:WaitForChild("LundstrongOrders"):WaitForChild("Events"):WaitForChild("orderList"):FireAllClients(Order:GetOrders())
        if (creator.Name ~= receiver) then -- Cashier GUI order
            game.ReplicatedStorage.LundstrongOrders.Events.sendNotification:FireClient(newOrder.orderReceiver, creator.Name.." has created an order for you.", 10)
            coroutine.resume(coroutine.create(function()
                wait(config.CashierSettings.OrderCooldown)
                debounce[creator.Name] = false
            end))
        else -- Kiosk Order
            coroutine.resume(coroutine.create(function()
                wait(config.KioskSettings.OrderCooldown)
                debounce[creator.Name] = false
            end))
        end
        return true
    else
        return "Slow down! Your order cooldown hasn't expired!"
    end
end
game.ReplicatedStorage:WaitForChild("LundstrongOrders"):WaitForChild("Events"):WaitForChild("claimOrder").OnServerEvent:Connect(function(plr, id)
    local orderFound = false
    for _,v in pairs(Order:GetOrders()) do 
        if (v.id == id) then
            if (not v.isCompleted) then
                if (config.OrderBoardSettings.GroupID) then
                    if (config.OrderBoardSettings.MinimumRankEnabled) then
                        if (plr:GetRankInGroup(config.OrderBoardSettings.GroupID) >= config.OrderBoardSettings.MinimumRank) then
                            v:Claim(plr)
                            orderFound = v
                        end
                    else
                        if (table.find(config.OrderBoardSettings.RankTable, plr:GetRankInGroup(config.OrderBoardSettings.GroupID))) then
                            v:Claim(plr)
                            orderFound = v
                        end
                    end
                else
                    v:Claim(plr)
                    orderFound = v
                end
                game.ReplicatedStorage.LundstrongOrders.Events.sendNotification:FireClient(v.orderReceiver, "Your order has been claimed by "..plr.Name..".", 10)
            else
               error("[LundstrongOrders] Cannot claim completed order "..id)
            end
        end
    end
    print(orderFound)
    if (orderFound) then 
         game.ReplicatedStorage:WaitForChild("LundstrongOrders"):WaitForChild("Events"):WaitForChild("orderList"):FireAllClients(Order:GetOrders())
         game.ReplicatedStorage:WaitForChild("LundstrongOrders"):WaitForChild("Events"):WaitForChild("completeOrder"):FireClient(plr, orderFound)
    else
       warn("[LundstrongOrders] No order found with ID "..id)
    end
end)
game.Players.PlayerAdded:Connect(function(plr)
    local pointsStore = DataStore2("points", plr)

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"

    local points = Instance.new("NumberValue")
    points.Name = "Points"
    points.Value = pointsStore:Get(0) -- The "0" means that by default, they'll have 0 points
    points.Parent = leaderstats

    pointsStore:OnUpdate(function(newPoints)
        -- This function runs every time the value inside the data store changes.
        points.Value = newPoints
    end)

    leaderstats.Parent = plr

    if (runService:IsStudio()) then
        game.ReplicatedStorage.LundstrongOrders.Events.sendNotification:FireClient(plr, "LundstrongOrders does work in studio, but will not save points.", 45)
    end
end)
for _,plr in pairs(Players:GetPlayers()) do
    local pointsStore = DataStore2("points", plr)

    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"

    local points = Instance.new("NumberValue")
    points.Name = "Points"
    points.Value = pointsStore:Get(0) -- The "0" means that by default, they'll have 0 points
    points.Parent = leaderstats

    pointsStore:OnUpdate(function(newPoints)
        -- This function runs every time the value inside the data store changes.
        points.Value = newPoints
    end)

    leaderstats.Parent = plr
    
    if (runService:IsStudio()) then
        game.ReplicatedStorage.LundstrongOrders.Events.sendNotification:FireClient(plr, "LundstrongOrders does work in studio, but will not save points.", 45)
    end
end
game.Players.PlayerRemoving:Connect(function(plr)
    local orderFound = false
    for _,v in pairs(Order:GetOrders()) do 
        if (v.orderReceiver == plr) then
            if (not v.isClaimed) then
                v:Complete()
                orderFound = v
            end
        end
    end
    print(orderFound)
    if (orderFound) then 
         game.ReplicatedStorage:WaitForChild("LundstrongOrders"):WaitForChild("Events"):WaitForChild("orderList"):FireAllClients(Order:GetOrders())
    else
       print("[LundstrongOrders] No orders found for leaving player "..plr.Name)
    end
end)
game.ReplicatedStorage:WaitForChild("LundstrongOrders"):WaitForChild("Events"):WaitForChild("completeOrder").OnServerEvent:Connect(function(_, id)
    local orderFound = false
    for _,v in pairs(Order:GetOrders()) do 
        if (v.id == id) then
            if (v.isClaimed) then
                v:Complete()
                game.ReplicatedStorage.LundstrongOrders.Events.sendNotification:FireClient(v.orderReceiver, "Your order has completed.", 20)
                orderFound = v
            else
               error("[LundstrongOrders] Cannot complete unclaimed order "..id)
            end
        end
    end
    print(orderFound)
    if (orderFound) then 
         game.ReplicatedStorage:WaitForChild("LundstrongOrders"):WaitForChild("Events"):WaitForChild("orderList"):FireAllClients(Order:GetOrders())
    else
       warn("[LundstrongOrders] No order found with ID "..id)
    end
end)
