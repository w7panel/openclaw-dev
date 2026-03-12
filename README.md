# OpenClaw Dev Environment

OpenClaw Dev Environment 是一个基于 Debian Bookworm 的容器化开发环境，专门为 [OpenClaw](https://openclaw.ai) AI 助手构建。预装 Node.js 22+、Go、kubectl、helm 等开发工具，并支持 OpenClaw Skills 扩展。

## 快速开始

```bash
# 构建镜像
make build

# 运行测试容器
make run
```

## 预装内容

### 基础环境

| 工具 | 版本 | 说明 |
|------|------|------|
| Go | 1.24.0 | Go 编程语言 |
| Node.js | 22.14.0 | JavaScript 运行时 |
| kubectl | 1.31.0 | Kubernetes CLI |
| helm | 3.17.2 | Kubernetes 包管理器 |
| pnpm | latest | Node.js 包管理器 |

### OpenClaw 生态

| 工具 | 说明 |
|------|------|
| OpenClaw | AI 助手核心 |
| agent-browser | 浏览器自动化工具 |
| @wenyan-cli | 微信公众号 Markdown 工具 |

### OpenClaw Skills

预装 Skills 位于 `preinstall/.openclaw/skills/`：

| Skill | 说明 |
|-------|------|
| docker-build | 使用 Buildah 构建 Docker/OCI 镜像 |
| dockerfile-creator | 创建高效、安全的 Dockerfile |
| makefile-creator | 创建高效、可维护的 Makefile |
| skill-creator | 创建和验证 OpenClaw Skills |

### 运行时安装的 Skills

| Skill | 来源 |
|-------|------|
| wechat-publisher | GitHub (0731coderlee-sudo) |

## OpenClaw 使用说明

### 首次启动

```bash
# 运行容器（必须设置 OPENCLAW_GATEWAY_TOKEN）
docker run -e OPENCLAW_GATEWAY_TOKEN=your_token_here -p 18789:18789 zpk.idc.w7.com/w7panel/openclaw-dev:latest

# 或使用预置配置启动
/entrypoint.sh
```

> **注意**：必须设置 `OPENCLAW_GATEWAY_TOKEN` 环境变量，未设置时容器会报错退出。

### 常用命令

| 命令 | 说明 |
|------|------|
| `openclaw onboard` | 交互式配置向导 |
| `openclaw dashboard` | 打开 Web 控制界面 |
| `openclaw gateway` | 启动 Gateway |
| `openclaw gateway status` | 查看 Gateway 状态 |
| `openclaw channels login` | 登录消息通道 |
| `openclaw configure` | 重新配置 |
| `openclaw doctor` | 诊断问题 |

### 配置说明

- **配置文件**: `~/.openclaw/openclaw.json`
- **工作空间**: `~/.openclaw/workspace`
- **Skills 目录**: `~/.openclaw/skills` 或 `<workspace>/skills`
- **默认端口**: 18789

详细配置说明见 [OpenClaw 官方文档](https://docs.openclaw.ai/)

## 构建说明

```bash
# 构建并推送镜像
make build

# 运行测试容器
make run

# 查看帮助
make help
```

### 构建配置 (config.yaml)

```yaml
registry: <你的镜像仓库>
registry_user: <用户名>
registry_pass: <密码>
image: <完整镜像地址>
```

### 镜像源配置 (config/registries.conf)

Buildah 镜像源配置，支持国内镜像加速。

## 项目结构

```
openclaw-dev/
├── .gitignore            # Git 忽略配置
├── Makefile             # 统一工具脚本
├── AGENTS.md            # 开发规范
├── README.md            # 项目说明
├── config/              # 配置文件
│   ├── Dockerfile.template  # Docker 镜像模板
│   └── registries.conf      # Buildah 镜像源配置
├── preinstall/
│   ├── preinstall.json   # 预装清单
│   └── .openclaw/       # OpenClaw 配置和 Skills
│       └── skills/       # 预装的 Skills
└── scripts/
    └── entrypoint.sh     # 启动脚本
```

## 添加自定义 Skills

### 方式一：修改 preinstall.json

在 `preinstall/openclaw` 数组中添加：

```json
{
  "name": "my-skill",
  "url": "N/A",
  "install": "git clone https://github.com/xxx/my-skill.git ~/.openclaw/skills/my-skill"
}
```

### 方式二：添加 skills 目录

将 skills 文件夹复制到 `preinstall/.openclaw/skills/`，构建时会自动打包：

```bash
cp -r /path/to/my-skill preinstall/.openclaw/skills/
```

## 启动脚本

`scripts/entrypoint.sh` 会自动：

1. 复制预装文件到 `/home/`
2. 创建必要目录 (`/home/go`, `~/.openclaw`)
3. 检查 `OPENCLAW_GATEWAY_TOKEN` 环境变量（未设置则报错）
4. 配置 Gateway（LAN 模式 + token 认证 + Control UI 安全选项）
5. 启动 OpenClaw Gateway

## 环境变量

| 变量 | 必填 | 说明 |
|------|------|------|
| OPENCLAW_GATEWAY_TOKEN | 是 | Gateway 认证 Token |
| PORT | 否 | Gateway 端口 (默认 18789) |
| APP | 否 | 应用名称 (默认 openclaw) |

## 持久化存储

`/home` 目录为工作目录，建议挂载宿主机目录进行持久化：

```bash
docker run \
  -e OPENCLAW_GATEWAY_TOKEN=your_token_here \
  -v /path/to/home:/home \
  -p 18789:18789 \
  zpk.idc.w7.com/w7panel/openclaw-dev:latest
```
