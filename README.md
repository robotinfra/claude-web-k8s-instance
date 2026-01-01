# claude-web-k8s-instance

Helm chart for per-instance Claude Code deployment with multi-container pods for Claude Web Kubernetes Engine.

## Description

This chart deploys a complete Claude Code instance with:
- **Multi-container pod** with Claude Code and MCP servers
- **Feature flags** for optional toolchains (Golang, TypeScript, PostgreSQL, GraphQL)
- **Persistent storage** for workspace and home directories
- **Database support** via CNPG (optional)
- **Ingress** with TLS certificate
- **RBAC** with namespace-scoped permissions
- **Network policies** for zero-trust security

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  Instance: a1b2c3d4 (hash of description)                   │
│  Namespace: claude-{userid}                                 │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Pod: Multi-container (same pod)                            │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Containers:                                            │ │
│  │                                                        │ │
│  │ 1. claude-web (main)                                   │ │
│  │    - Port 8080 (HTTP)                                  │ │
│  │    - Port 81 (MCP)                                     │ │
│  │    - Mounts: workspace, home, tmp, cache, npm, ssh    │ │
│  │                                                        │ │
│  │ 2. context7-mcp (documentation server)                │ │
│  │    - Port 81 (MCP)                                     │ │
│  │                                                        │ │
│  │ 3. playwright-browser (browser automation)            │ │
│  │    - Port 8831 (MCP), 6901 (noVNC), 5900 (VNC)       │ │
│  │                                                        │ │
│  │ 4. dockerhub-mcp (Docker registry integration)         │ │
│  │    - Port 81 (MCP)                                     │ │
│  │                                                        │ │
│  │ 5. golang-tool (optional, based on feature flag)      │ │
│  │    - Port 81 (MCP)                                     │ │
│  │                                                        │ │
│  │ 6. typescript-tool (optional, based on feature flag)   │ │
│  │    - Port 81 (MCP)                                     │ │
│  │                                                        │ │
│  │ 7. postgres (optional, based on feature flag)          │ │
│  │    - PostgreSQL 16 client                              │ │
│  │                                                        │ │
│  │ 8. hasura (optional, based on feature flag)            │ │
│  │    - Port 8080 (GraphQL)                               │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  Volumes:                                                     │
│  - PVC: workspace (10Gi), home (1Gi)                        │
│  - emptyDir: tmp (10Gi), cache (5Gi), npm-cache (1Gi)       │
│                                                              │
│  Services:                                                   │
│  - Service: ClusterIP on port 8080                           │
│  - Ingress: {hash}.dev.robotinfra.com → Service              │
│                                                              │
│  Database (optional):                                        │
│  - CNPG Database CR: {instanceName}-db                        │
│                                                              │
│  RBAC:                                                       │
│  - ServiceAccount, Role, RoleBinding (namespace-scoped)      │
│                                                              │
│  Network Policy:                                             │
│  - Zero-trust model (deny-all, allow DNS, specific egress)   │
└─────────────────────────────────────────────────────────────┘
```

## Installation

### Via ArgoCD (Recommended)

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: claude-instance-a1b2c3d4
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/robotinfra/claude-web-k8s-instance
    chart: .
    targetRevision: main
    helm:
      values: |
        instanceName: a1b2c3d4
        instanceDescription: "Backend API development"
        userid: user123
        features:
          golang: true
          typescript: true
          postgres: false
          graphql: false
  destination:
    server: https://kubernetes.default.svc
    namespace: claude-user123
```

### Via Helm CLI

```bash
helm install my-instance ./claude-web-k8s-instance \
  --namespace claude-user123 \
  --set instanceName=a1b2c3d4 \
  --set instanceDescription="Backend API development" \
  --set userid=user123 \
  --set features.golang=true
```

## Configuration

### Instance Identification

| Parameter | Description | Default |
|-----------|-------------|---------|
| `instanceName` | Unique instance identifier (hash of description) | `"a1b2c3d4"` |
| `instanceDescription` | Human-readable description | `"Backend API development"` |
| `userid` | User ID who owns this instance | `"user123"` |

### Feature Flags

