# OpenClaw Dev Environment

OpenClaw Dev Environment 是一个基于 Debian Bookworm 的容器化开发环境，专门为 [OpenClaw](https://openclaw.ai) AI 助手构建。预装 Node.js 22+、Go、kubectl、helm 等开发工具，并支持 OpenClaw Skills 扩展。

## 快速开始

```bash
make build    # 构建镜像
make deploy   # 部署应用
make exec     # 进入容器
make logs     # 查看日志
make clean    # 清理资源
```

## OpenClaw 使用说明

### 首次启动

```bash
# 1. 进入容器
make exec

# 2. 运行 onboarding 向导（推荐）
openclaw onboard --install-daemon

# 3. 启动 Gateway
openclaw gateway --port 18789

# 4. 打开 Control UI
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

## 构建模式

工具会自动检测构建方式：

| 模式 | 条件 | 说明 |
|------|------|------|
| 本地构建 | 无 kubeconfig.yaml | 使用本地 buildah 命令 |
| K8s 构建 | 有 kubeconfig.yaml | 使用 Buildah Job |

## 配置文件

### config.yaml（必需）

```yaml
registry: <你的镜像仓库>
registry_user: <用户名>
registry_pass: <密码>
image: <完整镜像地址>
```

### kubeconfig.yaml（可选）

从 K8s 集群获取 kubeconfig 配置文件。存在时使用 K8s 构建，否则使用本地构建。

## 项目结构

```
openclaw-dev/
├── .gitignore            # Git 忽略配置
├── Makefile             # 统一工具脚本
├── AGENTS.md            # 开发规范
├── README.md            # 项目说明
├── config/              # 配置文件
│   ├── Dockerfile.template  # Docker 镜像模板
│   ├── registries.conf      # Buildah 镜像源配置
│   ├── k8s-pod.yaml        # K8s Build Pod 模板
│   └── k8s-deploy.yaml     # K8s Deploy 模板
├── preinstall/
│   └── preinstall.json  # 预装清单
└── scripts/
    └── entrypoint.sh   # 启动脚本
```

## 预装配置

预装内容通过 `preinstall/preinstall.json` 管理：

- **dockerfile**：补充 Dockerfile 命令（如 COPY --from）
- **environment**：基础环境工具（Go、Node.js、kubectl 等）
- **openclaw**：OpenClaw 生态项目（Skills）

详见 AGENTS.md

## 部署应用

### 直接使用预构建镜像

可直接使用已构建的镜像部署：

```bash
# 部署默认镜像
kubectl run openclaw --image=zpk.idc.w7.com/w7panel/openclaw-dev:latest \
  --port=18789 --restart=Always --namespace=default

# 或使用 Deployment
kubectl create deployment openclaw --image=zpk.idc.w7.com/w7panel/openclaw-dev:latest \
  --namespace=default

# 暴露服务
kubectl expose deployment openclaw --port=18789 --target-port=18789 \
  --type=NodePort --namespace=default
```

### 自定义构建后部署

```bash
# 1. 构建镜像
make build

# 2. 部署到 K8s
make deploy

# 3. 查看状态
kubectl get pods,svc -n default -l app=openclaw

# 4. 进入容器
make exec
```

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| PORT | 18789 | Gateway 端口 |
| NS | default | K8s 命名空间 |

### 持久化存储

`/home` 目录为工作目录，建议挂载 PVC 进行持久化：

```yaml
volumeMounts:
  - name: home
    mountPath: /home
volumes:
  - name: home
    persistentVolumeClaim:
      claimName: openclaw-home
```
