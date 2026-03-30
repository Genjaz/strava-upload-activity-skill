# Strava 上传 Skill

自动上传健身文件（FIT、GPX、TCX）到 Strava，包含 Token 管理与完善的错误处理。

**语言：**[English](README.md) | 简体中文

## 功能特性

- ✅ **自动管理 Token**：在过期前自动刷新
- ✅ **文件校验**：检查格式、大小与重复上传
- ✅ **错误处理**：重试逻辑 + 清晰的错误信息
- ✅ **日志记录**：完整记录所有操作，便于排障
- ✅ **使用简单**：发送文件即可，其他步骤自动完成

## 快速开始

### 1. 安装依赖

```bash
# macOS
brew install jq curl

# Ubuntu/Debian
sudo apt-get install jq curl
```

### 2. 安装/初始化 Skill

```bash
# 运行初始化脚本
./scripts/setup.sh

# 配置凭据
# 编辑 strava-config.json，填写：
# - client_id
# - client_secret
# - refresh_token（需包含 activity:write scope）
```

### 3. 测试配置

```bash
./scripts/strava-upload.sh test
```

### 4. 上传文件

```bash
# 上传 FIT 文件
./scripts/strava-upload.sh upload activity.fit

# 查询上传状态
./scripts/strava-upload.sh status UPLOAD_ID
```

## 目录结构

```
strava-upload-activity-skill/
├── SKILL.md                    # Skill 主文档
├── scripts/
│   ├── strava-token-manager.sh # Token 管理
│   ├── strava-upload.sh        # 文件上传
│   └── setup.sh               # 初始化脚本
├── references/
│   ├── api-docs.md            # API 参考
│   ├── file-formats.md        # 文件格式说明
│   └── troubleshooting.md     # 常见问题与解决方案
└── assets/
    └── config-template.json   # 配置模板
```

## 使用方式

### 作为 OpenClaw 的 Skill 使用

当该 skill 被加载后，OpenClaw 会自动：

1. 识别附件中的健身文件
2. 上传到 Strava
3. 返回活动链接

### 手动使用

```bash
# 检查 Token 状态
./scripts/strava-token-manager.sh check

# 刷新 Token
./scripts/strava-token-manager.sh refresh

# 上传文件
./scripts/strava-upload.sh upload morning_run.fit

# 批量上传
for file in *.fit; do
    ./scripts/strava-upload.sh upload "$file"
    sleep 2  # 避免触发频率限制
done
```

## 配置说明

### 必需凭据

1. **Strava 应用**：在 `https://www.strava.com/settings/api` 创建
2. **Client ID 与 Client Secret**：在应用设置里获取
3. **Refresh Token**：通过 Strava API Playground 获取，并确保 scope 包含 `activity:write`

### 配置文件示例

```json
{
  "client_id": "your_client_id",
  "client_secret": "your_client_secret",
  "refresh_token": "your_refresh_token",
  "access_token": "",
  "expires_at": 0,
  "last_refresh": null
}
```

## 支持的文件格式

| 格式 | 扩展名 | 最大大小 | 说明 |
|------|--------|----------|------|
| FIT  | `.fit` | 25MB     | 常见于 Garmin/Wahoo 等设备 |
| GPX  | `.gpx` | 25MB     | GPS Exchange Format |
| TCX  | `.tcx` | 25MB     | Garmin Training Center |

## 错误处理

该 skill 会处理：

- ✅ Token 过期（自动刷新）
- ✅ 网络错误（指数退避重试）
- ✅ 频率限制（等待后重试）
- ✅ 文件校验（大小、格式）
- ✅ 重复上传检测

## 监控与排障

### 日志

- `strava-upload.log`：包含时间戳的完整操作记录
- 快速查错：`grep -i error strava-upload.log`

### Token 状态

```bash
./scripts/strava-token-manager.sh check
# Status: Token valid
# Remaining time: 21546 seconds
```

### 健康检查

```bash
./scripts/strava-upload.sh test
# ✓ Token obtained successfully
# ✓ API connection successful
# Athlete: Your Name
```

### 常见问题

更多问题与解决方案见 `references/troubleshooting.md`，例如：

1. **授权错误**：重新授权并确保 scope 正确
2. **文件过大**：压缩或拆分
3. **重复活动**：文件已上传
4. **触发频率限制**：降低请求频率/增加间隔

## 安全建议

- 配置文件建议设置权限：`chmod 600 strava-config.json`
- 不要在日志里写入凭据
- 全程使用 HTTPS 请求

## License

该 skill 按“原样”提供用于 OpenClaw；同时受 Strava API 条款约束。

## GitHub 仓库

- 仓库：`https://github.com/Genjaz/strava-upload-activity-skill`
- Issues：`https://github.com/Genjaz/strava-upload-activity-skill/issues`

## 支持

- **文档**：见 `references/`
- **问题**：先看 `troubleshooting.md`，再到 GitHub Issues 提交
- **Strava API 文档**：`https://developers.strava.com/docs/`
