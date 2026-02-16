import xml.etree.ElementTree as ET
import urllib.request
import os
import re

VK_XML_URL = "https://raw.githubusercontent.com/KhronosGroup/Vulkan-Docs/main/xml/vk.xml"
OUTPUT_FILE = "src/lua/vulkan/ffi.lua"

def download_vk_xml():
    if not os.path.exists("tools/vk.xml"):
        print("Downloading vk.xml...")
        urllib.request.urlretrieve(VK_XML_URL, "tools/vk.xml")

def evaluate_c_expression(expr):
    if not expr: return "0"
    if "(~0ULL)" in expr or "(~0U)" in expr or "(~0)" in expr: return "0xFFFFFFFFFFFFFFFFULL"
    if "(~1ULL)" in expr or "(~1U)" in expr or "(~1)" in expr: return "0xFFFFFFFFFFFFFFFEULL"
    if "(~2ULL)" in expr or "(~2U)" in expr or "(~2)" in expr: return "0xFFFFFFFFFFFFFFFDULL"
    
    expr = expr.replace("ULL", "").replace("ull", "")
    expr = expr.replace("U", "").replace("u", "")
    expr = expr.replace("F", "").replace("f", "")
    expr = expr.replace("L", "").replace("l", "")
    return expr

def is_vulkan_api(node):
    api = node.get("api")
    if api is None: return True
    apis = api.split(",")
    return "vulkan" in apis

