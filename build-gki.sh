#!/bin/bash
#
# Compile script for Hexagon kernel
# Copyright (C) 2020-2021 Adithya R.

SECONDS=0 # builtin bash timer
ZIPNAME="Hexagon-lisa-$(date '+%Y%m%d-%H%M').zip"
TC_DIR="/home/tew404/lisa-Kernel/clang-r530567"
DEVICE="lisa"

MAKE_PARAMS="O=out \
	ARCH=arm64 \
	CC=$TC_DIR/bin/clang \
	CLANG_TRIPLE=aarch64-linux-gnu- \
	LLVM=1 \
	LLVM_IAS=1 \
	TARGET_PRODUCT=$DEVICE \
	CROSS_COMPILE=$TC_DIR/bin/llvm- \
	CROSS_COMPILE_ARM32=$TC_DIR/bin/llvm- "

export PATH="$TC_DIR/bin:$PATH"

if [[ $2 = "-r" || $1 = "--regen" ]]; then
	make $MAKE_PARAMS $DEFCONFIG savedefconfig
	cp out/defconfig arch/arm64/configs/$DEFCONFIG
	echo -e "\nSuccessfully regenerated defconfig at $DEFCONFIG"
	exit
fi

if [[ $2 = "-c" || $1 = "--clean" ]]; then
	echo -e "\nCleaning output folder..."
	rm -rf out
fi

sudo rm -rf out

mkdir -p out
ARCH=arm64 CC=$TC_DIR/bin/clang CLANG_TRIPLE=aarch64-linux-gnu- LLVM=1 LLVM_IAS=1 CROSS_COMPILE=$TC_DIR/bin/llvm-  CROSS_COMPILE_ARM32=$TC_DIR/bin/llvm-  scripts/kconfig/merge_config.sh -O out arch/arm64/configs/lisa_defconfig

echo -e "\nStarting compilation...\n"
make -j$(nproc --all) $MAKE_PARAMS || exit $?

kernel="out/arch/arm64/boot/Image"
dtb="out/arch/arm64/boot/dts/vendor/qcom/yupik.dtb"
dtbo="out/arch/arm64/boot/dts/vendor/qcom/lisa-sm7325-overlay.dtbo"

sudo rm -rf *.zip

if [ ! -f "$kernel" ] || [ ! -f "$dtb" ] || [ ! -f "$dtbo" ]; then
	echo -e "\nCompilation failed!"
	exit 1
fi

rm -rf AnyKernel3/Image
rm -rf AnyKernel3/dtb
rm -rf AnyKernel3/dtbo.img

cp $kernel AnyKernel3
cp $dtb AnyKernel3/dtb
#cp $dtbo AnyKernel3

cd AnyKernel3
zip -r9 "../$ZIPNAME" * -x .git README.md *placeholder
cd ..
echo -e "\nCompleted in $((SECONDS / 60)) minute(s) and $((SECONDS % 60)) second(s) !"
echo "Zip: $ZIPNAME"


