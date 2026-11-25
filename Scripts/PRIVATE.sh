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

echo "########## 自定义配置结束 ##########"
echo ""
