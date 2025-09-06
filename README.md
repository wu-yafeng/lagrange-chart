# Lagrange OneBot Helm Chart

这是一个用于部署 Lagrange.OneBot 到 Kubernetes 集群的 Helm Chart。Lagrange.OneBot 是基于 Lagrange.Core 的 NTQQ 协议实现，提供 OneBot v11 标准的 API。

## 特性

- 使用 StatefulSet 部署，确保网络身份稳定和数据持久化
- 支持自动生成访问令牌 (Access Token)
- 支持多种 OneBot 实现（HTTP、WebSocket）
- 灵活的配置选项
- 支持 Ingress 和多种 Service 类型
- 可选的数据持久化

## 前置要求

- Kubernetes 1.19+
- Helm 3.0+

## 安装

### 添加 Helm Repository

```bash
# 添加 Helm repository
helm repo add lagrange-chart https://wu-yafeng.github.io/lagrange-chart
helm repo update
```

### 从 Repository 安装

```bash
# 安装 chart
helm install my-lagrange-onebot lagrange-chart/lagrange-onebot -n lagrange-system --create-namespace
```

### 从本地安装

```bash
# 克隆或下载 chart
git clone https://github.com/wu-yafeng/lagrange-chart.git
cd lagrange-chart

# 安装 chart
helm install my-lagrange-onebot ./lagrange-onebot -n lagrange-system --create-namespace
```

### 使用自定义配置安装

```bash
# 创建自定义 values 文件
helm show values lagrange-chart/lagrange-onebot > my-values.yaml
# 编辑 my-values.yaml

# 使用自定义配置安装
helm install my-lagrange-onebot lagrange-chart/lagrange-onebot -f my-values.yaml -n lagrange-system --create-namespace
```

## Chart 发布

本 Chart 使用 GitHub Actions 自动化发布流程：

1. 当代码推送到 `main` 分支时，GitHub Actions 会自动打包 Helm Chart
2. Chart 包会发布到 GitHub Pages，作为 Helm Repository
3. 当创建新的 tag（如 `v1.0.0`）时，会同时创建 GitHub Release

Repository URL: `https://wu-yafeng.github.io/lagrange-chart`

## 配置

### 基本配置

最重要的配置项：

```yaml
config:
  account:
    uin: "123456789"  # 你的 QQ 号
    protocol: "Linux"  # 协议类型: Linux, Windows, MacOS
    
  accessToken:
    autoGenerate: true  # 是否自动生成访问令牌
    # value: "manual-token"  # 手动指定令牌（当 autoGenerate 为 false 时）
    length: 32  # 自动生成令牌的长度
```

### 访问令牌配置

#### 自动生成令牌（推荐）

```yaml
config:
  accessToken:
    autoGenerate: true
    length: 32
```

当启用自动生成时，Helm 会为你创建一个安全的随机令牌。你可以通过以下命令获取生成的令牌：

```bash
kubectl get secret -n lagrange-system my-lagrange-onebot-token -o jsonpath="{.data.accessToken}" | base64 --decode
```

#### 手动指定令牌

```yaml
config:
  accessToken:
    autoGenerate: false
    value: "your-custom-token"
```

### OneBot 实现配置

```yaml
config:
  implementations:
    - type: "Http"
      host: "0.0.0.0"
      port: 8080
      # accessToken: "custom-token"  # 可选：为特定实现指定令牌
    - type: "ReverseWebSocket"
      host: "0.0.0.0"
      port: 8081
      heartBeatInterval: 5000
      heartBeatEnable: true
```

### 数据持久化

```yaml
persistence:
  enabled: true
  storageClass: ""  # 使用默认 StorageClass
  accessMode: ReadWriteOnce
  size: 1Gi
```

### 网络访问

#### 使用 NodePort

```yaml
service:
  type: NodePort
  httpPort: 8080
  wsPort: 8081
```

#### 使用 Ingress

```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: lagrange.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: lagrange-tls
      hosts:
        - lagrange.example.com
```

## 使用指南

### 1. 部署应用

```bash
helm install my-lagrange-onebot . \
  --set config.account.uin="123456789" \
  --set config.account.protocol="Linux" \
  -n lagrange-system --create-namespace
```

### 2. 查看部署状态

```bash
kubectl get pods -n lagrange-system
kubectl get svc -n lagrange-system
```

### 3. 查看二维码登录（如果使用二维码登录）

```bash
kubectl logs -n lagrange-system -l app.kubernetes.io/name=lagrange-onebot -f
```

### 4. 获取自动生成的访问令牌

```bash
kubectl get secret -n lagrange-system my-lagrange-onebot-token -o jsonpath="{.data.accessToken}" | base64 --decode
```

### 5. 访问 API

获取服务 URL：

```bash
# 如果使用 NodePort
kubectl get svc -n lagrange-system

# 如果使用端口转发
kubectl port-forward -n lagrange-system svc/my-lagrange-onebot 8080:8080 8081:8081
```

然后可以访问 OneBot API：

```bash
# 获取机器人信息（替换 YOUR_TOKEN 为实际令牌）
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/get_login_info
```

## 升级

```bash
# 升级到新版本
helm upgrade my-lagrange-onebot . -n lagrange-system

# 升级并修改配置
helm upgrade my-lagrange-onebot . -f my-values.yaml -n lagrange-system
```

## 卸载

```bash
# 卸载应用
helm uninstall my-lagrange-onebot -n lagrange-system

# 删除 PVC（如果需要）
kubectl delete pvc -n lagrange-system -l app.kubernetes.io/name=lagrange-onebot
```

## 故障排除

### 查看日志

```bash
kubectl logs -n lagrange-system -l app.kubernetes.io/name=lagrange-onebot -f
```

### 查看配置

```bash
kubectl get configmap -n lagrange-system my-lagrange-onebot-config -o yaml
```

### 检查网络

```bash
kubectl get svc,ingress -n lagrange-system
```

### 查看持久化存储

```bash
kubectl get pvc -n lagrange-system
```

## 参考资料

- [Lagrange.Core 文档](https://lagrangedev.github.io/Lagrange.Doc/)
- [OneBot 标准](https://onebot.dev/)
- [Kubernetes 文档](https://kubernetes.io/docs/)
- [Helm 文档](https://helm.sh/docs/)

## 贡献

欢迎提交 Issue 和 Pull Request 来改进这个 Helm Chart。

## 许可证

本项目遵循与 Lagrange.Core 相同的许可证。
