#!/bin/bash
# 红米 AX6000 Ubuntu编译脚本

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

# 显示选项菜单
show_menu() {
    echo "请选择编译模式："
    echo "1. 完整编译（包含所有步骤）"
    echo "2. 跳过依赖安装"
    echo "3. 跳过源码更新和依赖安装"
    echo "4. 跳过源码更新、依赖安装和feeds更新"
    echo "5. 仅编译（跳过所有准备步骤，直接开始编译）"
    echo "6. 跳过有问题的包（如ruby）"
    echo "0. 退出"
    echo ""
    read -p "请输入选项 [1-6]: " choice
}

# 显示菜单并获取用户选择
show_menu

# 根据用户选择设置跳过标志
SKIP_DEPS=0
SKIP_UPDATE=0
SKIP_FEEDS=0
SKIP_DOWNLOAD=0

case $choice in
    1)
        echo "您选择了完整编译模式"
        ;;
    2)
        echo "您选择了跳过依赖安装的编译模式"
        SKIP_DEPS=1
        ;;
    3)
        echo "您选择了跳过源码更新和依赖安装的编译模式"
        SKIP_DEPS=1
        SKIP_UPDATE=1
        ;;
    4)
        echo "您选择了跳过源码更新、依赖安装和feeds更新的编译模式"
        SKIP_DEPS=1
        SKIP_UPDATE=1
        SKIP_FEEDS=1
        ;;
    5)
        echo "您选择了仅编译模式（跳过所有准备步骤）"
        SKIP_DEPS=1
        SKIP_UPDATE=1
        SKIP_FEEDS=1
        SKIP_DOWNLOAD=1
        ;;
    6)
        echo "您选择了跳过有问题的包并编译模式"
        SKIP_DEPS=1
        SKIP_UPDATE=1
        SKIP_FEEDS=0
        SKIP_DOWNLOAD=0
        SKIP_PROBLEM_PACKAGES=1
        ;;
    0)
        echo "退出脚本"
        exit 0
        ;;
    *)
        echo "无效选项，使用完整编译模式"
        ;;
esac

# 设置错误时退出
set -e

# 检查磁盘空间
echo "===== 检查磁盘空间 ====="
df -h
FREE_SPACE=$(df -h . | awk 'NR==2 {print $4}')
echo "可用空间: $FREE_SPACE"
echo ""

# 检查必要工具
if [ $SKIP_DEPS -eq 0 ]; then
    echo "===== 检查并安装必要的依赖 ====="
    sudo apt-get update -y
    sudo apt-get install -y build-essential clang flex bison g++ gawk \
        gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
        python3-distutils rsync unzip zlib1g-dev file wget
else
    echo "===== 跳过依赖安装 ====="
fi

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
elif [ $SKIP_UPDATE -eq 0 ]; then
    echo "===== 更新固件源码 ====="
    cd openwrt
    git pull
    cd ..
else
    echo "===== 跳过源码更新 ====="
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
if [ $SKIP_FEEDS -eq 0 ]; then
    echo "===== 更新feeds ====="
    ./scripts/feeds update -a
    ./scripts/feeds install -a
else
    echo "===== 跳过feeds更新 ====="
fi

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
if [ $SKIP_DOWNLOAD -eq 0 ]; then
    echo "===== 下载依赖包 ====="
    make download -j$(nproc)
    find dl -size -1024c -exec rm -f {} \;
else
    echo "===== 跳过依赖包下载 ====="
fi

# 开始编译固件
echo "===== 开始编译固件 ====="
# 添加错误处理
make -j$(nproc) V=s 2>&1 | tee build.log || {
    echo "===== 编译失败，尝试单线程编译 ====="
    make -j1 V=s 2>&1 | tee -a build.log
}

# 检查编译结果
COMPILE_STATUS=$?
if [ $COMPILE_STATUS -ne 0 ]; then
    echo "===== 编译失败 ====="
    echo "查看错误日志: $WORK_DIR/openwrt/build.log"
    echo "尝试单独编译问题包:"
    echo "cd $WORK_DIR/openwrt && make package/luci-app-eqos-mtk/compile V=s"
    
    # 检查是否存在固件文件
    if [ ! -f "$WORK_DIR/openwrt/bin/targets/mediatek/mt7986/"*sysupgrade* ]; then
        echo "警告: 未找到固件文件，编译可能未完成"
        exit 1
    else
        echo "注意: 虽然有错误，但固件文件已生成"
    fi
fi

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
        if [ -f "$file" ] && [ "$(echo "$file" | grep -c "ax6000")" -gt 0 ]; then
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

# 在生成默认配置后添加
if [ "${SKIP_PROBLEM_PACKAGES:-0}" -eq 1 ]; then
    echo "===== 禁用可能有问题的包 ====="
    # 禁用ruby包
    sed -i 's/CONFIG_PACKAGE_ruby=y/# CONFIG_PACKAGE_ruby is not set/' .config
    sed -i 's/CONFIG_PACKAGE_ruby-.*=y/# &/' .config
    # 如果有其他问题包，可以在这里添加
fi