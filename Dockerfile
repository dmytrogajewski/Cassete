# syntax=docker/dockerfile:1

ARG APP_VERSION=0.0.0

FROM fedora:43 AS deps

USER root

# Disable Cisco OpenH264 repo to avoid 403s during CI and skip weak deps
RUN sed -i 's/^enabled=.*/enabled=0/' /etc/yum.repos.d/fedora-cisco-openh264.repo || true && \
  dnf -y install --setopt=install_weak_deps=False --exclude=openh264 \
    appstream \
    bubblewrap \
    desktop-file-utils \
    gettext \
    git \
    gcc \
    gcc-c++ \
    meson \
    ninja-build \
    pkgconf-pkg-config \
    vala \
    blueprint-compiler \
    python3-pip \
    glib2-devel \
    gtk4-devel \
    libadwaita-devel \
    libgee-devel \
    json-glib-devel \
    libsoup3-devel \
    libxml2-devel \
    sqlite-devel \
    webkitgtk6.0-devel \
    gstreamer1-devel \
    gstreamer1-plugins-base-devel \
    gstreamer1-plugins-bad-free-devel \
    libepoxy-devel \
    rpm-build \
    ruby \
    ruby-devel \
    rubygem-json \
    rubygems \
    xdg-dbus-proxy \
  && dnf clean all && rm -rf /var/cache/dnf/* && \
  gem install --no-document fpm

FROM deps AS builder
ARG APP_VERSION
ENV APP_VERSION=${APP_VERSION}
WORKDIR /app
COPY . .

RUN meson setup build --buildtype=release --prefix=/usr && \
    ninja -C build && \
    ninja -C build test && \
    BUILD_DIR=build ./scripts/package.sh

FROM ubuntu:24.04 AS artifacts
WORKDIR /dist
COPY --from=builder /app/build/package /dist/package

CMD ["bash"]

