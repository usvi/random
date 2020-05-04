CC = gcc

all: diskcont

diskcont: diskcont.c
	$(CC) -D_FILE_OFFSET_BITS=64 -Wall -o diskcont diskcont.c

clean:
	@rm -f *.o diskcont
