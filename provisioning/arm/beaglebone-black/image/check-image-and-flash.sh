#!/usr/bin/env sh

OS_IMAGE_ARCHIVE_PATH="$1"
if [ -z "${OS_IMAGE_ARCHIVE_PATH}" ]; then
    echo "Pass the OS image archive path as the first option. Terminating..."
    exit 1
fi

if ! [ -f "${OS_IMAGE_ARCHIVE_PATH}" ]; then
    echo "${OS_IMAGE_ARCHIVE_PATH} not found. Terminating..."
    exit 1
fi

DEVICE_TO_FLASH="$2"
if [ -z "${DEVICE_TO_FLASH}" ]; then
    echo "Pass the path to the device to flash as the second option. Terminating..."
    exit 1
fi

if ! [ -e "${DEVICE_TO_FLASH}" ]; then
    echo "${DEVICE_TO_FLASH} not found. Terminating..."
    exit 1
fi

OS_IMAGE_ARCHIVE_SUM_PATH="${OS_IMAGE_ARCHIVE_PATH}".sha256sum
if ! [ -f "${OS_IMAGE_ARCHIVE_SUM_PATH}" ]; then
    echo "${OS_IMAGE_ARCHIVE_SUM_PATH} not found. Terminating..."
    exit 1
fi

echo "Checking hashes..."
cd "$(dirname "${OS_IMAGE_ARCHIVE_SUM_PATH}")" || exit 1
sha256sum -c "${OS_IMAGE_ARCHIVE_SUM_PATH}"

echo "Unzipping the image archive"
xz -vkd "${OS_IMAGE_ARCHIVE_PATH}"

dd bs=1m if="${OS_IMAGE_ARCHIVE_PATH}" of="${DEVICE_TO_FLASH}"