---
name: prd-security-audit
description: |
  PRD 开发计划安全审查技能。
  针对任意类型项目（移动端/后台/Web/桌面），通过以下三步工作流完成审查：
    1. 在 GitHub/开源社区搜索同类权威参考项目
    2. 对比当前 PRD/实现计划，识别安全漏洞、架构缺陷、代码错误
    3. 输出结构化审查报告 + 内联修复建议，并可选直接修改计划文件

  触发词（中英文）：
  - 安全审查, 安全检查, 漏洞扫描, 方案审查, 可行性验证
  - security audit, prd review, plan review, vulnerability check
  - 检查计划, 审查开发计划, 验证可实施性
  - /prd-security-audit, /security-audit, /plan-review

  适用项目类型（通用，不局限于特定技术栈）：
  - iOS / watchOS / Android / Flutter 移动端
  - React / Vue / Next.js Web 前端
  - Node.js / Django / Spring Boot 后台服务
  - 后台管理系统 / SaaS / 小程序

  不用于：纯 UI 审美评审（用 phase-3-mockup）、性能 Benchmark（用专项工具）
version: 1.0.0
---

# PRD 安全审查流程规范（Claude 执行约束）

> 本 Skill 激活后，Claude 必须严格按照以下三步工作流执行，
> 每步完成后输出阶段结果，最终生成结构化报告。

---

## 一、工作流总览

```
Step 1: 技术栈识别 + GitHub 参考项目搜索
         ↓
Step 2: PRD / 实现计划深度分析
         ↓
Step 3: 交叉比对 → 输出审查报告 + 修复建议
         ↓
Step 4（可选）: 直接修改计划文件并记录审查日志
```

---

## 二、Step 1 — 技术栈识别 + 开源参考搜索

### 2.1 首先读取以下文件（按优先级）

```
1. docs/implementation-plan.md  或  docs/PRD.md  或  PLAN.md
2. memory/MEMORY.md（项目记忆）
3. README.md
4. pubspec.yaml / package.json / Gemfile / pom.xml / go.mod（依赖文件）
```

### 2.2 技术栈提取

从上述文件中提取：

| 维度 | 提取目标 |
|------|---------|
| 平台 | iOS / Android / Web / watchOS / 小程序 / 桌面 |
| 语言 | Swift / Dart / TypeScript / Python / Java / Go / Rust |
| 框架 | SwiftUI / Flutter / React / Next.js / Django / Spring Boot |
| 数据层 | SQLite / SwiftData / Hive / PostgreSQL / MongoDB / Redis |
| 认证 | HealthKit / Firebase Auth / OAuth / JWT / Session |
| 部署 | App Store / Play Store / Vercel / AWS / Docker |

### 2.3 并行搜索策略（必须同时发起 3 组搜索）

**搜索组 A — 同类权威开源项目**
```
查询模板："{框架} {平台} open source sample app GitHub {当前年份}"
示例：
  - "Flutter HealthKit open source iOS GitHub 2025"
  - "Next.js admin dashboard open source GitHub 2025"
  - "Django REST API security best practices GitHub 2025"
```

**搜索组 B — 已知漏洞与陷阱**
```
查询模板："{技术栈} known issues security vulnerability {当前年份}"
示例：
  - "Flutter SharedPreferences security vulnerability 2025"
  - "Next.js API route authentication bypass 2025"
  - "SwiftData watchOS known bugs migration 2025"
```

**搜索组 C — 跨进程/跨域数据共享安全**
```
查询模板："{数据共享机制} security best practices {平台}"
示例：
  - "App Group UserDefaults security watchOS Widget"
  - "Flutter Keychain vs SharedPreferences security"
  - "Next.js session cookie HttpOnly security"
  - "Django CSRF protection REST API"
```

### 2.4 参考项目评估标准

从搜索结果中优先选取满足以下条件的项目：

| 条件 | 权重 |
|------|------|
| GitHub Stars > 100 或官方 Sample 代码 | 高 |
| 最近 12 个月有更新 | 高 |
| 使用相同技术栈（框架版本接近）| 高 |
| 有清晰的架构文档或 README | 中 |
| 有 CI/CD 和测试覆盖 | 中 |

---

## 三、Step 2 — PRD / 实现计划深度分析

### 3.1 必须检查的七大维度

