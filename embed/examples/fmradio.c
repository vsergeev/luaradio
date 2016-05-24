#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <luaradio.h>

const char *script_template =
    "local frequency = %f\n"
    "return radio.CompositeBlock():connect("
    "    radio.RtlSdrSource(frequency - 250e3, 1102500),"
    "    radio.TunerBlock(-250e3, 200e3, 5),"
    "    radio.WBFMMonoDemodulator(),"
    "    radio.DownsamplerBlock(5),"
    "    radio.PulseAudioSink(1)"
    ")";

int main(int argc, char *argv[]) {
    luaradio_t *radio;
    char script[512];

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <FM radio frequency>\n", argv[0]);
        return -1;
    }

    /* Substitute station frequency in script template */
    snprintf(script, sizeof(script), script_template, atof(argv[1]));

    if ((radio = luaradio_new()) == NULL) {
        perror("Allocating memory");
        return -1;
    }

    if (luaradio_load(radio, script) < 0) {
        fprintf(stderr, "Error loading script: %s\n", luaradio_strerror(radio));
        return -1;
    }

    if (luaradio_start(radio) < 0) {
        fprintf(stderr, "Error starting script: %s\n", luaradio_strerror(radio));
        return -1;
    }

    if (luaradio_wait(radio) < 0) {
        fprintf(stderr, "Error waiting for script: %s\n", luaradio_strerror(radio));
        return -1;
    }

    luaradio_free(radio);

    return 0;
}
