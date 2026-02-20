package.path = "src/lua/?.lua;src/lua/?/init.lua;" .. package.path

local ffi = require("ffi")
local vk = require("vulkan.ffi")
local vulkan = require("vulkan")
_G.vulkan = vulkan
_G.mc = require("mc")

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
}

-- Default to the flagship if no arg provided
local target_key = _STARTUP_ARG or "32"
local target_path = examples[target_key]

if not target_path then
    print("Error: Unknown example '" .. tostring(target_key) .. "'")
    print("Available Examples:")
    for k, v in pairs(examples) do
        print("  " .. k .. " -> " .. v)
    end
    -- Fallback to safe default
    print("Falling back to Example 09...")
    target_path = examples["09"]
end

print("Loading: " .. target_path)
local example = require(target_path)

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
