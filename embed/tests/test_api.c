#include <stdio.h>
#include <assert.h>
#include <unistd.h>

#include <luaradio.h>

#define abs(x) ((x > 0) ? x : -x)

int main(void) {
    radio_t *radio;

    /* Test context creation */
    assert((radio = luaradio_new()) != NULL);

    /* Test invalid load: no return */
    assert(luaradio_load(radio, "x = 5") < 0);

    /* Test invalid load: not radio.CompositeBlock instance */
    assert(luaradio_load(radio, "return 5") < 0);

    /* Test valid load: radio.CompositeBlock instance */
    assert(luaradio_load(radio, "return radio.CompositeBlock()") == 0);
    assert(luaradio_start(radio) == 0);
    assert(luaradio_stop(radio) == 0);

    /* Test invalid load: not radio.CompositeBlock instance */
    assert(luaradio_load(radio, "return 5") < 0);
    assert(luaradio_start(radio) < 0);

    /* Load buf with incrementing floats */
    float buf[256];
    for (unsigned int i = 0; i < sizeof(buf)/sizeof(buf[0]); i++) {
        buf[i] = (float)i;
    }

    /* Create source pipe and load buf into it */
    int src_pipe_fds[2];
    assert(pipe(src_pipe_fds) == 0);
    assert(write(src_pipe_fds[1], buf, sizeof(buf)) == sizeof(buf));
    assert(close(src_pipe_fds[1]) == 0);

    /* Create sink pipe */
    int snk_pipe_fds[2];
    assert(pipe(snk_pipe_fds) == 0);

    /* Prepare script */
    const char *script_template =
        "local b0 = radio.RealFileSource(%d, 'f32le', 1)\n"
        "local b1 = radio.SumBlock()\n"
        "local b2 = radio.RealFileSink(%d, 'f32le')\n"
        "local top = radio.CompositeBlock()\n"
        ""
        "top:connect(b0, 'out', b1, 'in1')\n"
        "top:connect(b0, 'out', b1, 'in2')\n"
        "top:connect(b1, b2)\n"
        "return top";
    char script[2048];
    snprintf(script, sizeof(script), script_template, src_pipe_fds[0], snk_pipe_fds[1]);

    /* Load and run the script */
    assert(luaradio_load(radio, script) == 0);
    assert(luaradio_start(radio) == 0);
    assert(luaradio_wait(radio) == 0);

    /* Read sink pipe into buf */
    assert(read(snk_pipe_fds[0], buf, sizeof(buf)) == sizeof(buf));

    /* Check buf got doubled (FIXME assumes little endian) */
    for (unsigned int i = 0; i < sizeof(buf)/sizeof(buf[0]); i++) {
        assert(abs(buf[i]  - ((float)i*2)) < 1e-6);
    }

    luaradio_free(radio);

    return 0;
}
