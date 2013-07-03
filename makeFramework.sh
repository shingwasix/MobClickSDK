# Original Script by  Pete Goodliffe
# from http://accu.org/index.php/journals/1594

# Modified by Juan Batiz-Benet for GHUnitIOS
# Modified by Gabriel Handford for YAJL
# Modified by ShingwaSix(http://www.waaile.com/) for Anything

# 一.以下行的作用,当命令带非零值(即错误值)返回,立即退出
set -e

echo "================base info====================="
# Define these to suit your nefarious purposes
# 二.定义这些变量来满足你不可告人的目的
# 1)框架名
FRAMEWORK_NAME=MobClick
if [ -z "$FRAMEWORK_NAME" ]; then
echo "error:FRAMEWORK_NAME is not set."
exit 1
fi
echo "Framework name: "$FRAMEWORK_NAME
# 2)静态库文件名字,不带后缀
LIB_NAME=libMobClickLibrary
if [ -z "$LIB_NAME" ]; then
echo "error:LIB_NAME is not set."
exit 1
fi
echo "Lib name: "$LIB_NAME
# 3)静态库文件目录
LIB_PATH=./
if [ -z "$LIB_PATH" ]; then
echo "error:LIB_PATH is not set."
exit 1
fi
echo "Lib files path: "$LIB_PATH
# 4)头文件目录
INC_PATH=./
if [ -z "$INC_PATH" ]; then
echo "error:INC_PATH is not set."
exit 1
fi
echo "Include files path: "$INC_PATH
# 5)资源文件目录
RES_PATH=
if [ -n "$RES_PATH" ]; then
echo "Resource files path: "$RES_PATH
fi
# 6)框架版本,不为空则表示需要按多版本编译
FRAMEWORK_VERSION=
if [ -n "$FRAMEWORK_VERSION" ]; then
echo "Framework version: "$FRAMEWORK_VERSION
fi
# 7)编译类型(Debug或Release),不为空则表示lib分为iphoneos版本和iphonesimulator版本
LIB_PFX=
if [ -n "$LIB_PFX" ]; then
echo "Lib prefix:"$LIB_PFX
fi

# Where we'll put the build framework.
# The script presumes we're in the project root
# directory. Xcode builds in "build" by default
# 8)框架编译路径
FRAMEWORK_BUILD_PATH="./build"
echo "Framework build path:"$FRAMEWORK_BUILD_PATH

echo "===============build info====================="
# This is the full name of the framework we'll
# build
FRAMEWORK_DIR=$FRAMEWORK_BUILD_PATH/$FRAMEWORK_NAME.framework
# 三.删除已存在的框架
echo "Framework: Cleaning framework..."
[ -d "$FRAMEWORK_DIR" ] && \
rm -rf "$FRAMEWORK_DIR"

# Build the canonical Framework bundle directory
# structure
# 四.创建相应的目录
echo "Framework: Setting up directories..."
mkdir -p $FRAMEWORK_DIR

if [ -n "$FRAMEWORK_VERSION" ]; then
mkdir -p $FRAMEWORK_DIR/Versions
mkdir -p $FRAMEWORK_DIR/Versions/$FRAMEWORK_VERSION
mkdir -p $FRAMEWORK_DIR/Versions/$FRAMEWORK_VERSION/Resources
if [ -n "$RES_PATH" ]; then
mkdir -p $FRAMEWORK_DIR/Versions/$FRAMEWORK_VERSION/Headers
fi
else
if [ -n "$RES_PATH" ]; then
mkdir -p $FRAMEWORK_DIR/Resources
fi
mkdir -p $FRAMEWORK_DIR/Headers
fi

# 五.创建替身.不需要
if [ -n "$FRAMEWORK_VERSION" ]; then
echo "Framework: Creating symlinks..."
ln -s $FRAMEWORK_VERSION $FRAMEWORK_DIR/Versions/Current
ln -s Versions/Current/Headers $FRAMEWORK_DIR/Headers
if [ -n "$RES_PATH" ]; then
ln -s Versions/Current/Resources $FRAMEWORK_DIR/Resources
fi
fi
	
# Check that this is what your static libraries
# are called
if [ -n "$LIB_PFX" ]; then
ARM_FILES="$LIB_PATH/$LIB_PFX-iphoneos/${LIB_NAME}.a"
I386_FILES="$LIB_PATH/$LIB_PFX-iphonesimulator/${LIB_NAME}.a"
fi

# The trick for creating a fully usable library is
# to use lipo to glue the different library
# versions together into one file. When an
# application is linked to this library, the
# linker will extract the appropriate platform
# version and use that.
# The library file is given the same name as the
# framework with no .a extension.
echo "Framework: Creating library..."

if [ -n "$LIB_PFX" ]; then
lipo \
  -create \
  "$ARM_FILES" \
  "$I386_FILES" \
  -o "$FRAMEWORK_DIR/$FRAMEWORK_NAME"
else
cp $LIB_PATH/$LIB_NAME.a $FRAMEWORK_DIR/$FRAMEWORK_NAME
fi

if [ -n "$FRAMEWORK_VERSION" ]; then
mv $FRAMEWORK_DIR/$FRAMEWORK_NAME $FRAMEWORK_DIR/Versions/Current/$FRAMEWORK_NAME
ln -s Versions/Current/$FRAMEWORK_NAME $FRAMEWORK_DIR/$FRAMEWORK_NAME
fi

# Now copy the final assets over: your library
# header files and the plist file
echo "Framework: Copying assets into current version..."
cp $INC_PATH/*.h $FRAMEWORK_DIR/Headers/

if [ -n "$RES_PATH" ]; then
echo "Framework: Copying resources into current version..."
cp -r -f $RES_PATH/* $FRAMEWORK_DIR/Resources/
fi

chmod -R 775 $FRAMEWORK_DIR

echo "Well done!(^_^)"
