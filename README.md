# OpenClaw Dev Environment

OpenClaw Dev Environment 是一个基于 Debian Bookworm 的容器化开发环境，专门为 [OpenClaw](https://openclaw.ai) AI 助手构建。预装 Node.js 22+、Go、kubectl、helm 等开发工具，并支持 OpenClaw Skills 扩展。

## 快速开始

```bash
make build    # 构建镜像（使用本地 buildah）
```

## OpenClaw 使用说明

### 首次启动

```bash
# 1. 进入容器（需手动运行容器）
docker run -it --rm -p 18789:18789 zpk.idc.w7.com/w7panel/openclaw-dev:latest /bin/bash

# 2. 在容器内启动 Gateway
openclaw gateway --port 18789

# 3. 打开 Control UI
openclaw dashboard
# 或访问 http://127.0.0.1:18789
```

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

本项目使用本地 buildah 构建镜像：

```bash
# 构建并推送镜像
make build

# 查看帮助
make help
```

## 配置文件

### config.yaml（必需）

```yaml
registry: <你的镜像仓库>
registry_user: <用户名>
registry_pass: <密码>
image: <完整镜像地址>
```

### config/registries.conf

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
│   └── .openclaw/        # OpenClaw 配置和 Skills
│       └── skills/       # 预装的 Skills
└── scripts/
    └── entrypoint.sh     # 启动脚本
```

## 预装配置

预装内容通过 `preinstall/preinstall.json` 管理：

- **dockerfile**：补充 Dockerfile 命令（如 COPY --from）
- **environment**：基础环境工具（Go、Node.js、kubectl 等）
- **openclaw**：OpenClaw 生态项目（Skills）

### 添加自定义 Skills

将 skills 文件夹复制到 `preinstall/.openclaw/skills/`，构建时会自动打包：

```bash
# 示例：添加自定义 skill
cp -r /path/to/my-skill preinstall/.openclaw/skills/
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| PORT | 18789 | Gateway 端口 |
| APP | openclaw | 应用名称 |

## 持久化存储

`/home` 目录为工作目录，建议挂载 PVC 或宿主机目录进行持久化：

```bash
docker run -v /path/to/home:/home ...
```
