import os
import sys

def encode_string(s):
    # Converts a string to a C byte array
    return ','.join(str(b) for b in s.encode('utf-8')) + ',0'

def main():
    if len(sys.argv) < 3:
        print("Usage: embed_lua.py <output_file> <lua_files...>")
        sys.exit(1)

    output_file = sys.argv[1]
    lua_files = sys.argv[2:]

    with open(output_file, 'w') as out:
        out.write('#pragma once\n\n')
        out.write('#include <unordered_map>\n')
        out.write('#include <string>\n\n')
        
        # Write individual file contents
        for file in lua_files:
            # We want the key to be relative to src/lua, e.g., 'vulkan/ffi.lua'
            key = os.path.relpath(file, 'src/lua')
            # Sanitize the filename for a C variable name
            var_name = "lua_code_" + key.replace('/', '_').replace('.', '_')
            
            with open(file, 'r', encoding='utf-8') as f:
                content = f.read()
                
            c_array = encode_string(content)
            out.write(f'static const unsigned char {var_name}[] = {{{c_array}}};\n')
            out.write(f'static const unsigned int {var_name}_len = {len(content.encode("utf-8"))};\n\n')

        # Create a map to fetch these files
        out.write('static const std::unordered_map<std::string, std::pair<const unsigned char*, unsigned int>> embedded_lua_files = {\n')
        for file in lua_files:
            key = os.path.relpath(file, 'src/lua')
            var_name = "lua_code_" + key.replace('/', '_').replace('.', '_')
            out.write(f'    {{"{key}", {{{var_name}, {var_name}_len}}}},\n')
        out.write('};\n')

if __name__ == '__main__':
    main()
