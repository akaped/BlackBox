#!/bin/bash

# IMPORTANT:
# Run the install-little-backup-box.sh script first
# to install the required packages and configure the system.

# Specify devices and their mount points
STORAGE_DEV="sda2"
STORAGE_MOUNT_POINT="/media/storage"
CARD_DEV="sdb1"
CARD_MOUNT_POINT="/media/card"

# Set the ACT LED to heartbeat
#sudo sh -c "echo heartbeat > /sys/class/leds/led0/trigger"
echo "4" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio4/direction

echo "Waiting for a storage device - Connect USB HD or Flash stick"
# Wait for a USB storage device (e.g., a USB flash drive)
STORAGE=$(ls /dev/* | grep $STORAGE_DEV | cut -d"/" -f3)
while [ -z ${STORAGE} ]
  do
  sleep 1
  STORAGE=$(ls /dev/* | grep $STORAGE_DEV | cut -d"/" -f3)
done

# When the USB storage device is detected, mount it
mount /dev/$STORAGE_DEV $STORAGE_MOUNT_POINT

echo "USB Storage mounted"
echo "1" > /sys/class/gpio/gpio4/value

# Set the ACT LED to blink at 1000ms to indicate that the storage device has been mounted
#sudo sh -c "echo timer > /sys/class/leds/led0/trigger"
#sudo sh -c "echo 1000 > /sys/class/leds/led0/delay_on"

echo "Waiting for the camera or SD Card"

# Wait for a card reader or a camera
CARD_READER=$(ls /dev/* | grep $CARD_DEV | cut -d"/" -f3)
until [ ! -z $CARD_READER ]
  do
  sleep 1
  CARD_READER=$(ls /dev/sd* | grep $CARD_DEV | cut -d"/" -f3)
done

echo "0" > /sys/class/gpio/gpio4/value

# If the card reader is detected, mount it and obtain its UUID
if [ ! -z $CARD_READER ]; then
  mount /dev/$CARD_DEV $CARD_MOUNT_POINT
  # # Set the ACT LED to blink at 500ms to indicate that the card has been mounted
  sudo sh -c "echo 500 > /sys/class/leds/led0/delay_on"
  # Create the CARD_ID file containing a random 8-digit identifier if doesn't exist
  if [ ! -f $CARD_MOUNT_POINT/CARD_ID ]; then
    < /dev/urandom tr -cd 0-9 | head -c 8 > $CARD_MOUNT_POINT/CARD_ID
  fi
  # Read the 8-digit identifier number from the CARD_ID file on the card
  # and use it as a directory name in the backup path
  read -r ID < $CARD_MOUNT_POINT/CARD_ID
  BACKUP_PATH=$STORAGE_MOUNT_POINT/"$ID"

echo "Card mounted"
echo "Starting the backup"

echo "17" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio17/direction
echo "1" > /sys/class/gpio/gpio17/value

# Perform backup using rsync
rsync -avh $CARD_MOUNT_POINT/ $BACKUP_PATH
sleep 5
echo "0" > /sys/class/gpio/gpio17/value
# Turn off the ACT LED to indicate that the backup is completed
#sudo sh -c "echo 0 > /sys/class/leds/led0/brightness"
fi
# Shutdown
sync
sleep 3
init 0
