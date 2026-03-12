# OpenClaw Dev Environment Makefile

APP ?= openclaw
PORT ?= 18789

REGISTRY := $(shell grep '^registry:' config.yaml 2>/dev/null | awk '{print $$2}')
REGISTRY_USER := $(shell grep '^registry_user:' config.yaml 2>/dev/null | awk '{print $$2}')
REGISTRY_PASS := $(shell grep '^registry_pass:' config.yaml 2>/dev/null | awk '{print $$2}')
IMAGE := $(shell grep '^image:' config.yaml 2>/dev/null | awk '{print $$2}')
REGISTRIES_CONF := config/registries.conf
DOCKERFILE_TEMPLATE := config/Dockerfile.template

.PHONY: all
all: help

# =======================
# 检查配置
# =======================
check-config:
	@if [ -z "$(IMAGE)" ]; then echo "Error: image not configured"; exit 1; fi
	@if [ -z "$(REGISTRY)" ] || [ -z "$(REGISTRY_USER)" ] || [ -z "$(REGISTRY_PASS)" ]; then echo "Error: registry auth not configured"; exit 1; fi
	@echo "Config check passed"

check-preinstall:
	@echo "=== Checking GitHub proxy ==="
	@(which jq >/dev/null 2>&1 || (echo "Error: jq not installed" && exit 1))
	@echo "Check passed"

# =======================
# 检查镜像源配置
# =======================
check-registries:
	@echo "=== Checking buildah registries config ==="
	@if [ ! -f "$(REGISTRIES_CONF)" ]; then \
		echo "Error: $(REGISTRIES_CONF) not found"; \
		exit 1; \
	fi
	@cp $(REGISTRIES_CONF) /etc/containers/registries.conf 2>/dev/null || true
	@if ! grep -q "registry.cdn.w7.cc\|daocloud\|nju.edu.cn" /etc/containers/registries.conf 2>/dev/null; then \
		echo "Warning: No Chinese mirror configured"; \
	fi
	@echo "Registries config check passed"

# =======================
# 复制 OpenClaw skills
# =======================
copy-skills:
	@if [ -d "skills" ]; then \
		mkdir -p preinstall/.openclaw && \
		cp -r skills preinstall/.openclaw/ 2>/dev/null || true; \
	fi
	@if [ -d ".openclaw/skills" ]; then \
		mkdir -p preinstall/.openclaw && \
		cp -r .openclaw/skills preinstall/.openclaw/ 2>/dev/null || true; \
	fi

# =======================
# 生成 Dockerfile
# =======================
prepare-dockefile: check-config check-preinstall check-registries copy-skills
	@echo "=== Generating Dockerfile ==="
	@bash scripts/generate-dockefile.sh preinstall/preinstall.json $(DOCKERFILE_TEMPLATE) Dockerfile

# =======================
# 本地构建（使用 buildah）
# =======================
build: check-config prepare-dockefile
	@echo "=== Build Image (Local) ==="
	@echo "Image: $(IMAGE)"
	@(which buildah >/dev/null 2>&1 || (echo "Error: buildah not installed" && exit 1))
	@buildah login --username $(REGISTRY_USER) --password $(REGISTRY_PASS) $(REGISTRY) 2>/dev/null || true
	@buildah bud --squash -f Dockerfile -t $(IMAGE) --pull .
	@buildah push $(IMAGE)
	@echo ""
	@echo "========================================"
	@echo "Build and push successful!"
	@echo "Image: $(IMAGE)"
	@echo "========================================"

# =======================
# 运行测试（使用 buildah）
# =======================
run: check-config
	@echo "=== Run Container for Testing ==="
	@echo "Image: $(IMAGE)"
	@echo "Port: $(PORT)"
	@echo ""
	@echo "Press Ctrl+C to stop"
	@(which buildah >/dev/null 2>&1 || (echo "Error: buildah not installed" && exit 1))
	@buildah rm $(APP)-test 2>/dev/null || true
	@buildah from --name $(APP)-test $(IMAGE)
	@buildah config --cmd "/bin/bash" $(APP)-test
	@buildah run -t $(APP)-test

# =======================
# 显示帮助
# =======================
help:
	@echo "OpenClaw Dev Environment - Makefile"
	@echo ""
	@echo "Usage: make <target>"
	@echo ""
	@echo "Targets:"
	@echo "  build      Build Docker image using local buildah"
	@echo "  run        Run container for testing"
	@echo "  help       Show help"
	@echo ""
	@echo "Configuration files:"
	@echo "  config.yaml           - Registry and image config"
	@echo "  config/registries.conf - Buildah mirror config"
