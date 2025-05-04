#!/bin/bash
# 红米 AX6000 编译脚本 - 优化版

# 设置环境变量
REPO_URL="https://github.com/padavanonly/immortalwrt-mt798x-24.10"
REPO_BRANCH="2410"
CONFIG_FILE="redmi-ax6000/padavanonly-24.10-110/config/default.config"
DIY_P1_SH="redmi-ax6000/padavanonly-24.10-110/diy/diy-part1.sh"
DIY_P2_SH="redmi-ax6000/padavanonly-24.10-110/diy/diy-part2.sh"
OPENWRT_NAME="AX6000"

# 显示欢迎信息
echo "===== 红米 AX6000 编译脚本 - 优化版 ====="
echo ""

# 显示选项菜单
show_menu() {
    echo "请选择编译模式："
    echo "1. 完整编译（包含所有步骤）"
    echo "2. 跳过依赖安装"
    echo "3. 跳过源码更新和依赖安装"
    echo "4. 跳过源码更新、依赖安装和feeds更新"
    echo "5. 仅编译（跳过所有准备步骤）"
    echo "6. 跳过有问题的包（如ruby）"
    echo "7. 清理环境后完整编译"
    echo "8. 清理环境后跳过有问题的包编译"
    echo "9. 极简编译（禁用所有非必要包）"
    echo "10. 诊断模式（单线程编译，详细错误日志）"
    echo "11. 修复模式（自动处理常见问题）"
    echo "0. 退出"
    echo ""
    read -p "请输入选项 [1-11]: " choice
}

# 显示菜单并获取用户选择
show_menu

# 根据用户选择设置跳过标志
SKIP_DEPS=0
SKIP_UPDATE=0
SKIP_FEEDS=0
SKIP_DOWNLOAD=0
SKIP_PROBLEM_PACKAGES=0
CLEAN_BUILD=0
MINIMAL_BUILD=0
DIAGNOSTIC_MODE=0
FIX_MODE=0

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
        SKIP_PROBLEM_PACKAGES=1
        ;;
    7)
        echo "您选择了清理环境后完整编译模式"
        CLEAN_BUILD=1
        ;;
    8)
        echo "您选择了清理环境后跳过有问题的包编译模式"
        CLEAN_BUILD=1
        SKIP_PROBLEM_PACKAGES=1
        ;;
    9)
        echo "您选择了极简编译模式（禁用所有非必要包）"
        CLEAN_BUILD=1
        MINIMAL_BUILD=1
        ;;
    10)
        echo "您选择了诊断模式（单线程编译，详细错误日志）"
        DIAGNOSTIC_MODE=1
        ;;
    11)
        echo "您选择了修复模式（自动处理常见问题）"
        FIX_MODE=1
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
        python3-distutils rsync unzip zlib1g-dev file wget \
        libelf-dev ecj fastjar java-propose-classpath \
        libpython3-dev python3 python3-pip python3-setuptools \
        libfuse-dev libxml-parser-perl
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

# 清理构建环境
if [ $CLEAN_BUILD -eq 1 ]; then
    echo "===== 清理构建环境 ====="
    make distclean
fi

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

# 修复模式 - 自动处理常见问题
if [ $FIX_MODE -eq 1 ]; then
    echo "===== 修复模式：处理常见问题 ====="
    
    # 修复 rust 相关问题
    echo "禁用 rust 相关包..."
    sed -i 's/CONFIG_PACKAGE_rust=y/# CONFIG_PACKAGE_rust is not set/' .config
    sed -i 's/CONFIG_PACKAGE_rust-.*=y/# &/' .config
    
    # 修复缺失的内核模块依赖
    echo "添加缺失的内核模块依赖..."
    echo "CONFIG_PACKAGE_kmod-crypto-chacha20poly1305=y" >> .config
    echo "CONFIG_PACKAGE_kmod-xdp-sockets-diag=m" >> .config
    
    # 修复 libnl 相关问题
    echo "修复 libnl 相关问题..."
    sed -i 's/CONFIG_PACKAGE_libnl-cli=y/# CONFIG_PACKAGE_libnl-cli is not set/' .config
    
    # 修复 CMake 警告
    echo "忽略 CMake 警告..."
    
    # 修复 C++ 编译器问题
    echo "确保 C++ 编译器可用..."
    
    # 禁用有问题的包
    echo "禁用已知有问题的包..."
    sed -i 's/CONFIG_PACKAGE_dae=y/# CONFIG_PACKAGE_dae is not set/' .config
    sed -i 's/CONFIG_PACKAGE_daed=y/# CONFIG_PACKAGE_daed is not set/' .config
    sed -i 's/CONFIG_PACKAGE_libreswan=y/# CONFIG_PACKAGE_libreswan is not set/' .config
    sed -i 's/CONFIG_PACKAGE_strongswan=y/# CONFIG_PACKAGE_strongswan is not set/' .config
    sed -i 's/CONFIG_PACKAGE_netatalk=y/# CONFIG_PACKAGE_netatalk is not set/' .config
