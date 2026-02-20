local ffi = require("ffi")
local vk = require("vulkan.ffi")
local shader = require("vulkan.shader")
local reload = require("vulkan.reload")

local M = {}
local Pipeline = {}
Pipeline.__index = Pipeline

function M.create_layout(device, layouts, push_constant_ranges)
    local pc_count = 0
    local pPC = nil
    if push_constant_ranges then
        if type(push_constant_ranges) == "cdata" then
            pc_count = 1
            pPC = push_constant_ranges
        else
            pc_count = #push_constant_ranges
            pPC = ffi.new("VkPushConstantRange[?]", pc_count, push_constant_ranges)
        end
    end

    local layout_info = ffi.new("VkPipelineLayoutCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO,
        setLayoutCount = layouts and #layouts or 0,
        pSetLayouts = layouts and ffi.new("VkDescriptorSetLayout[?]", #layouts, layouts) or nil,
        pushConstantRangeCount = pc_count,
        pPushConstantRanges = pPC
    })
    
    local pLayout = ffi.new("VkPipelineLayout[1]")
    local result = vk.vkCreatePipelineLayout(device, layout_info, nil, pLayout)
    if result ~= vk.VK_SUCCESS then
        error("Failed to create Pipeline Layout: " .. tostring(result))
    end
    return pLayout[0]
end

function M.create_compute_pipeline(device, layout, shader_module, entry_point)
    local name = entry_point or "main"
    local pName = ffi.new("char[?]", #name + 1)
    ffi.copy(pName, name)
    
    local stage_info = ffi.new("VkPipelineShaderStageCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO,
        stage = vk.VK_SHADER_STAGE_COMPUTE_BIT,
        module = shader_module,
        pName = pName
    })
    
    local info = ffi.new("VkComputePipelineCreateInfo[1]", {{
        sType = vk.VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO,
        stage = stage_info,
        layout = layout
    }})
    
    local pPipeline = ffi.new("VkPipeline[1]")
    local result = vk.vkCreateComputePipelines(device, nil, 1, info, nil, pPipeline)
    if result ~= vk.VK_SUCCESS then
        error("Failed to create Compute Pipeline: " .. tostring(result))
    end
    
    return pPipeline[0]
end

