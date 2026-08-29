---
title: HTTP 服务器
description: 一个简单的 HTTP 服务器（解析请求、返回响应）
github: https://github.com/yjjj11/httpserver
category: 网络
tech: [C++, HTTP, socket, 网络编程]
order: 9
---

## 项目简介

一个手写的 HTTP 服务器：监听端口、接收连接、解析 HTTP 请求、返回响应。虽然现在框架满天飞，但自己从 socket 一层层把 HTTP 服务器搭起来，能真正理解"网页是怎么从服务器到你浏览器"的。

## 涉及要点

- socket 编程：bind / listen / accept
- HTTP 请求行与头部的解析
- 静态资源的读取与返回
- 简单的路由处理

## 价值

这是网络编程的起点。做完它，再学 Muduo、gRPC 那些上层框架时，底层都是熟悉的。
