#
# When building a package or installing otherwise in the system, make
# sure that the variable PREFIX is defined, e.g. make PREFIX=/usr/local
#
PROGNAME=dump1090
SDRPLAY=1
DUMP1090_VERSION="dump1090_mutability_sdrplay"

# Path to rtlsdr library ** ADD PATH TO RTL-SDR librtlsdr.pc file **
PKG_CONFIG_PATH=
LIBS_RTL=`pkg-config --libs librtlsdr`

ifndef DUMP1090_VERSION
DUMP1090_VERSION=$(shell git describe --tags --match=v*)
endif

ifdef PREFIX
BINDIR=$(PREFIX)/bin
SHAREDIR=$(PREFIX)/share/$(PROGNAME)
EXTRACFLAGS=-DHTMLPATH=\"$(SHAREDIR)\"
endif

ifdef SDRPLAY
SDRPLAY_CFLAGS=-DSDRPLAY
# path to API files
# the following is for building on Windows under CygWin
# uncomment as necessary
#SDRPLAY_LIBS=-L"/cygdrive/c/program files/sdrplay/api/x86"
#SDRPLAY_CFLAGS+=-I"/cygdrive/c/program files/sdrplay/api/inc"
endif

CPPFLAGS+=-DMODES_DUMP1090_VERSION=\"$(DUMP1090_VERSION)\"
CFLAGS+= -O3 -Wall -Wextra -pedantic -W -fcommon
CFLAGS+=$(SDRPLAY_CFLAGS)
LIBS=$(SDRPLAY_LIBS) $(LIBS_RTL) -lsdrplay_api -lpthread -lm -lrtlsdr
CC=gcc

UNAME := $(shell uname)

ifeq ($(UNAME), Linux)
LIBS+=-lrt
endif
ifeq ($(UNAME), Darwin)
# TODO: Putting GCC in C11 mode breaks things.
CFLAGS+=-std=c11
COMPAT+=compat/clock_gettime/clock_gettime.o compat/clock_nanosleep/clock_nanosleep.o
endif

all: dump1090 view1090

%.o: %.c *.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(EXTRACFLAGS) -c $< -o $@

dump1090.o: CFLAGS += `pkg-config --cflags librtlsdr`

dump1090: dump1090.o anet.o interactive.o mode_ac.o mode_s.o net_io.o crc.o demod_2000.o demod_2400.o demod_8000.o stats.o cpr.o icao_filter.o track.o util.o convert.o $(COMPAT)
	$(CC) -o $@ $^ $(LIBS) $(LDFLAGS) 

view1090: view1090.o anet.o interactive.o mode_ac.o mode_s.o net_io.o crc.o stats.o cpr.o icao_filter.o track.o util.o $(COMPAT)
	$(CC) -o $@ $^ $(LIBS) $(LDFLAGS)

faup1090: faup1090.o anet.o mode_ac.o mode_s.o net_io.o crc.o stats.o cpr.o icao_filter.o track.o util.o $(COMPAT)
	$(CC) -o $@ $^ $(LIBS) $(LDFLAGS)

clean:
	rm -f *.o compat/clock_gettime/*.o compat/clock_nanosleep/*.o dump1090 view1090 faup1090 cprtests crctests

test: cprtests
	./cprtests

cprtests: cpr.o cprtests.o
	$(CC) $(CPPFLAGS) $(CFLAGS) $(EXTRACFLAGS) -o $@ $^ -lm

crctests: crc.c crc.h
	$(CC) $(CPPFLAGS) $(CFLAGS) $(EXTRACFLAGS) -DCRCDEBUG -o $@ $<
