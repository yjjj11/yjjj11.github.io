---
title: Muduo 网络库复刻
description: 从零复刻 Muduo 的 C++ 多线程网络库学习项目
github: https://github.com/yjjj11/MyMuduo
category: 网络
tech: [C++, 多线程, 网络编程, 事件驱动]
order: 14
---

## 项目简介

Muduo 是陈硕用 C++ 写的著名多线程网络库，Reactor 模式、one loop per thread 的设计思想影响了无数 C++ 网络学习者。本项目是我跟着源码从零复刻一遍的学习产物。

## 学习重点

- Reactor 事件循环：`epoll` + 事件分发
- one loop per thread：每个线程一个事件循环，避免锁竞争
- 定时器、连接管理、缓冲区（Buffer）的实现细节
- RAII 与智能指针在生命周期管理上的运用

## 收获

亲手写一遍之后，才真正理解为什么 Muduo 会被称为"最好的 C++ 网络编程入门教材"。从只会用 socket 到能看懂整个网络库的架构，是巨大的跨越。

> 综述初稿，详细学习笔记可以后续补充。
