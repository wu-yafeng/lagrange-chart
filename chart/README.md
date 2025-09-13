# Lagrange OneBot Helm Chart

这是一个用于部署 Lagrange.OneBot 到 Kubernetes 集群的 Helm Chart。Lagrange.OneBot 是基于 Lagrange.Core 的 NTQQ 协议实现，提供 OneBot v11 标准的 API。

## 特性

- 使用 StatefulSet 部署，确保网络身份稳定和数据持久化
- 支持自动生成访问令牌 (Access Token)
- 支持多种 OneBot 实现（HTTP、WebSocket、反向WebSocket等）
- 内置 Portal 反向代理，支持多实例路由和负载均衡
- 灵活的配置选项和动态端口映射
- 支持 Ingress 和多种 Service 类型
- 可选的数据持久化
- 基于实例 ID 的智能路由

## 前置要求

- Kubernetes 1.19+
- Helm 3.0+

## 安装

### 添加 Helm Repository（如果有的话）

```bash
# 如果 chart 发布到了 repository
helm repo add lagrange-onebot https://your-repo-url
helm repo update
```

### 从本地安装

```bash
# 克隆或下载 chart
git clone <repository-url>
cd lagrange-chart/chart

# 安装 chart
helm install my-lagrange-onebot . -n lagrange-system --create-namespace
```

### 使用自定义配置安装

```bash
# 创建自定义 values 文件
cp values.yaml my-values.yaml
# 编辑 my-values.yaml

# 使用自定义配置安装
helm install my-lagrange-onebot . -f my-values.yaml -n lagrange-system --create-namespace
```

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
      host: "*"
      port: 8080
      # accessToken: "custom-token"  # 可选：为特定实现指定令牌
    - type: "ReverseWebSocket"
      host: "*"
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

### Portal 反向代理配置

```yaml
portal:
  replicaCount: 1
  service:
    type: ClusterIP
    port: 80
  resources:
    limits:
      cpu: 200m
      memory: 128Mi
    requests:
      cpu: 50m
      memory: 32Mi
```

### 网络访问

#### 使用 NodePort（通过 Portal）

```yaml
portal:
  service:
    type: NodePort
    port: 80
```

#### 使用 Ingress（通过 Portal）

```yaml
ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: lagrange.example.com
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
kubectl logs -n lagrange-system -l app.kubernetes.io/name=lagrange-onebot,app.kubernetes.io/component=onebot -f
```

### 4. 获取自动生成的访问令牌

```bash
kubectl get secret -n lagrange-system my-lagrange-onebot-token -o jsonpath="{.data.accessToken}" | base64 --decode
```

### 5. 访问 API

通过 Portal 访问 OneBot API。Portal 提供了基于实例 ID 的路由功能：

```bash
# 如果使用 NodePort
kubectl get svc -n lagrange-system

# 如果使用端口转发到 Portal
kubectl port-forward -n lagrange-system svc/my-lagrange-onebot-portal 8080:80
```

然后可以通过 Portal 访问 OneBot API：

```bash
# 获取机器人信息（替换 YOUR_TOKEN 为实际令牌，指定实例 ID 和端口）
curl -H "Authorization: Bearer YOUR_TOKEN" \
     -H "X-Instance-ID: 0" \
     -H "X-Instance-Port: 8080" \
     http://localhost:8080/get_login_info
```

**重要说明**：
- `X-Instance-ID`：指定要访问的 StatefulSet 实例 ID（从 0 开始）
- `X-Instance-Port`：指定要访问的端口（根据 OneBot 实现配置）
- Portal 会根据这些头部信息将请求路由到正确的后端实例

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
# 查看 OneBot 组件日志
kubectl logs -n lagrange-system -l app.kubernetes.io/name=lagrange-onebot,app.kubernetes.io/component=onebot -f

# 查看 Portal 组件日志
kubectl logs -n lagrange-system -l app.kubernetes.io/name=lagrange-onebot,app.kubernetes.io/component=portal -f
```

### 查看配置

```bash
# OneBot 配置
kubectl get configmap -n lagrange-system my-lagrange-onebot-config -o yaml

# Portal nginx 配置
kubectl get configmap -n lagrange-system my-lagrange-onebot-portal-nginx -o yaml
```

### 检查网络

```bash
kubectl get svc,ingress -n lagrange-system
```

### 检查组件状态

```bash
# 查看所有 Pods
kubectl get pods -n lagrange-system

# 查看 OneBot StatefulSet
kubectl get statefulset -n lagrange-system

# 查看 Portal Deployment
kubectl get deployment -n lagrange-system
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
