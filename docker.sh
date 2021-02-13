#!/usr/bin/env bash
#
# Copyright (C) 2018-2019 Rama Bondan Prakoso (rama982)
#
# Docker Kernel Build Script

# TELEGRAM START
git clone --depth=1 https://github.com/fabianonline/telegram.sh telegram

TELEGRAM=telegram/telegram

tg_channelcast() {
  "${TELEGRAM}" -f "$(echo "$ZIP_DIR"/*.zip)" \
  -t $TELEGRAM_TOKEN \
  -c $CHAT_ID -H \
      "$(
          for POST in "${@}"; do
              echo "${POST}"
          done
      )"
}
# TELEGRAM END

# Main environtment
BRANCH="$(git rev-parse --abbrev-ref HEAD)"
KERNEL_DIR=$(pwd)
PARENT_DIR="$(dirname "$KERNEL_DIR")"
KERN_IMG=$KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb
DTBO_IMG=$KERNEL_DIR/out/arch/arm64/boot/dtbo.img
NAME="Realme"

git submodule update --init --recursive
git clone https://github.com/dodyirawan85/AnyKernel3.git -b inc-dtbo
git clone https://github.com/silont-project/silont-clang.git --depth=1

# Build kernel
export TZ="Asia/Jakarta"
export PATH="$PWD/silont-clang/bin:$PATH"
export KBUILD_COMPILER_STRING="$PWD/silont-clang/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"

export ARCH=arm64
export KBUILD_BUILD_USER="Huril"
KBUILD_BUILD_TIMESTAMP=$(date)

build_kernel () {
    make -j$(nproc --all) O=out \
        ARCH=arm64 \
        CC=clang \
        AR=llvm-ar OBJDUMP=llvm-objdump \
        STRIP=llvm-strip \
        OBJCOPY=llvm-objcopy \
        CROSS_COMPILE=aarch64-linux-gnu- \
        CROSS_COMPILE_ARM32=arm-linux-gnueabi-
}

make O=out ARCH=arm64 ab_defconfig
build_kernel
if ! [ -a $KERN_IMG ]; then
    tg_channelcast "<b>BuildCI report status:</b> There are build running but its error, please fix and remove this message!"
    exit 1
fi

# Make zip installer

# ENV
ZIP_DIR=$KERNEL_DIR/AnyKernel3

# Modify kernel name in anykernel
sed -i 's/ExampleKernel by osm0sis @ xda-developer/'$KERNAME' by dodyirawan85 @ github.com/g' $ZIP_DIR/anykernel.sh

# Make zip
make -C $ZIP_DIR clean
cp $KERN_IMG $ZIP_DIR
cp $DTBO_IMG $ZIP_DIR
make -C $ZIP_DIR normal

KERNEL=$(cat out/.config | grep Linux/arm64 | cut -d " " -f3)
FILEPATH=$(echo "$ZIP_DIR"/*.zip)
HASH=$(git log --pretty=format:'%h' -1)
COMMIT=$(git log --pretty=format:'%h: %s' -1)
tg_channelcast "<b>Latest commit:</b> <a href='https://github.com/dodyirawan85/android_kernel_realme_trinket/commits/$HASH'>$COMMIT</a>" \
               "<b>Kernel:</b> $KERNEL" \
               "<b>sha1sum:</b> <pre>$(sha1sum "$FILEPATH" | awk '{ print $1 }')</pre>" \
               "<b>Date:</b> $KBUILD_BUILD_TIMESTAMP"
