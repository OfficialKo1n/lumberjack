CONFIG_LUMBERJACK = {
    --- Respawn of trees in **SECONDS**
    respawn = 5,
    --- Money player will receive per each wooden log
    --- You can set 2 random values like the example or leave it with a single number.
    reward = { 500, 1000 },
    --- Script will select for each coords a random model
    --- You can set a specific probability to spawn the model
    models = {
        { prop = 'prop_tree_jacada_02', chance = 75, logs = { 2, 3 } },
        { prop = 'prop_tree_birch_05', chance = 50, logs = 1 }
    },
    coords = {
        vec3(-466.79, 5302.44, 84.96),
        vec3(-467.34, 5294.4, 85.39),
        vec3(-459.15, 5292.42, 85.06)
    }
}