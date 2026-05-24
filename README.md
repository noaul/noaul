# Noaul

Noaul 是一个 Windows 优先的一键引导安装器，用来集中安装或更新包管理器、常用开发工具、Python/Node 运行时、AI 编程工具，以及可选的 Docker 服务。部分组件提供 Linux 分发路径，例如 `cc-switch` 在 Linux 上使用 `cc-switch-cli`。

核心原则：一键命令只启动引导器。第一步选择安装或更新：安装模式按推荐默认项和你的选择补齐依赖；更新模式只检测并更新本地已经安装的组件，不安装缺失工具。能用包管理器安装的工具优先走包管理器，CLI 工具优先 Scoop，系统级和 GUI 工具优先 winget。

## 选择规则

- 推荐默认项覆盖基础类型：包管理器、常用 CLI、Node/npm、Python/uv。
- 同类型工具不互相捆绑：选 Codex 不会自动安装 Claude Code 或 OpenCode。
- 依赖会自动补齐：选 npm 工具会加入 Node.js/npm；选 Python 工具会加入 Python；选 Docker 服务会加入 Docker Desktop。
- 更新模式只更新已检测到的本地组件；如果某个组件没安装，不会为了更新而安装它。
- Docker 服务、AI 工具、编辑器、Build Tools 都需要明确选择后才会安装。
- Windows Terminal 不纳入 Noaul 清单。

## 依赖预检

安装计划会先展开并检查必需工具。如果选中的组件依赖本机还没有的安装器或运行时，Noaul 会先把这些前置项加入计划再执行安装，例如 `codex` 会加入 `scoop`、`nodejs`、`npm`，Windows 上的 `cc-switch` 会加入 `winget`，`sub2api` 会加入 `winget` 和 `docker-desktop`。

如果某个必需工具无法由当前平台自动安装，脚本会在执行前给出明确错误，避免安装到一半才失败。

## 一键启动

在 PowerShell 中运行：

```powershell
irm https://noaul.uov.me|iex
```

如果当前 PowerShell 执行策略拦截，再使用完整启动命令：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://noaul.uov.me|iex"
```

备用短路径：

```powershell
irm https://noaul.uov.me/i|iex
```

备用 GitHub raw 入口：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/noaul/noaul/main/install.ps1 | iex"
```

Linux 一键安装：

```bash
curl -fsSL https://noaul.uov.me/linux | bash
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
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -DryRun -Install python,uv,pnpm
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -DryRun -Install cc-switch -Platform linux
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -DryRun -DockerService cpa,sub2api
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -DryRun -Update
```

## 非交互安装

明确指定要安装的组件：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -Install codex,claude-code,opencode,cc-switch
```

常用开发环境：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -Install git,curl,ripgrep,nodejs,npm,pnpm,python,uv,gh
```

Docker 服务需要 Docker Desktop，脚本会把 `docker-desktop` 加入计划：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -DockerService cpa,cpa-usage-keeper,sub2api
```

## 更新已安装组件

交互模式下，启动后第一步选择 `update` 即可。非交互模式用 `-Update`：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -Update
```

