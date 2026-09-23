# Built on top of the maintainer's own published image instead of compiling
# OpenWebRX+ and all its SDR/decoder dependencies from source. Building from
# source pulls in a lot of upstream build fragility that isn't ours to fix:
# Debian bullseye's security repo has been decommissioned, redsea dropped
# its old autotools build, js8call.com's old download URL is dead, and
# SDRplay's download is now behind a CAPTCHA. The maintainer's own image
# (built on their infrastructure) doesn't have those problems.
#
# Our Russian-localization changes are applied as a *patch* (patches/ru-
# localization.patch) against whatever those files currently look like in
# the base image, rather than overwriting them outright. This means a
# routine upstream version bump keeps working automatically (the patch
# still applies, our changes just layer on top of their latest code), and
# if the maintainer ever restructures those specific files enough that the
# patch no longer applies cleanly, the build fails loudly right here
# instead of silently reverting their changes back to our old snapshot.
#
# To refresh patches/ru-localization.patch after editing the tracked files
# (see the list in the RUN step below), regenerate it against a fresh pull
# of the base image — see DEPLOY-RU.md / the project README for the exact
# steps used to produce it.
FROM slechev/openwebrxplus-softmbe:latest

COPY patches/ru-localization.patch /tmp/ru-localization.patch
RUN cd /usr/lib/python3/dist-packages && \
    patch -p1 --fuzz=0 < /tmp/ru-localization.patch && \
    rm /tmp/ru-localization.patch
