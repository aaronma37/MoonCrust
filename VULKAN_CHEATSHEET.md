# MoonCrust Vulkan Cheat Sheet for LLM

This file contains a mapping of common Vulkan structs and their expected `sType` and fields.

## Common sTypes
| Struct Name | sType Constant |
| :--- | :--- |
| VkBufferCreateInfo | vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO |
| VkImageCreateInfo | vk.VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO |
| VkMemoryBarrier | vk.VK_STRUCTURE_TYPE_MEMORY_BARRIER |
| VkGraphicsPipelineCreateInfo | vk.VK_STRUCTURE_TYPE_GRAPHICS_PIPELINE_CREATE_INFO |
| VkComputePipelineCreateInfo | vk.VK_STRUCTURE_TYPE_COMPUTE_PIPELINE_CREATE_INFO |
| VkSubmitInfo | vk.VK_STRUCTURE_TYPE_SUBMIT_INFO |
| VkCommandBufferBeginInfo | vk.VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO |
| VkRenderPassBeginInfo | vk.VK_STRUCTURE_TYPE_RENDER_PASS_BEGIN_INFO |
| VkPipelineLayoutCreateInfo | vk.VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO |
| VkDescriptorSetLayoutCreateInfo | vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO |
| VkImageMemoryBarrier | vk.VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER |
| VkBufferMemoryBarrier | vk.VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER |
| VkImageViewCreateInfo | vk.VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO |
| VkSamplerCreateInfo | vk.VK_STRUCTURE_TYPE_SAMPLER_CREATE_INFO |
| VkDescriptorPoolCreateInfo | vk.VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO |
| VkDescriptorSetAllocateInfo | vk.VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO |
| VkWriteDescriptorSet | vk.VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET |
| VkRenderingInfo | vk.VK_STRUCTURE_TYPE_RENDERING_INFO |
| VkRenderingAttachmentInfo | vk.VK_STRUCTURE_TYPE_RENDERING_ATTACHMENT_INFO |

## Struct Definitions
### VkBufferCreateInfo
```c
struct VkBufferCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkBufferCreateFlags flags;
    VkDeviceSize size;
    VkBufferUsageFlags usage;
    VkSharingMode sharingMode;
    uint32_t queueFamilyIndexCount;
    const uint32_t* pQueueFamilyIndices;
};
```

### VkImageCreateInfo
```c
struct VkImageCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkImageCreateFlags flags;
    VkImageType imageType;
    VkFormat format;
    VkExtent3D extent;
    uint32_t mipLevels;
    uint32_t arrayLayers;
    VkSampleCountFlagBits samples;
    VkImageTiling tiling;
    VkImageUsageFlags usage;
    VkSharingMode sharingMode;
    uint32_t queueFamilyIndexCount;
    const uint32_t* pQueueFamilyIndices;
    VkImageLayout initialLayout;
};
```

### VkMemoryBarrier
```c
struct VkMemoryBarrier {
    VkStructureType sType;
    const void* pNext;
    VkAccessFlags srcAccessMask;
    VkAccessFlags dstAccessMask;
};
```

### VkGraphicsPipelineCreateInfo
```c
struct VkGraphicsPipelineCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkPipelineCreateFlags flags;
    uint32_t stageCount;
    const VkPipelineShaderStageCreateInfo* pStages;
    const VkPipelineVertexInputStateCreateInfo* pVertexInputState;
    const VkPipelineInputAssemblyStateCreateInfo* pInputAssemblyState;
    const VkPipelineTessellationStateCreateInfo* pTessellationState;
    const VkPipelineViewportStateCreateInfo* pViewportState;
    const VkPipelineRasterizationStateCreateInfo* pRasterizationState;
    const VkPipelineMultisampleStateCreateInfo* pMultisampleState;
    const VkPipelineDepthStencilStateCreateInfo* pDepthStencilState;
    const VkPipelineColorBlendStateCreateInfo* pColorBlendState;
    const VkPipelineDynamicStateCreateInfo* pDynamicState;
    VkPipelineLayout layout;
    VkRenderPass renderPass;
    uint32_t subpass;
    VkPipeline basePipelineHandle;
    int32_t basePipelineIndex;
};
```

### VkComputePipelineCreateInfo
```c
struct VkComputePipelineCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkPipelineCreateFlags flags;
    VkPipelineShaderStageCreateInfo stage;
    VkPipelineLayout layout;
    VkPipeline basePipelineHandle;
    int32_t basePipelineIndex;
};
```

### VkSubmitInfo
```c
struct VkSubmitInfo {
    VkStructureType sType;
    const void* pNext;
    uint32_t waitSemaphoreCount;
    const VkSemaphore* pWaitSemaphores;
    const VkPipelineStageFlags* pWaitDstStageMask;
    uint32_t commandBufferCount;
    const VkCommandBuffer* pCommandBuffers;
    uint32_t signalSemaphoreCount;
    const VkSemaphore* pSignalSemaphores;
};
```