#### 维度 A：数据存储安全
```
检查点：
□ 敏感数据（密钥/Token/密码）是否存入了不安全的存储（如明文 SharedPreferences/UserDefaults/localStorage）
□ 跨进程共享数据（Widget Extension / Keychain Group / App Group）是否正确配置
□ 本地数据库是否有唯一性约束、外键约束
□ 数据是否在写入前做了类型校验和范围校验
□ 缓存数据与持久化数据是否保持一致性（双写策略是否有 source of truth）

适配示例：
  - iOS/watchOS：UserDefaults.standard → 需改为 App Group suiteName
  - Flutter：SharedPreferences 存 JWT → 需改为 flutter_secure_storage
  - Web后台：localStorage 存 Session Token → 需改为 HttpOnly Cookie
  - Node.js：.env 文件提交 Git → 需加 .gitignore + Vault
```

#### 维度 B：认证与授权
```
检查点：
□ API 端点是否有完整的认证中间件（每个路由都受保护，非公开路由无遗漏）
□ 权限是否按最小化原则申请（HealthKit 只申请用到的类型）
□ Token 刷新逻辑是否处理过期和无效情况
□ 管理后台是否有 RBAC（基于角色的访问控制）
□ 文件上传接口是否有文件类型白名单和大小限制

适配示例：
  - iOS HealthKit：是否处理了部分授权（用户拒绝部分数据类型）的降级逻辑
  - Django REST：是否对所有 ViewSet 明确设置 permission_classes
  - Next.js：middleware.ts 是否覆盖了所有 /api/admin/* 路由
  - Flutter：是否在 Dio 拦截器中统一处理 401 → refresh token → retry
```

#### 维度 C：输入验证与注入防护
```
检查点：
□ 所有用户输入是否在边界处（API 入口、UI 表单）做了校验
□ SQL 查询是否使用参数化查询，禁止字符串拼接
□ 模板渲染是否有 XSS 防护（转义/CSP）
□ 文件路径操作是否防止路径穿越（Path Traversal）
□ 反序列化操作是否对来源做了验证

适配示例：
  - Django：是否使用 ORM 而非原始 SQL；Form 是否有 clean() 方法
  - React/Next.js：dangerouslySetInnerHTML 使用场景是否必要
  - Flutter：从 API 返回的 JSON 是否用 fromJson 解析而非 dynamic
  - Swift：从 UserDefaults 读取的值是否做了类型断言和范围校验
```

#### 维度 D：后台任务与资源预算
```
检查点：
□ 后台任务是否在完成时调用了结束回调（避免系统终止 App）
□ 定时刷新频率是否超出平台限制（watchOS: 4次/小时；iOS Background Fetch: 系统调度）
□ 网络请求是否有超时设置和重试上限
□ 内存泄漏风险点：循环引用、未释放的 Observer/Listener
□ 电池影响：高频传感器轮询是否只在前台启用

适配示例：
  - watchOS：Background Refresh + Complication 共享预算，合计不超过 4次/小时
  - Flutter：Isolate 或 compute() 使用后是否正确关闭
  - Node.js：setInterval 是否在服务关闭时 clearInterval
  - Django Celery：任务是否设置了 max_retries 和 time_limit
```

#### 维度 E：错误处理与降级策略
```
检查点：
□ 所有 async/await 调用是否有 try-catch 并向上传递或记录错误
□ 第三方服务（API/数据库/消息队列）失败时是否有降级方案
□ 权限被拒绝时是否有降级模式（不崩溃，提供基本功能）
□ 空状态/加载失败/网络超时是否有 UI 反馈
□ 错误日志是否包含敏感信息（Token/密码不应出现在日志中）

适配示例：
  - iOS HealthKit 全拒绝 → 纯签到养成模式
  - Flutter API 超时 → 展示缓存数据 + 提示刷新
  - Next.js 数据库连接失败 → 返回 503 而非 500 堆栈信息
  - Django 第三方支付失败 → 订单状态标记 pending，人工处理队列
```

#### 维度 F：数据唯一性与幂等性
```
检查点：
□ 数据库表是否有必要的唯一索引（防止重复记录）
□ 关键业务操作（支付/签到/奖励发放）是否有幂等性保护
□ 并发写入场景是否有锁机制或乐观锁
□ 前端重复提交（按钮双击）是否有防抖/禁用处理

适配示例：
  - SwiftData @Attribute(.unique) var dateKey 防止每日记录重复
  - Django Model unique_together / UniqueConstraint
  - PostgreSQL CREATE UNIQUE INDEX
  - React 表单提交按钮 disabled 状态管理
```

