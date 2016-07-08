SRC_DIR = ..
EXAMPLE_DIR = examples
TEST_DIR = tests
BUILD_DIR = build
GEN_DIR = $(BUILD_DIR)/gen

################################################################################

LIBNAME = luaradio
LIB_SRCS = luaradio.c
LUA_SRCS = $(shell find $(SRC_DIR)/radio -type f -name "*.lua")

EXAMPLE_SRCS = $(EXAMPLE_DIR)/fm-radio.c $(EXAMPLE_DIR)/rds-timesync.c
TEST_SRCS = $(TEST_DIR)/test_api.c

################################################################################

ifneq ($(shell uname -s),Darwin)
SHARED_LIB = $(BUILD_DIR)/lib$(LIBNAME).so
else
SHARED_LIB = $(BUILD_DIR)/lib$(LIBNAME).dylib
endif

STATIC_LIB = $(BUILD_DIR)/lib$(LIBNAME).a

LUA_C_SRCS := $(patsubst $(SRC_DIR)/%.lua, $(GEN_DIR)/%.c, $(LUA_SRCS))
LIB_OBJS := $(patsubst $(GEN_DIR)/%.c, $(BUILD_DIR)/%.o, $(LUA_C_SRCS)) $(patsubst %.c, $(BUILD_DIR)/%.o, $(LIB_SRCS))

EXAMPLE_BINS = $(patsubst $(EXAMPLE_DIR)/%.c, $(BUILD_DIR)/$(EXAMPLE_DIR)/%, $(EXAMPLE_SRCS))
TEST_BINS = $(patsubst $(TEST_DIR)/%.c, $(BUILD_DIR)/$(TEST_DIR)/%, $(TEST_SRCS))

PREFIX ?= /usr/local

INSTALL_CMOD = $(shell pkg-config luajit --variable INSTALL_CMOD)

################################################################################

OPT = -O3
DEBUG =

VERSION_MAJOR := $(shell cd ../; luajit -e "package.path = './?/init.lua;' .. package.path; print(require('radio').version_info.major)")
VERSION_MINOR := $(shell cd ../; luajit -e "package.path = './?/init.lua;' .. package.path; print(require('radio').version_info.minor)")
VERSION_PATCH := $(shell cd ../; luajit -e "package.path = './?/init.lua;' .. package.path; print(require('radio').version_info.patch)")
VERSION_COMMIT := $(shell git describe --abbrev --always --tags --dirty 2>/dev/null || echo "")

CFLAGS = -std=c99 -D_DEFAULT_SOURCE
CFLAGS += $(shell pkg-config --cflags luajit)
CFLAGS += -fPIC
CFLAGS += $(OPT) $(DEBUG) $(INCLUDES)
CFLAGS += -DVERSION_MAJOR=$(VERSION_MAJOR) -DVERSION_MINOR=$(VERSION_MINOR) -DVERSION_PATCH=$(VERSION_PATCH)
CFLAGS += -DVERSION_COMMIT=\"$(VERSION_COMMIT)\"
CFLAGS += -Wall -Wextra -Wcast-align -Wcast-qual -Wimplicit
CFLAGS += -Wpointer-arith -Wswitch -Wredundant-decls -Wreturn-type
CFLAGS += -Wshadow -Wunused -Wno-unused-parameter

LIBFLAGS = $(shell pkg-config --libs luajit)

ifneq ($(shell uname -s),Darwin)
LDFLAGS = -Wl,-E
EXTRA_LDFLAGS =
else
LDFLAGS =
EXTRA_LDFLAGS = -pagezero_size 10000 -image_base 100000000
endif

LUAJIT = luajit

################################################################################

.PHONY: all
all: lib tests examples

.PHONY: lib
lib: $(SHARED_LIB) $(STATIC_LIB)

.PHONY: examples
examples: $(SHARED_LIB) $(EXAMPLE_BINS)

.PHONY: tests
tests: $(SHARED_LIB) $(TEST_BINS)

.PHONY: runtests
runtests: $(TEST_BINS)
	for f in $(TEST_BINS); do \
		LD_LIBRARY_PATH=$(BUILD_DIR) DYLD_LIBRARY_PATH=$(BUILD_DIR) ./$$f; \
	done