只更新指定且已安装的组件：

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File .\install.ps1 -NoPrompt -Update -Install git,python,codex
```

更新模式会按本地状态生成计划：Scoop 包走 `scoop update <package>`，winget 包只走 `winget upgrade`，npm CLI 走 `npm install -g <package>@latest`，Docker 服务只更新已有 Compose 目录。

## 组件 ID

| ID | 名称 | 类型 | 默认选择 | 安装方式 |
| --- | --- | --- | --- | --- |
| `winget` | Windows Package Manager | Package Manager | 是 | 检测 `winget` |
| `scoop` | Scoop | Package Manager | 是 | 官方 `get.scoop.sh` bootstrap |
| `git` | Git for Windows | Core Dev | 是 | scoop `git` |
| `curl` | curl | Core Dev | 是 | scoop `curl` |
| `7zip` | 7-Zip | Core Dev | 是 | scoop `7zip` |
| `ripgrep` | ripgrep | Core Dev | 是 | scoop `ripgrep` |
| `fd` | fd | Core Dev | 否 | scoop `fd` |
| `jq` | jq | Core Dev | 否 | scoop `jq` |
| `gh` | GitHub CLI | Core Dev | 否 | scoop `gh` |
| `git-lfs` | Git LFS | Core Dev | 否 | scoop `git-lfs` |
| `nodejs` | Node.js LTS | Runtime | 是 | scoop `nodejs-lts` |
| `npm` | npm | Runtime | 是 | Node.js 提供，脚本只验证 |
| `pnpm` | pnpm | Node Tooling | 否 | scoop `pnpm` |
| `python` | Python 3 | Runtime | 是 | scoop `python` |
| `uv` | uv | Python Tooling | 是 | scoop `uv` |
| `pipx` | pipx | Python Tooling | 否 | scoop `pipx` |
| `ruff` | Ruff | Python Tooling | 否 | scoop `ruff` |
| `visual-build-tools` | Visual Studio Build Tools | Build Tools | 否 | winget `Microsoft.VisualStudio.2022.BuildTools` |
| `powershell` | PowerShell 7 | Shell | 否 | winget `Microsoft.PowerShell` |
| `vscode` | Visual Studio Code | Editor | 否 | winget `Microsoft.VisualStudioCode` |
| `docker-desktop` | Docker Desktop | Docker Runtime | 否 | winget `Docker.DockerDesktop` |
| `codex` | OpenAI Codex CLI，默认 reasoning effort 设为 `xhigh` | AI CLI | 否 | npm `@openai/codex` |
| `claude-code` | Claude Code | AI CLI | 否 | npm `@anthropic-ai/claude-code` |
| `kiro` | Kiro | AI App | 否 | winget `Amazon.Kiro` |
| `opencode` | OpenCode | AI CLI | 否 | npm `opencode-ai` |
| `cc-switch` | CC Switch | AI App | 否 | Windows: winget `farion1231.CC-Switch`; Linux: `saladday/cc-switch-cli` install.sh |
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

- `winget`：检测系统命令是否存在。
- `scoop`：使用 Scoop 官方 `get.scoop.sh` bootstrap。
- Scoop 组件：执行 `scoop install <package>`，例如 `git`、`curl`、`python`、`uv`、`pnpm`。
- winget 组件：先尝试 `winget upgrade`，失败再尝试 `winget install`。
- npm 组件：执行 `npm install -g <package>@latest`。
- 虚拟组件：例如 `npm` 由 `nodejs` 提供，脚本只验证命令是否可用。
- Docker 服务：生成 Compose 文件后执行 `docker compose pull` 和 `docker compose up -d`。
- 更新模式：不会走 install fallback；只对已安装组件执行 update/upgrade。

## 注意事项

- Docker Desktop 安装后通常需要手动启动一次，并完成 WSL 2 初始化。
- npm 工具依赖 Node.js LTS；选择 Codex、Claude Code 或 OpenCode 时，Noaul 会自动把 `nodejs` 和 `npm` 加进计划。
- Scoop 安装的工具会自动把 `scoop` 加进计划；Python 工具会自动把 `python` 加进计划。
- Linux 上选择 `cc-switch` 时，Noaul 会使用 `https://github.com/saladday/cc-switch-cli` 的 release install script；需要系统已有 `bash` 和 `curl`。
- `curl` 会检测 `curl.exe`，避免和 Windows PowerShell 里的 `curl` alias 混淆。
- 选择 Codex 时，Noaul 会把 `%USERPROFILE%\.codex\config.toml` 中的 `model_reasoning_effort` 设置为 `xhigh`。
- PowerShell 当前会话可能不会马上刷新 PATH；如果安装后找不到命令，重新打开终端。
- Docker Desktop 的授权条款以 Docker 官方说明为准。

## Linux 支持

Noaul 的核心设计是 Windows 优先，但 Linux 入口也能一键安装支持的工具清单。短命令默认安装推荐基础集合：

- 默认基础：`git`、`curl`、`ripgrep`、`nodejs`、`npm`、`python`、`uv`
- 可选工具：`fd`、`jq`、`gh`、`git-lfs`、`pnpm`、`pipx`、`ruff`、`codex`、`claude-code`、`opencode`、`cc-switch`
- `cc-switch` 是平台差异项：Windows 用 `farion1231.CC-Switch`，Linux 用 `saladday/cc-switch-cli`

Linux 默认安装：

```bash
curl -fsSL https://noaul.uov.me/linux | bash
```

指定组件、安装全部 Linux 支持项或 dry-run：

```bash
curl -fsSL https://noaul.uov.me/linux | bash -s -- codex cc-switch
curl -fsSL https://noaul.uov.me/linux | bash -s -- all
curl -fsSL https://noaul.uov.me/linux | NOAUL_DRY_RUN=1 bash
pwsh -NoProfile -Command "./install.ps1 -NoPrompt -DryRun -Install codex,cc-switch -Platform linux"
```

## 验证

运行测试（需要 Pester 5）：

```powershell
Install-Module Pester -Force -Scope CurrentUser -SkipPublisherCheck
Invoke-Pester ./tests/ -Output Detailed
```

## 构建

远程分发使用打包后的单文件 `dist/Noaul.psm1`。本地开发使用 `src/` 下的子模块。

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File ./build.ps1
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
- CC Switch CLI: https://github.com/saladday/cc-switch-cli
- Sub2API repository: https://github.com/Wei-Shaw/sub2api
