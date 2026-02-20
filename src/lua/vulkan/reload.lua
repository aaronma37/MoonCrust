local ffi = require("ffi")

ffi.cdef[[
    typedef long time_t;
    struct timespec {
        time_t tv_sec;
        long tv_nsec;
    };
    struct stat {
        unsigned long st_dev;
        unsigned long st_ino;
        unsigned long st_nlink;
        unsigned int st_mode;
        unsigned int st_uid;
        unsigned int st_gid;
        int __pad0;
        unsigned long st_rdev;
        long st_size;
        long st_blksize;
        long st_blocks;
        struct timespec st_atim;
        struct timespec st_mtim;
        struct timespec st_ctim;
        long __glibc_reserved[3];
    };
    int stat(const char *path, struct stat *buf);
]]

local M = {}

local function get_mtime(path)
    local s = ffi.new("struct stat")
    if ffi.C.stat(path, s) == 0 then
        return s.st_mtim.tv_sec
    end
    return 0
end

local Watcher = {}
Watcher.__index = Watcher

function M.new_watcher()
    return setmetatable({
        files = {}
    }, Watcher)
end

function Watcher:watch(path, callback)
    self.files[path] = {
        mtime = get_mtime(path),
        callback = callback
    }
end

function Watcher:update()
    for path, info in pairs(self.files) do
        local current_mtime = get_mtime(path)
        if current_mtime > info.mtime then
            info.mtime = current_mtime
            info.callback(path)
        end
    end
end

return M