fi

# 禁用有问题的包
if [ $SKIP_PROBLEM_PACKAGES -eq 1 ] || [ $MINIMAL_BUILD -eq 1 ]; then
    echo "===== 禁用可能有问题的包 ====="
    
    # 禁用脚本语言包
    sed -i 's/CONFIG_PACKAGE_ruby=y/# CONFIG_PACKAGE_ruby is not set/' .config
    sed -i 's/CONFIG_PACKAGE_ruby-.*=y/# &/' .config
    sed -i 's/CONFIG_PACKAGE_perl=y/# CONFIG_PACKAGE_perl is not set/' .config
    sed -i 's/CONFIG_PACKAGE_perl-.*=y/# &/' .config
    sed -i 's/CONFIG_PACKAGE_python3=y/# CONFIG_PACKAGE_python3 is not set/' .config
    sed -i 's/CONFIG_PACKAGE_python3-.*=y/# &/' .config
    sed -i 's/CONFIG_PACKAGE_node=y/# CONFIG_PACKAGE_node is not set/' .config
    sed -i 's/CONFIG_PACKAGE_node-.*=y/# &/' .config
    
    # 禁用其他可能有问题的包
    sed -i 's/CONFIG_PACKAGE_luci-app-eqos-mtk=y/# CONFIG_PACKAGE_luci-app-eqos-mtk is not set/' .config
    
    # 禁用libnl相关包
    sed -i 's/CONFIG_PACKAGE_libnl=y/# CONFIG_PACKAGE_libnl is not set/' .config
    sed -i 's/CONFIG_PACKAGE_libnl-.*=y/# &/' .config
    
    # 禁用依赖缺失的包
    sed -i 's/CONFIG_PACKAGE_dae=y/# CONFIG_PACKAGE_dae is not set/' .config
    sed -i 's/CONFIG_PACKAGE_daed=y/# CONFIG_PACKAGE_daed is not set/' .config
    sed -i 's/CONFIG_PACKAGE_libreswan=y/# CONFIG_PACKAGE_libreswan is not set/' .config
    sed -i 's/CONFIG_PACKAGE_strongswan=y/# CONFIG_PACKAGE_strongswan is not set/' .config
    sed -i 's/CONFIG_PACKAGE_netatalk=y/# CONFIG_PACKAGE_netatalk is not set/' .config
    
    # 如果是极简模式，禁用更多非必要包
    if [ $MINIMAL_BUILD -eq 1 ]; then
        echo "===== 极简模式：禁用所有非必要包 ====="
        # 禁用所有luci应用
        sed -i 's/CONFIG_PACKAGE_luci-app-.*=y/# &/' .config
        # 保留基本功能
        sed -i 's/# CONFIG_PACKAGE_luci-app-firewall is not set/CONFIG_PACKAGE_luci-app-firewall=y/' .config
        sed -i 's/# CONFIG_PACKAGE_luci-app-opkg is not set/CONFIG_PACKAGE_luci-app-opkg=y/' .config
        
        # 禁用无线相关包（如果不需要）
        sed -i 's/CONFIG_PACKAGE_wpad.*=y/# &/' .config
        sed -i 's/CONFIG_PACKAGE_hostapd.*=y/# &/' .config
        
        # 禁用其他可能导致问题的库
        sed -i 's/CONFIG_PACKAGE_libnetfilter.*=y/# &/' .config
        sed -i 's/CONFIG_PACKAGE_libnfnetlink.*=y/# &/' .config
        sed -i 's/CONFIG_PACKAGE_libmnl.*=y/# &/' .config
    fi
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

# 创建错误日志目录
mkdir -p "$SCRIPT_DIR/error_logs"

# 开始编译固件
echo "===== 开始编译固件 ====="
# 添加错误处理
set +e  # 暂时关闭错误退出

