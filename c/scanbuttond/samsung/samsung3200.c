/* samsung3200.c: Samsung SCX-3200 backend
 * This file is part of scanbuttond.
 * Copyleft )c( 2015 by Janne Paalijarvi <jpaalija gmail.com>,
 * adapted from hp code written by Ilia Sotnikov <hostcc@gmail.com>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */
#include <unistd.h>
#include <limits.h>
#include <stdlib.h>
#include <sys/types.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>
#include <stdio.h>
#include <netinet/in.h>         /* For htons() */
#include "scanbuttond/scanbuttond.h"
#include "scanbuttond/libusbi.h"
#include "samsung3200.h"

static char *backend_name = "SAMSUNG3200 USB";

#define NUM_SUPPORTED_USB_DEVICES 1

static int supported_usb_devices[NUM_SUPPORTED_USB_DEVICES][3] = {
  /* vendor, product, num_buttons */
  {0x04e8, 0x3441, 1},          /* Samsung SCX-3200 series. For example SCX-3205. */
};

static char *usb_device_descriptions[NUM_SUPPORTED_USB_DEVICES][2] = {
  {"Samsung", "SCX-3200"},
};

static libusb_handle_t *libusb_handle;
static scanner_t *samsung3200_scanners = NULL;

/* returns -1 if the scanner is unsupported, or the index of the
 * corresponding vendor-product pair in the supported_usb_devices array.
 */
static int samsung3200_match_libusb_scanner (libusb_device_t * device)
{
  int index;

  for (index = 0; index < NUM_SUPPORTED_USB_DEVICES; index++)
  {
    if (supported_usb_devices[index][0] == device->vendorID &&
        supported_usb_devices[index][1] == device->productID)
      break;
  }

  if (index >= NUM_SUPPORTED_USB_DEVICES)
    return -1;

  return index;
}

static void samsung3200_attach_libusb_scanner (libusb_device_t * device)
{
  const char *descriptor_prefix = "samsung3200:libusb:";
  int index;

  index = samsung3200_match_libusb_scanner (device);
  /* Unsupported */
  if (index < 0)
    return;

  scanner_t *scanner = (scanner_t *) malloc (sizeof (scanner_t));
  scanner->vendor = usb_device_descriptions[index][0];
  scanner->product = usb_device_descriptions[index][1];
  scanner->connection = CONNECTION_LIBUSB;
  scanner->internal_dev_ptr = (void *) device;
  scanner->lastbutton = 0;
  scanner->sane_device = (char *) malloc (strlen (device->location) +
                                          strlen (descriptor_prefix) + 1);
  strcpy (scanner->sane_device, descriptor_prefix);
  strcat (scanner->sane_device, device->location);
  scanner->num_buttons = supported_usb_devices[index][2];
  scanner->is_open = 0;
  scanner->next = samsung3200_scanners;
  samsung3200_scanners = scanner;
}

static void samsung3200_detach_scanners (void)
{
  scanner_t *next;

  while (samsung3200_scanners != NULL)
  {
    next = samsung3200_scanners->next;
    free (samsung3200_scanners->sane_device);
    free (samsung3200_scanners);
    samsung3200_scanners = next;
  }
}

static void samsung3200_scan_devices (libusb_device_t * devices)
{
  int index;
  libusb_device_t *device = devices;

  while (device != NULL)
  {
    index = samsung3200_match_libusb_scanner (device);
    if (index >= 0)
      samsung3200_attach_libusb_scanner (device);
    device = device->next;
  }
}

static int samsung3200_init_libusb (void)
{
  libusb_device_t *devices;

  libusb_handle = libusb_init ();
  devices = libusb_get_devices (libusb_handle);
  samsung3200_scan_devices (devices);
  return 0;
}

static void samsung3200_flush (scanner_t * scanner)
{
  switch (scanner->connection)
  {
  case CONNECTION_LIBUSB:
    libusb_flush ((libusb_device_t *) scanner->internal_dev_ptr);
    break;
  }
}

const char *scanbtnd_get_backend_name (void)
{
  return backend_name;
}

int scanbtnd_init (void)
{
  samsung3200_scanners = NULL;

  syslog (LOG_INFO, "samsung3200-backend: init");
  return samsung3200_init_libusb ();
}

int scanbtnd_rescan (void)
{
  libusb_device_t *devices;

  samsung3200_detach_scanners ();
  samsung3200_scanners = NULL;
  libusb_rescan (libusb_handle);
  devices = libusb_get_devices (libusb_handle);
  samsung3200_scan_devices (devices);

  return 0;
}

const scanner_t *scanbtnd_get_supported_devices (void)
{
  return samsung3200_scanners;
}

int scanbtnd_open (scanner_t * scanner)
{
  int result = -ENOSYS;

  if (scanner->is_open)
    return -EINVAL;

  switch (scanner->connection)
  {
  case CONNECTION_LIBUSB:
    /* if devices have been added/removed, return -ENODEV to
     * make scanbuttond update its device list
     */
    if (libusb_get_changed_device_count () != 0)
      return -ENODEV;
    result = libusb_open ((libusb_device_t *) scanner->internal_dev_ptr);
    break;
  }
  if (result == 0)
    scanner->is_open = 1;

  return result;
}

int scanbtnd_close (scanner_t * scanner)
{
  int result = -ENOSYS;

  if (!scanner->is_open)
    return -EINVAL;

  switch (scanner->connection)
  {
  case CONNECTION_LIBUSB:
    result = libusb_close ((libusb_device_t *) scanner->internal_dev_ptr);
    break;
  }
  if (result == 0)
    scanner->is_open = 0;

  return result;
}

#define USB_READ_DIR                0x80
#define USB_READ_REQUEST            0x0c
#define USB_READ_VALUE              0x0087
#define USB_READ_INDEX              0x0100
#define USB_READ_LENGTH             0x0008
static unsigned char scan_button_array[] =
  { 0x1B, 0x9A, 0x00, 0x08, 0x05, 0x02, 0x01, 0x00 };

static int samsung3200_read (scanner_t * scanner, void *bufdata, int bufsize)
{
  int ret;

  ret = libusb_control_msg ((libusb_device_t *) scanner->internal_dev_ptr,
                            USB_READ_DIR | USB_TYPE_VENDOR,
                            USB_READ_REQUEST, USB_READ_VALUE, USB_READ_INDEX,
                            bufdata, bufsize);

  return ret;
}

int scanbtnd_get_button (scanner_t * scanner)
{
  unsigned char bytes[USB_READ_LENGTH] = { 0 };
  int ret = 0;

  if (!scanner->is_open)
    return -EINVAL;

  ret = samsung3200_read (scanner, (void *) bytes, USB_READ_LENGTH);

  if (ret != USB_READ_LENGTH)
  {
    samsung3200_flush (scanner);
    syslog (LOG_INFO, "samsung3200-backend: Couldn't read button state");
    return 0;
  }
  if (memcmp (scan_button_array, bytes, USB_READ_LENGTH) == 0)
  {
    return 1;
  }

  return 0;
}

const char *scanbtnd_get_sane_device_descriptor (scanner_t * scanner)
{
  return scanner->sane_device;
}

int scanbtnd_exit (void)
{
  syslog (LOG_INFO, "samsung3200-backend: exit");
  samsung3200_detach_scanners ();
  libusb_exit (libusb_handle);
  return 0;
}
