#include <stdio.h>
#include <assert.h>
#include <unistd.h>

#include <luaradio.h>

const char *script_template =
    "local frequency = %s\n"
    "local offset = -600e3\n"
    "return radio.CompositeBlock():connect("
    "    radio.RtlSdrSource(frequency + offset, 2048000),"
    "    radio.TunerBlock(offset, 190e3, 10),"
    "    radio.FrequencyDiscriminatorBlock(6.0),"
    "    radio.FMDeemphasisFilterBlock(75e-6),"
    "    radio.DecimatorBlock(15e3, 4),"
    "    radio.PulseAudioSink()"
    ")";

int main(int argc, char *argv[]) {
    radio_t *radio;
    char script[2048];

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <FM radio frequency>\n", argv[0]);
        return -1;
    }

    snprintf(script, sizeof(script), script_template, argv[1]);

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
