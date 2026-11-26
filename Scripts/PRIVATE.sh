#!/bin/bash
# 放在 fork 后仓库的 Scripts/PRIVATE.sh
# 会被 Scripts/Packages.sh 在末尾自动 source（此时工作目录是 ./wrt/package/）
#
# 作用：显式保证 airoha/an7581 的内核配置里关掉 flow stats。
# 上游 pbs05/ponwrt 目前已经是关的，这里只是"保险 + 打印核实"，
# 万一将来上游改回 =y，这行能把它掰回来。

CFG="../target/linux/airoha/an7581/config-6.18"

echo ""
echo "########## 自定义内核配置：NPU flow stats 开关 ##########"

if [ ! -f "$CFG" ]; then
	echo "!! 找不到 $CFG，跳过"
else
	if grep -q '^CONFIG_NET_AIROHA_FLOW_STATS' "$CFG"; then
		sed -i 's/^CONFIG_NET_AIROHA_FLOW_STATS=.*/# CONFIG_NET_AIROHA_FLOW_STATS is not set/' "$CFG"
		echo "已把 CONFIG_NET_AIROHA_FLOW_STATS 改为 not set"
	elif grep -q '^# CONFIG_NET_AIROHA_FLOW_STATS is not set' "$CFG"; then
		echo "上游已是 not set，无需改动"
	else
		echo "# CONFIG_NET_AIROHA_FLOW_STATS is not set" >> "$CFG"
		echo "已追加 CONFIG_NET_AIROHA_FLOW_STATS is not set"
	fi

	echo "--- 当前生效值："
	grep -n 'NET_AIROHA' "$CFG" | sed 's/^/    /'
fi

echo ""
echo "########## 补装 luci-app-airoha-npu（LuCI 芯片状态面板）##########"
# ponwrt 上游不带这个应用（VSEAN 固件才有），从 lilaoye88/ImmortalWrt-Airoha 取
# 此脚本被 Packages.sh source 时，工作目录是 ./wrt/package/
PKG_DIR="./luci-app-airoha-npu"
if [ -f "$PKG_DIR/Makefile" ]; then
	echo "luci-app-airoha-npu 已存在，跳过"
else
	rm -rf ./_lilaoye88_tmp
	if git clone --depth 1 --filter=blob:none --sparse \
		https://github.com/lilaoye88/ImmortalWrt-Airoha ./_lilaoye88_tmp >/dev/null 2>&1; then
		git -C ./_lilaoye88_tmp sparse-checkout set packages/luci-app-airoha-npu >/dev/null 2>&1
		if [ -f "./_lilaoye88_tmp/packages/luci-app-airoha-npu/Makefile" ]; then
			cp -r ./_lilaoye88_tmp/packages/luci-app-airoha-npu ./luci-app-airoha-npu
			echo "luci-app-airoha-npu 已放入 package/"
		else
			echo "!! 仓库里没有 packages/luci-app-airoha-npu，面板将缺席"
		fi
		rm -rf ./_lilaoye88_tmp
	else
		echo "!! git 克隆失败（网络问题），芯片状态面板将缺席"
	fi
fi
echo ""
echo "########## 补装 Nikki（mihomo 透明代理 + LuCI 面板）##########"
# ponwrt 源码树里没有 luci-app-nikki（Packages.sh 的 nikki 更新被注释掉了），
# 从 nikkinikki-org/OpenWrt-nikki 官方仓库拉取。此脚本被 Packages.sh source
# 时工作目录是 ./wrt/package/
NIKKI_DIR="./_nikki_src"
if [ -f "./nikki/Makefile" ] && [ -f "./luci-app-nikki/Makefile" ]; then
	echo "nikki 已存在，跳过"
else
	rm -rf "$NIKKI_DIR"
	if git clone --depth 1 https://github.com/nikkinikki-org/OpenWrt-nikki "$NIKKI_DIR" >/dev/null 2>&1; then
		for p in nikki luci-app-nikki mihomo-meta; do
			if [ -f "$NIKKI_DIR/$p/Makefile" ]; then
				rm -rf "./$p"
				cp -r "$NIKKI_DIR/$p" "./$p"
				echo "  $p 已放入 package/"
			else
				echo "  !! $NIKKI_DIR/$p 不存在"
			fi
		done
		rm -rf "$NIKKI_DIR"
	else
		echo "!! git 克隆失败（网络问题），Nikki 将缺席"
	fi
fi
echo ""
echo "########## 装入本地自维护包（local-packages）##########"
# luci-app-pon-status：从旧固件备份重建的"状态/概览"PON 光模块卡片
# 此脚本被 Packages.sh source 时工作目录是 ./wrt/package/，
# CI 仓库根 = ../../ ，local-packages/ 放在仓库根下
for src in ../../local-packages/*/; do
	[ -d "$src" ] || continue
	name=$(basename "$src")
	if [ -f "$src/Makefile" ]; then
		rm -rf "./$name"
		cp -r "$src" "./$name"
		echo "  $name 已放入 package/"
	else
		echo "  !! $src 缺少 Makefile，跳过"
	fi
done
echo "########## 自定义配置结束 ##########"
echo ""
