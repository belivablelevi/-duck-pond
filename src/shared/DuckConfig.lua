local DuckConfig = {}

DuckConfig.Rarities = {
    {
        name            = "Common",
        weight          = 60,
        color           = Color3.fromRGB(210, 210, 210),
        incomePerMinute = 10,
        catchCost       = 0,
        size            = Vector3.new(2, 1.5, 2),
    },
    {
        name            = "Uncommon",
        weight          = 22,
        color           = Color3.fromRGB(100, 200, 100),
        incomePerMinute = 30,
        catchCost       = 10,
        size            = Vector3.new(2, 1.5, 2),
    },
    {
        name            = "Rare",
        weight          = 10,
        color           = Color3.fromRGB(100, 150, 255),
        incomePerMinute = 80,
        catchCost       = 50,
        size            = Vector3.new(2.2, 1.7, 2.2),
    },
    {
        name            = "Epic",
        weight          = 5,
        color           = Color3.fromRGB(180, 100, 255),
        incomePerMinute = 200,
        catchCost       = 200,
        size            = Vector3.new(2.4, 1.8, 2.4),
    },
    {
        name            = "Legendary",
        weight          = 2,
        color           = Color3.fromRGB(255, 200, 50),
        incomePerMinute = 600,
        catchCost       = 750,
        size            = Vector3.new(2.6, 2, 2.6),
    },
    {
        name            = "Mythic",
        weight          = 1,
        color           = Color3.fromRGB(255, 80, 80),
        incomePerMinute = 2000,
        catchCost       = 2500,
        size            = Vector3.new(3, 2.2, 3),
    },
}

function DuckConfig:GetRandomRarity()
    local totalWeight = 0
    for _, r in ipairs(self.Rarities) do
        totalWeight += r.weight
    end
    local roll = math.random(1, totalWeight)
    local cumulative = 0
    for _, r in ipairs(self.Rarities) do
        cumulative += r.weight
        if roll <= cumulative then
            return r
        end
    end
    return self.Rarities[1]
end

return DuckConfig
