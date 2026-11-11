# PetLife iOS App

SwiftUI 宠物成长记录原型，最低 iOS 17。已连接 Supabase 项目 `petner`，使用真实账号认证、Postgres 数据库和私有文件存储。

## 运行

在 Xcode 打开 `PetLife.xcodeproj`，选择 `PetLife` scheme 和 iPhone 模拟器运行。

2026-11-11 已通过 Xcode 27.2 的 Debug 模拟器构建。Supabase 项目此前暂停，现已恢复。

首次使用：在账号页切换到「注册」，填写邮箱、密码（至少 8 位）、昵称和城市。若项目启用邮箱确认，先确认邮件，再切换到「登录」。邮箱确认完成后可直接回 App 用邮箱和密码登录，无需依赖网页跳转回 App。

登录后创建自己的宠物档案和相册。云端账号不自动填充演示记录。退出只清除登录状态，重新登录同一账号可以恢复云端数据。

## 后端配置

Debug 和 Release 的 Build Settings 已设置：

- `INFOPLIST_KEY_SUPABASE_URL`：项目根地址 `https://rgcndvamvnondxjzmxdl.supabase.co`
- `INFOPLIST_KEY_SUPABASE_ANON_KEY`：客户端公开 publishable key
- `INFOPLIST_KEY_SUPABASE_MEDIA_BUCKET`：`petner`
- `INFOPLIST_KEY_SUPABASE_MEDIA_PUBLIC`：`NO`

同名的 `SUPABASE_*` 环境变量优先于 Info.plist。不要把服务端 secret/service-role key 放入 App。

公开 Key 通过 `apikey` 发送；认证后的请求用用户 access token 作为 Bearer。登录令牌保存在设备 Keychain，过期时使用 refresh token 刷新。旧版 UserDefaults 的 UUID 只作为本地标识，不作为云端认证凭据。

只有缺少 Supabase 配置、SwiftUI Preview 或显式设置 `PETLIFE_BACKEND=memory` 时使用模拟数据。配置了云端后的操作失败会显示错误并保留上次读取的状态，不会偷偷切换到内存数据库。

## 数据库和权限

`supabase/schema.sql` 是已应用到云端的结构与策略；云端迁移名为 `create_petlife_authenticated_backend`。不要运行旧版匿名开放权限脚本。

8 张业务表：

- `user_accounts`：账号资料，ID 对应 `auth.users.id`
- `owned_pets`：宠物档案
- `holiday_memories`：相册记录和图片/音频路径
- `upload_videos`：视频发布记录
- `feed_posts`：动态
- `post_comments`：评论
- `chat_threads`、`chat_messages`：会话和消息记录

所有业务表启用 RLS，只允许已认证用户访问自身 ID 对应的记录。未登录角色没有业务表权限。

私有桶 `petner` 保持私有，文件路径为 `users/<auth-user-id>/memories/<memory-id>/...`。上传、读取、覆盖和删除均按用户目录隔离。媒体缓存文件名保留用户和相册标识，避免不同记录的 `photo.jpg` 相互覆盖。

## 功能边界

发现页展示主动公开的真实宠物档案；聊天已支持跨用户双人会话与 Supabase Realtime。动态仍按当前账号隔离。视频页保存发布记录，尚未实现完整的视频文件上传与处理；动态附件尚未接入云端存储。相册图片和音频使用私有 Storage。

## 后端验证

`tools/backend_smoke.swift` 调用 App 实际数据层。仅使用专用测试账号运行，会创建测试宠物和相册记录。

```bash
xcrun swiftc -parse-as-library PetLife/Shared/Models.swift PetLife/Shared/AppState.swift tools/backend_smoke.swift -o /tmp/petlife-backend-smoke
```

运行前通过环境变量提供 `SUPABASE_URL`、`SUPABASE_ANON_KEY`、`SUPABASE_MEDIA_BUCKET=petner`、`SUPABASE_MEDIA_PUBLIC=NO`，以及专用测试账号的 `PETLIFE_TEST_EMAIL`、`PETLIFE_TEST_PASSWORD`。测试工具不会打印密码或令牌。

```bash
/tmp/petlife-backend-smoke write
/tmp/petlife-backend-smoke read
/tmp/petlife-backend-smoke signout
```

`write` 验证真实账号登录、档案和相册写入、私有图片上传；`read` 在新的进程中恢复 Keychain 登录状态并读取云端记录与图片；`signout` 验证清除本地会话。另通过数据库端检查 RLS 账号隔离及退出后数据保留。


## 中英文切换与实时聊天（2026-11-12）

首页右上角的地球图标和 English / 中文按钮可立即切换所有应用界面。选择保存在设备中；切换不会重建导航或清除表单。用户填写的昵称、动态、相册和消息保留原文。翻译目录位于 `PetLife/Shared/Localization.swift`，系统相册等系统界面仍遵循 iOS 自身的语言设置。

在“我的”打开某份档案的“公开档案并接受交友消息”，其他已登录账号即可在交友页下拉刷新后找到它并发起聊天。新档案默认私密；可随时关闭公开展示。既有会话不受隐藏档案影响。旧版仅属于一个账号的历史会话保留，发送时会提示重新从真实公开档案发起双人会话。

聊天支持双方前台实时收发、已读/未读、发送中状态、失败保留文字并重试、幂等消息 ID、自动滚动、连接断开后退避重连、令牌刷新和心跳；前台每 15 秒补同步。消息历史分页读取，UI 使用惰性列表。App 退到后台会取消订阅，返回前台重新连接与补拉；尚未配置 APNs 离线推送。

数据库增量配置在 `supabase/chat_realtime.sql`，已经应用到当前项目。该脚本是一次性升级，不能在已升级数据库重复执行。两方成员权限由 RLS 约束，客户端不能变更会话成员或伪造发送者。`chat_reads` 保存每个参与者的已读时间，`chat_threads`、`chat_messages`、`chat_reads` 已加入 Realtime publication。

服务资料仍为展示数据，没有真实服务商接收账号，所以已移除本地模拟聊天与假未读数，改为明确提示未接入在线聊天。服务商账号与服务发布后端接入是独立后续工作。

验证：`tools/localization_smoke.swift` 检查切换、插值与原文保留；`tools/chat_smoke.swift` 使用专门测试账号验证双向 WebSocket 消息、未读、已读、重复重试、失败返回、心跳后消息与关闭档案公开。测试账号通过临时 JSON 传入，严禁使用真实用户账号运行写入测试。数据库侧另验证无关账号读取/发送被拒绝，冒充发送者和修改成员被拒绝。测试数据验证后清理。

Supabase 安全检查另提示泄露密码检测未开启（非聊天权限问题）：https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection
