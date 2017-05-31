#include <stdio.h>
#include <libusb-1.0/libusb.h>

#define SAMSUNG_MANUF 0x04E8
#define SAMSUNG_DEV_SCX3200 0x3441

#define BM_REQUEST_TYPE 0xC1
#define B_REQUEST 0x0C
#define W_VALUE 0x0087
#define W_INDEX 0x0100
#define W_LENGTH 0x8
#define POLL_TIMEOUT_MS 100

#define SCAN_BUTTON_POS 6
#define SCAN_BUTTON_PRESVAL 1

// Remember to install usb library and pkg-config before building
// In Ubuntu done like this:
// sudo apt-get install libusb-1.0-0-dev pkg-config

int main()
{
  libusb_context* px_usb_ctx;
  libusb_device** px_dev_list;
  libusb_device_handle* px_dev_handle;
  struct libusb_device_descriptor x_dev_desc;
  unsigned char return_data[W_LENGTH] = { 0 };
  
  ssize_t dev_count;
  ssize_t i;
  int i_device_found = 0;
  int i_retval = 0;
  int i_status = 0;
  
  if(libusb_init(&px_usb_ctx) != 0)
  {
    printf("ERROR: Failed to initialize libusb, exiting");

    return i_status;
  }
  dev_count = libusb_get_device_list(px_usb_ctx, &px_dev_list);

  for(i = 0; i < dev_count; i++)
  {
    libusb_get_device_descriptor(px_dev_list[i], &x_dev_desc);

    if((x_dev_desc.idVendor ==  SAMSUNG_MANUF) && (x_dev_desc.idProduct == SAMSUNG_DEV_SCX3200))
    {
      i_device_found = 1;
      
      if((i_retval = libusb_open(px_dev_list[i] , &px_dev_handle)) != 0)
      {
	if(i_retval == LIBUSB_ERROR_NO_MEM)
	{
	  printf("ERROR: Unable to allocate memory\n");
	}
	else if(i_retval == LIBUSB_ERROR_ACCESS)
	{
	  printf("ERROR: Insufficient permissions accessing device\n");
	}
	else if(i_retval == LIBUSB_ERROR_NO_DEVICE)
	{
	  printf("ERROR: Device has been disconnected\n");
	}
	else
	{
	  printf("ERROR: Unspecified error while opening device\n");
	}
	i_status = 1;

	break;
      }
      if(W_LENGTH != libusb_control_transfer(px_dev_handle,
					     BM_REQUEST_TYPE,
					     B_REQUEST,
					     W_VALUE,
					     W_INDEX,
					     return_data,
					     W_LENGTH,
					     POLL_TIMEOUT_MS))
      {
	printf("ERROR: USB query failed\n");
	libusb_close(px_dev_handle);
	i_status = 1;

	break;
      }
      if(return_data[SCAN_BUTTON_POS] == SCAN_BUTTON_PRESVAL)
      {
	i_status = 0;
	printf("OK: Scan button pressed\n");
      }
      else
      {
	i_status = 0;
	printf("OK: Scan button clear\n");
      }
      libusb_close(px_dev_handle);
      break;
    }
  }
  if(!i_device_found)
  {
    i_status = 1;
    printf("ERROR: Unable to find suiteble Samsung device\n");
  }
  libusb_free_device_list(px_dev_list, 1);
  libusb_exit(px_usb_ctx);

  return i_status;
}
