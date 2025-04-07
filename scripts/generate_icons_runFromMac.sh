#!/bin/sh

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "usage: $0 <source image> <ios destination directory>"
    exit 1
fi

if [ ! -f "$1" ]; then
    echo "Source image does not exist"
    exit 2
fi

mkdir -p "$2"
if [ $? -ne 0 ]; then
    echo "Could not create directory"
    exit 3
fi

mkdir $2
sips -z 40 40     $1 --out $2/iphone_notification_2x.png
sips -z 60 60     $1 --out $2/iphone_notification_3x.png
sips -z 58 58     $1 --out $2/iphone_settings_2x.png
sips -z 87 87     $1 --out $2/iphone_settings_3x.png
sips -z 80 80     $1 --out $2/iphone_spotlight_2x.png
sips -z 120 120     $1 --out $2/iphone_spotlight_3x.png
sips -z 120 120     $1 --out $2/iphone_app_2x.png
sips -z 180 180     $1 --out $2/iphone_app_3x.png
sips -z 20 20     $1 --out $2/ipad_notification_1x.png
sips -z 40 40     $1 --out $2/ipad_notification_2x.png
sips -z 29 29     $1 --out $2/ipad_settings_1x.png
sips -z 58 58     $1 --out $2/ipad_settings_2x.png
sips -z 40 40     $1 --out $2/ipad_spotlight_1x.png
sips -z 80 80     $1 --out $2/ipad_spotlight_2x.png
sips -z 76 76     $1 --out $2/ipad_app_1x.png
sips -z 152 152     $1 --out $2/ipad_app_2x.png
sips -z 167 167     $1 --out $2/ipad_pro_app_2x.png
cp $1 $2/original.png
