# Go Hello World Web Server

用于学习 Jenkins 的简单 Go Web 服务，仅使用 Go 标准库，无第三方依赖。

## 运行

安装 Go 1.22 或更高版本，在项目目录执行：

```sh
go run .
```

访问 http://localhost:8080/，返回：

```text
Hello, World!
```

访问 http://localhost:8080/test，返回 `Hello from the test route!`，可用于验证新分支的构建结果。

按 `Ctrl+C` 停止服务。可通过 `PORT` 环境变量修改端口，例如在 PowerShell 中：

```powershell
$env:PORT = "9090"
go run .
```

## 构建与检查

下面的命令也可以用于 Jenkins 构建步骤：

```sh
go vet ./...
go build -o server .
```

运行构建产物：Linux/macOS 使用 `./server`；Windows 构建时使用
`go build -o server.exe .`，再执行 `.\server.exe`。

## Jenkins Pipeline

项目根目录的 `Jenkinsfile` 使用声明式 Pipeline，参考 [Jenkins Docker Pipeline 文档](https://www.jenkins.io/doc/book/pipeline/docker/) 和 [条件阶段文档](https://www.jenkins.io/doc/book/pipeline/syntax/#when)。流程如下：

1. **Check**：输出 Go 版本，并执行 `go vet ./...` 静态检查。
2. **Test**：执行 `go test ./...`（当前项目尚无测试文件）。
3. **Build**：编译生成 `server`，并归档到 Jenkins 构建产物中，方便下载。
4. **Build Docker Image**：根据 `Dockerfile` 构建镜像，标签为 `learn-jenkin:<提交 SHA>-<构建编号>`，保存在当前 Docker 主机上。
5. **Deploy**：仅多分支流水线的 `main` 分支执行，PR 和其他分支跳过部署。替换 `learn-jenkin` 容器，等待健康检查通过；启动或健康检查失败时，尝试恢复上一个容器。

检查、测试和 Go 编译在 `golang:1.26` 容器中执行。镜像构建和部署命令在 Jenkins 执行节点上执行，部署目标是该节点连接的 Docker daemon。流水线会串行执行同一分支的构建，防止同一个 `main` 任务并发替换容器。

### Jenkins 环境配置

1. Jenkins 安装 **Docker Pipeline** 插件。
2. 为此学习项目使用一个固定的 **Linux 执行节点**，节点需要有 `sh`、Git、Docker CLI，并能以 Jenkins 运行用户执行 `docker version`、拉取镜像和启动容器；无需单独安装 Go。当前 `agent any` 适用于只有这个可用节点的环境。多个节点时，将它改为 `agent { label 'docker-deploy' }`，并只给目标部署节点设置这个标签。
3. 若 Jenkins 本身运行在 Docker 容器中，仅安装插件不够：执行节点容器还需要 Docker CLI、对 Docker daemon 的访问权限，以及编译容器能够挂载的工作区。构建出的服务是同一 daemon 下的独立容器，不在 Jenkins 容器内部。
4. 使用 **Multibranch Pipeline** 任务（例如 `my_job2`），配置 GitHub 仓库来源，Script Path 保持 `Jenkinsfile`，开启分支发现。`when { branch 'main' }` 依赖多分支任务的分支信息。
5. 推送代码后手动扫描仓库，或配置定时扫描/Webhook，再运行 `main` 的构建。其他分支需要包含新版 Jenkinsfile 才会使用这套流程。

部署成功后，在 Docker 主机上访问 http://localhost:8080/，返回 `Hello, World!`；http://localhost:8080/test 返回测试内容。远程主机使用其实际地址。可修改 Jenkinsfile 中的 `APP_PORT` 更换宿主机端口，容器内部端口固定为 8080；`CONTAINER_NAME` 是此任务管理的容器名称，应避免与其他任务重复。

这是单机学习用的部署方式，替换容器时会有短暂停机。旧容器会暂存为 `learn-jenkin-previous`，新容器健康后才删除；如果这个备份名称已存在，部署会停止并提示先检查。历史镜像保留在本机，本流程不推送镜像仓库。健康检查通过只表示首页可访问。

### 本地体验 Docker 镜像

在支持 Linux 容器的 Docker 环境中执行：

```sh
docker build -t learn-jenkin:local .
docker run -d --name learn-jenkin-local -p 8081:8080 learn-jenkin:local
docker inspect --format '{{.State.Health.Status}}' learn-jenkin-local
docker logs learn-jenkin-local
```

访问 http://localhost:8081/。体验完成后执行 `docker rm -f learn-jenkin-local` 停止并删除该测试容器。
