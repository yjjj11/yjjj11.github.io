#!/usr/bin/env bash
# 百度搜索资源平台「普通收录 → 主动推送」脚本
# 用法: ./scripts/baidu-push.sh <站点> <token>
#   站点 = https://yjjj11.github.io  （资源平台里添加的站点，不带尾斜杠）
#   token = 资源平台「链接提交」页分配给该站点的推送令牌
# 前提: 先 npm run build，从 dist/sitemap-0.xml 提取全部 URL 推送。
# 参考: https://ziyuan.baidu.com/linksubmit/index
set -euo pipefail

SITE="${1:?用法: ./scripts/baidu-push.sh <站点> <token>}"
TOKEN="${2:?用法: ./scripts/baidu-push.sh <站点> <token>}"
SITEMAP="${SITEMAP:-dist/sitemap-0.xml}"

if [[ ! -f "$SITEMAP" ]]; then
	echo "找不到 $SITEMAP，请先执行 npm run build" >&2
	exit 1
fi

urls=$(grep -o '<loc>[^<]*</loc>' "$SITEMAP" | sed 's/<[^>]*>//g')
tmp=$(mktemp)
printf '%s\n' $urls > "$tmp"

echo "准备推送 $(wc -l < "$tmp") 个 URL → 百度（$SITE）..."
echo "--- 推送内容预览（前 3 条）---"
head -3 "$tmp"

echo "--- 推送结果 ---"
# 代理环境下直连百度数据接口，加 --noproxy '*'
curl -s --noproxy '*' -H 'Content-Type:text/plain' \
	--data-binary @"$tmp" \
	"https://data.zz.baidu.com/urls?site=$SITE&token=$TOKEN"
echo ""
rm -f "$tmp"
