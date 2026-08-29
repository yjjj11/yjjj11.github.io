---
title: 2026-04 快手数据库实习面经
description: 快手数据库日常实习一面——Asio 线程模型与 Strand、Git 依赖管理
pubDate: 2026-08-29
category: 面经
tags: [面经, C++, 网络, 实习, 快手]
---

> 2026 年 4 月找实习的面经整理。本篇为快手数据库日常实习一面。

## Q1：RPC 用了 Asio 做网络 IO，Asio 的线程模型了解过吗？

Asio 主要有两种 IO 线程模型：

**① IOServicePool（多 io_context，每线程一个）**
创建一个线程池，每个线程一个 io_context。根据 CPU 核心数创建多个 io_context 实例，每个实例绑定一个独立线程并在线程中调用 `run()`，构成一个 IO 服务池。新连接进来时，通过轮询等负载均衡方式分配，把 socket 分配到不同的事件循环。

优势：
- **同一个 socket 的所有异步回调都在同一个 io_context 里**（async_read、async_write 等），单条连接的 IO 处理天然线程安全、无需加锁，完全避免多线程竞争；
- 可以利用多核 CPU 性能，大大提高网络 IO 并发吞吐；
- 每个 io_context 可开启 `SO_REUSEPORT` 监听同一端口，让内核帮忙做负载均衡；或采用主线程监听分发 + 线程池处理单连接 IO。

**② IOThreadPoll（单 io_context，多线程 run）**
单实例 + 多线程竞争。全局只有一个 io_context，但启动多个线程同时 `run()` 它——所有异步任务都放进该 io_context 的任务队列，多个线程抢任务。

特点：负载均衡效果好，但**需要用 Strand 绑定执行线程**，让被同一个 strand 包装的回调串行执行，在不显式加锁的情况下保证线程安全。Strand 是某个 io_context 创建出来的投递队列：一个连接绑定一个 strand，该连接的所有异步回调都投递进 strand 串行化——即使多个线程在抢 IO 任务，strand 始终只会放出一个任务，执行完才放下一个，所以同一连接不会被并发操作、无需加锁。一个 io_context 可以创建多个 strand：一个连接一个 strand 保证本连接串行化，不同连接并行化。

**我的 RPC 用的是多 io_context 实例模型**：主线程负责监听，从线程负责 IO。

**补充要点**：
- `executor_work_guard` 用来保证 io_context 在没有 IO 任务时 `run()` 不会立马退出——创建 guard 就增加对应 io_context 的未完成工作计数，让其一直运行，除非手动 `guard.reset()` 减少计数：

```cpp
asio::io_context ioc;
auto guard = asio::make_work_guard(ioc);  // 获取即加计数
std::thread([&] { ioc.run(); }).detach();
guard.reset();  // 通知 io_context 可以退出了
```

- **executor** 是一种通用基类：自己的异步函数参数如果声明成 executor，就可以由外界传入想用的对象（io_context、strand、thread pool 等），实现类型擦除。

**一个易错点**：如果回调函数内部把后续回调通过 `post` 放回对应 strand 执行，IO 完成时会先被某个线程拿到、该线程再执行 post 把回调重新投递回 strand——这实际上是**两次 IO 调度**。不能跨线程操作带共享资源的变量，所以必须投递回去；如果在 post 之前就操作了该连接的共享变量，会立刻产生并发错误。更好的做法是：执行回调时直接放在 strand 对应的 executor 中执行，无需额外调度，性能更好。

## Q2：Git 怎么管理克隆时的依赖下载？

三种常见方式：

**① thirdparty 目录直接存放**
仓库作者直接把依赖放进 thirdparty 目录，导致仓库臃肿；需要作者自己提取公共依赖避免重复，否则就重复（vendor 类型）。

**② Git submodule**
在项目根目录的 `.gitmodules` 里记录第三方仓库地址 + 固定 commit 哈希，批量从 GitHub 克隆所有子模块源码。**主仓库只存指针、不存第三方代码**。
缺点：第三方 commit 版本写死、不随上游更新变动；底层依赖可能互相重复；嵌套依赖容易多层递归。

**③ 包管理器**
例如 Python 用 `requirements.txt` 列出所需包，安装时能够去重。
