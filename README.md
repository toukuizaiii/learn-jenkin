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

项目根目录的 `Jenkinsfile` 参考 [Jenkins 官方入门示例](https://www.jenkins.io/zh/doc/pipeline/tour/hello-world/#examples)，使用声明式 Pipeline，在 `golang:1.26` Docker 容器中执行：

1. **Check**：输出 Go 版本，并执行 `go vet ./...` 静态检查。
2. **Test**：执行 `go test ./...`（当前项目尚无测试文件）。
3. **Build**：编译生成 `server`，并归档到 Jenkins 构建产物中，方便下载。

Jenkins 执行节点需要支持 Linux 容器、安装并能运行 Docker，Jenkins 需要安装 Docker Pipeline 插件。Go 由容器提供，无需在节点上单独安装。

将代码推送到 Git 仓库后，在 Jenkins 中创建 **Pipeline** 任务，将 Definition 设为 **Pipeline script from SCM**，选择 Git 并填写仓库地址（私有仓库还需配置凭据），选择对应分支，Script Path 填 `Jenkinsfile`，保存后点击 **Build Now**。也可以按官方示例创建 **Multibranch Pipeline** 并配置仓库来源。

构建成功后，可在该次构建页面的构建产物中下载 `server`。它是 Linux 可执行文件，可在兼容的 Linux 环境中运行。
