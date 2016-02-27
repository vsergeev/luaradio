#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#include "luaradio.h"

/* Radio context */
typedef struct radio {
    lua_State *L;
    char errmsg[256];
} radio_t;

radio_t *luaradio_new(void) {
    radio_t *radio;

    /* Allocate radio context */
    radio = calloc(1, sizeof(radio_t));
    if (radio == NULL)
        return NULL;

    /* Create a new Lua state */
    radio->L = luaL_newstate();
    if (radio->L == NULL) {
        free(radio);
        return NULL;
    }

    /* Open standard libraries */
    luaL_openlibs(radio->L);

    return radio;
}

static int lua_iscompositeblock(lua_State *L) {
    /* Check stack size */
    if (lua_gettop(L) < 1)
        return 0;

    /* Check instance of top element is CompositeBlock, i.e.,
     * call radio.object.isinstanceof(top, radio.CompositeBlock) */
    lua_getglobal(L, "radio");
    lua_getfield(L, -1, "CompositeBlock");
    lua_getfield(L, -2, "object");
    lua_getfield(L, -1, "isinstanceof");
    lua_pushvalue(L, 1);
    lua_pushvalue(L, 3);
    if (lua_pcall(L, 2, 1, 0) != 0)
        return 0;

    /* Check result is true */
    if (!(lua_isboolean(L, -1) && lua_toboolean(L, -1)))
        return 0;

    /* Pop off intermediate elements off the stack */
    lua_pop(L, 4);

    return 1;
}

int luaradio_load(radio_t *radio, const char *script) {
    /* Clear stack */
    lua_settop(radio->L, 0);

    /* Load radio module into global namespace */
    lua_getglobal(radio->L, "require");
    lua_pushliteral(radio->L, "radio");
    if (lua_pcall(radio->L, 1, 1, 0) != 0)
        goto handle_error;
    lua_setglobal(radio->L, "radio");

    /* Run script */
    if (luaL_dostring(radio->L, script) != 0)
        goto handle_error;

    /* Check instance of top element is CompositeBlock */
    if (!lua_iscompositeblock(radio->L)) {
        strncpy(radio->errmsg, "Script did not return a radio.CompositeBlock instance.", sizeof(radio->errmsg));
        lua_settop(radio->L, 0);
        return -1;
    }

    return 0;

    handle_error:
    /* Copy error message into context */
    strncpy(radio->errmsg, lua_tostring(radio->L, -1), sizeof(radio->errmsg));
    /* Clear stack */
    lua_settop(radio->L, 0);

    return -1;
}

int luaradio_start(radio_t *radio) {
    /* Check instance of top element is CompositeBlock */
    if (!lua_iscompositeblock(radio->L)) {
        strncpy(radio->errmsg, "No LuaRadio flowgraph found to run.", sizeof(radio->errmsg));
        return -1;
    }

    /* Call block:run() */
    lua_getfield(radio->L, -1, "start");
    lua_pushvalue(radio->L, -2);
    if (lua_pcall(radio->L, 1, 0, 0) != 0) {
        /* Copy error message into context */
        strncpy(radio->errmsg, lua_tostring(radio->L, -1), sizeof(radio->errmsg));
        /* Pop error off of stack */
        lua_pop(radio->L, 1);
        return -1;
    }

    return 0;
}

int luaradio_wait(radio_t *radio) {
    /* Check instance of top element is CompositeBlock */
    if (!lua_iscompositeblock(radio->L)) {
        strncpy(radio->errmsg, "No LuaRadio flowgraph found to run.", sizeof(radio->errmsg));
        return -1;
    }

    /* Call block:wait() */
    lua_getfield(radio->L, -1, "wait");
    lua_pushvalue(radio->L, -2);
    if (lua_pcall(radio->L, 1, 0, 0) != 0) {
        /* Copy error message into context */
        strncpy(radio->errmsg, lua_tostring(radio->L, -1), sizeof(radio->errmsg));
        /* Pop error off of stack */
        lua_pop(radio->L, 1);
        return -1;
    }

    return 0;
}

int luaradio_stop(radio_t *radio) {
    /* Check instance of top element is CompositeBlock */
    if (!lua_iscompositeblock(radio->L)) {
        strncpy(radio->errmsg, "No LuaRadio flowgraph found to stop.", sizeof(radio->errmsg));
        return -1;
    }

    /* Call block:stop() */
    lua_getfield(radio->L, -1, "stop");
    lua_pushvalue(radio->L, -2);
    if (lua_pcall(radio->L, 1, 0, 0) != 0) {
        /* Copy error message into context */
        strncpy(radio->errmsg, lua_tostring(radio->L, -1), sizeof(radio->errmsg));
        /* Pop error off of stack */
        lua_pop(radio->L, 1);
        return -1;
    }

    return 0;
}

void luaradio_free(radio_t *radio) {
    /* Close Lua state */
    lua_close(radio->L);

    /* Free radio context */
    free(radio);
}

const char *luaradio_strerror(radio_t *radio) {
    return radio->errmsg;
}
