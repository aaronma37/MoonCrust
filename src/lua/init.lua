package.path = "src/lua/?.lua;src/lua/?/init.lua;" .. package.path

local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
_G.vulkan = vulkan
_G.mc = require("mc")
local linter = require("vulkan.linter")

-- Handle --lint CLI arg
local should_lint = false
if _ARGS then
    for i=0, #_ARGS do
        if _ARGS[i] == "--lint" then should_lint = true end
    end
end

if should_lint then
    print("[VULKAN LINTER] Startup scan enabled.")
    -- We can scan the core library and the target example
    linter.lint_file("src/lua/mc/gpu.lua")
    linter.lint_file("src/lua/vulkan/pipeline.lua")
    linter.lint_file("src/lua/vulkan/graph.lua")
end

-- Example Registry
local examples = {
    ["01"] = "examples.01_hello_gpu.main",
    ["02"] = "examples.02_compute_basic.main",
    ["04"] = "examples.04_particles_1m.main",
    ["06"] = "examples.06_particles_visual.main",
    ["07"] = "examples.07_interactive_particles.main",
    ["08"] = "examples.08_slime_mold.main",
    ["09"] = "examples.09_fluid_sph.main",
    ["10"] = "examples.10_moo_graph_search.main",
    ["11"] = "examples.11_grass_mesh_shader.main",
    ["12"] = "examples.12_path_tracer.main",
    ["13"] = "examples.13_graph_visualizer.main",
    ["14"] = "examples.14_moo_graph_search_reward3d.main",
    ["15"] = "examples.15_wavefront_rrt_dubins3d.main",
    ["16"] = "examples.16_hybrid_astar.main",
    ["17"] = "examples.17_mppi_gpu.main",
    ["18"] = "examples.18_voronoi_sdf_graph.main",
    ["19"] = "examples.19_octree_astar.main",
    ["20"] = "examples.20_gpu_culling.main",
    ["21"] = "examples.21_volumetric_fog.main",
    ["22"] = "examples.22_neural_regression.main",
    ["23"] = "examples.23_sa_tsp_massing.main",
    ["24"] = "examples.24_neuro_audio.main",
    ["25"] = "examples.25_voxel_atrium.main",
    ["26"] = "examples.26_mesh_cathedral.main",
    ["27"] = "examples.27_obj_viewer.main",
    ["28"] = "examples.28_voxel_world.main",
    ["29"] = "examples.29_magic_sandbox.main",
    ["30"] = "examples.30_sponza_gltf.main",
    ["31"] = "examples.31_neuro_symbolic_mesh.main",
    ["32"] = "examples.32_cellular_automata.main",
    ["33"] = "examples.33_gpu_vrp.main",
    ["34"] = "examples.34_optimal_transport.main",
    ["35"] = "examples.35_ant_colony.main",
    ["36"] = "examples.36_topology_opt.main",
    ["37"] = "examples.37_admm_consensus.main",
    ["38"] = "examples.38_job_shop_scheduling.main",
    ["39"] = "examples.39_branch_and_bound.main",
    ["40"] = "examples.40_particle_term.main",
    ["41"] = "examples.41_imgui_visualizer.main",
    ["42"] = "examples.42_robot_visualizer.main",
    ["43"] = "examples.43_forward_plus.main",
    ["44"] = "examples.44_bespoke_orchestrator.main",
}

-- Default to the flagship if no arg provided
local startup_arg = _ARGS and _ARGS[1]
local target_key = startup_arg or "32"
local target_path = examples[target_key]

-- If not a key, assume it's a direct path
if not target_path and startup_arg then
    target_path = startup_arg
    -- Update package.path to include the directory of the target path
    local base_dir = target_path:match("(.*[/\\])") or "./"
    package.path = base_dir .. "?.lua;" .. base_dir .. "?/init.lua;" .. package.path
end

if not target_path then
    print("Error: Unknown example or path '" .. tostring(target_key) .. "'")
    print("Available Examples:")
    for k, v in pairs(examples) do
        print("  " .. k .. " -> " .. v)
    end
    -- Fallback to safe default
    print("Falling back to Example 09...")
    target_path = examples["09"]
end

print("Loading: " .. target_path)
if should_lint then
    local path = target_path:gsub("%.", "/")
    if not path:find("%.lua$") then path = path .. ".lua" end
    linter.lint_file(path)
end

local example
if target_path:find("%.lua$") then
    local chunk, err = loadfile(target_path)
    if not chunk then error(err) end
    example = chunk()
else
    -- Convert path.to.module to require-able string if needed
    example = require(target_path)
end

if type(example) ~= "table" then
    -- Handle scripts that don't return a table
    example = { init = function() end, update = function() end }
end

function mooncrust_update()
    mc.tick()
    local ok, err = pcall(example.update)
    if not ok then
        print("mooncrust_update: ERROR:", err)
        error(err)
    end
end

-- Initialize the selected example
local ok, err = pcall(example.init)
if not ok then
    print("example.init: ERROR:", err)
    error(err)
end

print("MoonCrust Kernel Ready.")
