# Project N.O.M.A.D — macOS M-Series Port

> **Knowledge That Never Goes Offline** — running natively on Apple Silicon.

A community port of [Project N.O.M.A.D](https://www.projectnomad.us) for **Apple Silicon Macs (M1, M2, M3, M4)**. The official project targets Linux x86 servers. This port solves the key compatibility issues so the full stack runs on your Mac.

---

## What is Project N.O.M.A.D?

Project N.O.M.A.D is a self-contained, offline server packed with critical tools, knowledge, and AI. Designed for preppers, off-grid living, and anyone who wants access to human knowledge without an internet connection.

| Feature | What you get |
|---|---|
| **AI Chat** | Local LLM inference via Ollama, with document upload and semantic search (RAG) |
| **Offline Library** | Wikipedia, medical references, repair guides, ebooks via Kiwix |
| **Offline Education** | Khan Academy courses with progress tracking via Kolibri |
| **Vector Search** | Qdrant powers RAG so your AI can search your own documents |

---

## What's Different from the Official Version?

| | Official (Linux x86) | This Port (macOS M-series) |
|---|---|---|
| **NOMAD image** | `linux/amd64` native | `linux/amd64` via **Rosetta 2** emulation |
| **Ollama** | Docker container | **Native macOS app** (full GPU/Metal) |
| **AI speed** | Baseline | **5–6× faster** (unified memory + Metal) |
| **Install dir** | `/opt/project-nomad` | `~/project-nomad` |
| **Service manager** | systemd | Docker Compose + optional LaunchAgent |
| **ARM64 images** | Qdrant, Kiwix, Kolibri, Open WebUI ✓ | Same ✓ |

> **Why Rosetta for the main container?**
> The `ghcr.io/crosstalk-solutions/project-nomad` image is currently x86/amd64 only. Docker Desktop on M-series Macs runs it via Rosetta 2 transparently. When an official ARM64 image ships, remove `platform: linux/amd64` from `docker-compose.yml` and run `./scripts/update.sh`.
>
> Track ARM64 support at: https://github.com/Crosstalk-Solutions/project-nomad

---

## System Requirements

| | Minimum | Recommended |
|---|---|---|
| **Mac chip** | M1 | M2 Pro / M3 Pro or better |
| **Unified RAM** | 8 GB | 16–32 GB |
| **Free storage** | 20 GB | 100 GB+ (for offline libraries) |
| **macOS** | 13 Ventura | 14 Sonoma / 15 Sequoia |
| **Docker Desktop** | 4.x | Latest |

---

## Quick Install

```bash
# 1. Clone this repo
git clone https://github.com/josesermeno/project-nomad-macos.git
cd project-nomad-macos

# 2. Make scripts executable
chmod +x install.sh uninstall.sh scripts/*.sh

# 3. Run the installer
./install.sh
```

The installer automatically handles everything: Homebrew, Docker Desktop verification, Rosetta 2, Ollama native install, config setup, and container startup.

📄 **For a full step-by-step walkthrough, see [INSTALL_GUIDE.md](./INSTALL_GUIDE.md)**

---

## Architecture

```
Your M-series Mac
├── Docker Desktop (ARM64 host)
│   ├── project-nomad        [x86 via Rosetta]   :8080  ← Command Center
│   ├── nomad_open_webui     [ARM64 native]       :3000  ← AI Chat UI
│   ├── nomad_qdrant         [ARM64 native]    (internal) ← Vector DB
│   ├── nomad_kiwix          [ARM64 native]       :8888  ← Library (optional)
│   └── nomad_kolibri        [ARM64 native]       :8090  ← Education (optional)
│
└── Native macOS
    └── ollama               [ARM64 + Metal GPU]  :11434 ← LLM inference
                                                          ↑ 5–6× faster than Docker
```

All containers communicate over the `project_nomad_network` bridge. Containers reach native Ollama via `host.docker.internal:11434`.

---

## Services & Ports

| Service | URL | Notes |
|---|---|---|
| **NOMAD Command Center** | http://localhost:8080 | Main management UI |
| **Open WebUI** (AI Chat) | http://localhost:3000 | Chat interface for Ollama |
| **Ollama API** | http://localhost:11434 | Native macOS, GPU-accelerated |
| **Kiwix** | http://localhost:8888 | Offline library (optional — uncomment in compose) |
| **Kolibri** | http://localhost:8090 | Offline education (optional — uncomment in compose) |

---

## Daily Usage

```bash
./scripts/start.sh          # Start everything
./scripts/stop.sh           # Stop everything
./scripts/update.sh         # Update to latest NOMAD version
./scripts/check-deps.sh     # Health check all dependencies and services

# Container management
cd ~/project-nomad && docker compose ps         # Status
cd ~/project-nomad && docker compose logs -f    # Live logs
```

---

## Adding AI Models

```bash
ollama pull llama3             # 4.7 GB — best all-around (16 GB RAM+)
ollama pull mistral            # 4.1 GB — fast and capable
ollama pull phi3:mini          # 2.3 GB — lightweight (great for 8 GB RAM)
ollama pull nomic-embed-text   # 274 MB — required for document search (RAG)
ollama list                    # see all installed models
```

Browse all models at [ollama.com/library](https://ollama.com/library).

---

## Adding Offline Library Content (Kiwix)

1. Download `.zim` files from [library.kiwix.org](https://library.kiwix.org/)
2. Place them in `~/project-nomad/zim/`
3. Uncomment the `kiwix` service in `docker-compose.yml`
4. Restart: `cd ~/project-nomad && docker compose up -d`
5. Access at http://localhost:8888

Popular content: Wikipedia (~22 GB no pics / ~90 GB with pics), iFixit repair guides (~8 GB), MedlinePlus medical reference (~2 GB), Project Gutenberg ebooks (~65 GB).

---

## Auto-Start on Login

```bash
# Enable
cp LaunchAgent/com.projectnomad.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.projectnomad.plist

# Disable
launchctl unload ~/Library/LaunchAgents/com.projectnomad.plist
rm ~/Library/LaunchAgents/com.projectnomad.plist
```

---

## Upgrading to Native ARM64 (When Available)

When the upstream project releases an official ARM64 image:

1. In `docker-compose.yml`, under the `nomad` service, remove: `platform: linux/amd64`
2. Run `./scripts/update.sh`

---

## Troubleshooting

| Problem | Fix |
|---|---|
| NOMAD takes 60+ seconds to start | Normal on first launch via Rosetta — wait and reload |
| "Cannot connect to Docker daemon" | Open Docker Desktop, wait for whale icon to stop animating |
| AI is slow / Ollama not found | Run `curl http://localhost:11434` — if nothing, open Ollama.app or run `ollama serve` |
| "exec format error" on start | Enable Rosetta in Docker Desktop → Settings → General |
| Port conflict | Edit `~/project-nomad/.env`, change `NOMAD_PORT` or `OPEN_WEBUI_PORT`, then restart |

---

## Project Files

```
project-nomad-macos/
├── install.sh                     # One-command macOS M-series installer
├── uninstall.sh                   # Clean uninstaller
├── docker-compose.yml             # Mac-specific compose (Rosetta + native Ollama)
├── .env.example                   # Configuration template
├── INSTALL_GUIDE.md               # Full step-by-step installation guide
├── scripts/
│   ├── start.sh                   # Start all services
│   ├── stop.sh                    # Stop all services
│   ├── update.sh                  # Update to latest version
│   └── check-deps.sh              # Health check all dependencies
└── LaunchAgent/
    └── com.projectnomad.plist     # macOS auto-start on login
```

---

## Credits

- [Project N.O.M.A.D](https://www.projectnomad.us) by [Crosstalk Solutions](https://github.com/Crosstalk-Solutions/project-nomad) — the original project
- [Ollama](https://ollama.com) - local LLM runner with Apple Silicon GPU support
- [Open WebUI](https://github.com/open-webui/open-webui) — browser-based AI chat UI	- [Kiwix](https://kiwix.org) - offline Wikipedia and knowledge library
- [Kolibri](https://learningequality.org/kolibri/) - offline education platform
- [Qdrant](https://qdrant.tech) — vector database for semantic search

---

## License

This port is released under the same license as the upstream project. See the [original repository](https://github.com/Crosstalk-Solutions/project-nomad) for license details.
