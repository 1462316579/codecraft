#!/bin/bash
# 生成支持 v4 签名的 keystore
# 用法: ./scripts/gen_keystore_v4.sh

set -e

KEYSTORE="android/app/upload-keystore.jks"
ALIAS="upload"
STORE_PASSWORD="codecraft123"
KEY_PASSWORD="codecraft123"
VALIDITY=10000

if [ -f "$KEYSTORE" ]; then
  echo "Warning: $KEYSTORE already exists, will overwrite."
  rm -f "$KEYSTORE"
fi

keytool -genkeypair -v \
  -alias "$ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -sigalg SHA256withRSAandPSS \
  -validity "$VALIDITY" \
  -keystore "$KEYSTORE" \
  -storepass "$STORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -dname "CN=CodeCraft, O=CodeCraft, C=CN"

echo ""
echo "=== Keystore generated: $KEYSTORE ==="
echo "Alias: $ALIAS"
echo "Store password: $STORE_PASSWORD"
echo "Key password: $KEY_PASSWORD"
echo ""
echo "=== Next steps ==="
echo "1. Base64 encode the keystore:"
echo "   base64 -w0 android/app/upload-keystore.jks"
echo ""
echo "2. Update GitHub Secret ANDROID_KEYSTORE_BASE64 with the output above"
echo ""
echo "3. Keep STORE_PASSWORD, KEY_PASSWORD, KEY_ALIAS secrets unchanged:"
echo "   STORE_PASSWORD=codecraft123"
echo "   KEY_PASSWORD=codecraft123"
echo "   KEY_ALIAS=upload"
