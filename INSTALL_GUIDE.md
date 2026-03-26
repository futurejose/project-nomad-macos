# Project N.O.M.A.D — macOS M-Series Installation Guide

**Step-by-step setup for Apple Silicon (M1, M2, M3, M4)**

> Estimated time: 20–40 minutes | Requires macOS 13 Ventura or later

---

## Overview

This guide walks through installing Project N.O.M.A.D on an M-series Mac from scratch. The setup installs:

- **Homebrew** — macOS package manager
- **Docker Desktop** — container runtime for the NOMAD stack
- **Rosetta 2** — x86 emulation for the NOMAD Command Center image
- **Ollama** (native) — local AI engine that uses your GPU via Metal
- **The NOMAD stack** — Command Center, Open WebUI, Qdrant, and optional services

### Why native Ollama?

Running Ollama inside Docker on a Mac means it can only use the CPU — Docker Desktop cannot access the Apple GPU. Running Ollama natively lets it use Metal and your M-chip's unified memory architecture, giving **5–6× faster AI responses** at no extra cost.

---

## Before You Begin

### System Requirements

| | Minimum | Recommended |
|---|---|---|
| Mac chip | M1 | M2 Pro / M3 Pro or better |
| Unified RAM | 8 GB | 16–32 GB |
| Free storage | 20 GB | 100 GB+ (for offline libraries) |
| macOS | 13 Ventura | 14 Sonoma / 15 Sequoia |

### Pre-flight checklist

- [ ] You have administrator access on this Mac
- [ ] At least 20 GB of free disk space
- [ ] Mac is plugged in (downloads can be large)
- [ ] Stable internet connection for the initial setup
- [ ] ~30–40 minutes available

> **Note on storage:** The base install uses ~5 GB. AI models add 2–15 GB each. Offline Wikipedia ZIM files are 20–90 GB. You can add these later.

---

## Step 1: Install Homebrew

Homebrew is the package manager for macOS, used to install Ollama and other tools.

### 1.1 Open Terminal

Press **⌘ + Space** to open Spotlight, type **Terminal**, and press Enter.

### 1.2 Install Homebrew

Paste this into Terminal and press Enter:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

You will be prompted for your Mac password. Type it and press Enter (the cursor will not move — this is normal). The installation takes 3–5 minutes.

### 1.3 Add Homebrew to your PATH

After installation finishes, Terminal shows a **"Next steps"** section with two commands to run. They look like this (your username will differ):

