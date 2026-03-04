[[English]](updatelog-en.md)

# 更新日志

## 1.7.1
- 与 Android PR #60 同步：SECURITY_V2（BluFi 1.4）现使用 AES/CTR/NoPadding，采用域派生 IV（`blufi_enc` / `blufi_dec`）及持久化加解密 cryptor 以支持流式加解密。

## 1.7.0
- 更新 Blufi 库以支持 IDF 6.0 BluFi
- 添加对设备端 BluFi 1.4 加密的支持
- 添加 SHA256 哈希支持用于 AES 密钥生成
- 添加 DH 3072 密钥交换支持以增强安全性

## 1.1.0
- 全新 UI
- 全新开发接口
