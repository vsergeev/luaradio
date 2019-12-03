---
-- Network server and client classes.
--
-- @module radio.utilities.network_utils

local ffi = require('ffi')

local platform = require('radio.core.platform')
local class = require('radio.core.class')
local debug = require('radio.core.debug')

if platform.os == "Linux" then
    ffi.cdef[[
        typedef uint16_t sa_family_t;
        typedef uint32_t socklen_t;

        struct sockaddr {
            sa_family_t sa_family;
            char sa_data[14];
        };

        struct sockaddr_storage {
            sa_family_t sa_family;
            char sa_data[126];
        };

        struct sockaddr_un {
	        sa_family_t sun_family;
	        char sun_path[108];
        };

        struct sockaddr_in {
            sa_family_t sin_family;
            uint16_t sin_port;
            struct in_addr {
                uint32_t s_addr;
            } sin_addr;
            char sin_zero[8];
        };

        struct sockaddr_in6 {
            sa_family_t sin6_family;
            uint16_t sin6_port;
            uint32_t sin6_flowinfo;
            struct in6_addr {
                uint8_t u6_addr8[16];
            } sin6_addr;
            uint32_t sin6_scope_id;
        };
    ]]
elseif ffi.os == "BSD" or ffi.os == "OSX" then
    ffi.cdef[[
        typedef uint8_t sa_family_t;
        typedef uint32_t socklen_t;

        struct sockaddr {
            uint8_t sa_len;
            sa_family_t sa_family;
            char sa_data[14];
        };

        struct sockaddr_storage {
            uint8_t sa_len;
            sa_family_t sa_family;
            char sa_data[126];
        };

        struct sockaddr_un {
            uint8_t sun_len;
	        sa_family_t sun_family;
	        char sun_path[104];
        };

        struct sockaddr_in {
            uint8_t sin_len;
            sa_family_t sin_family;
            uint16_t sin_port;
            struct in_addr {
                uint32_t s_addr;
            } sin_addr;
            char sin_zero[8];
        };

        struct sockaddr_in6 {
            uint8_t sin6_len;
            sa_family_t sin6_family;
            uint16_t sin6_port;
            uint32_t sin6_flowinfo;
            struct in6_addr {
                uint8_t u6_addr8[16];
            } sin6_addr;
            uint32_t sin6_scope_id;
        };
    ]]
end

ffi.cdef[[
    struct addrinfo {
        int ai_flags;
        int ai_family;
        int ai_socktype;
        int ai_protocol;
        socklen_t ai_addrlen;
        struct sockaddr *ai_addr;
        char *ai_canonname;
        struct addrinfo *ai_next;
    };

    uint16_t ntohs(uint16_t netshort);
    const char *inet_ntop(int af, const void *src, char *dst, socklen_t size);

    int getaddrinfo(const char *node, const char *service, const struct addrinfo *hints, struct addrinfo **res);
    void freeaddrinfo(struct addrinfo *res);

    int socket(int domain, int type, int protocol);
    int getsockopt(int socket, int level, int option_name, void *option_value, socklen_t *option_len);
    int setsockopt(int socket, int level, int option_name, const void *option_value, socklen_t option_len);

    int bind(int socket, const struct sockaddr *address, socklen_t address_len);
    int connect(int socket, const struct sockaddr *address, socklen_t address_len);

    int listen(int socket, int backlog);
    int accept(int socket, struct sockaddr *restrict address, socklen_t *restrict address_len);

    ssize_t send(int socket, const void *buffer, size_t length, int flags);
    ssize_t recv(int socket, void *buffer, size_t length, int flags);
]]

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

---
-- Parse an address string into host, port.
--
-- @internal
-- @function parse_address
-- @tparam string address Address as host:port.
-- @treturn string Address
-- @treturn int Port
local function parse_address(address)
    local host = address:gmatch("(.*):(%d*)")()
    local port = address:gmatch(".*:(%d*)")()

    if not host or host == "" then
        error("Invalid address \"" .. address .. "\": invalid host")
    elseif not port or port == "" then
        error("Invalid address \"" .. address .. "\": invalid port")
    end

    return host, port
end

