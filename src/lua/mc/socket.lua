local ffi = require("ffi")

ffi.cdef[[
    typedef uint32_t socklen_t;
    typedef uint16_t in_port_t;
    typedef uint32_t in_addr_t;

    struct in_addr {
        in_addr_t s_addr;
    };

    struct sockaddr_in {
        int16_t sin_family;
        in_port_t sin_port;
        struct in_addr sin_addr;
        char sin_zero[8];
    };

    int socket(int domain, int type, int protocol);
    int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
    ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags, struct sockaddr *src_addr, socklen_t *addrlen);
    int close(int fd);
    int fcntl(int fd, int cmd, ...);
    
    uint16_t htons(uint16_t hostshort);
    in_addr_t inet_addr(const char *cp);
]]

local M = {}

local AF_INET = 2
local SOCK_DGRAM = 2
local F_SETFL = 4
local O_NONBLOCK = 2048

function M.udp_listen(ip, port)
    local fd = ffi.C.socket(AF_INET, SOCK_DGRAM, 0)
    if fd < 0 then return nil, "Failed to create socket" end

    -- Set non-blocking
    ffi.C.fcntl(fd, F_SETFL, ffi.cast("int", O_NONBLOCK))

    local addr = ffi.new("struct sockaddr_in")
    addr.sin_family = AF_INET
    addr.sin_port = ffi.C.htons(port)
    addr.sin_addr.s_addr = ffi.C.inet_addr(ip)

    local res = ffi.C.bind(fd, ffi.cast("const struct sockaddr*", addr), ffi.sizeof(addr))
    if res < 0 then
        ffi.C.close(fd)
        return nil, "Failed to bind socket"
    end

    return {
        fd = fd,
        receive = function(self)
            local buf = ffi.new("char[4096]")
            local res = ffi.C.recvfrom(self.fd, buf, 4096, 0, nil, nil)
            if res > 0 then
                return ffi.string(buf, res)
            end
            return nil
        end,
        close = function(self)
            ffi.C.close(self.fd)
        end
    }
end

return M
