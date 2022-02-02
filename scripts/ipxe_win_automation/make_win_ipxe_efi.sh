#!/bin/sh

# Give like /make_win_ipxe_efi.sh Win10_21H2_English_x64-2022-02-02 /rwmount/to/ipxe_dir /rwmount/to/wims_base_dir
#
# apt-get install wimtools
#
# Might need non-free repos on debian
#


IPXE_SRC_DIR="/root/ipxe/src"
IPXE_HTTP_PREFIX="http://172.16.8.254/ipxe"
WIM_HTTP_PREFIX="http://172.16.8.254/wims"

IPXE_ID="$1"
IPXE_INST_DIR="$2"
WIMS_INST_DIR="$3"

if [ ! -d "$IPXE_INST_DIR" -o ! -w "$IPXE_INST_DIR" ];
then
    echo "Problem with IPXE installation directory $IPXE_INST_DIR"
    exit 1
fi

if [ ! -d "$WIMS_INST_DIR" -o ! -w "$WIMS_INST_DIR" ];
then
    echo "Problem with WIMS installation directory $WIMS_INST_DIR"
    exit 1
fi

if [ ! -d "$IPXE_SRC_DIR" -o ! -w "$IPXE_SRC_DIR" ];
then
    echo "Problem with IPXE build source directory $IPXE_INST_DIR"
    exit 1
fi

EMBED_SCRIPT_FULL_PATH="$IPXE_SRC_DIR/$IPXE_ID.efi.ipxe.embed"

IPXE_HTTP_BASE="$IPXE_HTTP_PREFIX/$IPXE_ID"
WIMS_HTTP_BASE="$WIM_HTTP_PREFIX/$IPXE_ID"

WIMS_FS_SOURCE="$WIMS_INST_DIR/amd64template"
WIMS_FS_DEST="$WIMS_INST_DIR/$IPXE_ID"


echo "Using:"
echo "ID = $IPXE_ID"
echo "IPXE install directory = $IPXE_INST_DIR"
echo "IPXE build source directory = $IPXE_SRC_DIR"
echo "IPXE http base = $IPXE_HTTP_BASE"
echo "WIMS http base = $WIMS_HTTP_BASE"


rm -f "$EMBED_SCRIPT_FULL_PATH"

echo "#!ipxe" >> "$EMBED_SCRIPT_FULL_PATH"
echo "# $IPXE_ID.efi.ipxe.embed" >> "$EMBED_SCRIPT_FULL_PATH"
echo "" >> "$EMBED_SCRIPT_FULL_PATH"
echo "echo \"Loading $IPXE_HTTP_BASE.efi.ipxe\"" >> "$EMBED_SCRIPT_FULL_PATH"
echo "" >> "$EMBED_SCRIPT_FULL_PATH"
echo "dhcp" >> "$EMBED_SCRIPT_FULL_PATH"
echo "chain $IPXE_HTTP_BASE.efi.ipxe" >> "$EMBED_SCRIPT_FULL_PATH"
echo "" >> "$EMBED_SCRIPT_FULL_PATH"

IPXE_EFI_BIN_PATH="bin-x86_64-efi/ipxe.efi"

make -C "$IPXE_SRC_DIR" "$IPXE_EFI_BIN_PATH" EMBED="$IPXE_ID.efi.ipxe.embed"

if [ $? -ne 0 ];
then
    echo "Failed to build IPXE"
    exit 1
fi

cp "$IPXE_SRC_DIR/$IPXE_EFI_BIN_PATH" "$IPXE_INST_DIR/$IPXE_ID.efi"

# Check
if [ $? -ne 0 ];
then
    echo "Failed to copy build ipxe to $IPXE_INST_DIR/$IPXE_ID.efi"
    exit 1
fi


IPXE_INST_SCRIPT_FULL_PATH="$IPXE_INST_DIR/$IPXE_ID.efi.ipxe"

rm -f "$IPXE_INST_SCRIPT_FULL_PATH"

echo "#!ipxe" >> "$IPXE_INST_SCRIPT_FULL_PATH"
echo "" >> "$IPXE_INST_SCRIPT_FULL_PATH"
echo "kernel $WIMS_HTTP_BASE/wimboot" >> "$IPXE_INST_SCRIPT_FULL_PATH"
echo "initrd $WIMS_HTTP_BASE/BCD" >> "$IPXE_INST_SCRIPT_FULL_PATH"
echo "initrd $WIMS_HTTP_BASE/boot.sdi" >> "$IPXE_INST_SCRIPT_FULL_PATH"
echo "initrd $WIMS_HTTP_BASE/boot.wim" >> "$IPXE_INST_SCRIPT_FULL_PATH"
echo "" >> "$IPXE_INST_SCRIPT_FULL_PATH"
echo "boot" >> "$IPXE_INST_SCRIPT_FULL_PATH"
echo "" >> "$IPXE_INST_SCRIPT_FULL_PATH"


# Need to edit the wim file to contain in cmd something like this
#wpeinit

#net use j: \\172.16.8.221\Install\Isos\win10
#j:\Win10_21H2_English_x64-2022-02-02.iso_unpacked/setup.exe


#WIMS_FS_SOURCE="$WIMS_INST_DIR/amd64template"
#WIMS_FS_DEST="$WIMS_INST_DIR/$IPXE_ID"

rm -rf "$WIMS_FS_DEST"

cp -rv "$WIMS_FS_SOURCE" "$WIMS_FS_DEST"

if [ $? -ne 0 ];
then
    echo "Failed to copy wim template data from $WIMS_FS_SOURCE to $WIMS_FS_DEST"
    exit 1
fi

wimmountrw "$WIMS_FS_DEST/boot.wim" "$WIMS_FS_DEST/mount"

if [ $? -ne 0 ];
then
    echo "Failed to mount wim file $WIMS_FS_DEST/boot.wim to $WIMS_FS_DEST/mount"
    exit 1
fi


STARTNET="$WIMS_FS_DEST/mount/Windows/System32/startnet.cmd"

rm -f "$STARTNET"

printf "wpeinit\r\n" >> "$STARTNET"
printf "\r\n" >> "$STARTNET"
printf "net use j: \\\\\\\\172.16.8.221\\\\Install\\\\Isos\\\\win10\r\n" >> "$STARTNET"
printf "j:\\\\$IPXE_ID.iso_unpacked\\\\setup.exe\r\n" >> "$STARTNET"
printf "\r\n" >> "$STARTNET"


wimunmount --commit "$WIMS_FS_DEST/mount"

if [ $? -ne 0 ];
then
    echo "Failed to unmount wim location $WIMS_FS_DEST/mount"
    exit 1
fi



echo "All done, all OK!"

exit 0

