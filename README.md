# EspBluFiForiOS
This is a demo app to control the ESP device which run [BluFi](https://github.com/espressif/esp-idf/tree/release/v4.0/examples/bluetooth/bluedroid/ble/blufi)

## ESPRSSIF MIT License
- See [License](LICENSE.txt)

## Development Documents
- See [Doc](doc/Introduction_to_the_EspBlufi_API_Interface_for_iOS__en.md)

## Update Log
- See [Log](log/updatelog-en.md)

## Configure Project

Configure openssl

* Drag the BlufiLibrary file into the project root directory.
* Add **$(inherited)** and **$(PROJECT_DIR)/(project name)/BlufiLibrary/Security/openssl** to **Library Search Paths**.
* Add **$(SRCROOT)/(project name)/BlufiLibrary/Security/openssl/include/** to **Header Search Paths**