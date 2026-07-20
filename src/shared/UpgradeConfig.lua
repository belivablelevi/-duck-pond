-- Each tier: {cost = Coins, value = new stat value}
return {
    CarryCapacity = {
        name        = "Carry Capacity",
        description = "Carry more ducks at once",
        tiers = {
            { cost = 50,     value = 2  },
            { cost = 150,    value = 3  },
            { cost = 400,    value = 5  },
            { cost = 1000,   value = 7  },
            { cost = 2500,   value = 10 },
            { cost = 6000,   value = 14 },
            { cost = 15000,  value = 18 },
            { cost = 40000,  value = 22 },
            { cost = 100000, value = 25 },
        },
    },
    WalkSpeed = {
        name        = "Walk Speed",
        description = "Move faster across the pond",
        tiers = {
            { cost = 100,  value = 18 },
            { cost = 300,  value = 20 },
            { cost = 800,  value = 23 },
            { cost = 2000, value = 26 },
            { cost = 5000, value = 30 },
            { cost = 12000,value = 35 },
            { cost = 30000,value = 40 },
        },
    },
    NetRange = {
        name        = "Net Range",
        description = "Catch ducks from further away",
        tiers = {
            { cost = 75,   value = 6  },
            { cost = 200,  value = 7.5},
            { cost = 500,  value = 9  },
            { cost = 1200, value = 11 },
            { cost = 3000, value = 13 },
            { cost = 8000, value = 15 },
        },
    },
    FarmCapacity = {
        name        = "Farm Capacity",
        description = "Store more ducks in your farm",
        tiers = {
            { cost = 200,  value = 10 },
            { cost = 600,  value = 15 },
            { cost = 1500, value = 20 },
            { cost = 4000, value = 28 },
            { cost = 10000,value = 38 },
            { cost = 25000,value = 50 },
        },
    },
    IncomeMultiplier = {
        name        = "Income Multiplier",
        description = "Earn more coins from each duck",
        tiers = {
            { cost = 500,  value = 1.25 },
            { cost = 1500, value = 1.5  },
            { cost = 4000, value = 1.75 },
            { cost = 10000,value = 2.0  },
            { cost = 25000,value = 2.5  },
            { cost = 60000,value = 3.0  },
        },
    },
}
