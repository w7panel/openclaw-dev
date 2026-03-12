# OpenClaw Dev Environment

开发环境容器镜像，支持 Go、Node.js、kubectl、helm、openclaw、agent-browser。

## 交流规则

- 始终使用中文回复

## 项目变动规则

当项目发生变动时（新增预装内容、修改构建流程、调整目录结构等），**必须同步更新相关文档**：
- README.md（项目结构、使用说明）
- AGENTS.md（开发规范）
- Makefile help 目标（配置说明）

具体要求：
1. 调整目录结构 → 更新 README.md 项目结构
2. 新增配置文件 → 更新 Makefile 变量定义和 help 说明
3. 修改构建流程 → 更新 AGENTS.md 相关规范

## 修改审批规则

以下文件的修改**必须经过用户同意后才能执行**：
- Dockerfile.template（Dockerfile 模板，现移至 config/ 目录）
- Makefile（构建脚本）
- config.yaml（配置文件）
- config/ 目录下所有配置文件

未经同意，不得擅自修改上述文件。

## 预装内容

预装内容分为两部分：

### 构建时代理配置

代理配置从 `gitconfig.yaml` 读取，用于构建时访问 GitHub：
- 有配置 `proxy` 字段时：构建时使用代理
- 无配置时：构建不使用代理

代理配置**不会**写入镜像，仅在构建时临时使用。

### 1. 构建时安装（preinstall.json）

定义在 `preinstall/preinstall.json`，构建时执行安装命令。

### 2. 本地已有文件（preinstall/ 目录）

`preinstall/` 目录下的所有文件，构建时添加到镜像的 `/opt/preinstall/`，容器启动时复制到 `/home/`。

### preinstall.json 结构

```json
{
  "dockerfile": [...],
  "environment": [...],
  "openclaw": [...]
}
```

### dockerfile 字段

用于补充 Dockerfile 命令（如从镜像提取文件）。**可以直接使用 Dockerfile 原生指令**。

| 字段 | 说明 | 必填 |
|------|------|------|
| name | 项目名称 | 是 |
| commands | Dockerfile 命令列表（如 RUN、COPY 等） | 是 |

**使用场景**：
- 从已有镜像中提取文件
- 需要使用多阶段构建
- 其他需要直接操作 Dockerfile 的场景

**示例**：
```json
{
  "name": "extract-files",
  "commands": [
    "FROM debian:bookworm-slim AS extractor",
    "COPY --from=target /app /opt/app"
  ]
}
```

### environment 字段

用于安装可执行工具（如 kubectl、helm、node 等）。**不支持 Dockerfile 原生指令，只能填写安装命令**，脚本会自动拼接 RUN 指令。

| 字段 | 说明 | 必填 |
|------|------|------|
| name | 工具名称 | 是 |
| version | 版本号 | 是 |
| url | 下载地址 | 是 |
| install | 安装命令（使用 `$URL` 变量） | 是 |

**安装方式**：

1. **下载解压**（推荐）：使用 wget/curl 下载官方预编译包，解压到 `/opt/tools/bin/`
2. **包管理器**：使用 npm/bunx/yarn/apt-get 等安装

**使用场景**：
- 安装有官方预编译二进制包的命令行工具：kubectl、helm、gh、node、golang 等
- 使用包管理器安装：npm install、apt-get install 等

**规范**：
1. **禁止使用 RUN**：install 字段只能填写安装命令，禁止使用 RUN、COPY 等 Dockerfile 指令
2. **脚本自动拼接**：Makefile 生成 Dockerfile 时会自动拼接 `RUN` 前缀
3. **下载解压方式**：必须使用 `$URL` 变量表示 url 字段的值
4. **包管理器方式**：npm/bunx/yarn/apt-get 等直接安装，无需 $URL
5. **软链接使用相对路径**：创建软链接时使用相对路径，禁止使用绝对路径

**示例 - 下载解压**：
```json
{
  "name": "kubectl",
  "version": "1.31.0",
  "url": "https://dl.k8s.io/release/v1.31.0/bin/linux/amd64/kubectl",
  "install": "wget -q $URL -O /opt/tools/bin/kubectl && chmod +x /opt/tools/bin/kubectl"
}
```

