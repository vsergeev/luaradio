#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <sys/time.h>

#include <luaradio.h>

const char *script_template =
    "local frequency = %f\n"
    "return radio.CompositeBlock():connect("
    "    radio.RtlSdrSource(frequency - 250e3, 1102500),"
    "    radio.TunerBlock(-250e3, 200e3, 5),"
    "    radio.RDSReceiver(),"
    "    radio.RawFileSink(%d)"
    ")";

/* radio.RDSFramerBlock.RDSFrameType */
typedef struct {
    uint16_t blocks[4];
} rds_frame_t;

static time_t rds_decode_time(const rds_frame_t *time_frame) {
    /* See RDS Standard 3.1.5.6, pg. 28 */
    /* Extract modified julian date, hour, minute */
    uint32_t mjd = ((time_frame->blocks[1] & 0x3) << 15) | ((time_frame->blocks[2] & 0xfffe) >> 1);
    uint32_t hour = ((time_frame->blocks[2] & 0x1) << 4) | ((time_frame->blocks[3] & 0xf000) >> 12);
    uint32_t minute = ((time_frame->blocks[3] >> 6) & 0x3f);

    /* See RDS Standard Annex G, pg. 81 */
    /* Convert modified julian date to year, month, day */
    uint32_t yp = (uint32_t)(((float)mjd - 15078.2) / 365.25);
    uint32_t mp = (uint32_t)(((float)mjd - 14956.1 - ((uint32_t)((float)yp * 365.25))) / 30.6001);
    uint32_t k = (mp == 14 || mp == 15) ? 1 : 0;
    uint32_t day = mjd - 14956 - ((uint32_t)((float)yp * 365.25))-((uint32_t)((float)mp * 30.6001));
    uint32_t month = mp - 1 - k * 12;
    uint32_t year = yp + k;

    /* Convert hour, minute, year, month, day to time_t */
    struct tm tm = {
        .tm_sec = 0, .tm_min = minute, .tm_hour = hour,
        .tm_mday = day, .tm_mon = month - 1, .tm_year = year,
        .tm_isdst = -1,
    };
    return timegm(&tm);
}

int main(int argc, char *argv[]) {
    luaradio_t *radio;
    char script[512];
    int sink_fds[2];
    rds_frame_t frame;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <FM station frequency>\n", argv[0]);
        return -1;
    }

    /* Create a pair of connected file descriptors with pipe() */
    if (pipe(sink_fds) < 0) {
        perror("pipe()");
        return -1;
    }

    /* Substitute station frequency and write fd of pipe in script template */
    snprintf(script, sizeof(script), script_template, atof(argv[1]), sink_fds[1]);

    /* Create context */
    if ((radio = luaradio_new()) == NULL) {
        perror("Allocating memory");
        return -1;
    }

    /* Load flow graph */
    if (luaradio_load(radio, script) < 0) {
        fprintf(stderr, "Error loading flow graph: %s\n", luaradio_strerror(radio));
        return -1;
    }

    /* Start flow graph */
    if (luaradio_start(radio) < 0) {
        fprintf(stderr, "Error starting flow graph: %s\n", luaradio_strerror(radio));
        return -1;
    }

    for (unsigned int frame_count = 1; ; frame_count++) {
        /* Read RDS frame from read fd of pipe */
        if (read(sink_fds[0], &frame, sizeof(frame)) != sizeof(frame)) {
            perror("read()");
            return -1;
        }

        printf("\rRDS frames received:  % 5d", frame_count);

        /* Check if it's a time frame (group = 0x4, version = 0x0) */
        uint32_t group = (frame.blocks[1] >> 12) & 0xf;
        uint32_t version = (frame.blocks[1] >> 11) & 0x1;
        if (group == 0x4 && version == 0) {
            printf("\nRDS time frame found!\n");
            break;
        }
    }

    /* Stop flow graph */
    if (luaradio_stop(radio) < 0) {
        fprintf(stderr, "Error stopping flow graph: %s\n", luaradio_strerror(radio));
        return -1;
    }

    /* Decode the time */
    time_t t = rds_decode_time(&frame);

    printf("Setting system time to %s", ctime(&t));

    /* Set system time */
    struct timeval tv = { .tv_sec = t, .tv_usec = 0 };
    if (settimeofday(&tv, NULL) < 0) {
        perror("settimeofday()");
        return -1;
    }

    /* Free context */
    luaradio_free(radio);

    return 0;
}