#### 维度 G：代码质量与编译安全
```
检查点：
□ 变量名/函数名是否有 typo（空格、拼写错误）导致编译失败
□ 枚举/switch 是否有 exhaustive 处理（Swift 的 @unknown default）
□ 强制解包（Swift 的 !、Dart 的 !）是否在无法避免的情况下使用
□ 类型断言是否有失败处理
□ 废弃 API 是否有替代方案（deprecated 警告）

适配示例：
  - Swift：var lotusCalm Minutes → lotusCalmMinutes（空格导致编译错误）
  - Dart：widget.data! → widget.data ?? defaultValue
  - TypeScript：any 类型滥用 → 明确类型定义
  - Python：except Exception: pass → 具体异常类型 + 日志记录
```

---

## 四、Step 3 — 输出审查报告格式

### 4.1 报告结构（必须包含以下所有部分）

```markdown
## PRD 安全审查报告

### 审查元信息
- 审查日期：{日期}
- 项目类型：{技术栈}
- 审查依据：{参考的开源项目列表}
- 审查范围：{读取的计划文件路径}

---

### GitHub 参考项目
| 项目 | Stars | 描述 | 参考价值 | 链接 |
|-----|-------|------|---------|------|

---

### 发现问题汇总
| # | 严重程度 | 维度 | 问题描述 | 影响 | 状态 |
|---|---------|------|---------|------|------|

---

### 各问题详细说明

#### 🔴 严重问题（必须在开发启动前修复）
#### 🟡 中等问题（应在对应 Phase 开发前修复）
#### 🟢 建议优化（可在 MVP 后迭代处理）

---

### 安全总结
- 整体风险等级：低 / 中 / 高
- 必须修复项：N 项
- 建议优化项：N 项
- 可直接开发：是 / 否（修复上述 🔴 项后方可）
```

### 4.2 严重程度定义

| 等级 | 标志 | 触发条件 | 处理优先级 |
|------|------|---------|-----------|
| 严重 | 🔴 | 会导致功能完全失效（如 Widget 读不到数据）或数据泄露 | 开发前必须修复 |
| 中等 | 🟡 | 会导致数据丢失/重复、性能问题、编译失败 | 对应 Phase 前修复 |
| 建议 | 🟢 | 安全加固建议，不影响核心功能 | MVP 后迭代 |

---

## 五、Step 4（可选）— 直接修改计划文件

### 5.1 触发条件

用户说"帮我修改计划"/"直接修复"/"更新文件"时执行。

### 5.2 修改规范

1. **优先使用 Edit 工具**（局部修改，保留原有内容结构）
2. 每处修改前加注释标记：`// [安全修复] 原因说明` 或 markdown 加粗 `**[安全修复]**`
3. 在计划文件末尾追加"安全审查记录"表格

### 5.3 审查记录表格模板

```markdown
## 安全审查记录（prd-security-audit）

> 由 `prd-security-audit` Skill 于 {日期} 执行

| # | 严重程度 | 问题描述 | 修复位置 | 状态 |
|---|---------|---------|---------|------|
| 1 | 🔴 严重 | {描述} | {文件:行号} | ✅ 已修复 |
| 2 | 🟡 中等 | {描述} | {文件:行号} | ✅ 已修复 |
| 3 | 🟢 建议 | {描述} | {文件:行号} | 📌 待优化 |

**参考项目：**
- [{项目名}]({GitHub URL}) — {参考价值}
```

---

## 六、各技术栈专项检查清单

### 6.1 iOS / watchOS（Swift + SwiftUI）

```
□ App Group 是否为 Widget Extension 和主 App 共同配置
□ UserDefaults.standard → 必须改为 UserDefaults(suiteName:)（跨 Extension）
□ HealthKit 授权是否处理部分拒绝的降级
□ SwiftData @Model 是否对唯一键加 @Attribute(.unique)
□ 后台任务是否调用 setTaskCompleted()
□ Digital Crown 交互是否搭配 .focusable()
□ WCSession 是否检查 isReachable 再发送消息
□ Keychain 是否用于存储敏感凭据（而非 UserDefaults）
```

### 6.2 Flutter / Dart

