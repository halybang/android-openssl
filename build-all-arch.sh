#!/bin/bash
#
# http://wiki.openssl.org/index.php/Android
#
set -e
rm -rf prebuilt
mkdir prebuilt

#archs=(armeabi arm64-v8a mips mips64 x86 x86_64)
archs=(armeabi arm64-v8a)
for arch in ${archs[@]}; do
    xLIB="/lib"
    case ${arch} in
        "armeabi")
            _ANDROID_TARGET_SELECT=arch-arm
            _ANDROID_ARCH=arch-arm
            _ANDROID_EABI=arm-linux-androideabi-4.9
            #PI -marm -march=armv7-a -mtune=cortex-a7 -mfpu=neon-vfpv4 -mthumb-interwork -mabi=aapcs-linux
            #BB -marm -march=armv7-a -mtune=cortex-a8 -mfpu=neon -mfloat-abi=hard
            #VP -marm -march=armv8-a -mtune=cortex-a53 -mfloat-abi=softfp
            #configure_platform="android -march=armv7-a -mtune=cortex-a7 -mfloat-abi=softfp -mfpu=neon " ;;
            configure_platform="android -marm -march=armv8-a -mtune=cortex-a53 -mfloat-abi=softfp" ;;
        "arm64-v8a")
            _ANDROID_TARGET_SELECT=arch-arm64-v8a
            _ANDROID_ARCH=arch-arm64
            _ANDROID_EABI=aarch64-linux-android-4.9
            configure_platform="android64-aarch64 -march=armv8-a -mtune=cortex-a53 -DB_ENDIAN" ;;
        "mips")
            _ANDROID_TARGET_SELECT=arch-mips
            _ANDROID_ARCH=arch-mips
            _ANDROID_EABI=mipsel-linux-android-4.9
            configure_platform="android -DB_ENDIAN" ;;
        "mips64")
            _ANDROID_TARGET_SELECT=arch-mips64
            _ANDROID_ARCH=arch-mips64
            _ANDROID_EABI=mips64el-linux-android-4.9
            xLIB="/lib64"
            configure_platform="linux-generic64 -DB_ENDIAN" ;;
        "x86")
            _ANDROID_TARGET_SELECT=arch-x86
            _ANDROID_ARCH=arch-x86
            _ANDROID_EABI=x86-4.9
            configure_platform="android-x86" ;;
        "x86_64")
            _ANDROID_TARGET_SELECT=arch-x86_64
            _ANDROID_ARCH=arch-x86_64
            _ANDROID_EABI=x86_64-4.9
            xLIB="/lib64"
            configure_platform="linux-generic64" ;;
        *)
            configure_platform="linux-elf" ;;
    esac

    mkdir prebuilt/${arch}

    . ./setenv-android-mod.sh

    echo "CROSS COMPILE ENV : $CROSS_COMPILE"
    cd openssl-1.1.0b

    xCFLAGS="-DSHARED_EXTENSION=.so -fPIC -DOPENSSL_PIC -DDSO_DLFCN -DHAVE_DLFCN_H -mandroid -I$ANDROID_DEV/include -B$ANDROID_DEV/$xLIB -O3 -fomit-frame-pointer -Wall -s"
    perl -pi -e 's/install: all install_docs install_sw/install: install_docs install_sw/g' Makefile.org
#    ./Configure shared no-threads no-asm no-zlib no-ssl2 no-ssl3 no-comp no-hw no-engine $configure_platform $xCFLAGS
#    ./Configure shared --prefix=$ANDROID_DEV --openssldir=$ANDROID_DEV $configure_platform $xCFLAGS
    ./Configure shared --prefix=$HOME/usr/android/prebuilt/$ANDROID_API/$_ANDROID_ARCH/usr --openssldir=$HOME/usr/android/prebuilt/$ANDROID_API/$_ANDROID_ARCH/usr $configure_platform $xCFLAGS
    
    # patch SONAME

    perl -pi -e 's/\.so\.\$\(SHLIB_MAJOR\)\.\$\(SHLIB_MINOR\)/\.so/g' Makefile
    perl -pi -e 's/LIBVERSION=\$\(SHLIB_MAJOR\)\.\$\(SHLIB_MINOR\)//g' Makefile
    perl -pi -e 's/SHLIB_MAJOR=1/SHLIB_MAJOR=/g' Makefile
    perl -pi -e 's/SHLIB_MINOR=1/SHLIB_MINOR=/g' Makefile
    
    make clean
    make depend
    make all
    make install_dev

    file libcrypto.so
    file libssl.so
    cp libcrypto.so ../prebuilt/${arch}/libcrypto.so
    cp libssl.so ../prebuilt/${arch}/libssl.so
    cd ..
done
exit 0

