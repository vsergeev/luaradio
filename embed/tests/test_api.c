#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <unistd.h>
#include <time.h>

#include <luaradio.h>

#include "test.h"

#define abs(x) ((x > 0) ? x : -x)

void test_context(void) {
    luaradio_t *radio;

    ptest();

    /* Create context */
    passert((radio = luaradio_new()) != NULL);

    /* Get Lua state */
    passert(luaradio_get_state(radio) != NULL);

    /* Flow graph operations should fail, since no composite block is loaded */
    passert(luaradio_start(radio) < 0);
    passert(luaradio_status(radio, NULL) < 0);
    passert(luaradio_wait(radio) < 0);
    passert(luaradio_stop(radio) < 0);

    luaradio_free(radio);
}

void test_load(void) {
    luaradio_t *radio;

    ptest();

    /* Create context */
    passert((radio = luaradio_new()) != NULL);

    /* Test invalid load: error in script */
    passert(luaradio_load(radio, "error('foobar')") < 0);
    passert(luaradio_start(radio) < 0);

    /* Test invalid load: no object returned */
    passert(luaradio_load(radio, "x = 5") < 0);
    passert(luaradio_start(radio) < 0);

    /* Test invalid load: not radio.CompositeBlock instance returned */
    passert(luaradio_load(radio, "return 5") < 0);
    passert(luaradio_start(radio) < 0);

    /* Test valid load: radio.CompositeBlock instance */
    passert(luaradio_load(radio, "return radio.CompositeBlock()") == 0);
    passert(luaradio_start(radio) == 0);

    luaradio_free(radio);
}

void test_flowgraph1(void) {
    luaradio_t *radio;
    int source_pipe[2];

    const char *script_template =
        "return radio.CompositeBlock():connect(\n"
            "radio.RawFileSource(%d, radio.types.Byte, 1),\n"
            "radio.DelayBlock(10),\n"
            "radio.PrintSink()\n"
        ")";
    char script[256];

    ptest();

    /* Create pipe */
    assert(pipe(source_pipe) == 0);

    /* Create context */
    passert((radio = luaradio_new()) != NULL);

    /* Prepare script */
    snprintf(script, sizeof(script), script_template, source_pipe[0]);

    /* Load script */
    passert(luaradio_load(radio, script) == 0);

    /* Start flow graph */
    passert(luaradio_start(radio) == 0);

    /* Close read end of pipe */
    passert(close(source_pipe[0]) == 0);

    /* Check flow graph status */
    bool running;
    passert(luaradio_status(radio, &running) == 0);
    passert(running == true);

    /* Break pipe */
    passert(close(source_pipe[1]) == 0);

    /* Check flow graph terminates naturally */
    time_t tic = time(NULL);
    while (true) {
        assert(luaradio_status(radio, &running) == 0);
        if (running == false)
            break;

        if ((time(NULL) - tic) > 5)
            passert(false);
    }

    /* Wait should return immediately */
    passert(luaradio_wait(radio) == 0);

    luaradio_free(radio);
}

void test_flowgraph2(void) {
    luaradio_t *radio;
    bit_t source_buf[256], sink_buf[256];
    int source_pipe[2], sink_pipe[2];

    const char *script_template =
        "return radio.CompositeBlock():connect(\n"
            "radio.RawFileSource(%d, radio.types.Bit, 1),\n"
            "radio.DifferentialDecoderBlock(),\n"
            "radio.RawFileSink(%d)\n"
        ")";
    char script[256];

    ptest();

    /* Load source_buf with random bits */
    for (int i = 0; i < 256; i++) {
        source_buf[i].value = random() & 0x1;
    }

    /* Create source and sink pipes */
    passert(pipe(source_pipe) == 0);
    passert(pipe(sink_pipe) == 0);

    /* Load source buf into source pipe */
    passert(write(source_pipe[1], source_buf, sizeof(source_buf)) == sizeof(source_buf));
    passert(close(source_pipe[1]) == 0);

    /* Create context */
    passert((radio = luaradio_new()) != NULL);

    /* Prepare script */
    snprintf(script, sizeof(script), script_template, source_pipe[0], sink_pipe[1]);

    /* Load the script */
    passert(luaradio_load(radio, script) == 0);

    /* Start flow graph */
    passert(luaradio_start(radio) == 0);

    /* Close write end of sink pipe */
    passert(close(sink_pipe[1]) == 0);

    /* Wait for flow graph termination */
    passert(luaradio_wait(radio) == 0);

    /* Check script status */
    bool running;
    passert(luaradio_status(radio, &running) == 0);
    passert(running == false);

    /* Read sink pipe into sink buf */
    passert(read(sink_pipe[0], sink_buf, sizeof(sink_buf)) == sizeof(sink_buf));

    /* Close read ends of pipes */
    passert(close(source_pipe[0]) == 0);
    passert(close(sink_pipe[0]) == 0);

    /* Check sink buffer */
    for (int i = 0; i < 256; i++) {
        assert(sink_buf[i].value == (source_buf[i].value ^ ((i == 0) ? 0 : (source_buf[i-1].value))));
    }

    luaradio_free(radio);
}

int main(void) {
    test_context();
    test_load();
    test_flowgraph1();
    test_flowgraph2();

    fprintf(stderr, "\nAll tests passed!\n");

    return 0;
}
