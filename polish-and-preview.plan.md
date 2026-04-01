# 润色 + 实时预览 功能计划

日期：2026-04-01
范围：RealtimeAPIClient + SessionCoordinator + instructions 调整

## 1. 实时预览方案

### 问题
当前是 Manual 模式（turn_detection=null），必须松开 Fn 后 commit + response.create 才能收到文字。
录音过程中胶囊是空白的。

### 方案：改为 Server VAD 模式

切换到 `turn_detection: server_vad`，让服务端自动检测语音段落：

- **录音中**：服务端检测到语音停顿时，自动 commit 并返回 transcript delta
- **效果**：用户说话时，胶囊里会逐句出现文字
- **松开 Fn**：发送 commit + response.create 获取最终完整文本

但 server_vad 有个问题：它会在每个停顿后自动生成 response，
可能导致多段 response 拼接不完整。

### 更优方案：保持 Manual 模式 + 启用 input_audio_transcription

百炼 Realtime API 支持 `input_audio_transcription` 配置：
在 session.update 中设置后，服务端会在 commit 后返回
`conversation.item.input_audio_transcription.completed` 事件，
包含用户语音的原始转录（不经过模型改写）。

但这只在 commit 后才返回，不是真正的实时。

### 最终方案：Server VAD + 智能拼接

1. `turn_detection` 设为 `server_vad`（自动检测语音段落）
2. 不发送 `response.create`——让 VAD 自动触发
3. 每次收到 `response.audio_transcript.delta` 就实时更新胶囊
4. 松开 Fn 时：
   - 停止发送音频
   - 等待当前 response 完成（response.done）
   - 用最终的累计 transcript 做注入
5. Instructions 允许适度润色

## 2. 润色功能

调整 instructions：
- 保持转录为核心任务
- 允许修正口误、重复词、语气词（"嗯"、"那个"）
- 允许修正语法错误
- 仍然不允许改写语义或添加内容

## 3. 改动范围

- `RealtimeAPIClient.sendSessionUpdate()` — 改 turn_detection 和 instructions
- `SessionCoordinator.fnKeyDidPress/Release` — 适配 VAD 模式
- `SessionCoordinator` — 累计多个 response 的 transcript

## 4. 验收标准

- 按住 Fn 说话时，胶囊里逐句显示文字
- 松开后自动注入最终文字
- 口误和语气词被自动修正
- 核心语义不被改变