| Parameter | Description | Default |
|-----------|-------------|---------|
| `features.golang` | Enable Golang support container | `true` |
| `features.typescript` | Enable TypeScript support container | `true` |
| `features.postgres` | Enable PostgreSQL sidecar + database | `true` |
| `features.graphql` | Enable Hasura GraphQL container | `false` |

### MCP Servers (Always Included)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `mcpServers.context7.enabled` | Enable Context7 documentation server | `true` |
| `mcpServers.playwrightBrowser.enabled` | Enable Playwright browser automation | `true` |
| `mcpServers.dockerhubMcp.enabled` | Enable Docker Hub integration | `true` |

### Storage

| Parameter | Description | Default |
|-----------|-------------|---------|
| `storage.workspace.size` | Workspace PVC size | `"10Gi"` |
| `storage.home.size` | Home directory PVC size | `"1Gi"` |
| `storage.tmp.size` | Temporary directory (emptyDir) | `"10Gi"` |
| `storage.cache.size` | Cache directory (emptyDir) | `"5Gi"` |
| `storage.npmCache.size` | NPM cache (emptyDir) | `"1Gi"` |

### Resources

| Parameter | Description | Default |
|-----------|-------------|---------|
| `resources.requests.memory` | Memory request | `"512Mi"` |
| `resources.requests.cpu` | CPU request | `"250m"` |
| `resources.limits.memory` | Memory limit | `"2Gi"` |
| `resources.limits.cpu` | CPU limit | `"1000m"` |

### Database (Optional)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `database.enabled` | Create CNPG database | `false` |
| `database.namespace` | CNPG cluster namespace | `"database"` |
| `database.cluster` | CNPG cluster name | `"postgresql"` |
| `database.reclaimPolicy` | Database reclaim policy | `"delete"` |

### Ingress

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Create ingress resource | `true` |
| `ingress.hostname` | Custom hostname (defaults to {hash}.dev.robotinfra.com) | `""` |
| `ingress.className` | Ingress class | `"nginx"` |

## Instance Naming

Instances are named using SHA256 hash of the description:
```
"Backend API development" → sha256(desc)[:12] → "a1b2c3d4e5f6"
```

The instance name is stored as:
- Kubernetes resource name
- Ingress subdomain: `a1b2c3d4.dev.robotinfra.com`
- Annotation on all resources for traceability

## Volumes

### Persistent Volume Claims (PVCs)
- **workspace** (10Gi): Main workspace directory mounted at `/workspace`
- **home** (1Gi): Home directory mounted at `/home/code/.claude`

### EmptyDirs
- **tmp** (10Gi): Temporary files at `/tmp`
- **cache** (5Gi): Cache at `/home/code/.cache`
- **npm-cache** (1Gi): NPM cache at `/home/code/.npm`
- **claude-lock** (10Mi): Claude lock file at `/home/code/.claude.json.lock`
- **ssh-directory** (10Mi): SSH keys at `/home/code/.ssh`

## Security

### RBAC
- **ServiceAccount**: Per-instance service account
- **Role**: Full admin access within instance namespace
- **RoleBinding**: Binds role to service account

### Network Policies (Zero-Trust Model)
- Default deny-all ingress/egress
- Allow DNS resolution (port 53)
- Allow HTTPS egress for MCP servers
- Allow cluster-internal communication
- Block all other traffic