ifneq ($(shell uname -s),Darwin)
.PHONY: install
install: $(STATIC_LIB) $(SHARED_LIB)
	install -d $(DESTDIR)$(PREFIX)/lib
	install -m755 $(STATIC_LIB) $(DESTDIR)$(PREFIX)/lib/lib$(LIBNAME).a
	install -m755 $(SHARED_LIB) $(DESTDIR)$(PREFIX)/lib/lib$(LIBNAME).so.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH)
	ln -sf lib$(LIBNAME).so.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH) $(DESTDIR)$(PREFIX)/lib/lib$(LIBNAME).so.$(VERSION_MAJOR)
	ln -sf lib$(LIBNAME).so.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH) $(DESTDIR)$(PREFIX)/lib/lib$(LIBNAME).so
	install -d $(DESTDIR)$(PREFIX)/include
	install -m644 luaradio.h $(DESTDIR)$(PREFIX)/include/luaradio.h
	install -d $(DESTDIR)$(INSTALL_CMOD)
	ln -sf $(PREFIX)/lib/lib$(LIBNAME).so.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH) $(DESTDIR)$(INSTALL_CMOD)/radio.so
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m755 ../luaradio $(DESTDIR)$(PREFIX)/bin/luaradio
	install -d $(DESTDIR)$(PREFIX)/share/licenses/luaradio
	install -m644 ../LICENSE $(DESTDIR)$(PREFIX)/share/licenses/luaradio/LICENSE
else
# Mac OS X install
.PHONY: install
install: $(STATIC_LIB) $(SHARED_LIB)
	install -d $(DESTDIR)$(PREFIX)/lib
	install -m755 $(STATIC_LIB) $(DESTDIR)$(PREFIX)/lib/lib$(LIBNAME).a
	install -m755 $(SHARED_LIB) $(DESTDIR)$(PREFIX)/lib/lib$(LIBNAME).$(VERSION_MAJOR).dylib
	ln -sf lib$(LIBNAME).$(VERSION_MAJOR).dylib $(DESTDIR)$(PREFIX)/lib/lib$(LIBNAME).dylib
	install -d $(DESTDIR)$(PREFIX)/include
	install -m644 luaradio.h $(DESTDIR)$(PREFIX)/include/luaradio.h
	install -d $(DESTDIR)$(INSTALL_CMOD)
	ln -sf $(PREFIX)/lib/lib$(LIBNAME).$(VERSION_MAJOR).dylib $(DESTDIR)$(INSTALL_CMOD)/radio.so
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m755 ../luaradio $(DESTDIR)$(PREFIX)/bin/luaradio
	install -d $(DESTDIR)$(PREFIX)/share/licenses/luaradio
	install -m644 ../LICENSE $(DESTDIR)$(PREFIX)/share/licenses/luaradio/LICENSE
endif

.PHONY: clean
clean:
	rm -rf $(BUILD_DIR)

################################################################################

$(BUILD_DIR)/$(TEST_DIR)/%: $(TEST_DIR)/%.c $(SHARED_LIB)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -I./ $< -o $@ -L$(BUILD_DIR) -l$(LIBNAME) $(LIBFLAGS) $(LDFLAGS) $(EXTRA_LDFLAGS)

$(BUILD_DIR)/$(EXAMPLE_DIR)/%: $(EXAMPLE_DIR)/%.c $(SHARED_LIB)
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -I./ $< -o $@ -L$(BUILD_DIR) -l$(LIBNAME) $(LIBFLAGS) $(LDFLAGS) $(EXTRA_LDFLAGS)

$(STATIC_LIB): $(LIB_OBJS)
	ar rcs $@ $^

ifneq ($(shell uname -s),Darwin)
$(SHARED_LIB): $(LIB_OBJS)
	$(CC) $(CFLAGS) -shared -Wl,-soname,lib$(LIBNAME).so.$(VERSION_MAJOR) -o $@.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH) $^ $(LDFLAGS)
	ln -sf lib$(LIBNAME).so.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH) $@.$(VERSION_MAJOR)
	ln -sf lib$(LIBNAME).so.$(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH) $@
else
# Mac OS X shared library build
$(SHARED_LIB): $(LIB_OBJS)
	$(CC) $(CFLAGS) -dynamiclib -Wl,-undefined -Wl,dynamic_lookup -install_name "lib$(LIBNAME).$(VERSION_MAJOR).dylib" -current_version $(VERSION_MAJOR).$(VERSION_MINOR).$(VERSION_PATCH) -compatibility_version $(VERSION_MAJOR).$(VERSION_MINOR) -o $(subst .dylib,.$(VERSION_MAJOR).dylib,$@) $^ $(LDFLAGS)
	ln -sf lib$(LIBNAME).$(VERSION_MAJOR).dylib $@
endif

$(BUILD_DIR)/%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: $(GEN_DIR)/%.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

.SECONDARY: $(LUA_C_SRCS)
$(GEN_DIR)/%.c: $(SRC_DIR)/%.lua
	@mkdir -p $(dir $@)
	$(LUAJIT) -bn $(subst .init, , $(subst /,., $(patsubst $(SRC_DIR)/%.lua, %, $<))) $< $@
