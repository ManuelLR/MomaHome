# immich / remote-ml

Optional Immich machine-learning worker (CLIP smart search + facial recognition)
for a spare machine with an AMD RDNA3 iGPU, offloading the work from the server's
CPU. Keep it on the **same Immich version** as `immich-server`, `docker compose up -d`,
and add `http://<host>:3003` to `machineLearning.urls` in `../immich-config.json`.

The container has **no authentication**: LAN / WireGuard only, never public. It
only receives image previews, so it needs no access to the photo library. If ROCm
misbehaves, drop the `-rocm` suffix, `devices`, `group_add` and `HSA_*` to fall
back to CPU.
