---
title: Asio 高性能 RPC 框架
description: 基于 Asio 的轻量级 RPC 框架，任意参数传递、异步回调、ZooKeeper 服务发现
github: https://github.com/yjjj11/Asio_mrpc
category: 网络
tech: [C++, 网络编程, 分布式]
order: 21
difficulty: 5
---

## 项目简介

基于 Asio 的轻量级 RPC 框架，核心亮点：模板元编程实现任意参数传递、ZooKeeper 服务注册发现、promise/future 异步回调机制，以及应对粘包拆包的协议头设计。

## 模板元编程：任意参数传递

路由类维护一个 unordered_map，用于业务函数注册与存储：函数名 → 固定类型 `invoke_type` 的函数指针 `bool(*)(connection, buffer)`。通过 `reg_handle` 注册业务函数时，包一层 lambda，把 `connection` 和 buffer 作为参数占位符预留给调用侧；内部调用模板函数 `invoke_callback` 补齐参数。

为什么这么做：invoke 调用在客户端触发时才传入 conn 和 buffer，所以回调参数必须预留这两个占位符；而业务函数指针在注册时就能传入。

```cpp
template<typename Function>
void reg_handle(const std::string& name, Function f) {
    auto h = hash(name);
    invokes_[h] = { name, [f](const std::shared_ptr<connection>& conn,
                              const std::string& buffer) {
        return invoke_callback<Function, std::nullptr_t>(f, nullptr, conn, name, id, buffer);
    }};
}
```

配合 `function_traits` 分离出返回值与可变参数包（`total_argc = sizeof...(Args)`，用 tuple 去掉引用/const 得到类型元组），最终在 `invoke_callback` 里用 `std::apply(f, std::tuple_cat(std::make_tuple(conn), std::move(args)))` 统一调用，支持任意数量、任意类型的业务参数。

## ZooKeeper 服务注册发现

避免地址硬编码，实现节点动态感知：watch `/mrpc/` 节点下的路径有没有变化，有就重新全量拉取并缓存。此后每个节点调用时先遍历缓存表，按 rpc 名称找到对应节点、取 IP:Port 再发送，支持服务水平扩展。

## promise/future 实现异步回调

发送消息后为消息号创建 promise，从协议头收到对应 req_id 的响应后再触发注册的回调，避免同步阻塞空等。异步基础上封装同步 `call`（带超时）：

```cpp
template<size_t TIMEOUT, typename RET = void, msg_type_fmt FMT = DEFAULT_MSG_FORMAT, typename... Args>
req_result<RET> call(const std::string& rpc_name, Args&&... args) {
    auto [req_id, future] = async_call<FMT>(rpc_name, std::forward<Args>(args)...);
    auto status = future.wait_for(std::chrono::milliseconds(TIMEOUT));
    if (status == std::future_status::timeout || status == std::future_status::deferred) {
        future_map_.erase(req_id);   // 清理悬挂请求
        return req_result<RET>(408, "Request Timeout");
    }
    auto [id, msg_body] = future.get();
    return req_result<RET>(id, msg_body);
}
```

## 协议头设计

- **Msg_type**（32 位整数）：类型定义——请求/响应、异步/同步、是否需要响应、是否协程调用、广播/心跳等；同时包含序列化格式类型（JSON、原始二进制、BJSON 等）。
- **Msg_id**：rpc 函数哈希后的 id，用来让对端识别要调用的函数。
- **Req_id**：唯一标识请求，防止响应乱序或丢失。
- **Bodylen**：序列化参数体长度。

这样设计保证每个请求都能应对粘包与拆包的情况。
