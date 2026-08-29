---
title: Raft 分布式一致性实现
description: Raft 一致性 + KV 存储 + 分布式锁/配置中心/任务调度业务
github: https://github.com/yjjj11/Raft_distributes
category: 分布式
tech: [分布式, C++, 网络编程]
order: 20
difficulty: 5
---

## 项目简介

基于 Raft 论文从零实现的分布式一致性（选主、日志复制）+ 其上的 KV 存储，并基于 KV 扩展出分布式锁、配置中心与任务调度系统。下面归纳踩过的坑、性能优化与业务应用。

## 遇到的问题与解决

**1. 日志阻塞心跳线程**
纯 raft 实现时日志应用逻辑放在心跳线程里（发送所有心跳并检测是否可提交后再应用）。加了一个睡眠两秒的业务任务后，集群开始胡乱选举——心跳线程被阻塞，其他节点选举超时变 candidate。解决：加入日志应用线程，通过条件变量在心跳线程与日志应用线程之间传递日志应用信息，异步处理。

**2. 读一致性问题**
业务操作都通过 raft 的 submit 提交再等日志应用，对客户端是异步的；提交后立刻查询该 key 会读到应用前的旧值。解决：为 submit 加 req_id（只有 leader 节点可以产生，保证集群内全局统一），本地保存对应 req_id 的 promise，实现「异步转同步」——读操作可加 barrier 日志等待应用后再本地读；要立刻读上次写的结果，就等上次写操作 req_id 的 future 阻塞结束再读状态机。

**3. 故障重启数据为空**
实现 kv 实例测试故障恢复时，节点恢复出现大量"操作未注册"报错、状态机里键值对为空。原因：raft 的选举线程和日志应用线程比 kv 回调注册更早初始化，节点间已开始应用日志但 kv 回调还没注册好。解决：
- 日志应用线程从 `last_applied` 恢复到最新复制 index（每次唤醒都从 last_applied 开始应用）；给应用加最大重试次数（重试多次仍未注册才是真正未注册的操作）；
- 加入快照机制，重启时从快照恢复，减少单条日志应用次数。

## 性能优化

**ReadIndex 机制**：客户端提交 barrier 后不进行日志复制，而是把 req_id 和当时 log_index 加入 raft 等待列表，等 `last_applied` 追上该 log_index 再返回。核心收益：无需复制日志，仅做水位锁定与本地追赶，在保证强一致的同时大幅优化读请求开销。

**快速回退**：prev 日志不匹配时，follower 端从 prevlogindex 开始一直递减滚动到上一任期的日志 index，避免逐个 -1 带来的大量 RPC 开销。

**快照恢复加速**：故障节点恢复时，有本地快照先加载本地快照；无快照则靠快速回退机制让 leader 的 nextindex 快速降到 -1，leader 检测到其 index 小于 lastsnapshotindex 就发送快照并应用，加快重启速度。用 nlohmann/json 把 KV 状态机 map、最大快照 index、term 打包序列化；日志超阈值后做快照复制（存储元数据、截断日志列表，定位数据时减去 lastSnapshotIndex）。

## 业务示例（基于 KV 能力）

- **KV 存储**：put / del / get / CAS / CAS_with_ttl，通过 pack_entry 打包命令参数、commandtype 确定命令函数回调。
- **分布式锁**：直接用 `cas_with_ttl` 实现 Get_lock / Release_lock，带重试机制且不会死锁。
- **配置中心**：为每个操作提供多个可注册的 watch 函数，可细化到对某一个键名 watch，触发后遍历执行所有 watch 回调（侵入式实现，无 watch 绑定则跳过）。
- **任务调度系统**：调度器（仅 Leader 运行，每 100ms 检查待执行任务，轮询分配到执行器）+ 执行器（每 500ms 轮询任务队列执行任务并更新状态）+ KV 承担任务元数据存储、状态流转跟踪、调度器与执行器的通信桥梁；分布式锁保证只有 Leader 获得调度锁防脑裂、节点取任务队列前先加锁。KV key 设计：
  - `task:{task_id}` 任务完整信息 JSON（id、执行时间、payload、状态）
  - `task_status:{task_id}` 状态流转 JSON（时间戳、错误信息）
  - `scheduler:tasks_list` 全局任务清单
  - `scheduler:leader_lock` 调度锁
  - `executor:{executor_id}` 每个执行器的任务队列

## 潜在问题（面试复盘）

submit 接口当前只要把请求日志写入 leader 本地日志队列就返回成功，默认业务数据已生效。但若 leader 还没来得及把日志同步给多数节点就宕机，按 Raft 该日志不应被视为已提交；旧主恢复后会变 follower 并截断冲突日志。也就是说业务层显示成功的操作实际可能未被执行，与共识层日志产生差异——集群内数据依然同步，但部分你认为存在的操作/数据可能不存在。后续优化方向：submit 应等日志提交（被多数节点同步）后再返回。