def generate_ffi():
    tree = ET.parse("tools/vk.xml")
    root = tree.getroot()

    constants = {}
    blacklist = {"L", "U", "F"}
    # First pass for direct values
    for enums in root.findall("enums"):
        for enum in enums.findall("enum"):
            if not is_vulkan_api(enum): continue
            ename = enum.get("name")
            if ename in blacklist: continue
            evalue = enum.get("value")
            ebitpos = enum.get("bitpos")
            if evalue:
                constants[ename] = evaluate_c_expression(evalue)
            elif ebitpos:
                constants[ename] = str(1 << int(ebitpos))
    
    # Second pass for aliases
    for enums in root.findall("enums"):
        for enum in enums.findall("enum"):
            if not is_vulkan_api(enum): continue
            ename = enum.get("name")
            alias = enum.get("alias")
            if alias and alias in constants:
                constants[ename] = constants[alias]

    # Third pass for extension enums
    # Formula: 1000000000 + (ext_num - 1) * 1000 + offset
    for extensions in root.findall("extensions/extension"):
        if not is_vulkan_api(extensions): continue
        ext_num = int(extensions.get("number") or 0)
        for enum in extensions.findall("require/enum"):
            ename = enum.get("name")
            offset = enum.get("offset")
            ext_num_local = int(enum.get("extnumber") or ext_num)
            if offset:
                val = 1000000000 + (ext_num_local - 1) * 1000 + int(offset)
                if enum.get("dir") == "-": val = -val
                constants[ename] = str(val)
            alias = enum.get("alias")
            if alias and alias in constants:
                constants[ename] = constants[alias]

    for feature in root.findall("feature"):
        if not is_vulkan_api(feature): continue
        for enum in feature.findall("require/enum"):
            ename = enum.get("name")
            offset = enum.get("offset")
            ext_num = int(enum.get("extnumber") or 0)
            if offset and ext_num:
                val = 1000000000 + (ext_num - 1) * 1000 + int(offset)
                constants[ename] = str(val)
            alias = enum.get("alias")
            if alias and alias in constants:
                constants[ename] = constants[alias]

    def fast_replace(text):
        # Repeat replacement to handle nested constants in expressions
        for _ in range(3):
            text = re.sub(r'\b[A-Z0-9_]+\b', lambda m: constants.get(m.group(0), m.group(0)), text)
        return text

    with open(OUTPUT_FILE, "w") as f:
        f.write("-- Auto-generated Vulkan FFI bindings for MoonCrust\n")
        f.write("local ffi = require('ffi')\n\n")
        f.write("ffi.cdef[[\n")
        
        f.write("    typedef unsigned char uint8_t;\n")
        f.write("    typedef unsigned short uint16_t;\n")
        f.write("    typedef unsigned int uint32_t;\n")
        f.write("    typedef unsigned long long uint64_t;\n")
        f.write("    typedef signed char int8_t;\n")
        f.write("    typedef short int16_t;\n")
        f.write("    typedef int int32_t;\n")
        f.write("    typedef long long int64_t;\n")
        f.write("    typedef size_t size_t;\n")
        f.write("    typedef size_t uintptr_t;\n")
        
        known_types = {
            "uint8_t", "uint16_t", "uint32_t", "uint64_t", "int8_t", "int16_t", "int32_t", "int64_t", "size_t", "uintptr_t",
            "void", "char", "float", "double", "int", "long", "short", "unsigned"
        }
        
        # Base types
        for types in root.findall("types/type"):
            if not is_vulkan_api(types): continue
            category = types.get("category")
            if category in ["basetype", "bitmask"]:
                name_tag = types.find("name")
                type_tag = types.find("type")
                if name_tag is not None and type_tag is not None:
                    f.write(f"    typedef {type_tag.text} {name_tag.text};\n")
                    known_types.add(name_tag.text)

        # Enum and Bitmask Forward Declarations (including aliases)
        for types in root.findall("types/type"):
            if not is_vulkan_api(types): continue
            category = types.get("category")
            if category in ["enum", "bitmask"]:
                name = types.get("name")
                if name:
                    f.write(f"    typedef int {name};\n")
                    known_types.add(name)

        for enums in root.findall("enums"):
            if not is_vulkan_api(enums): continue
            name = enums.get("name")
            if name and name != "API Constants" and name not in known_types:
                f.write(f"    typedef int {name};\n")
                known_types.add(name)

        f.write("    typedef uint32_t VkFlags;\n")
        f.write("    typedef uint64_t VkDeviceSize;\n")
        f.write("    typedef uint64_t VkDeviceAddress;\n")
        f.write("    typedef uint32_t VkSampleMask;\n")
        known_types.update(["VkFlags", "VkDeviceSize", "VkDeviceAddress", "VkSampleMask"])
        
        # Struct and Handle Forward Declarations
        for types in root.findall("types/type"):
            if not is_vulkan_api(types): continue
            category = types.get("category")
            if category == "handle":
                name_tag = types.find("name")
                if name_tag is not None:
                    f.write(f"    typedef struct {name_tag.text}_T* {name_tag.text};\n")
                    known_types.add(name_tag.text)
            elif category == "struct":
                f.write(f"    typedef struct {types.get('name')} {types.get('name')};\n")
                known_types.add(types.get('name'))
            elif category == "union":
                f.write(f"    typedef union {types.get('name')} {types.get('name')};\n")
                known_types.add(types.get('name'))

        # Func Pointers (PFN_*)
        for type_node in root.findall("types/type"):
            if not is_vulkan_api(type_node): continue
            if type_node.get("category") == "funcpointer":
                proto = type_node.find("proto")
                if proto is not None:
                    ret_type = "".join(proto.itertext()).replace(proto.find("name").text, "").strip()
                    pfn_name = proto.find("name").text
                    params = []
                    for param in type_node.findall("param"):
                        params.append("".join(param.itertext()).strip())
                    f.write(f"    typedef {ret_type} (*{pfn_name})({', '.join(params)});\n")
                    known_types.add(pfn_name)
                else:
                    pfn_text = "".join(type_node.itertext()).strip()
                    if "typedef" in pfn_text:
                        pfn_text = pfn_text.replace("VKAPI_PTR", "").replace("VKAPI_ATTR", "").replace("VKAPI_CALL", "")
                        if not pfn_text.endswith(";"): pfn_text += ";"
                        f.write(f"    {pfn_text}\n")
                        # Extract name from typedef void (VKAPI_PTR *PFN_vkVoidFunction)(void);
                        m = re.search(r'\(\s*\*\s*([A-Za-z0-9_]+)\s*\)', pfn_text)
                        if m: known_types.add(m.group(1))

        # Topologically sort structs
        struct_defs = {}
        unknown_types = set()
        for types in root.findall("types/type"):
            if not is_vulkan_api(types): continue
            category = types.get("category")
            if category in ["struct", "union"]:
                s_name = types.get("name")
                members = []
                deps = set()
                for member in types.findall("member"):
                    if not is_vulkan_api(member): continue
                    m_type_node = member.find("type")
                    if m_type_node is not None:
                        m_type = m_type_node.text
                        m_stars = (m_type_node.tail or "").strip()
                        if "*" not in m_stars:
                            if m_type.startswith("Vk"):
                                deps.add(m_type)
                            elif m_type not in known_types:
                                unknown_types.add(m_type)
                        else:
                            if m_type not in known_types and not m_type.startswith("Vk"):
                                unknown_types.add(m_type)
                    
                    m_name_node = member.find("name")
                    m_name = m_name_node.text
                    
                    # Construct clean declaration: type + stars + name + array
                    # Skip <comment> tags during text collection
                    m_parts = []
                    if member.text: m_parts.append(member.text)
                    for child in member:
                        if child.tag != "comment":
                            m_parts.append("".join(child.itertext()))
                        if child.tail: m_parts.append(child.tail)
                    
                    m_type_full = "".join(m_parts).split("//")[0].split("/*")[0].strip()
                    # Only remove const if it's NOT a pointer (LuaJIT needs const for auto string conv)
                    if "*" not in m_type_full:
                        m_type_full = re.sub(r'\bconst\b\s*', '', m_type_full)
                    
                    m_line = fast_replace(m_type_full)
                    m_line = re.sub(r':\s*[0-9]+', '', m_line) # bitfields
                    m_line = re.sub(r'\b([0-9]+)[UIFLL]+\b', r'\1', m_line)
                    m_line = re.sub(r'\s+', ' ', m_line).strip()
                    members.append(m_line)
                struct_defs[s_name] = {"members": members, "deps": deps, "category": category}

        command_defs = []
        written_commands = set()
        for commands in root.findall("commands/command"):
            if not is_vulkan_api(commands): continue
            proto = commands.find("proto")
            if proto is not None:
                func_name = proto.find("name").text
                if func_name in written_commands: continue
                written_commands.add(func_name)
                
                ret_type_node = proto.find("type")
                ret_type = ret_type_node.text if ret_type_node is not None else "void"
                if ret_type not in known_types and not ret_type.startswith("Vk"):
                    unknown_types.add(ret_type)
                
                ret_parts = []
                if proto.text: ret_parts.append(proto.text)
                for child in proto:
                    if child.tag != "comment":
                        ret_parts.append("".join(child.itertext()))
                    if child.tail: ret_parts.append(child.tail)
                ret_full = "".join(ret_parts).replace(proto.find("name").text, "").strip()
                if "*" not in ret_full:
                    ret_full = re.sub(r'\bconst\b\s*', '', ret_full).strip()
                
                func_name = proto.find("name").text
                params = []
                for p in commands.findall("param"):
                    if not is_vulkan_api(p): continue
                    p_type_node = p.find("type")
                    p_type = p_type_node.text if p_type_node is not None else "void"
                    if p_type not in known_types and not p_type.startswith("Vk"):
                        unknown_types.add(p_type)
                    
                    p_parts = []
                    if p.text: p_parts.append(p.text)
                    for child in p:
                        if child.tag != "comment":
                            p_parts.append("".join(child.itertext()))
                        if child.tail: p_parts.append(child.tail)
                    p_full = "".join(p_parts).strip()
                    if "*" not in p_full:
                        p_full = re.sub(r'\bconst\b\s*', '', p_full).strip()
                    p_full = fast_replace(p_full)
                    params.append(p_full)
                
                command_defs.append(f"    {ret_full} {func_name}({', '.join(params)});\n")

        # Output unknown types as void* stubs
        for ut in sorted(list(unknown_types)):
            f.write(f"    typedef void* {ut};\n")
        f.write("\n")

        written_structs = set()
        def write_struct(s_name):
            if s_name in written_structs or s_name not in struct_defs: return
            if s_name == "VkBaseOutStructure" or s_name == "VkBaseInStructure":
                f.write(f"    struct {s_name} {{ VkStructureType sType; struct {s_name}* pNext; }};\n")
                written_structs.add(s_name)
                return
            for dep in struct_defs[s_name]["deps"]:
                write_struct(dep)
            cat = struct_defs[s_name]["category"]
            f.write(f"    {cat} {s_name} {{\n")
            for m in struct_defs[s_name]["members"]:
                f.write(f"        {m};\n")
            f.write(f"    }};\n\n")
            written_structs.add(s_name)

        for s_name in struct_defs:
            write_struct(s_name)

        for cmd in command_defs:
            f.write(cmd)

        f.write("]]\n\n")
        f.write("local ffi_lib = ffi.load('vulkan')\n")
        f.write("local M = { _lib = ffi_lib }\n")
        for c_name, c_val in constants.items():
            f.write(f"M.{c_name} = {c_val}\n")
        f.write("setmetatable(M, { __index = function(t, k)\n")
        f.write("    local ok, res = pcall(function() return ffi_lib[k] end)\n")
        f.write("    if ok then return res end\n")
        f.write("    return ffi.C[k]\n")
        f.write("end })\n\n")
        f.write("M.VK_API_VERSION_1_3 = 4202496\n")
        f.write("return M\n")

if __name__ == "__main__":
    download_vk_xml()
    generate_ffi()
    print(f"Generated {OUTPUT_FILE}")
