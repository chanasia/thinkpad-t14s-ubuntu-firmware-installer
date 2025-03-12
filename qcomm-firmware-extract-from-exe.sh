#!/bin/bash

set -e
set -u

# Define the URL for the Lenovo firmware update
LENOVO_FIRMWARE_URL="https://download.lenovo.com/pccbbs/mobiles/n42qq11w.exe"
FIRMWARE_FILE="n42qq11w.exe"

device_model="$(tr -d '\0' </proc/device-tree/model)"
case "$device_model" in
	"Lenovo ThinkPad T14s Gen 6")
		device_path="LENOVO/21N1"
		;;
	*)
		printf "error: Device is currently not supported, this script is only for Lenovo ThinkPad T14s Gen 6" >&2
		exit 1
		;;
esac

tmpdir="$(mktemp -p /tmp -d fwfetch.XXXXXXXX)"

function cleanup {
	rm -rf "$tmpdir"
}
trap cleanup EXIT

# Check for required tools
if ! command -v innoextract >/dev/null 2>&1; then
	echo "Installing innoextract..."
	apt-get update -qq
	apt-get install -qq -y innoextract
fi

# Download firmware update if it doesn't exist
if [ ! -f "$FIRMWARE_FILE" ]; then
	echo "Downloading firmware update from Lenovo..."
	if command -v wget >/dev/null 2>&1; then
		wget -q "$LENOVO_FIRMWARE_URL" -O "$tmpdir/$FIRMWARE_FILE"
	elif command -v curl >/dev/null 2>&1; then
		curl -s "$LENOVO_FIRMWARE_URL" -o "$tmpdir/$FIRMWARE_FILE"
	else
		echo "Error: Neither wget nor curl found. Please install one of them." >&2
		exit 1
	fi
else
	cp "$FIRMWARE_FILE" "$tmpdir/"
fi

cd "$tmpdir"

# Extract the EXE file
echo "Extracting firmware update..."
mkdir -p app
innoextract -d app "$FIRMWARE_FILE"

# Create Package boilerplate
pkgver="$(date +'%Y%m%d')"
pkgname="qcom-x1e-firmware-extracted_${pkgver}_arm64"
pkgpath="${tmpdir}/${pkgname}"
mkdir -p "${pkgpath}"
mkdir -p "${pkgpath}/DEBIAN"
mkdir -p "${pkgpath}/lib/firmware/qcom/x1e80100/${device_path}"
cat <<EOF> "${pkgpath}/DEBIAN/control"
Package: qcom-x1e-firmware-extracted
Version: ${pkgver}
Architecture: arm64
Maintainer: Tobias Heider <tobias.heider@canonical.com>
Description: Extracted Snapdragon X Elite firmware for ${device_model}
 This package is automatically generated and includes firmware
 files extracted from Lenovo firmware update.
EOF

# Extract Windows FW files
fw_files="adsp_dtbs.elf
adspr.jsn
adsps.jsn
adspua.jsn
battmgr.jsn
cdsp_dtbs.elf
cdspr.jsn
qcadsp8380.mbn
qccdsp8380.mbn
qcdxkmsuc8380.mbn"

echo "Extracting firmware"
for f_path in ${fw_files}; do
	echo -e "\t${f_path}"
	
	# Find the firmware file in the extracted content
	fw_path="$(find app -name "${f_path}" -print -quit)"
	
	if [ -n "$fw_path" ]; then
		cp "${fw_path}" "${pkgpath}/lib/firmware/qcom/x1e80100/${device_path}/"
	else
		echo "Warning: Could not find ${f_path}" >&2
	fi
done

chmod -R 0644 "${pkgpath}/lib/firmware/qcom/x1e80100/${device_path}"

echo "Building package ${pkgname}..."
# Pack and install
dpkg-deb --build "${pkgname}" > /dev/null

echo "Installing ${pkgname}..."
apt-get install --reinstall -f "./${pkgname}.deb" > /dev/null

echo -e "$(tput bold)Done! Reboot to load the added firmware files. $(tput sgr0)"