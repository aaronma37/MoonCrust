import re
import os

FFI_PATH = "src/lua/vulkan/ffi.lua"
OUTPUT_PATH = "VULKAN_CHEATSHEET.md"

STRUCTS_TO_EXTRACT = [
    "VkBufferCreateInfo", "VkImageCreateInfo", "VkMemoryBarrier",
    "VkGraphicsPipelineCreateInfo", "VkComputePipelineCreateInfo",
    "VkSubmitInfo", "VkCommandBufferBeginInfo", "VkRenderPassBeginInfo",
    "VkPipelineLayoutCreateInfo", "VkDescriptorSetLayoutCreateInfo",
    "VkImageMemoryBarrier", "VkBufferMemoryBarrier",
    "VkImageViewCreateInfo", "VkSamplerCreateInfo",
    "VkDescriptorPoolCreateInfo", "VkDescriptorSetAllocateInfo",
    "VkWriteDescriptorSet", "VkRenderingInfo", "VkRenderingAttachmentInfo"
]

def extract_meta():
    with open(FFI_PATH, "r") as f:
        content = f.read()

    # Extract Constants for sTypes
    stypes = {}
    stype_matches = re.findall(r"M\.VK_STRUCTURE_TYPE_([A-Z0-9_]+)\s*=\s*([0-9]+)", content)
    for name, val in stype_matches:
        stypes[name] = val

    cheatsheet = "# MoonCrust Vulkan Cheat Sheet for LLM\n\n"
    cheatsheet += "This file contains a mapping of common Vulkan structs and their expected `sType` and fields.\n\n"
    
    cheatsheet += "## Common sTypes\n"
    cheatsheet += "| Struct Name | sType Constant |\n"
    cheatsheet += "| :--- | :--- |\n"
    for sname in STRUCTS_TO_EXTRACT:
        # Convert VkBufferCreateInfo -> BUFFER_CREATE_INFO
        short_name = sname[2:]
        # Convert CamelCase to SNAKE_CASE
        snake_name = re.sub(r'(?<!^)(?=[A-Z])', '_', short_name).upper()
        full_stype = "VK_STRUCTURE_TYPE_" + snake_name
        if full_stype in ["VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO", "VK_STRUCTURE_TYPE_BUFFER_MEMORY_BARRIER", "VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER"]:
             pass # just verification
        cheatsheet += f"| {sname} | vk.{full_stype} |\n"

    cheatsheet += "\n## Struct Definitions\n"
    for sname in STRUCTS_TO_EXTRACT:
        pattern = rf"struct {sname} \{{(.*?)\}};"
        match = re.search(pattern, content, re.DOTALL)
        if match:
            fields_raw = match.group(1).strip()
            fields = []
            for line in fields_raw.split(";"):
                line = line.strip()
                if line:
                    fields.append(line)
            
            cheatsheet += f"### {sname}\n"
            cheatsheet += "```c\n"
            cheatsheet += f"struct {sname} {{\n"
            for f in fields:
                cheatsheet += f"    {f};\n"
            cheatsheet += "};\n"
            cheatsheet += "```\n\n"

    with open(OUTPUT_PATH, "w") as f:
        f.write(cheatsheet)

if __name__ == "__main__":
    extract_meta()
    print(f"Generated {OUTPUT_PATH}")