```bash
(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Copy and run both commands exactly as shown in your Terminal output.

### 1.4 Verify

```bash
brew --version
```

You should see `Homebrew 4.x.x` or similar. If so, Homebrew is ready.

> **Already have Homebrew?** Just run `brew update` and skip to Step 2.

---

## Step 2: Install Docker Desktop

Docker Desktop runs the containerized services (NOMAD Command Center, chat interface, database).

### 2.1 Download

Visit **https://www.docker.com/products/docker-desktop/** and click **"Download for Mac — Apple Silicon"**. Make sure you choose Apple Silicon, not Intel.

### 2.2 Install

1. Open the downloaded `.dmg` file
2. Drag **Docker.app** to your Applications folder
3. Open Docker from Applications (or Spotlight: `Docker`)
4. Click **Open** when prompted about running the application
5. Follow the setup wizard — you may be asked for your password
6. Wait for the **whale icon** to appear in your menu bar and stop animating

> **First launch is slow.** Docker Desktop can take 1–2 minutes to start. Wait until the whale icon stops animating before continuing.

### 2.3 Verify

```bash
docker --version && docker info | grep 'Server Version'
```

You should see Docker version and server information. If you see `"Cannot connect to the Docker daemon"`, wait a moment and try again.

---

## Step 3: Enable Rosetta 2 in Docker Desktop

> ⚠️ **Do not skip this step.** Without Rosetta enabled, the NOMAD container will fail with an `"exec format error"`.

The main NOMAD Command Center Docker image is currently x86-only. Rosetta 2 lets Docker Desktop run it on your M-series chip.

### 3.1 Enable the setting

1. Click the whale icon in the menu bar → **Settings** (or press **⌘,**)
2. Click **General** in the left sidebar
3. Find: **"Use Rosetta for x86/amd64 emulation on Apple Silicon"**
4. Make sure the checkbox is **checked** (enabled)
5. Click **Apply & Restart** at the bottom right
6. Wait for Docker Desktop to restart

### 3.2 Install Rosetta 2 on macOS (if needed)

Most Macs already have it. To install or verify:

```bash
softwareupdate --install-rosetta --agree-to-license
```

If it says already installed, you're all set.

---

## Step 4: Install Ollama (Native)

Ollama is the engine that runs AI language models locally. We install it natively so it can access your M2's GPU via Metal.

### 4.1 Install via Homebrew

```bash
brew install --cask ollama
```

This downloads and installs Ollama.app (~1–2 minutes).

### 4.2 Start Ollama

Open **Ollama** from your Applications folder (or Spotlight: `Ollama`). A small llama icon will appear in your menu bar. Ollama runs silently in the background.

Alternatively, start from Terminal:

```bash
ollama serve
```

### 4.3 Verify Ollama is running

```bash
curl http://localhost:11434
```

Expected output: `Ollama is running`

> **Ollama auto-starts after the first time.** Once installed, the Ollama app launches automatically when you log in.

### 4.4 Pull your first AI model

| Model | Size | Best for |
|---|---|---|
| `llama3` | 4.7 GB | General use — great balance of speed and quality |
| `mistral` | 4.1 GB | Fast responses, strong reasoning |
| `phi3:mini` | 2.3 GB | Lightweight — ideal for 8 GB RAM Macs |
| `nomic-embed-text` | 274 MB | **Required for document search (RAG) — always install this** |

For an M2 with 16+ GB RAM:

```bash
ollama pull llama3
ollama pull nomic-embed-text   # needed for document search
```

`llama3` is ~4.7 GB, so allow 5–10 minutes on a typical connection.

### 4.5 Test the model

```bash
ollama run llama3
```

Type a message and press Enter. You should get a response in a few seconds. Press **Ctrl+D** to exit.

---

## Step 5: Get the Project Files

### Option A: Clone with Git (recommended)

```bash
git clone https://github.com/josesermeno/project-nomad-macos.git
cd project-nomad-macos
```

### Option B: Download ZIP

1. Download `project-nomad-macos.zip`
2. Double-click to extract
3. Move to a convenient location (Desktop or Documents)
4. In Terminal: `cd ~/Desktop/project-nomad-macos`

### Make scripts executable

```bash
chmod +x install.sh uninstall.sh scripts/*.sh
```

---

## Step 6: Configure Your Settings

The `.env` file controls ports and timezone. For most users, **the defaults work perfectly and no changes are needed** — the installer creates this file automatically.

| Setting | Default | Description |
|---|---|---|
| `NOMAD_PORT` | `8080` | NOMAD Command Center web UI |
| `OPEN_WEBUI_PORT` | `3000` | AI chat interface |
| `KIWIX_PORT` | `8888` | Offline library (optional) |
| `KOLIBRI_PORT` | `8090` | Offline education (optional) |
| `TZ` | `America/New_York` | Your local timezone |
| `OLLAMA_BASE_URL` | `http://host.docker.internal:11434` | Points to native Ollama (do not change) |

**To change a port** (only if something else is already using 8080 or 3000):

```bash
nano ~/project-nomad/.env
# Change NOMAD_PORT=8081 or OPEN_WEBUI_PORT=3001
```

---

## Step 7: Run the Installer

With all prerequisites in place, run the installer:

```bash
./install.sh
```

The installer walks through these stages automatically:

| Stage | What happens |
|---|---|
| Platform check | Confirms you're on Apple Silicon (arm64) |
| Homebrew check | Verifies Homebrew is present |
| Docker check | Confirms Docker Desktop is running |
| Rosetta check | Installs Rosetta 2 if needed |
| Ollama check | Verifies Ollama is running at :11434 |
| Directory setup | Creates `~/project-nomad/` with all config files |
| Image pull | Downloads NOMAD and supporting Docker images (~2–3 GB) |
| Start | Starts all containers in the background |

> **Image download takes time.** First run downloads ~2–3 GB total. This takes 5–15 minutes depending on your connection. Subsequent starts are instant.

### Confirm success

The installer prints a summary when done:

```
==> Installation Complete!

  NOMAD Command Center:  http://localhost:8080
  Open WebUI (AI Chat):  http://localhost:3000
  Ollama API:            http://localhost:11434
```

Open **http://localhost:8080** in your browser to access the NOMAD Command Center.

---

## Step 8: Verify the Installation

Run the built-in health check:

```bash
./scripts/check-deps.sh
```

Expected output:

```
Platform:
  ✓ macOS detected
  ✓ Apple Silicon (arm64)
  ✓ Rosetta 2 available

Core dependencies:
  ✓ Homebrew installed
  ✓ Docker CLI installed
  ✓ Docker Desktop running
  ✓ docker compose (v2)

Services:
  ✓ Ollama running (port 11434)
  ✓ NOMAD UI running (port 8080)
  ✓ Open WebUI running (port 3000)

All checks passed! (9/9)
```

### Check container status

```bash
cd ~/project-nomad && docker compose ps
```

All containers should show `running`. The NOMAD container may show `starting` for up to 60 seconds on first launch — this is normal (it's running via Rosetta emulation).

### Access the interfaces

| Interface | URL |
|---|---|
| NOMAD Command Center | http://localhost:8080 |
| Open WebUI (AI Chat) | http://localhost:3000 |
| Ollama API | http://localhost:11434 |

---

## Optional: Enable the Offline Library (Kiwix)

Kiwix lets you browse Wikipedia, medical references, ebooks, and more — completely offline.

### Download ZIM content files

Visit **https://library.kiwix.org/** and download the content you want:

| Content | Approx. Size | Recommended? |
|---|---|---|
| Wikipedia (English, no pictures) | ~22 GB | ✓ Essential reference |
| Wikipedia (English, with pictures) | ~90 GB | Optional (needs large drive) |
| iFixit (repair & how-to guides) | ~8 GB | ✓ Great for off-grid |
| MedlinePlus (US medical reference) | ~2 GB | ✓ Highly recommended |
| Project Gutenberg (ebooks) | ~65 GB | Optional |

### Set up Kiwix

```bash
mv ~/Downloads/*.zim ~/project-nomad/zim/
nano ~/project-nomad/docker-compose.yml
# Remove the # from each line under "# kiwix:" and its settings
cd ~/project-nomad && docker compose up -d
```

Kiwix will be available at **http://localhost:8888**.

---

## Optional: Auto-Start on Login

```bash
cp LaunchAgent/com.projectnomad.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.projectnomad.plist
```

**To disable auto-start:**

```bash
launchctl unload ~/Library/LaunchAgents/com.projectnomad.plist
rm ~/Library/LaunchAgents/com.projectnomad.plist
```

---

## Day-to-Day Usage

```bash
./scripts/start.sh      # Start everything
./scripts/stop.sh       # Stop everything
./scripts/update.sh     # Update to latest NOMAD sversion
./scripts/check-deps.sh # Verify all services are healthy
```

### Adding more AI models

```bash
ollama pull mistral           # 4.1 GB — fast and capable
ollama pull gemma:7b          # 5.0 GB — Google's model
ollama pull phi3:mini         # 2.3 GB — great for low RAM
ollama list                   # see all installed models
```

### Recommended models by RAM

| Unified RAM | Recommended models |
|---|---|
| 8 GB | `phi3:mini`, `gemma:2b` |
| 16 GB | `llama3`, `mistral`, `gemma:7b` |
| 32 GB+ | `llama3:70b-q4`, `mixtral` |

---

## Troubleshooting

### NOMAD container takes 60+ seconds to start

Expected on first launch. Wait and reload http://localhost:8080.

### "Cannot connect to Docker daemon"

Open Docker Desktop, wait for whale icon to stop animating.

### AI responses are slow / Ollama not found

```bash
curl http://localhost:11434       # Should return: "Ollama is running"
pgrep -l ollama                    # Should show the ollama process
```

### "exec format error" when starting NOMAD

**Docker Desktop → Settings ing → General → enable "Use Rosetta for x86/amd64 emulation on Apple Silicon" → Apply & Restart**

### Port conflict

```bash
nano ~/project-nomad/.env
cd ~/project-nomad && docker compose down && docker compose up -d
```

---

## Quick Reference

| Service | URL |
|---|---|
| NOMAD Command Center | http://localhost:8080 |
| Open WebUI (AI Chat) | http://localhost:3000 |
| Ollama API | http://localhost:11434 |
| Kiwix Library | http://localhost:8888 (optional) |
| Kolibri Education | http://localhost:8090 (optional) |