---
-- Resolve host and port into an socket address structure.
--
-- @internal
-- @function resolve_address
-- @tparam int socket_family Socket family filter
-- @tparam int socket_type Socket type filter
-- @tparam string host Host to resolve
-- @tparam int port Port to resolve
-- @treturn int Resolved socket family
-- @treturn int Resolved socket type
-- @treturn cdata|nil Resolved socket address structure
local function resolve_address(socket_family, socket_type, host, port)
    local hints = ffi.new("struct addrinfo")
    hints.ai_family = socket_family
    hints.ai_socktype = socket_type

    -- Resolve the address
    local result = ffi.new("struct addrinfo *[1]")
    local ret = ffi.C.getaddrinfo(host, port, hints, result)
    if ret < 0 then
        error("getaddrinfo(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    elseif result[0] == nil then
        return socket_family, socket_type, nil
    end

    -- Make a copy of the first result
    local result_family = result[0].ai_family
    local result_type = result[0].ai_socktype
    local result_sockaddr = ffi.new("struct sockaddr_storage")
    ffi.copy(result_sockaddr, result[0].ai_addr, math.min(ffi.sizeof(result_sockaddr), result[0].ai_addrlen))

    ffi.C.freeaddrinfo(result[0])

    return result_family, result_type, result_sockaddr
end


---
-- Format a socket address structure as a string.
--
-- @internal
-- @function format_address
-- @tparam cdata Socket address structure
-- @tparam string Address as a string
local function format_address(sock_addr)
    local sock_addr = ffi.cast("const struct sockaddr *", sock_addr)

    if sock_addr.sa_family == ffi.C.AF_INET then
        local sock_addr_in, buf = ffi.cast("const struct sockaddr_in *", sock_addr)
        local buf = ffi.new("char[16]")

        local ret = ffi.C.inet_ntop(ffi.C.AF_INET, sock_addr_in.sin_addr, buf, ffi.sizeof(buf))

        local addr = ret and ffi.string(ret) or "unknown"
        local port = ffi.C.ntohs(sock_addr_in.sin_port)

        return string.format("%s:%d", ffi.string(ret), port)
    elseif sock_addr.sa_family == ffi.C.AF_INET6 then
        local sock_addr_in6 = ffi.cast("const struct sockaddr_in6 *", sock_addr)
        local buf = ffi.new("char[48]")

        local ret = ffi.C.inet_ntop(ffi.C.AF_INET6, sock_addr_in6.sin6_addr, buf, ffi.sizeof(buf))

        local addr = ret and ffi.string(ret) or "unknown"
        local port = ffi.C.ntohs(sock_addr_in6.sin6_port)

        return string.format("%s:%d", ffi.string(ret), port)
    elseif sock_addr.sa_family == ffi.C.AF_UNIX then
        -- sockaddr_un not populated with socket path, so return dummy string
        return "<unix socket>"
    end

    return "unknown"
end

--------------------------------------------------------------------------------
-- Network Server
--------------------------------------------------------------------------------

---
-- Network Server class.
--
-- @internal
-- @class NetworkServer
-- @tparam string transport Transport type. Choice of "tcp" or "unix".
-- @tparam string address Address, as host:port for TCP, or as a file path for
--                        for UNIX.
local NetworkServer = class.factory()

function NetworkServer.new(transport, address)
    local self = setmetatable({}, NetworkServer)

    self.transport = assert(transport, "Missing argument #1 (transport)")
    self.address = assert(address, "Missing argument #2 (address)")
    assert(self.transport == "tcp" or self.transport == "unix", string.format("Invalid transport \"%s\"", self.transport))

    self.server_fd = nil
    self.client_fd = nil

    return self
end

---
-- Initialize socket and start listening.
--
-- @internal
-- @function NetworkServer:listen
function NetworkServer:listen()
    local socket_family, socket_type, server_addr

    if self.transport == "tcp" then
        socket_family = ffi.C.AF_UNSPEC
        socket_type = ffi.C.SOCK_STREAM

        -- Split address into host and port
        local host, port = parse_address(self.address)

        -- Resolve socket addess
        socket_family, socket_type, server_addr = resolve_address(socket_family, socket_type, host, port)
        if not server_addr then
            error("Error resolving address \"" .. self.address .. "\"")
        end
    elseif self.transport == "unix" then
        socket_family = ffi.C.AF_UNIX
        socket_type = ffi.C.SOCK_STREAM

        -- Unlink potentially existing socket file
        ffi.C.unlink(self.address)

        -- Create socket address
        server_addr = ffi.new("struct sockaddr_un")
        server_addr.sun_family = ffi.C.AF_UNIX
        server_addr.sun_path = self.address
    end

    -- Create socket
    self.server_fd = ffi.C.socket(socket_family, socket_type, 0)
    if self.server_fd < 0 then
        error("socket(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Bind socket
    local ret = ffi.C.bind(self.server_fd, ffi.cast("const struct sockaddr *", server_addr), ffi.sizeof(server_addr))
    if ret ~= 0 then
        error("bind(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Listen on socket
    local ret = ffi.C.listen(self.server_fd, 1)
    if ret ~= 0 then
        error("listen(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    debug.print("[NetworkServer] Listening on " .. (self.transport == "unix" and self.address or format_address(server_addr)))
end

---
-- Accept a client with blocking.
--
-- @internal
-- @function NetworkClient:connect
function NetworkServer:accept()
    -- Create client address structure
    client_addr = ffi.new("struct sockaddr_storage")
    client_addr_size = ffi.new("socklen_t[1]", ffi.sizeof(client_addr))

    -- Accept on server socket
    local fd = ffi.C.accept(self.server_fd, ffi.cast("struct sockaddr *", client_addr), client_addr_size)
    if fd < 0 then
        error("accept(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    self.client_fd = fd

    debug.print("[NetworkServer] Accepted client from " .. (self.transport == "unix" and self.address or format_address(client_addr)))
end

---
-- Try to accept a client without blocking.
--
-- @internal
-- @function NetworkServer:try_accept
-- @treturn bool Client was accepted
function NetworkServer:try_accept()
    -- Poll server fd
    local pollfds = ffi.new("struct pollfd[1]")
    pollfds[0].fd = self.server_fd
    pollfds[0].events = ffi.C.POLLIN

    local ret = ffi.C.poll(pollfds, 1, 0)
    if ret < 0 then
        error("poll(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    elseif ret == 0 then
        return false
    end

    self:accept()

    return true
end

---
-- Test if a client is connected to the server.
--
-- @internal
-- @function NetworkServer:connected
-- @treturn bool Connected
function NetworkServer:connected()
    return self.client_fd ~= nil
end

---
-- Receive into buffer up to size bytes from the client.
--
-- @internal
-- @function NetworkServer:recv
-- @tparam cdata buf Buffer
-- @tparam int size Buffer size
-- @treturn int Number of bytes received or zero on disconnect
function NetworkServer:recv(buf, size)
    if not self.client_fd then
        return 0
    end

    local ret = ffi.C.recv(self.client_fd, buf, size, 0)
    if ret == 0 then
        self.client_fd = nil
        return 0
    elseif ret < 0 then
        error("recv(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    return ret
end

---
-- Send length bytes of buffer to the client.
--
-- @internal
-- @function NetworkServer:sendall
-- @tparam cdata buf Buffer
-- @tparam int size Buffer size
function NetworkServer:sendall(buf, size)
    if not self.client_fd then
        return
    end

    local sent = 0
    while sent < size do
        local ret = ffi.C.send(self.client_fd, ffi.cast("const char *", buf) + sent, size - sent, ffi.C.MSG_NOSIGNAL)
        if ret < 0 then
            local errno = ffi.errno()
            if errno == ffi.C.EPIPE or errno == ffi.C.ECONNRESET then
                self.client_fd = nil
                return
            else
                error("send(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end
        end

        sent = sent + ret
    end
end

---
-- Close client and listening sockets.
--
-- @internal
-- @function NetworkServer:close
function NetworkServer:close()
    if self.client_fd ~= nil then
        if ffi.C.close(self.client_fd) ~= 0 then
            error("close(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
        self.client_fd = nil
    end
    if self.server_fd ~= nil then
        if ffi.C.close(self.server_fd) ~= 0 then
            error("close(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end
        self.server_fd = nil
    end
end

--------------------------------------------------------------------------------
-- Network Client
--------------------------------------------------------------------------------

---
-- Network Client class.
--
-- @internal
-- @class NetworkClient
-- @tparam string transport Transport type. Choice of "tcp" or "unix".
-- @tparam string address Address, as host:port for TCP, or as a file path for
--                        for UNIX.
local NetworkClient = class.factory()

function NetworkClient.new(transport, address)
    local self = setmetatable({}, NetworkClient)

    self.transport = assert(transport, "Missing argument #1 (transport)")
    self.address = assert(address, "Missing argument #2 (address)")
    assert(self.transport == "tcp" or self.transport == "unix", string.format("Invalid transport \"%s\"", self.transport))

    self.fd = nil
    self.fd_flags = nil
    self._connected = false

    return self
end

---
-- Connect to server with blocking.
--
-- @internal
-- @function NetworkClient:connect
function NetworkClient:connect()
    local socket_family, socket_type, server_addr

    if self.transport == "tcp" then
        socket_family = ffi.C.AF_UNSPEC
        socket_type = ffi.C.SOCK_STREAM

        -- Split address into host and port
        local host, port = parse_address(self.address)

        -- Resolve socket addess
        socket_family, socket_type, server_addr = resolve_address(socket_family, socket_type, host, port)
        if not server_addr then
            error("Error resolving address \"" .. self.address .. "\"")
        end
    elseif self.transport == "unix" then
        socket_family = ffi.C.AF_UNIX
        socket_type = ffi.C.SOCK_STREAM

        -- Create socket address
        server_addr = ffi.new("struct sockaddr_un")
        server_addr.sun_family = ffi.C.AF_UNIX
        server_addr.sun_path = self.address
    end

    -- Create socket
    self.fd = ffi.C.socket(socket_family, socket_type, 0)
    if self.fd < 0 then
        error("socket(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    -- Connect to server
    local ret = ffi.C.connect(self.fd, ffi.cast("const struct sockaddr *", server_addr), ffi.sizeof(server_addr))
    if ret < 0 and ffi.errno() == ffi.C.ECONNREFUSED then
        return false
    elseif ret < 0 then
        error("connect(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    self._connected = true

    debug.print("[NetworkClient] Connected to " .. (self.transport == "unix" and self.address or format_address(server_addr)))

    return true
end

---
-- Connect to server without blocking.
--
-- @internal
-- @function NetworkClient:try_connect
-- @treturn bool Connection succeeded
function NetworkClient:try_connect()
    if not self.fd then
        local socket_family, socket_type, server_addr

        if self.transport == "tcp" then
            socket_family = ffi.C.AF_UNSPEC
            socket_type = ffi.C.SOCK_STREAM

            -- Split address into host and port
            local host, port = parse_address(self.address)

            -- Resolve socket addess
            socket_family, socket_type, server_addr = resolve_address(socket_family, socket_type, host, port)
            if not server_addr then
                error("Error resolving address \"" .. self.address .. "\"")
            end
        elseif self.transport == "unix" then
            socket_family = ffi.C.AF_UNIX
            socket_type = ffi.C.SOCK_STREAM

            -- Create socket address
            server_addr = ffi.new("struct sockaddr_un")
            server_addr.sun_family = ffi.C.AF_UNIX
            server_addr.sun_path = self.address
        end

        -- Create socket
        self.fd = ffi.C.socket(socket_family, socket_type, 0)
        if self.fd < 0 then
            error("socket(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        -- Get socket flags
        self.fd_flags = ffi.C.fcntl(self.fd, ffi.C.F_GETFL)
        if self.fd_flags < 0 then
            error("fcntl(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        -- Set non-blocking on socket flags
        local ret = ffi.C.fcntl(self.fd, ffi.C.F_SETFL, bit.bor(self.fd_flags, ffi.C.O_NONBLOCK))
        if ret < 0 then
            error("fcntl(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        -- Start connecting to server
        local ret = ffi.C.connect(self.fd, ffi.cast("const struct sockaddr *", server_addr), ffi.sizeof(server_addr))
        if ret < 0 and ffi.errno() ~= ffi.C.ECONNREFUSED and ffi.errno() ~= ffi.C.ENOENT and ffi.errno() ~= ffi.C.EINPROGRESS then
            error("connect(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        elseif ret < 0 and (ffi.errno() == ffi.C.ECONNREFUSED or ffi.errno() == ffi.C.ENOENT) then
            -- Try again on next call to try_connect()
            self:close()
            return false
        elseif ret < 0 and ffi.errno() == ffi.C.EINPROGRESS then
            -- Check for success on the next call to try_connect()
            return false
        end

        -- Restore blocking to socket flags
        local ret = ffi.C.fcntl(self.fd, ffi.C.F_SETFL, self.fd_flags)
        if ret < 0 then
            error("fcntl(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        self._connected = true

        debug.print("[NetworkClient] Connected to " .. (self.transport == "unix" and self.address or format_address(server_addr)))

        return true
    end

    -- Poll client fd for connectivity
    local pollfds = ffi.new("struct pollfd[1]")
    pollfds[0].fd = self.fd
    pollfds[0].events = ffi.C.POLLOUT

    local ret = ffi.C.poll(pollfds, 1, 0)
    if ret < 0 then
        error("poll(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    elseif ret == 0 then
        -- Check again in next call to try_connect()
        return false
    end

    -- Check for socket error
    local err = ffi.new("int[1]")
    local err_size = ffi.new("socklen_t[1]", ffi.sizeof(err))
    local ret = ffi.C.getsockopt(self.fd, ffi.C.SOL_SOCKET, ffi.C.SO_ERROR, err, err_size)
    if ret < 0 then
        error("getsockopt(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    elseif err[0] ~= 0 and err[0] ~= ffi.C.ECONNREFUSED then
        error("connect(): " .. ffi.string(ffi.C.strerror(err[0])))
    elseif err[0] == ffi.C.ECONNREFUSED then
        -- Try again on next call to try_connect()
        self:close()
        return false
    end

    -- Restore blocking to socket flags
    local ret = ffi.C.fcntl(self.fd, ffi.C.F_SETFL, self.fd_flags)
    if ret < 0 then
        error("fcntl(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    self._connected = true

    debug.print("[NetworkClient] Connected to " .. (self.transport == "unix" and self.address or format_address(server_addr)))

    return true
end

---
-- Test if the client is connected to a server.
--
-- @internal
-- @function NetworkClient:connected
-- @treturn bool Connected
function NetworkClient:connected()
    return self._connected
end

---
-- Receive into buffer up to length bytes from the server.
--
-- @internal
-- @function NetworkClient:recv
-- @tparam cdata buf Buffer
-- @tparam int size Buffer size
-- @treturn int Number of bytes received or zero on disconnect
function NetworkClient:recv(buf, size)
    if not self.fd then
        return 0
    end

    local ret = ffi.C.recv(self.fd, buf, size, 0)
    if ret == 0 then
        self:close()
        return 0
    elseif ret < 0 then
        error("recv(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
    end

    return ret
end

---
-- Send length bytes of buffer to the server.
--
-- @internal
-- @function NetworkClient:sendall
-- @tparam cdata buf Buffer
-- @tparam int size Buffer size
function NetworkClient:sendall(buf, size)
    if not self.fd then
        return
    end

    local sent = 0
    while sent < size do
        local ret = ffi.C.send(self.fd, ffi.cast("const char *", buf) + sent, size - sent, ffi.C.MSG_NOSIGNAL)
        if ret < 0 then
            local errno = ffi.errno()
            if errno == ffi.C.EPIPE or errno == ffi.C.ECONNRESET then
                self:close()
                return
            else
                error("send(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
            end
        end

        sent = sent + ret
    end
end

---
-- Close socket.
--
-- @internal
-- @function NetworkClient:close
function NetworkClient:close()
    if self.fd ~= nil then
        if ffi.C.close(self.fd) ~= 0 then
            error("close(): " .. ffi.string(ffi.C.strerror(ffi.errno())))
        end

        self.fd = nil
        self.fd_flags = nil
        self._connected = false
    end
end

return {NetworkServer = NetworkServer, NetworkClient = NetworkClient}
