---
title: Lightweight-gRPC
description: 一个从零实现的轻量级、高性能 RPC 框架
github: https://github.com/yjjj11/Lightweight-gRPC
category: 网络
tech: [C++, gRPC, 网络编程, 序列化]
order: 1
---

## 项目简介

一个轻量级的 RPC（远程过程调用）框架，基于 Google Protobuf 做数据序列化，封装在 Muduo 高性能 C++ 网络库之上。目标是去掉冗余设计，聚焦核心通信需求，同时兼顾扩展性与灵活性。

## 设计思路

- 用 Protobuf 定义接口和服务，天然支持跨语言、跨模块通信
- 底层网络用 Muduo 的事件驱动模型处理并发连接
- 框架只保留核心的通信与编解码能力，方便按需扩展

## 技术亮点

适用于微服务架构、分布式计算、跨模块通信等多种场景。麻雀虽小，五脏俱全，是理解 RPC 底层原理的绝佳练习。

> 这里是综述初稿，详细的设计过程、踩坑记录和个人收获可以后续补充。
