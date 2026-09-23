# Built on top of the maintainer's own published image instead of compiling
# OpenWebRX+ and all its SDR/decoder dependencies from source. Building from
# source (see attic/docker/Dockerfiles/) pulls in a lot of upstream build
# fragility that isn't ours to fix: Debian bullseye's security repo has been
# decommissioned, redsea dropped its old autotools build, js8call.com's old
# download URL is dead, and SDRplay's download is now behind a CAPTCHA. The
# maintainer's own image (built on their infrastructure) doesn't have those
# problems, and matches this project's version exactly (v1.2.124) — so we
# just layer our Russian-localization / custom-feature changes on top of it.
FROM slechev/openwebrxplus-softmbe:latest

# Paths as installed by the "openwebrx" .deb package inside that image.
COPY htdocs/index.html /usr/lib/python3/dist-packages/htdocs/index.html
COPY owrx/config/defaults.py /usr/lib/python3/dist-packages/owrx/config/defaults.py
COPY owrx/controllers/settings/general.py /usr/lib/python3/dist-packages/owrx/controllers/settings/general.py
COPY owrx/controllers/template.py /usr/lib/python3/dist-packages/owrx/controllers/template.py
COPY owrx/version.py /usr/lib/python3/dist-packages/owrx/version.py
COPY owrx/feature.py /usr/lib/python3/dist-packages/owrx/feature.py