**示例 - NPM 包管理器**：
```json
{
  "name": "openclaw",
  "version": "latest",
  "url": "https://openclaw.ai/install.sh",
  "install": "curl -fsSL $URL | bash"
}
```

### openclaw 字段

用于安装 OpenClaw 技能和扩展。**不支持 Dockerfile 原生指令，只能填写安装命令**，脚本会自动拼接 RUN 指令。

| 字段 | 说明 | 必填 |
|------|------|------|
| name | 项目名称 | 是 |
| url | Git 仓库地址 | 是 |
| install | 安装命令（使用 `$URL` 变量） | 是 |

**使用场景**：
- 安装 OpenClaw Skills
- 克隆 Git 仓库到预装目录

**规范**：
1. **禁止使用 RUN**：install 字段只能填写安装命令，禁止使用 RUN、COPY 等 Dockerfile 指令
2. **脚本自动拼接**：Makefile 生成 Dockerfile 时会自动拼接 `RUN` 前缀
3. **必须使用 `$URL` 变量**：install 命令中必须使用 `$URL` 表示 url 字段的值

**示例 - 克隆 skill 到预装目录**：
```json
{
  "name": "wechat-publisher",
  "url": "N/A",
  "install": "mkdir -p ~/.openclaw/skills && git clone --depth 1 https://github.com/0731coderlee-sudo/wechat-publisher.git ~/.openclaw/skills/wechat-publisher || true"
}
```

### 处理规则

编写 Dockerfile 前，必须处理 preinstall.json：

1. **URL 验证与替换**
   - 检测 url 是否可访问（`curl -sI $URL | head -1` 返回 200）
   - 不可访问时，寻找可替代的国内源
   - 验证国内源可用后，直接更新 url 字段

2. **install 命令检测**
   - 构建脚本会检查 environment 和 openclaw 类型的 install 字段是否存在
   - 如果缺少 install 字段，脚本会报错并提示根据规范补充
   - install 命令中使用 `$URL` 变量表示 url 字段的值

3. **install 命令写入**
   - 所有 install 命令统一写入 Dockerfile

4. **软链接处理**
   - 软链接在 install 命令中创建（使用相对路径，禁止使用绝对路径）

5. **本地文件处理**
   - `preinstall/` 目录整个 COPY 到镜像的 `/opt/preinstall/`
   - 容器启动时由 entrypoint.sh 复制到 `/home/`

