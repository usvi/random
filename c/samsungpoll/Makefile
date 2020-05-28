CC = gcc
LINK_USB = `pkg-config --libs --cflags libusb-1.0`
DEBUG = -g

# These are needed, installation in debian:
#apt-get install libusb-1.0.0-dev
#apt-get install apt-get install pkg-config


all: samsungpoll

samsungpoll: samsungpoll.c
	$(CC) $(DEBUG) -Wall samsungpoll.c $(LINK_USB) -o samsungpoll


clean:
	@rm -f *.o samsungpoll
