---
title: 第一天：我用 Node.js 写了一个服务器
description: 用 Node.js 搭一个最简单的 HTTP 服务器，跑起来的那一刻特别有成就感。
pubDate: 2026-08-27
category: 编程笔记
tags: [Node.js, 后端, 学习]
---

今天终于迈出了第一步：用 Node.js 搭了一个最简单的 HTTP 服务器。代码不长，但跑起来的那一刻特别有成就感。

```js
const http = require('http');

http.createServer((req, res) => {
  res.end('Hello from Node.js!');
}).listen(3000);
```

运行 `node hello-server.js`，然后打开浏览器访问 `http://localhost:3000`，就能看到网页了。

总结：Node.js 让 JavaScript 能跑在服务器上，配合事件驱动和非阻塞 I/O，处理并发请求很高效。接下来想试试能不能给博客加个访问计数器！
