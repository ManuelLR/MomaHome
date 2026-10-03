# restic + an rclone built from the unmerged Funambol / OneMediaHub backend.
#
# Stock rclone cannot talk to O2 Cloud (Spain) yet. The backend comes from
# https://github.com/rclone/rclone/pull/9536 (fballiano/rclone, branch
# funambol-backend), pinned to a full commit so every build is the same binary.
# Renovate proposes a PR when the branch moves; read the PR's new commits before
# merging. Once rclone ships the backend
# in a release (upstream may rename it to `onemediahub`), replace this stage with
# the official binary and reconfigure the remote; the restic repository itself
# does not change.

FROM golang:1.26-alpine AS rclone

ARG RCLONE_REPO=https://github.com/fballiano/rclone.git
# renovate: datasource=git-refs depName=fballiano/rclone packageName=https://github.com/fballiano/rclone branch=funambol-backend
ARG RCLONE_COMMIT=d653fdc9a7c38df59936f69a6cf7189d326dfa87

RUN apk add --no-cache git

WORKDIR /src
RUN git init -q \
    && git remote add origin "$RCLONE_REPO" \
    && git fetch -q --depth 1 origin "$RCLONE_COMMIT" \
    && git checkout -q FETCH_HEAD

RUN CGO_ENABLED=0 go build -trimpath \
        -ldflags "-s -w -X github.com/rclone/rclone/fs.Version=v1.76.0-funambol-${RCLONE_COMMIT}" \
        -o /out/rclone . \
    && /out/rclone version

# Alpine-based; ENTRYPOINT is restic. Ships ca-certificates and fuse already.
FROM restic/restic:0.19.1

RUN apk add --no-cache bash tzdata

COPY --from=rclone /out/rclone /usr/local/bin/rclone
