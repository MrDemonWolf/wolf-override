# Godot 4.7.2 in a Linux container with a virtual screen (Xvfb) and software OpenGL (Mesa llvmpipe),
# so rendered captures never open a window on the host machine. See tools/render/README.md.
FROM debian:bookworm-slim

ARG GODOT_VERSION=4.7.2
ARG GODOT_SHA512_ARM64=dd59918da086bd49bde2f5450b5e567ff8650cbde9abbd7b8f4ca1197ff8c609baa38834666d032deafb47099078d7822279e2a0e06e5665745468f26533e7e2
ARG GODOT_SHA512_X86_64=9aa00f7a605200940bce3027a567b782f49bd8e940dd06ae9e987bd65aee1b1467edd56ed84fcdcbdd44354bf613bdbb4e5d2913e925850368e150c59ed54c65

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip xvfb xauth \
      libgl1 libgl1-mesa-dri libglx-mesa0 libegl1 libgles2 \
      libx11-6 libxcursor1 libxinerama1 libxrandr2 libxi6 libxext6 libxrender1 libxkbcommon0 \
      libasound2 libpulse0 libfontconfig1 libdbus-1-3 libudev1 \
 && rm -rf /var/lib/apt/lists/*

RUN set -eux; \
    case "$(dpkg --print-architecture)" in \
      arm64) build=linux.arm64; sum="$GODOT_SHA512_ARM64" ;; \
      amd64) build=linux.x86_64; sum="$GODOT_SHA512_X86_64" ;; \
      *) echo "unsupported architecture" >&2; exit 1 ;; \
    esac; \
    zip="Godot_v${GODOT_VERSION}-stable_${build}.zip"; \
    curl -fsSL --retry 3 -o "/tmp/$zip" "https://github.com/godotengine/godot-builds/releases/download/${GODOT_VERSION}-stable/$zip"; \
    echo "$sum  /tmp/$zip" | sha512sum -c -; \
    unzip -q "/tmp/$zip" -d /tmp/godot; \
    mv "/tmp/godot/Godot_v${GODOT_VERSION}-stable_${build}" /usr/local/bin/godot; \
    chmod +x /usr/local/bin/godot; \
    rm -rf /tmp/godot "/tmp/$zip"

# The container's own throwaway user data: nothing reaches the host's Godot settings or saves.
ENV HOME=/home/render \
    XDG_DATA_HOME=/home/render/.local/share \
    XDG_CONFIG_HOME=/home/render/.config \
    LIBGL_ALWAYS_SOFTWARE=1
RUN mkdir -p /home/render/.local/share /home/render/.config && chmod -R a+rwX /home/render
WORKDIR /work
