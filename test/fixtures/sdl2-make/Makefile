# LiveNiro fixture: plain C + SDL2 + a Makefile.
CFLAGS = -O2 -Wall $(shell sdl2-config --cflags)
LDLIBS = $(shell sdl2-config --libs) -lm

blocks: main.c
	$(CC) $(CFLAGS) main.c -o blocks $(LDLIBS)

clean:
	rm -f blocks
