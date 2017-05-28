CC = gcc
LINK_USB = `pkg-config --libs --cflags libusb-1.0`
DEBUG = -g


all: samsungpoll

samsungpoll: samsungpoll.c
	$(CC) $(DEBUG) -Wall samsungpoll.c $(LINK_USB) -o samsungpoll


clean:
	@rm -f *.o samsungpoll
