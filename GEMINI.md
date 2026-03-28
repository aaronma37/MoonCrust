# MoonCrust: Senior Engineer & AI Guidelines

MoonCrust is a minimalist Vulkan 1.4 compute and render kernel (1% C++ / 99% Lua). When writing code for this project, adhere to these technical mandates:

## 📜 Vulkan FFI Protocol
- **DO NOT** guess Vulkan struct fields. Always refer to `VULKAN_CHEATSHEET.md` for exact layouts and field names.
- **sType Requirement**: Every Vulkan struct created via `ffi.new` MUST include the correct `sType`.
  - *Example:* `ffi.new("VkBufferCreateInfo", { sType = vk.VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO, ... })`
- **Bindless First**: Use `mc.gpu.get_bindless_set()` and descriptors via indexing. Avoid legacy binding patterns.

## 🛠️ Development & Validation
- **CLI Linting**: Always run the binary with the `--lint` flag to catch common sType mismatches and structural errors.
  - `./build/mooncrust examples/your_example/main.lua --lint`
- **Memory Management**: Use `mc.buffer` and `mc.image` factories which utilize the internal Lua-TLSF allocator. Avoid raw `vkAllocateMemory` unless doing something highly specialized.
- **Render Graph**: Prefer adding passes to the `RenderGraph` (see `vulkan/graph.lua`) to automate barriers and layout transitions.

## 📂 Project Structure
- `src/lua/vulkan/`: Core Vulkan FFI wrappers and resource management.
- `src/lua/mc/`: High-level "Sugar" API for common tasks (GPU, Math, Input).
- `examples/`: Reference implementations for various GPU-driven techniques.