6. **OpenClaw Skills 处理**
   - OpenClaw Skills 位于 `~/.openclaw/skills` 或 `<workspace>/skills`
   - Skills 格式：AgentSkills 兼容，包含 `SKILL.md` + YAML frontmatter
   - 详细说明见 [OpenClaw Skills 文档](https://docs.openclaw.ai/skills)

## OpenClaw Skills 说明

OpenClaw 使用 AgentSkills 兼容的 skill 文件夹来扩展 agent 能力。

### Skills 位置（优先级从高到低）

1. `<workspace>/skills` - 工作空间级
2. `~/.openclaw/skills` - 本地管理
3. 内置 skills - 随安装包分发

### SKILL.md 格式

```markdown
---
name: skill-name
description: 技能描述
metadata:
  {
    "openclaw": {
      "requires": { "bins": ["command"], "env": ["API_KEY"] },
      "emoji": "🔧"
    }
  }
---

# 技能使用说明

这个技能可以...
```

### 安装 Skills

```bash
# 手动安装
git clone <skill-repo> ~/.openclaw/skills/<skill-name>
```

详细文档：[OpenClaw Skills](https://docs.openclaw.ai/skills)

## 中国镜像源

由于 Docker Hub 和 GCR 在国内无法访问，构建时必须使用镜像源：

| 仓库 | 镜像地址 |
|------|----------|
| docker.io | https://registry.cdn.w7.cc |
| gcr.io | https://gcr.m.daocloud.io |
| ghcr.io | https://ghcr.m.daocloud.io |
| k8s.gcr.io | https://k8s-gcr.m.daocloud.io |
| registry.k8s.io | https://k8s.m.daocloud.io |
| quay.io | https://quay.nju.edu.cn |
| mcr.microsoft.com | https://mcr.m.daocloud.io |
| nvcr.io | https://nvcr.m.daocloud.io |

详细用法见 `docker-build` skill。

## GitHub 加速代理

由于 GitHub 在国内访问较慢，可以使用代理服务加速。以下是验证可用的代理服务：

### 推荐代理（按优先级）

| 优先级 | 代理地址 | 状态 |
|--------|----------|------|
| 1 | https://ghproxy.net/ | ⚠️ K8s 环境不稳定 |
| 2 | https://gh-proxy.com/ | ✅ 可用 |
| 3 | https://v6.gh-proxy.org/ | ✅ 可用 |
| 4 | https://gh.ddlc.top/ | ✅ 可用 |
| 5 | https://bgithub.xyz | ✅ 可用 |
| 6 | https://gitclone.com | ✅ 可用 |
| 7 | https://github.ur1.fun | ✅ 可用 |
| 8 | https://fastgit.cc | ✅ 可用 |
| 9 | https://gh.xxooo.cf/ | ✅ 可用 |
| 10 | https://github.xxlab.tech/ | ✅ 可用 |

### 使用方法

将 GitHub 原始 URL 作为参数传递给代理：

```bash
# 格式
https://<代理地址>/https://github.com/<用户名>/<仓库>

# 示例
https://ghproxy.net/https://github.com/obra/superpowers
https://gh-proxy.com/https://github.com/cli/cli/releases/download/v2.63.2/gh_2.63.2_linux_amd64.tar.gz
```

### 在 preinstall.json 中的使用

```json
{
  "name": "superpowers",
  "url": "https://ghproxy.net/https://github.com/obra/superpowers",
  "install": "git clone --depth 1 $URL /tmp/superpowers && ..."
}
```

### 注意事项

1. **代理服务不稳定**：代理服务可能随时失效，使用前建议验证可用性
2. **构建环境差异**：某些代理在本地可用但在 K8s Pod 内不可用
3. **优先使用官方源**：如网络条件允许，优先使用 GitHub 原始地址
4. **构建检查跳过**：Makefile 会跳过 ghproxy.net 等已知代理的 URL 检查

## 开发流程

### 完整示例

```bash
# 1. 构建镜像
make build
```

### 配置文件

#### config.yaml（必需）

```yaml
registry: <镜像仓库>
registry_user: <用户名>
registry_pass: <密码>
image: <完整镜像地址>
```

### 生产环境处理

1. **镜像构建时**：install 命令执行，安装内容写入 `/opt/preinstall/`
2. **容器首次启动时**：entrypoint.sh 将 `/opt/preinstall/` 复制到 `/home/`
3. **容器后续启动**：检测已存在则跳过复制

```
/opt/preinstall/    # 镜像内，原始预装内容
/home/             # 持久化目录
```

### 注意事项

- 工具安装在 `/opt/tools`（避免覆盖）
- `/home` 目录为工作目录，建议挂载宿主机目录进行持久化
- Go mod 缓存: `$GOPATH=/home/go`

### 项目文件规则

以下文件不需要提交到 git（已在 `.gitignore` 中配置）：

- `config.yaml` - 用户配置文件
- `gitconfig.yaml` - Git 认证配置（用户名、Token、代理）
- `Dockerfile` - 构建产物

### gitconfig.yaml

Git 认证配置文件，用于 Git 操作的用户名、Token 和代理配置：

```yaml
# GitHub 用户名
user: <你的GitHub用户名>

# GitHub Personal Access Token
password: <你的Token>

# HTTP/HTTPS 代理
proxy: <你的代理地址>
```

**注意**：
- 此文件包含敏感信息，**必须**添加到 `.gitignore`
- Makefile 会读取此文件配置 Git 代理和认证
- 首次使用需手动创建此文件
