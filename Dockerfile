# Dell remote RACADM (idracadm7) from Dell's public OpenManage apt repository,
# for pushing certificates and running commands against iDRACs from a
# container. Build args pick the OpenManage release; 9.5.0 is the last line
# that documents 12G/13G (iDRAC7/8) support.
ARG BASE=ubuntu:20.04
FROM ${BASE}
ARG OM_VERSION=950
ARG OM_DIST=focal
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg openssl \
 && curl -fsSL https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc | gpg --dearmor -o /usr/share/keyrings/dell.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/dell.gpg] https://linux.dell.com/repo/community/openmanage/${OM_VERSION}/${OM_DIST} ${OM_DIST} main" > /etc/apt/sources.list.d/dell.list \
 && apt-get update \
 # srvadmin-hapi's postinst enables a kernel-driver service (instsvcdrv) via
 # systemctl, which does not exist in a container and fails the install. The
 # racadm binary itself needs none of that: if configuration fails, neuter the
 # postinst and finish configuring.
 && (apt-get install -y --no-install-recommends srvadmin-idracadm7 \
     || (printf '#!/bin/sh\nexit 0\n' > /var/lib/dpkg/info/srvadmin-hapi.postinst && dpkg --configure -a)) \
 && test -x /opt/dell/srvadmin/bin/idracadm7 \
 && ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/local/bin/racadm \
 && apt-get purge -y curl gnupg && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*
# racadm keeps a small cache under $HOME; give the unprivileged user one.
RUN mkdir -p /home/racadm && chown 65534:65534 /home/racadm
ENV HOME=/home/racadm
USER 65534:65534
ENTRYPOINT ["racadm"]