```
□ flutter_secure_storage 替代 shared_preferences 存储 Token/密钥
□ Dio 拦截器是否统一处理 401 Token 刷新
□ API 返回值是否用强类型 fromJson 解析（避免 dynamic 类型）
□ Platform Channel 调用是否处理 PlatformException
□ dispose() 中是否释放所有 StreamSubscription / AnimationController
□ Navigator 路由是否做了认证守卫（未登录重定向到登录页）
□ BuildContext 跨 async 使用是否检查 mounted
□ 图片/文件上传是否有大小和类型限制
```

### 6.3 Next.js / React（TypeScript）

```
□ API Routes 是否用 middleware.ts 统一鉴权
□ 环境变量是否区分 NEXT_PUBLIC_ 和服务端变量（避免密钥暴露到客户端）
□ Cookie 是否设置 HttpOnly + Secure + SameSite=Strict
□ dangerouslySetInnerHTML 使用场景是否必要，是否做了 sanitize
□ fetch/axios 是否设置超时和 AbortController
□ 数据库查询是否使用 ORM（Prisma/Drizzle）防止 SQL 注入
□ CORS 配置是否明确白名单（不使用 * 通配符）
□ Rate Limiting 是否在 API Routes 层实现
□ 图片域名是否在 next.config.js 的 images.domains 中明确列出
```

### 6.4 Django / Python 后台

```
□ DEBUG=False 在生产环境
□ ALLOWED_HOSTS 是否明确配置（不使用 ['*']）
□ SECRET_KEY 是否通过环境变量注入（不硬编码）
□ CSRF_COOKIE_SECURE + SESSION_COOKIE_SECURE = True（生产环境）
□ 所有 ViewSet 是否明确设置 permission_classes
□ 文件上传是否有 MIME 类型白名单和大小限制（FILE_UPLOAD_MAX_MEMORY_SIZE）
□ 数据库是否使用 ORM 参数化查询（禁止 raw() + 字符串拼接）
□ Celery 任务是否设置 max_retries + time_limit + acks_late
□ 日志配置是否过滤掉密码/Token 字段
```

### 6.5 Node.js / Express / NestJS 后台

```
□ 依赖是否定期更新（npm audit 无高危漏洞）
□ helmet() 中间件是否启用
□ express-rate-limit 是否配置
□ bcrypt/argon2 哈希密码（禁止 md5/sha1）
□ JWT secret 是否足够长（≥256 位），是否通过环境变量注入
□ 数据库连接字符串是否通过环境变量注入（不硬编码）
□ 错误响应是否屏蔽堆栈信息（生产环境）
□ 文件上传是否限制 MIME 类型和大小（multer 配置）
```

### 6.6 后台管理系统（通用）

```
□ 所有管理接口是否有多因素认证（MFA）或 IP 白名单
□ 批量操作（删除/导出）是否有二次确认和操作日志
□ 数据导出接口是否有权限控制（避免任意用户导出全量数据）
□ 软删除（soft delete）而非硬删除，保留审计轨迹
□ 操作日志是否记录操作人、操作时间、操作内容、IP 地址
□ 敏感数据（手机号/身份证）是否在列表页做了脱敏展示
□ 超级管理员账户是否有独立的审计机制
```

---

## 七、执行约束（Claude 必须遵守）

1. **必须先读文件**，再执行搜索，禁止在未读计划文件的情况下输出报告
2. **必须同时发起 ≥3 组并行搜索**（技术栈参考 + 已知漏洞 + 数据共享安全）
3. **搜索结果必须附带可点击链接**，不得捏造 URL
4. **报告必须按严重程度排序**（🔴 → 🟡 → 🟢）
5. **修改计划文件前必须先确认**，除非用户明确说"直接修复"
6. **发现 🔴 严重问题时，必须在报告顶部用醒目方式标注**，不得埋藏在列表中
7. **未发现问题时**，明确输出"未发现明显安全漏洞，可继续开发"，给出置信度（高/中/低）和搜索覆盖范围
8. **每次审查结束后**，询问用户是否需要将结果写入 `memory/MEMORY.md` 持久化记忆

---

## 八、快速调用示例

```
用户：/prd-security-audit
→ Claude 自动读取项目计划文件，识别技术栈，搜索参考项目，输出完整报告

用户：帮我审查一下当前的开发计划有没有安全漏洞
→ 同上

用户：/prd-security-audit 只检查数据存储安全
→ Claude 聚焦维度 A，跳过其他维度，快速输出针对性报告

用户：审查完之后帮我把问题都修复到计划文件里
→ Claude 执行 Step 4，直接修改文件并追加审查记录表格
```