### VkCommandBufferBeginInfo
```c
struct VkCommandBufferBeginInfo {
    VkStructureType sType;
    const void* pNext;
    VkCommandBufferUsageFlags flags;
    const VkCommandBufferInheritanceInfo* pInheritanceInfo;
};
```

### VkRenderPassBeginInfo
```c
struct VkRenderPassBeginInfo {
    VkStructureType sType;
    const void* pNext;
    VkRenderPass renderPass;
    VkFramebuffer framebuffer;
    VkRect2D renderArea;
    uint32_t clearValueCount;
    const VkClearValue* pClearValues;
};
```

### VkPipelineLayoutCreateInfo
```c
struct VkPipelineLayoutCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkPipelineLayoutCreateFlags flags;
    uint32_t setLayoutCount;
    const VkDescriptorSetLayout* pSetLayouts;
    uint32_t pushConstantRangeCount;
    const VkPushConstantRange* pPushConstantRanges;
};
```

### VkDescriptorSetLayoutCreateInfo
```c
struct VkDescriptorSetLayoutCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkDescriptorSetLayoutCreateFlags flags;
    uint32_t bindingCount;
    const VkDescriptorSetLayoutBinding* pBindings;
};
```

### VkImageMemoryBarrier
```c
struct VkImageMemoryBarrier {
    VkStructureType sType;
    const void* pNext;
    VkAccessFlags srcAccessMask;
    VkAccessFlags dstAccessMask;
    VkImageLayout oldLayout;
    VkImageLayout newLayout;
    uint32_t srcQueueFamilyIndex;
    uint32_t dstQueueFamilyIndex;
    VkImage image;
    VkImageSubresourceRange subresourceRange;
};
```

### VkBufferMemoryBarrier
```c
struct VkBufferMemoryBarrier {
    VkStructureType sType;
    const void* pNext;
    VkAccessFlags srcAccessMask;
    VkAccessFlags dstAccessMask;
    uint32_t srcQueueFamilyIndex;
    uint32_t dstQueueFamilyIndex;
    VkBuffer buffer;
    VkDeviceSize offset;
    VkDeviceSize size;
};
```

### VkImageViewCreateInfo
```c
struct VkImageViewCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkImageViewCreateFlags flags;
    VkImage image;
    VkImageViewType viewType;
    VkFormat format;
    VkComponentMapping components;
    VkImageSubresourceRange subresourceRange;
};
```

### VkSamplerCreateInfo
```c
struct VkSamplerCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkSamplerCreateFlags flags;
    VkFilter magFilter;
    VkFilter minFilter;
    VkSamplerMipmapMode mipmapMode;
    VkSamplerAddressMode addressModeU;
    VkSamplerAddressMode addressModeV;
    VkSamplerAddressMode addressModeW;
    float mipLodBias;
    VkBool32 anisotropyEnable;
    float maxAnisotropy;
    VkBool32 compareEnable;
    VkCompareOp compareOp;
    float minLod;
    float maxLod;
    VkBorderColor borderColor;
    VkBool32 unnormalizedCoordinates;
};
```

### VkDescriptorPoolCreateInfo
```c
struct VkDescriptorPoolCreateInfo {
    VkStructureType sType;
    const void* pNext;
    VkDescriptorPoolCreateFlags flags;
    uint32_t maxSets;
    uint32_t poolSizeCount;
    const VkDescriptorPoolSize* pPoolSizes;
};
```

### VkDescriptorSetAllocateInfo
```c
struct VkDescriptorSetAllocateInfo {
    VkStructureType sType;
    const void* pNext;
    VkDescriptorPool descriptorPool;
    uint32_t descriptorSetCount;
    const VkDescriptorSetLayout* pSetLayouts;
};
```

### VkWriteDescriptorSet
```c
struct VkWriteDescriptorSet {
    VkStructureType sType;
    const void* pNext;
    VkDescriptorSet dstSet;
    uint32_t dstBinding;
    uint32_t dstArrayElement;
    uint32_t descriptorCount;
    VkDescriptorType descriptorType;
    const VkDescriptorImageInfo* pImageInfo;
    const VkDescriptorBufferInfo* pBufferInfo;
    const VkBufferView* pTexelBufferView;
};
```

### VkRenderingInfo
```c
struct VkRenderingInfo {
    VkStructureType sType;
    const void* pNext;
    VkRenderingFlags flags;
    VkRect2D renderArea;
    uint32_t layerCount;
    uint32_t viewMask;
    uint32_t colorAttachmentCount;
    const VkRenderingAttachmentInfo* pColorAttachments;
    const VkRenderingAttachmentInfo* pDepthAttachment;
    const VkRenderingAttachmentInfo* pStencilAttachment;
};
```

### VkRenderingAttachmentInfo
```c
struct VkRenderingAttachmentInfo {
    VkStructureType sType;
    const void* pNext;
    VkImageView imageView;
    VkImageLayout imageLayout;
    VkResolveModeFlagBits resolveMode;
    VkImageView resolveImageView;
    VkImageLayout resolveImageLayout;
    VkAttachmentLoadOp loadOp;
    VkAttachmentStoreOp storeOp;
    VkClearValue clearValue;
};
```

