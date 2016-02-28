#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

int main(int argc, char *argv[]) {
    lua_State *L;

    if (argc < 2) {
        printf("Usage: %s <script>\n", argv[0]);
        return -1;
    }

    /* Create a new Lua state */
    L = luaL_newstate();
    if (L == NULL) {
        perror("Allocating Lua state");
        return -1;
    }

    /* Open standard libraries */
    luaL_openlibs(L);

    /* Preload radio */
    lua_getglobal(L, "package");
    lua_getfield(L, -1, "preload");
    lua_getglobal(L, "require");
    lua_pushliteral(L, "radio");
    if (lua_pcall(L, 1, 1, 0) != 0) {
        fprintf(stderr, "Error loading radio module: %s\n", lua_tostring(L, -1));
        return -1;
    }
    lua_setfield(L, -2, "radio");

    /* Clear stack */
    lua_settop(L, 0);

    /* Run script */
    if (luaL_dofile(L, argv[1]) != 0) {
        fprintf(stderr, "Error: %s\n", lua_tostring(L, -1));
        return -1;
    }

    /* Close Lua state */
    lua_close(L);

    return 0;
}
