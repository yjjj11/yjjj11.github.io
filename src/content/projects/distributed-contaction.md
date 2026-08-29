---
title: 分布式即时通讯系统
description: 基于 gRPC 微服务架构的分布式 IM 系统（C++ 服务端 + Go 网关）
github: https://github.com/yjjj11/Distributed_Contaction
category: 分布式
tech: [分布式, C++, 网络编程, 数据库]
order: 18
difficulty: 5
---

## 项目简介

一个基于 gRPC 微服务架构的分布式即时通讯（IM）系统。登录、认证、消息、数据库各自独立成一个 gRPC 服务，Go 实现 REST 网关做统一入口，前端原生 HTML/CSS/JS。

## 服务架构

- `gateway`（Go :8080）：REST API 网关，HTTP → gRPC 协议转换 + 统一鉴权
- `grpc_server`（:50051）：注册、登录（gRPC 双向流式 RPC）、改密码、注销账号
- `auth_server`（:50053）：JWT 签发/校验/吊销（OpenSSL HMAC-SHA256 + Redis 黑名单）
- `db_server`（:50052）：MySQL 数据库代理，批量 CRUD、好友关系、消息记录
- `msg_server`（:50054 gRPC / :50055 WebSocket）：在线实时推送、Redis 离线消息、批量落库

## 核心功能

- 好友系统：发送/处理好友请求、好友列表（含在线状态）
- 实时聊天：Boost.Beast WebSocket 在线推送
- 离线消息：Redis 暂存离线消息，上线后 Pull + Ack
- 历史消息：按好友分页拉取聊天记录
- 消息攒批写库（阈值 50 条 / 5s），降低高频写库压力

## 收获

一个项目同时串起了 gRPC 服务拆分、跨语言通信（C++ + Go 共用 .proto）、自实现 JWT 认证、WebSocket 实时推送、Redis 离线缓存、MySQL 批量写入——IM 该有的东西基本都覆盖了，对理解"微服务怎么拆、怎么协作"帮助巨大。

> 综述初稿，架构图细节和部署步骤可以后续补充。
