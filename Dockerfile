# Combined multi-stage build (base deps + full app) so a single
# `docker compose build` / Dockge stack can build the whole image
# without a separate two-step `docker build` dance.
#
# Build context must be the repository root (this file's directory),
# because both stages COPY from ./docker/... — that path is a symlink
# to attic/docker/ kept for this reason; keep it when you push to git.

FROM debian:bullseye-slim AS base
ARG MAKEFLAGS

COPY docker/files/js8call/js8call-hamlib.patch \
     docker/files/wsjtx/wsjtx.patch \
     docker/files/wsjtx/wsjtx-hamlib.patch \
     docker/files/dream/dream.patch \
     docker/files/direwolf/direwolf-hamlib.patch \
     docker/scripts/add-dependencies.sh /
RUN /add-dependencies.sh && \
    rm /add-dependencies.sh && \
    rm /*.patch
COPY docker/scripts/add-owrx-tools.sh /
RUN /add-owrx-tools.sh && \
    rm /add-owrx-tools.sh

COPY docker/files/services/codecserver /etc/services.d/codecserver

ENTRYPOINT ["/init"]

WORKDIR /opt/openwebrx

VOLUME /etc/openwebrx
VOLUME /var/lib/openwebrx

ENV S6_CMD_ARG0="/opt/openwebrx/docker/scripts/run.sh"
CMD []

EXPOSE 8073


FROM base AS full
ARG MAKEFLAGS

COPY docker/scripts/install-*.sh \
     docker/files/sdrplay/install-lib.*.patch /

RUN export FULL_BUILD=1 && \
    for x in $(ls -1 /install-*.sh | sort -n); do \
      echo "installing $x" && \
      $x || exit 1; \
    done && \
    for x in $(ls -1 /install-*.sh | sort -n); do \
      echo "cleaning $x" && \
      $x clean; \
    done && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm /install-*.sh && \
    rm /install-lib.*.patch

COPY docker/files/services/sdrplay /etc/services.d/sdrplay

COPY docker/scripts/run.sh /

# this build-arg will reset the cache here, so we will have a fresh copy of the files
ARG GIT_HASH=0
RUN echo "$GIT_HASH" > /build-hash
RUN date > /build-date
RUN date +%s > /build-stamp

ADD . /opt/openwebrx
