SRC_DIR = ..
DEMO_DIR = demos
TEST_DIR = tests
BUILD_DIR = build
STANDALONE_DIR = standalone
GEN_DIR = $(BUILD_DIR)/gen

################################################################################

LIBNAME = luaradio
LIB_SRCS = libluaradio.c
LUA_SRCS = $(shell find $(SRC_DIR)/radio -type f -name "*.lua")

DEMO_SRCS = $(DEMO_DIR)/fmradio.c $(DEMO_DIR)/rds-timesync.c
TEST_SRCS = $(TEST_DIR)/test_api.c
STANDALONE_SRCS = $(STANDALONE_DIR)/luaradio.c

################################################################################

SHARED_LIB = $(BUILD_DIR)/lib$(LIBNAME).so
STATIC_LIB = $(BUILD_DIR)/lib$(LIBNAME).a
LUA_C_SRCS := $(patsubst $(SRC_DIR)/%.lua, $(GEN_DIR)/%.c, $(LUA_SRCS))
LIB_OBJS := $(patsubst $(GEN_DIR)/%.c, $(BUILD_DIR)/%.o, $(LUA_C_SRCS)) $(patsubst %.c, $(BUILD_DIR)/%.o, $(LIB_SRCS))

DEMO_BINS = $(patsubst $(DEMO_DIR)/%.c, $(BUILD_DIR)/$(DEMO_DIR)/%, $(DEMO_SRCS))
TEST_BINS = $(patsubst $(TEST_DIR)/%.c, $(BUILD_DIR)/$(TEST_DIR)/%, $(TEST_SRCS))
STANDALONE_BINS = $(patsubst $(STANDALONE_DIR)/%.c, $(BUILD_DIR)/$(STANDALONE_DIR)/%, $(STANDALONE_SRCS))

################################################################################

OPT = -O3
DEBUG =
GIT_VERSION = $(shell git describe --abbrev --always --tags --dirty)

CFLAGS = $(shell pkg-config --cflags luajit)
CFLAGS += -fPIC
CFLAGS += $(OPT) $(DEBUG) $(INCLUDES)
CFLAGS += -DGIT_VERSION=\"$(GIT_VERSION)\"
CFLAGS += -Wall -Wextra -Wcast-align -Wcast-qual -Wimplicit
CFLAGS += -Wpointer-arith -Wswitch -Wredundant-decls -Wreturn-type
CFLAGS += -Wshadow -Wunused -Wno-unused-parameter

LIBFLAGS = $(shell pkg-config --libs luajit)

LDFLAGS =
EXTRA_LDFLAGS =

ifeq ($(shell uname -s),Darwin)
	EXTRA_LDFLAGS = -pagezero_size 10000 -image_base 100000000
endif

LUAJIT = luajit

################################################################################

.PHONY: all
all: lib tests demos standalone

.PHONY: lib
lib: $(SHARED_LIB) $(STATIC_LIB)

.PHONY: demos
demos: $(SHARED_LIB) $(DEMO_BINS)

.PHONY: tests
tests: $(SHARED_LIB) $(TEST_BINS)

.PHONY: standalone
standalone: $(STANDALONE_BINS)

.PHONY: runtests
runtests: $(TEST_BINS)
	for f in $(TEST_BINS); do \
		LD_LIBRARY_PATH=$(BUILD_DIR) ./$$f; \
	done

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

################################################################################

$(BUILD_DIR)/$(STANDALONE_DIR)/%: $(STANDALONE_DIR)/%.c $(SHARED_LIB)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -I./ $< -o $@ -L$(BUILD_DIR) -l$(LIBNAME) $(LIBFLAGS) $(LDFLAGS) $(EXTRA_LDFLAGS)

$(BUILD_DIR)/$(TEST_DIR)/%: $(TEST_DIR)/%.c $(SHARED_LIB)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -I./ $< -o $@ -L$(BUILD_DIR) -l$(LIBNAME) $(LIBFLAGS) $(LDFLAGS) $(EXTRA_LDFLAGS)

$(BUILD_DIR)/$(DEMO_DIR)/%: $(DEMO_DIR)/%.c $(SHARED_LIB)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -I./ $< -o $@ -L$(BUILD_DIR) -l$(LIBNAME) $(LIBFLAGS) $(LDFLAGS) $(EXTRA_LDFLAGS)

$(STATIC_LIB): $(LIB_OBJS)
	ar rcs $@ $^

$(SHARED_LIB): $(LIB_OBJS)
	$(CC) $(CFLAGS) -shared -o $@ $^ $(LDFLAGS)

$(BUILD_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(GEN_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

.SECONDARY: $(LUA_C_SRCS)
$(GEN_DIR)/%.c: $(SRC_DIR)/%.lua
	@mkdir -p $(dir $@)
	$(LUAJIT) -bn $(subst .init, , $(subst /,., $(patsubst $(SRC_DIR)/%.lua, %, $<))) $< $@
