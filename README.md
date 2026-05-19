# Noaul

Noaul 是一个 Windows 优先的一键引导安装器，用来集中安装或更新常用开发工具、AI 编程工具，以及可选的 Docker 服务。

核心原则：一键命令只启动引导器。除 Git 这类基础开发工具外，Codex、Claude Code、Kiro、OpenCode、CC Switch、Docker 服务都需要你明确选择后才会安装。

## 一键启动

在 PowerShell 中运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/uovme/noaul/main/install.ps1 | iex"
```

如果你已经克隆了仓库：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

## 查看组件

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -ListComponents
```

## Dry Run

先看会执行什么，不安装：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -DryRun -Install codex,cc-switch
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -DryRun -DockerService cpa,sub2api
```

## 非交互安装

明确指定要安装的组件：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -Install codex,claude-code,opencode,cc-switch
```

Docker 服务需要 Docker Desktop，脚本会把 `docker-desktop` 加入计划：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -DockerService cpa,cpa-usage-keeper,sub2api
```

## 组件 ID

| ID | 名称 | 类型 | 默认选择 | 安装方式 |
| --- | --- | --- | --- | --- |
| `git` | Git for Windows | Core | 是 | winget `Git.Git` |
| `nodejs` | Node.js LTS | Core | 否 | winget `OpenJS.NodeJS.LTS` |
| `powershell` | PowerShell 7 | Core | 否 | winget `Microsoft.PowerShell` |
| `vscode` | Visual Studio Code | Core | 否 | winget `Microsoft.VisualStudioCode` |
| `windows-terminal` | Windows Terminal | Core | 否 | winget `Microsoft.WindowsTerminal` |
| `docker-desktop` | Docker Desktop | Docker Runtime | 否 | winget `Docker.DockerDesktop` |
| `codex` | OpenAI Codex CLI，默认 reasoning effort 设为 `xhigh` | AI CLI | 否 | npm `@openai/codex` |
| `claude-code` | Claude Code | AI CLI | 否 | npm `@anthropic-ai/claude-code` |
| `kiro` | Kiro | AI App | 否 | winget `Amazon.Kiro` |
| `opencode` | OpenCode | AI CLI | 否 | npm `opencode-ai` |
| `cc-switch` | CC Switch | AI App | 否 | winget `farion1231.CC-Switch` |
| `cpa` | CLIProxyAPI / CPA | Docker Service | 否 | Docker image `eceasy/cli-proxy-api:latest` |
| `cpa-usage-keeper` | CPA Usage Keeper | Docker Service | 否 | Docker image `ghcr.io/willxup/cpa-usage-keeper:latest` |
| `sub2api` | Sub2API | Docker Service | 否 | Docker image `weishaw/sub2api:latest` |

## Docker 服务位置

默认生成到：

```text
%USERPROFILE%\.noaul\services\
```

可用 `-InstallRoot` 改位置：

```powershell
pwsh -File .\install.ps1 -NoPrompt -DockerService sub2api -InstallRoot D:\noaul
```

生成内容：

| 服务 | 路径 |
| --- | --- |
| `cpa` / `cpa-usage-keeper` | `services\cpa-stack\docker-compose.yml` |
| `sub2api` | `services\sub2api\docker-compose.yml` |

Docker 服务默认绑定到 `127.0.0.1`，避免直接暴露到局域网。生成的 `.env` 会包含随机密码和密钥，请妥善保存。

## 更新逻辑

- winget 组件：先尝试 `winget upgrade`，失败再尝试 `winget install`。
- npm 组件：执行 `npm install -g <package>@latest`。
- Docker 服务：生成 Compose 文件后执行 `docker compose pull` 和 `docker compose up -d`。

## 注意事项

- Docker Desktop 安装后通常需要手动启动一次，并完成 WSL 2 初始化。
- npm 工具依赖 Node.js LTS；选择 Codex、Claude Code 或 OpenCode 时，Noaul 会自动把 `nodejs` 加进计划。
- 选择 Codex 时，Noaul 会把 `%USERPROFILE%\.codex\config.toml` 中的 `model_reasoning_effort` 设置为 `xhigh`。
- PowerShell 当前会话可能不会马上刷新 PATH；如果安装后找不到命令，重新打开终端。
- Docker Desktop 的授权条款以 Docker 官方说明为准。

## 验证

运行测试：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\tests\Noaul.Tests.ps1
```

## 参考来源

- Codex npm package: https://www.npmjs.com/package/@openai/codex
- Claude Code setup: https://docs.anthropic.com/en/docs/claude-code/setup
- Kiro installation: https://kiro.dev/docs/getting-started/installation/
- Kiro CLI installation: https://kiro.dev/docs/cli/installation/
- OpenCode: https://opencode.ai/
- Docker Desktop Windows install: https://docs.docker.com/desktop/setup/install/windows-install/
- CLIProxyAPI quick start: https://help.router-for.me/introduction/quick-start
- CC Switch releases: https://github.com/farion1231/cc-switch/releases
- Sub2API repository: https://github.com/Wei-Shaw/sub2api
