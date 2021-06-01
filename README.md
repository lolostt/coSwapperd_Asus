
# coSwapperd
This script will create swap.swp file in STORAGE_NAME volume for enable swap memory, running every UPDATE_INTERVAL minutes.

Script uses some internal witchery deep in the firmware (for now) allowing run scripts at every boot. If you are using [Asuswrt-Merlin](https://www.asuswrt-merlin.net) you don't need this because Merlin firmware can run scripts from JFFS partition. Sadly, Asuswrt-Merlin is not available for every Asus router (for very good reasons). This script is intended for that unsupported devices. **Only tested on Asus RT-AC52U B1 (firmware 3.0.0.4.380.10760 from January 2019)**.

## Getting Started
### Prerequisites
#### Hardware
* Asus router with USB and running AsusWRT.
* USB drive.
#### Software
* USB drive must be formatted in a supported filesystem. It must be properly mounted.

### Installing
1. Place script at USB root.
2. Edit needed variables with usb name and desired swap file size in kilobytes:
  ```
  STORAGE_NAME="usb8gb"
  SWAP_SIZE="524288"
  ```

## Usage
Login router via SSH and execute:
```
cd /tmp/mnt/YOUR_USBSTORAGE_NAME
chmod +x coSwapperd.sh
./coSwapperd.sh -e
```
### Available options
-i | --initcheck
Initial check. Mount point reachable check.
	
-e | --enable
Enables script autorun.
	
-d | --disable
Disables script autorun.
	
-c | --clean
Removes autorun support files.
	
-s | --start
Starts script itself.

### Script behaviour
You can set some variables to customize script behaviour:
 - UPDATE_INTERVAL. Sets time in minutes between script runs. It must be set before enabling script.
 - SWAP_SIZE. Sets swap file size in kilobytes.

## Authors
* **lolost** - [sleepingcoconut.com](https://sleepingcoconut.com/)

## License
This project is licensed under the [Zero Clause BSD license](https://opensource.org/licenses/0BSD).