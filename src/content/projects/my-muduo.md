---
title: Muduo 网络库复刻
description: 从零复刻 Muduo 的多线程网络库，并迭代出 HTTP 服务与动漫论坛
github: https://github.com/yjjj11/MyMuduo
category: 网络
tech: [C++, 网络编程, IO]
order: 16
difficulty: 5
---

## 项目简介

从零复刻陈硕的 Muduo 多线程网络库（Reactor 模式、one loop per thread），并在其上迭代出 HTTP 解析、动漫论坛网站。下面归纳线程安全设计、压测踩坑与性能优化。

## 线程安全问题（为什么用任务队列）

**问题**：同一 connection 的业务操作可能被不同工作线程取走执行；若在工作线程中做网络 IO，两个线程会同时操作该 connection 的输出缓冲区和写标识，造成数据竞争。

**为什么选择任务队列**：给每个 connection 的缓冲区加锁固然能解决，但锁资源变多、管理和竞争开销变大。实际做法——每个 connection 持有对应 loop 的指针，工作线程调用 send 时，send 内部触发该 loop 的 `run_in_loop` 函数（专门投递发送 IO 的 eventloop 成员函数），函数内加锁投递，投递后立即 `wakeup` 唤醒 epoll_wait 开始处理任务队列中的发送请求。

**收益**：
1. IO 线程处理所有网络 IO，业务逻辑分离，避免阻塞网络 IO；
2. 任务队列让锁从「每个 connection 一把」降为「每个事件循环一把」。

## 踩坑：压测时文件描述符耗尽

做 QPS 压测时没过多久就文件描述符耗尽，以为是上限太小就调大了 Linux fd 上限，问题依旧。查资料发现大量 **close_wait 状态产生连接泄露**，最终耗尽 fd 导致进程退出。回到 close 相关代码段排查，发现是对连接断开的分支判断不够仔细，部分连接断开没有正常调用 close，加强了异常处理才解决。

## 性能优化

- **Socket 层面**：`SO_REUSEADDR`——端口可快速重启，解决 Address already in use、复用 time_wait；`SO_REUSEPORT`——多线程绑定同一端口、多核负载均衡、提升并发；`TCP_NODELAY`——关闭 Nagle 低延迟，数据立即发送。
- **Reactor 层面**：Reactor 是事件驱动 + IO 多路复用（epoll）的高性能模型，一个或多个 IO 线程持续循环监听 fd 上的读写/连接事件，触发后同步分发给对应回调，全程非阻塞 IO。读回调里最后一次读空时非阻塞 IO 直接返回（阻塞 IO 会一直等到有数据进来）。Reactor 是同步事件分离器（应用主动读写）；Proactor 由操作系统完成拷贝后通知应用。Reactor 实现简单、Linux 生态成熟，是高性能服务器主流方案。

## 迭代：HTTP 服务与动漫论坛

在网络库基础上实现了 HTTP 解析，并写了一个动漫论坛网站：基本的登录登出、token 状态缓存、图片上传与点赞、图片排行榜；用 **Redis 缓存热点图片**提高响应速度、**Nginx 反向代理**避免网络爬虫、**数据库连接池**实现连接复用提升增删改查速度。进一步的迭代方向：升级为通用 HTTPS 库。
