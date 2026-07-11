# immich / remote-ml

**Runs on the ThinkPad T14 Gen 5, not on woody.** Offloads Immich's machine
learning (CLIP smart search + facial recognition) from woody's weak Athlon 200GE
to this laptop's Ryzen 7 8840U + **Radeon 780M** (RDNA3, gfx1103) via **ROCm**.

woody keeps running its own (CPU) ML container as a fallback; its
`immich-server` lists this laptop first in `machineLearning.urls`, so when the
laptop is on it does the heavy lifting, and when it's off/away jobs fall back to
woody (slow) or queue.

Only image previews are sent here over HTTP — this box does **not** need access
to the photo library. The ML container has **no authentication**, so it must
stay on the trusted home network (LAN / WireGuard), never exposed publicly.

## Requirements

- **Disk**: the `-rocm` image is ~7.9 GB to download and **~18–25 GB extracted**,
  plus the model cache. Make sure `/` has **~25–30 GB free** before pulling
  (`df -h /`). See the repo notes on extending the btrfs-on-LVM root if needed.
- **ROCm compute node**: `/dev/kfd` must exist (it does on this laptop).
- Docker + Docker Compose v2 (present).
- Keep this image on the **same Immich version as woody's `immich-server`**
  (currently `v3.0.2`). Bump both together.

## Setup

```bash
cd immich/remote-ml
docker compose pull          # ~7.9 GB
docker compose up -d
docker compose logs -f       # watch it start
```

woody is already pointed here via `machineLearning.urls` in
`immich/immich-config.json`. Give this laptop a **stable address** (DHCP
reservation for its MAC, or an AdGuard host entry) so the URL doesn't change —
the current IP is baked into that config.

## Verify it's actually using the GPU

```bash
# ROCm should see the GPU as an Agent (gfx1103/gfx1100), not just the CPU:
docker compose exec immich-machine-learning rocminfo | grep -iE 'Name|gfx'

# Trigger a Smart Search / face job from Immich and watch the logs for the ROCm
# execution provider and NO hipError*/fallback-to-CPU messages:
docker compose logs -f immich-machine-learning

# Optional, on the host, watch GPU load during inference:
#   sudo pacman -S radeontop && radeontop
```

The first inference after start is slow (models are compiled for the GPU at
runtime); it speeds up afterwards.

## Troubleshooting (ROCm on the 780M)

- **Won't initialize / HSA errors**: keep `HSA_OVERRIDE_GFX_VERSION=11.0.0`; also
  try adding `HSA_USE_SVM=0` to `environment`.
- **Permission / device errors**: confirm `/dev/kfd` and `/dev/dri/renderD128`
  are accessible; the `group_add` GIDs (render 989, video 985) come from
  `getent group render video` on this host — update them if they differ.
- **Still failing**: add `security_opt: ["seccomp:unconfined"]` to the service
  (some ROCm setups need it). If ROCm just won't cooperate, switch to CPU:
  change the image tag to `ghcr.io/immich-app/immich-machine-learning:v3.0.2`
  and remove `devices`, `group_add` and the `HSA_*` env — still far faster than
  woody thanks to the 16-thread CPU.

## Rollback

Bring it down (`docker compose down`) and woody automatically falls back to its
local ML container. Nothing needs reprocessing when switching ML backends.
