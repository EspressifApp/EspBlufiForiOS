


# This APP is a demo for Blufi of ESP-IDF

## V1.0.3

* Open the source code
* Add get wifi list around ESP32 command
* Add send error report to phone when blufi has error
* Add send or receive custom data command, the command is for user echange user-defined data


## V1.0.2 

* 此版本为 ESP-IDF 中 Blufi Demo 配合使用的 APP (This APP is demo for Blufi demo of ESP-IDF)
* 设备蓝牙名称必须为`BLUFI`开头才能被搜索到 (APP can only search for devices whose ADV name has a `BLUFI_` prefix)
* 支持蓝牙的连接,断开自动重连 (Support BLE reconnect)
* 支持配置成 SOFTAP, STATION 或者 SOFTAP & STATION 模式 (Support SOFTAP mode and STATION mode)
