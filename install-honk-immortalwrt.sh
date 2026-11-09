#!/bin/sh
# ImmortalWrt 25.12.2 (qualcommax/ipq807x, kernel 6.12.103) 一键安装 honk
# 包含: daeuniverse 软件源 + 定制 vmlinux-btf (绕开内核无 BTF 的问题) + honk + LuCI 应用
# 用法: 在路由器上以 root 执行: sh install-honk-immortalwrt.sh
set -e

BTF_URL='https://gh-proxy.com/https://github.com/markiswin/list/blob/main/vmlinux-btf-6.12.103-r1.apk'
BTF_SHA256='afe085c8bef2ef7b97b5bc5acca4b6c6a9837ab10ed8120d665752cf5bd07c30'
BTF_FILE='/tmp/vmlinux-btf-6.12.103-r1.apk'

echo '== 0. 环境检查 =='
. /etc/openwrt_release
echo "release=$DISTRIB_RELEASE arch=$DISTRIB_ARCH target=$DISTRIB_TARGET kernel=$(uname -r)"
if [ "$DISTRIB_RELEASE" != '25.12.2' ] || [ "$(uname -r)" != '6.12.103' ]; then
  echo '!! 此脚本只适用于 ImmortalWrt 25.12.2 / 内核 6.12.103, 当前环境不符, 已退出'
  exit 1
fi

echo '== 1. 导入 daeuniverse 签名公钥 =='
wget -O /etc/apk/keys/daeuniverse.pem https://openwrt.daeuniverse.org/public-key.pem

echo '== 2. 添加 daeuniverse 软件源 =='
FEED="https://openwrt.daeuniverse.org/$(echo "$DISTRIB_RELEASE" | cut -d. -f1-2)"
cat > /etc/apk/repositories.d/daeuniverse.list <<EOF
@daeuniverse $FEED/packages/$DISTRIB_ARCH/packages.adb
EOF
apk update

echo '== 3. 下载并校验 vmlinux-btf =='
wget -O "$BTF_FILE" "$BTF_URL"
ACTUAL="$(sha256sum "$BTF_FILE" | cut -d' ' -f1)"
if [ "$ACTUAL" != "$BTF_SHA256" ]; then
  echo "!! BTF 包 sha256 不符: $ACTUAL, 下载到的文件不对, 已退出"
  exit 1
fi
echo 'sha256 校验通过'

echo '== 4. 安装 vmlinux-btf (先装它, honk 才不会去拉占位包) =='
apk add --allow-untrusted "$BTF_FILE"
ls -lh /usr/lib/debug/boot/

echo '== 5. 安装 honk =='
apk add honk@daeuniverse luci-app-honk@daeuniverse

echo '== 6. 启用并启动 honk =='
/etc/init.d/honk enable
/etc/init.d/honk start
sleep 2
logread | grep -i honk | tail -5 || true

echo
echo '完成: 打开 http://192.168.1.1:9527/ 进入 doona (首次先建管理员账号)。'
echo '默认全部流量直连, 在界面里加节点/订阅后再配分流规则。'