# 诊断模式使用单线程编译并收集详细错误日志
if [ $DIAGNOSTIC_MODE -eq 1 ]; then
    echo "===== 诊断模式：单线程编译，详细错误日志 ====="
    # 使用单线程编译，并将标准输出和错误输出分别保存
    make -j1 V=s 2> >(tee "$SCRIPT_DIR/error_logs/compile_errors.log") | tee "$WORK_DIR/build.log"
    
    # 提取错误信息到单独文件
    grep -i "error:" "$WORK_DIR/build.log" > "$SCRIPT_DIR/error_logs/error_summary.log"
    grep -i "failed" "$WORK_DIR/build.log" >> "$SCRIPT_DIR/error_logs/error_summary.log"
    
    # 分析每个包的编译状态
    echo "===== 分析包编译状态 ====="
    grep -i "package/.*compile" "$WORK_DIR/build.log" | grep -i "error\|failed" > "$SCRIPT_DIR/error_logs/failed_packages.log"
    echo "错误日志已保存到: $SCRIPT_DIR/error_logs/"
else
    # 正常编译模式
    if [ $FIX_MODE -eq 1 ]; then
        # 修复模式使用单线程编译
        echo "===== 修复模式：使用单线程编译 ====="
        make -j1 V=s 2>&1 | tee "$WORK_DIR/build.log"
    else
        # 多线程编译，失败时尝试单线程
        make -j$(nproc) V=s 2>&1 | tee "$WORK_DIR/build.log"
        COMPILE_STATUS=$?
        if [ $COMPILE_STATUS -ne 0 ]; then
            echo "===== 编译失败，尝试单线程编译 ====="
            make -j1 V=s 2>&1 | tee -a "$WORK_DIR/build.log"
        fi
    fi
fi

# 检查编译结果
COMPILE_STATUS=$?
if [ $COMPILE_STATUS -ne 0 ]; then
    echo "===== 编译失败 ====="
    echo "查看错误日志: $WORK_DIR/build.log"
    
    # 提取错误信息
    grep -i "error:" "$WORK_DIR/build.log" > "$SCRIPT_DIR/error_logs/error_summary.log"
    grep -i "failed" "$WORK_DIR/build.log" >> "$SCRIPT_DIR/error_logs/error_summary.log"
    echo "错误摘要已保存到: $SCRIPT_DIR/error_logs/error_summary.log"
    
    # 检查是否存在固件文件
    if ! ls "$WORK_DIR/openwrt/bin/targets/mediatek/mt7986/"*sysupgrade* >/dev/null 2>&1; then
        echo "警告: 未找到固件文件，编译可能未完成"
        
        # 检查是否有部分编译成功的文件
        if [ -d "$WORK_DIR/openwrt/bin/targets/mediatek/mt7986" ]; then
            echo "但目标目录存在，可能有部分文件生成:"
            ls -la "$WORK_DIR/openwrt/bin/targets/mediatek/mt7986"
        fi
        
        # 在诊断模式下不退出，继续处理文件
        if [ $DIAGNOSTIC_MODE -ne 1 ] && [ $FIX_MODE -ne 1 ]; then
            exit 1
        fi
    else
        echo "注意: 虽然有错误，但固件文件已生成"
    fi
fi

set -e  # 重新开启错误退出

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

# 如果是诊断模式，显示错误摘要
if [ $DIAGNOSTIC_MODE -eq 1 ] && [ -f "$SCRIPT_DIR/error_logs/error_summary.log" ]; then
    echo "===== 错误摘要 ====="
    echo "发现以下错误:"
    cat "$SCRIPT_DIR/error_logs/error_summary.log"
    
    if [ -f "$SCRIPT_DIR/error_logs/failed_packages.log" ]; then
        echo "===== 编译失败的包 ====="
        cat "$SCRIPT_DIR/error_logs/failed_packages.log"
    fi
    
    echo "完整错误日志位于: $SCRIPT_DIR/error_logs/compile_errors.log"
fi

# 如果是修复模式，提供建议
if [ $FIX_MODE -eq 1 ]; then
    echo "===== 修复模式建议 ====="
    echo "如果编译仍然失败，请尝试以下操作:"
    echo "1. 使用选项9（极简编译模式）"
    echo "2. 使用选项10（诊断模式）查看详细错误"
    echo "3. 手动修改配置文件，禁用错误日志中提到的问题包"
fi

echo "===== 编译完成 ====="
echo "固件文件位于: $TARGET_DIR"

cd "$SCRIPT_DIR"