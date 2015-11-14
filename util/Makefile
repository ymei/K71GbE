OSTYPE = $(shell uname)
ARCH   = $(shell uname -m)
##################################### Defaults ################################
CC             := gcc
INCLUDE        := -I.
CFLAGS         := -Wall -O2
CFLAGS_32      := -m32
SHLIB_CFLAGS   := -fPIC -shared
SHLIB_EXT      := .so
LIBS           := -lm
LDFLAGS        :=
############################# Library add-ons #################################
INCLUDE += -I/opt/local/include -I/usr/local/include
LIBS    += -L/opt/local/lib -L/usr/local/lib -lpthread -lhdf5
GSLLIBS  = $(shell gsl-config --libs)
GLLIBS   =
############################# OS & ARCH specifics #############################
ifneq ($(OSTYPE)), Linux)
  ifeq ($(OSTYPE), Darwin)
    CC            = clang
    GLLIBS       += -framework GLUT -framework OpenGL -framework Cocoa
    SHLIB_CFLAGS := -dynamiclib
    SHLIB_EXT    := .dylib
    ifeq ($(shell sysctl -n hw.optional.x86_64), 1)
      ARCH       := x86_64
    endif
  else ifeq ($(OSTYPE), FreeBSD)
    CC      = clang
    GLLIBS += -lGL -lGLU -lglut
  else ifeq ($(OSTYPE), SunOS)
    CFLAGS     := -Wall
  else
    # Let's assume this is win32
    SHLIB_EXT  := .dll
  endif
else
  GLLIBS += -lGL -lGLU -lglut
endif

ifneq ($(ARCH), x86_64)
  CFLAGS_32 += -m32
endif

# Are all G5s ppc970s?
ifeq ($(ARCH), ppc970)
  CFLAGS += -m64
endif
############################ Define targets ###################################
EXE_TARGETS = tcpio fmc112 waveview
DEBUG_EXE_TARGETS = hdf5rawWaveformIo
# SHLIB_TARGETS = XXX$(SHLIB_EXT)

ifeq ($(ARCH), x86_64) # compile a 32bit version on 64bit platforms
  # SHLIB_TARGETS += XXX_m32$(SHLIB_EXT)
endif

.PHONY: exe_targets shlib_targets debug_exe_targets clean
exe_targets: $(EXE_TARGETS)
shlib_targets: $(SHLIB_TARGETS)
debug_exe_targets: $(DEBUG_EXE_TARGETS)

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDE) -c $< -o $@
tcpio: tcpio.c command.o tge.o
	$(CC) $(CFLAGS) $(INCLUDE) $^ $(LIBS) $(LDFLAGS) -o $@
fmc112: fmc112.c command.o sip.o hdf5rawWaveformIo.o
	$(CC) $(CFLAGS) $(INCLUDE) $^ $(LIBS) $(LDFLAGS) -o $@
waveview: waveview.c hdf5rawWaveformIo.o
	$(CC) $(CFLAGS) $(INCLUDE) -Wno-deprecated-declarations $^ $(LIBS) $(GLLIBS) $(LDFLAGS) -o $@
command.o: command.c command.h common.h
	$(CC) $(CFLAGS) $(INCLUDE) -c $<
tge.o: tge.c tge.h command.h common.h
	$(CC) $(CFLAGS) $(INCLUDE) -c $<
sip.o: sip.c sip.h command.h common.h
	$(CC) $(CFLAGS) $(INCLUDE) -c $<
hdf5rawWaveformIo.o: hdf5rawWaveformIo.c hdf5rawWaveformIo.h common.h
	$(CC) $(CFLAGS) -DH5_NO_DEPRECATED_SYMBOLS $(INCLUDE) -c $<
hdf5rawWaveformIo: hdf5rawWaveformIo.c hdf5rawWaveformIo.h
	$(CC) $(CFLAGS) -DH5_NO_DEPRECATED_SYMBOLS $(INCLUDE) -DHDF5IO_DEBUG_ENABLEMAIN $< $(LIBS) $(LDFLAGS) -o $@

# libmreadarray$(SHLIB_EXT): mreadarray.o
# 	$(CC) $(SHLIB_CFLAGS) $(CFLAGS) $(LIBS) -o $@ $<
# mreadarray.o: mreadarray.c
# 	$(CC) $(CFLAGS) $(INCLUDE) -c -o $@ $<
# mreadarray: mreadarray.c
# 	$(CC) $(CFLAGS) -DENABLEMAIN $(INCLUDE) $(LIBS) -o $@ $<
# libmreadarray_m32$(SHLIB_EXT): mreadarray.c
# 	$(CC) -m32 $(SHLIB_CFLAGS) $(CFLAGS) $(CFLAGS_32) -o $@ $<

clean:
	rm -f *.o *.so *.dylib *.dll *.bundle
	rm -f $(SHLIB_TARGETS) $(EXE_TARGETS) $(DEBUG_EXE_TARGETS)
