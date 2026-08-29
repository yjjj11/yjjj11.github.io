---
title: Raft 分布式一致性实现
description: Raft 分布式一致性算法实现
github: https://github.com/yjjj11/Raft_distributes
category: 分布式
tech: [C++, 分布式系统, 一致性算法]
order: 20
difficulty: 5
---

## 项目简介

Raft 是一种易于理解的分布式一致性算法，用来解决多节点之间如何就某个状态达成一致的问题（如选主、日志复制）。本项目是基于 Raft 论文从零实现的分布式系统练习。

## 核心模块

- 领导者选举（Leader Election）
- 日志复制（Log Replication）
- 安全性保证（Safety）
- 成员变更与日志压缩

## 价值

一致性算法是分布式系统的基石，面试和实战都绕不开。从"看懂论文"到"跑通代码"再到"处理各种边界情况"，这个过程对理解分布式系统帮助巨大。

> 综述初稿，具体的实现细节和测试可以后续补充。
