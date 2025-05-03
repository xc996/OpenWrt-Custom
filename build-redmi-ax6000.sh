#!/bin/bash
# 红米 AX6000 Ubuntu编译脚本

# 设置错误时退出
set -e

# 设置环境变量
REPO_URL="https://github.com/padavanonly/immortalwrt-mt798x-24.10"
REPO_BRANCH="2410"
CONFIG_FILE="redmi-ax6000/padavanonly-24.10-110/config/default.config"
DIY_P1_SH="redmi-ax6000/padavanonly-24.10-110/diy/diy-part1.sh"
DIY_P2_SH="redmi-ax6000/padavanonly-24.10-110/diy/diy-part2.sh"
OPENWRT_NAME="AX6000"

# 显示欢迎信息
echo "===== 红米 AX6000 Ubuntu编译脚本 ====="
echo ""

# 检查必要工具
echo "===== 检查并安装必要的依赖 ====="
sudo apt-get update -y
sudo apt-get install -y build-essential clang flex bison g++ gawk \
    gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
    python3-distutils rsync unzip zlib1g-dev file wget

# 创建工作目录
SCRIPT_DIR=$(pwd)
WORK_DIR="$SCRIPT_DIR/build"
mkdir -p "$WORK_DIR"
cd "$WORK_DIR"

echo "工作目录: $WORK_DIR"
echo ""

# 检查是否已经克隆了代码库
if [ ! -d "openwrt" ]; then
    echo "===== 下载固件源码 ====="
    git clone $REPO_URL -b $REPO_BRANCH openwrt
else
    echo "===== 更新固件源码 ====="
    cd openwrt
    git pull
    cd ..
fi

# 准备编译环境
echo "===== 准备编译环境 ====="
cd "$WORK_DIR/openwrt"

# 应用自定义配置
echo "===== 应用自定义配置 ====="
if [ -e "$SCRIPT_DIR/$CONFIG_FILE" ]; then
    cp "$SCRIPT_DIR/$CONFIG_FILE" .config
fi

# 执行自定义脚本1
echo "===== 执行自定义脚本1 ====="
if [ -e "$SCRIPT_DIR/$DIY_P1_SH" ]; then
    chmod +x "$SCRIPT_DIR/$DIY_P1_SH"
    "$SCRIPT_DIR/$DIY_P1_SH"
fi

# 更新feeds
echo "===== 更新feeds ====="
./scripts/feeds update -a
./scripts/feeds install -a

# 执行自定义脚本2
echo "===== 执行自定义脚本2 ====="
if [ -e "$SCRIPT_DIR/$DIY_P2_SH" ]; then
    chmod +x "$SCRIPT_DIR/$DIY_P2_SH"
    "$SCRIPT_DIR/$DIY_P2_SH"
fi

# 检查配置文件格式
echo "===== 检查配置文件格式 ====="
wc -l .config

# 生成默认配置
echo "===== 生成默认配置 ====="
make defconfig

# 下载依赖包
echo "===== 下载依赖包 ====="
make download -j$(nproc)
find dl -size -1024c -exec rm -f {} \;

# 开始编译固件
echo "===== 开始编译固件 ====="
make -j$(nproc) V=s || make -j1 V=s

# 整理文件
echo "===== 整理文件 ====="
TARGET_DIR="$WORK_DIR/openwrt/bin/targets/mediatek/mt7986"
if [ -d "$TARGET_DIR" ]; then
    cd "$TARGET_DIR"
    echo "当前目录: $(pwd)"
    
    # 删除packages目录
    if [ -d "packages" ]; then
        rm -rf packages
        echo "已删除packages目录"
    fi
    
    # 重命名文件
    echo "===== 重命名文件 ====="
    for file in *; do
        if [[ "$file" == *"ax6000"* ]]; then
            newname=$(echo "$file" | sed 's/ax6000/ax6000-spi_nand-110m/')
            echo "重命名: $file -> $newname"
            mv "$file" "$newname"
        fi
    done
    
    echo "===== 重命名后的文件 ====="
    ls -la
else
    echo "警告: 目标目录不存在: $TARGET_DIR"
fi

echo "===== 编译完成 ====="
echo "固件文件位于: $TARGET_DIR"

cd "$SCRIPT_DIR"