function M.create_graphics_pipeline(device, layout, vert_or_shaders, frag_module, options)
    local shaders = {}
    if type(vert_or_shaders) == "cdata" then
        shaders = {
            { stage = vk.VK_SHADER_STAGE_VERTEX_BIT, module = vert_or_shaders },
            { stage = vk.VK_SHADER_STAGE_FRAGMENT_BIT, module = frag_module }
        }
    else
        shaders = vert_or_shaders
        options = frag_module
    end

    options = options or {}
    local name_main = ffi.new("char[5]", "main")
    
    local stage_count = #shaders
    local stages = ffi.new("VkPipelineShaderStageCreateInfo[?]", stage_count)
    for i = 0, stage_count - 1 do
        stages[i].sType = vk.VK_STRUCTURE_TYPE_PIPELINE_SHADER_STAGE_CREATE_INFO
        stages[i].stage = shaders[i+1].stage
        stages[i].module = shaders[i+1].module
        stages[i].pName = name_main
    end

    local vertex_input = ffi.new("VkPipelineVertexInputStateCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VERTEX_INPUT_STATE_CREATE_INFO,
        vertexBindingDescriptionCount = options.vertex_binding and 1 or 0,
        pVertexBindingDescriptions = options.vertex_binding,
        vertexAttributeDescriptionCount = options.vertex_attribute_count or (options.vertex_attributes and 1 or 0),
        pVertexAttributeDescriptions = options.vertex_attributes
    })

    local input_assembly = ffi.new("VkPipelineInputAssemblyStateCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_INPUT_ASSEMBLY_STATE_CREATE_INFO,
        topology = options.topology or vk.VK_PRIMITIVE_TOPOLOGY_TRIANGLE_LIST
    })

    local viewport_state = ffi.new("VkPipelineViewportStateCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_VIEWPORT_STATE_CREATE_INFO,
        viewportCount = 1,
        scissorCount = 1
    })

    local rasterizer = ffi.new("VkPipelineRasterizationStateCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_RASTERIZATION_STATE_CREATE_INFO,
        polygonMode = vk.VK_POLYGON_MODE_FILL,
        lineWidth = 1.0,
        cullMode = options.cull_mode or vk.VK_CULL_MODE_NONE,
        frontFace = options.front_face or vk.VK_FRONT_FACE_COUNTER_CLOCKWISE
    })

    local multisampling = ffi.new("VkPipelineMultisampleStateCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_MULTISAMPLE_STATE_CREATE_INFO,
        rasterizationSamples = vk.VK_SAMPLE_COUNT_1_BIT
    })

    local formats_count = options.color_formats and #options.color_formats or 1
    local formats = ffi.new("VkFormat[?]", formats_count)
    if options.color_formats then
        for i=1, formats_count do formats[i-1] = options.color_formats[i] end
    else
        formats[0] = vk.VK_FORMAT_B8G8R8A8_SRGB
    end

    local color_blend_attachments = ffi.new("VkPipelineColorBlendAttachmentState[?]", formats_count)
    for i=0, formats_count-1 do
        color_blend_attachments[i].colorWriteMask = bit.bor(vk.VK_COLOR_COMPONENT_R_BIT, vk.VK_COLOR_COMPONENT_G_BIT, vk.VK_COLOR_COMPONENT_B_BIT, vk.VK_COLOR_COMPONENT_A_BIT)
        color_blend_attachments[i].blendEnable = vk.VK_FALSE
    end

    local color_blending = ffi.new("VkPipelineColorBlendStateCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_COLOR_BLEND_STATE_CREATE_INFO,
        attachmentCount = formats_count,
        pAttachments = color_blend_attachments
    })

    local depth_stencil = ffi.new("VkPipelineDepthStencilStateCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_DEPTH_STENCIL_STATE_CREATE_INFO,
        depthTestEnable = options.depth_test and vk.VK_TRUE or vk.VK_FALSE,
        depthWriteEnable = options.depth_write and vk.VK_TRUE or vk.VK_FALSE,
        depthCompareOp = vk.VK_COMPARE_OP_LESS,
        depthBoundsTestEnable = vk.VK_FALSE,
        stencilTestEnable = vk.VK_FALSE
    })

    local dynamic_states = ffi.new("VkDynamicState[2]", { vk.VK_DYNAMIC_STATE_VIEWPORT, vk.VK_DYNAMIC_STATE_SCISSOR })
    local dynamic_state = ffi.new("VkPipelineDynamicStateCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_DYNAMIC_STATE_CREATE_INFO,
        dynamicStateCount = 2,
        pDynamicStates = dynamic_states
    })

    local rendering_info = ffi.new("VkPipelineRenderingCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_PIPELINE_RENDERING_CREATE_INFO,
        colorAttachmentCount = formats_count,
        pColorAttachmentFormats = formats,
        depthAttachmentFormat = options.depth_format or (options.depth_test and vk.VK_FORMAT_D32_SFLOAT or vk.VK_FORMAT_UNDEFINED)
    })

    local info = ffi.new("VkGraphicsPipelineCreateInfo", {
        sType = vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO,
        pNext = rendering_info,
        stageCount = stage_count,
        pStages = stages,
        pVertexInputState = vertex_input,
        pInputAssemblyState = input_assembly,
        pViewportState = viewport_state,
        pRasterizationState = rasterizer,
        pMultisampleState = multisampling,
        pColorBlendState = color_blending,
        pDepthStencilState = depth_stencil,
        pDynamicState = dynamic_state,
        layout = layout,
        renderPass = nil
    })

    local pPipeline = ffi.new("VkPipeline[1]")
    local result = vk.vkCreateGraphicsPipelines(device, nil, 1, info, nil, pPipeline)
    if result ~= vk.VK_SUCCESS then
        error("Failed to create Graphics Pipeline: " .. tostring(result))
    end
    return pPipeline[0]
end

local Cache = {}
Cache.__index = Cache

function M.new_cache(device)
    return setmetatable({
        device = device,
        pipelines = {},
        layouts = {},
        watcher = reload.new_watcher()
    }, Cache)
end

function Cache:add_compute_from_file(name, path, layout, entry_point)
    local function load()
        local f = io.open(path, "r")
        if not f then return end
        local source = f:read("*all")
        f:close()
        
        local spirv = shader.compile_glsl(source, vk.VK_SHADER_STAGE_COMPUTE_BIT)
        local mod = shader.create_module(self.device, spirv)
        local pipe = M.create_compute_pipeline(self.device, layout, mod, entry_point)
        
        if self.pipelines[name] then
            vk.vkDestroyPipeline(self.device, self.pipelines[name], nil)
        end
        
        self.pipelines[name] = pipe
        self.layouts[name] = layout
        print("Pipeline '" .. name .. "' loaded/reloaded from: " .. path)
    end
    
    load()
    self.watcher:watch(path, load)
end

function Cache:update()
    self.watcher:update()
end

function Cache:get(name)
    return self.pipelines[name], self.layouts[name]
end

return M
