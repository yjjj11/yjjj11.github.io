---
title: 博客部署到 GitHub Pages 的完整流程
description: 从本地 Astro 静态站到 GitHub Actions 自动部署上线的全流程记录
category: 部署
tags: [GitHub Pages, GitHub Actions, Astro]
pubDate: 2026-08-29
---

## 问题现象

博客用 Astro 搭好后，只能在本机 `localhost` 预览，别人访问不了，也没法看真实浏览量。

## 解决过程

### 1. 生成静态产物

Astro 是静态站点生成器，`npm run build` 会把源码编译成纯 HTML/CSS/JS，输出到 `dist/` 目录。这个目录就是"静态网站"本体。

### 2. 选托管平台

不买域名也可以部署：GitHub Pages / Netlify / Vercel 等免费托管平台都会送一个子域名。这里选 GitHub Pages，因为生态好、无限免费，域名是 `用户名.github.io`。

### 3. 安装并登录 gh CLI

```bash
# 下载免安装的 gh 二进制放到 ~/.local/bin
# 然后走官方"设备码"登录（不需要密码）
gh auth login -h github.com -p https --web
```

### 4. 建仓库并推送

```bash
git init -b main
git remote add origin https://github.com/用户名/用户名.github.io.git
git add -A && git commit -m "first deploy"
git push -u origin main
```

### 5. 配置 GitHub Actions 自动部署

在 `.github/workflows/deploy.yml` 写一个 workflow：每次 push 到 main，就自动 `npm ci` + `npm run build`，再用 `actions/deploy-pages` 部署。以后更新文章只要 `git push`，网站自动更新。

### 6. 启用 Pages

仓库名如果就是 `用户名.github.io`，GitHub 会自动启用 Pages。等 Actions 跑完，访问 `https://用户名.github.io` 就上线了。

## 经验总结

- 静态站部署 = 构建出 `dist/` + 扔到托管平台，不需要自己的后端
- 本地预览看不到不蒜子浏览量是正常的，上线后才会正常计数