### Security Context
- `runAsUser: 1000`, `runAsGroup: 1000`
- `runAsNonRoot: true`
- `readOnlyRootFilesystem: true`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: ALL`

## MCP Servers

### Included by Default

**Context7** (`transformia/context7-mcp:1.0.27`)
- Documentation server for code examples
- Port: 81 (MCP)

**Playwright Browser** (`transformia/playwright-browser:1.0.3`)
- Browser automation with VNC/noVNC
- Ports: 8831 (MCP), 6901 (noVNC), 5900 (VNC)

**Docker Hub MCP** (`ghcr.io/transform-ia/dockerhub-mcp:v0.17.0`)
- Docker registry integration
- Port: 81 (MCP)

### Optional (Feature Flags)

**Golang Tool** (`ghcr.io/transform-ia/golang-image:latest`)
- Go development tools and MCP server
- Port: 81 (MCP)
- Resources: 128Mi memory, 100m CPU

**TypeScript Tool** (`ghcr.io/transform-ia/typescript-image:latest`)
- Node.js/TypeScript development tools and MCP server
- Port: 81 (MCP)
- Resources: 128Mi memory, 100m CPU

**PostgreSQL** (`postgres:16-alpine`)
- PostgreSQL client for database access
- Resources: 128Mi memory, 50m CPU
- Requires CNPG database to be created

**Hasura GraphQL** (`hasura/graphql-engine:v2.36.0`)
- GraphQL API server with Postgres integration
- Port: 8080 (GraphQL)
- Resources: 256Mi memory, 100m CPU

## Init Containers

### Git Clone
Clones the initial repository into `/workspace`:
- Uses GitHub token from secret
- Supports pulling latest changes if repo exists
- Branch: `master` (configurable)

### SSH Setup
Generates SSH keys and configuration:
- Copies private key from secret
- Generates public key from private key
- Sets up known_hosts (GitHub + custom)
- Sets ownership to 1000:1000

## Probes

### Liveness Probe
Checks if `sleep 2147483647` process is running (infinite sleep)

### Readiness Probe
Checks if `/workspace/.git` directory exists

## Environment Variables

### Main Container
- `HOME`: `/home/code`
- `TZ`: Timezone (default: `America/Montreal`)
- `DISABLE_AUTOUPDATER`: `"1"`
- `EDITOR`: `vim`
- `CLAUDE_INSTANCE_NAME`: Instance identifier
- `CLAUDE_INSTANCE_DESCRIPTION`: Instance description
- `CLAUDE_USERID`: User ID
- `CLAUDE_NAMESPACE`: Kubernetes namespace
- `OTEL_EXPORTER_OTLP_ENDPOINT`: Tempo/Jaeger endpoint
- `OTEL_SERVICE_NAME`: Service name for tracing
- `GITHUB_TOKEN`: From secret for GitHub operations
- `DATABASE_URL`: From secret (if postgres feature enabled)

## Usage Examples

### Create Instance with All Features

```yaml
instanceName: a1b2c3d4
instanceDescription: "Full-stack development with Go and TypeScript"
userid: user123
features:
  golang: true
  typescript: true
  postgres: true
  graphql: false
```

### Create Minimal Instance

```yaml
instanceName: e5f6g7h8
instanceDescription: "Simple documentation project"
userid: user456
features:
  golang: false
  typescript: false
  postgres: false
  graphql: false
```

### Instance with PostgreSQL Database

```yaml
instanceName: i9j0k1l2
instanceDescription: "API development with database"
userid: user789
features:
  postgres: true
database:
  enabled: true
  namespace: database
  cluster: postgresql
```

## Troubleshooting

### Pod Not Starting

Check events:
```bash
kubectl describe pod <instance-name> -n <namespace>
```

Check logs:
```bash
kubectl logs <instance-name> -n <namespace> -c claude-web
```

### Database Connection Issues

Verify secret exists:
```bash
kubectl get secret <instance-name>-db -n <namespace>
```

Check database CR:
```bash
kubectl get database <instance-name>-db -n database
```

### Storage Issues

Check PVCs:
```bash
kubectl get pvc -n <namespace>
```

Describe PVC:
```bash
kubectl describe pvc <instance-name>-workspace -n <namespace>
```

## Upgrading

```bash
helm upgrade my-instance ./claude-web-k8s-instance \
  --namespace claude-user123 \
  --reuse-values \
  --set features.golang=false
```

## Uninstalling

```bash
helm uninstall my-instance --namespace claude-user123
```

**Note**: This will delete the deployment, service, ingress, and RBAC resources. PVCs and databases will be retained based on their reclaim policies.

## Roadmap

Future enhancements:
- Horizontal pod autoscaling
- Vertical pod autoscaling
- Pod disruption budgets
- Backup and restore for PVCs
- Metrics dashboards per instance
- Instance templates (predefined configurations)

## Contributing

This is part of the Claude Web Kubernetes Engine project. Contributions are welcome via pull requests.

## License

MIT

## Maintainer

- robotinfra (infra@robotinfra.com)

## See Also

- [claude-web-k8s-user](https://github.com/robotinfra/claude-web-k8s-user) - Per-user namespace infrastructure
- [claude-web-k8s-engine](https://github.com/robotinfra/claude-web-k8s-engine) - Go proxy + React frontend
