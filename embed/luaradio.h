#ifndef _LUARADIO_H
#define _LUARADIO_H

#include <stdint.h>
#include <stdbool.h>
#include <lua.h>

/**
 * @brief Opaque radio context.
 */
typedef struct luaradio luaradio_t;

/**
 * @brief Create a new LuaRadio context.
 * @return a new LuaRadio context
 *
 * Create a new LuaRadio context. Returns a LuaRadio context on success, or
 * NULL on memory allocation error.
 */
luaradio_t *luaradio_new(void);

/**
 * @brief Load a script that returns a LuaRadio flow graph.
 * @return 0 on success, -1 on failure
 *
 * Load a script that returns a LuaRadio flow graph. The script must return an
 * instance of radio.CompositeBlock. On failure, use luaradio_strerror() to get
 * a human readable error string.
 */
int luaradio_load(luaradio_t *radio, const char *script);

/**
 * @brief Start a LuaRadio flow graph.
 * @return 0 on success, -1 on failure
 *
 * Start a LuaRadio flow graph. On failure, use luaradio_strerror() to get a
 * human readable error string.
 */
int luaradio_start(luaradio_t *radio);

/**
 * @brief Get the running status of a LuaRadio flow graph.
 * @return 0 on success, -1 on failure
 *
 * Get the running status of a LuaRadio flow graph. On failure, use
 * luaradio_strerror() to get a human readable error string.
 */
int luaradio_status(luaradio_t *radio, bool *running);

/**
 * @brief Wait for a LuaRadio flow graph to finish.
 * @return 0 on success, -1 on failure
 *
 * Wait for a LuaRadio flow graph to finish. On failure, use
 * luaradio_strerror() to get a human readable error string.
 */
int luaradio_wait(luaradio_t *radio);

/**
 * @brief Stop a LuaRadio flow graph.
 * @return 0 on success, -1 on failure
 *
 * Stop a running LuaRadio flow graph. On failure, use luaradio_strerror() to
 * get a human readable error string.
 */
int luaradio_stop(luaradio_t *radio);

/**
 * @brief Free a LuaRadio context.
 *
 * Free a LuaRadio context created with luaradio_new().
 */
void luaradio_free(luaradio_t *radio);

/**
 * @brief Get the Lua state of a LuaRadio context.
 * @return Lua state
 */
lua_State *luaradio_get_state(luaradio_t *radio);

/**
 * @brief Get a human readable error message for the last error that occurred.
 * @return error string
 */
const char *luaradio_strerror(luaradio_t *radio);

/**
 * @brief Get the LuaRadio version as a string, e.g. "0.0.12".
 * @return version string
 */
const char *luaradio_version(void);

/**
 * @brief Get the LuaRadio version as a number, encoded in decimal as xxyyzz. For example, 5.1.2 would be 50102.
 * @return version number
 */
unsigned int luaradio_version_number(void);

/**
 * @brief Version information structure.
 */
typedef struct {
    unsigned int major; /**< major version number */
    unsigned int minor; /**< minor version number */
    unsigned int patch; /**< patch version number */
    const char *commit_id; /**< commit id string */
} luaradio_version_t;

/**
 * @brief Get the LuaRadio version information.
 * @return version information structure
 */
const luaradio_version_t *luaradio_version_info(void);

/* Basic LuaRadio types */

/**
 * @brief Complex 32-bit float type.
 */
typedef struct {
    float real;
    float imag;
} complex_float32_t;

/**
 * @brief 32-bit float type.
 */
typedef struct {
    float value;
} float32_t;

/**
 * @brief 8-bit byte type.
 */
typedef struct {
    uint8_t value;
} byte_t;

/**
 * @brief Bit type.
 */
typedef struct {
    uint8_t value;
} bit_t;

#endif
