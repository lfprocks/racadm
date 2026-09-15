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
 # libargtable2-0: runtime dependency of idracadm7 that Dell's Debian package does not declare.
 && apt-get install -y --no-install-recommends ca-certificates curl gnupg openssl libargtable2-0 \
 && curl -fsSL https://linux.dell.com/repo/pgp_pubkeys/0x1285491434D8786F.asc | gpg --dearmor -o /usr/share/keyrings/dell.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/dell.gpg] https://linux.dell.com/repo/community/openmanage/${OM_VERSION}/${OM_DIST} ${OM_DIST} main" > /etc/apt/sources.list.d/dell.list \
 && apt-get update \
 # The Dell postinst scripts enable a kernel-driver service with systemctl,
 # which does not exist in a container. dpkg runs maintainer scripts with a
 # fixed PATH, so the no-op shim must live in /usr/bin. Belt and braces: if
 # configuration still fails, neuter the scripts and finish configuring.
 && printf '#!/bin/sh\nexit 0\n' > /usr/bin/systemctl && chmod +x /usr/bin/systemctl \
 && (apt-get install -y --no-install-recommends srvadmin-idracadm7 \
     || (for pkg in srvadmin-hapi srvadmin-idracadm7; do printf '#!/bin/sh\nexit 0\n' > /var/lib/dpkg/info/$pkg.postinst; done && dpkg --configure -a)) \
 && rm /usr/bin/systemctl \
 # racadm dlopens the unversioned libssl.so/libcrypto.so names (RAC1170 if
 # absent); point them at the distro's current OpenSSL.
 && cd /usr/lib/x86_64-linux-gnu \
 && ln -s "$(ls libssl.so.* | sort -V | tail -1)" libssl.so \
 && ln -s "$(ls libcrypto.so.* | sort -V | tail -1)" libcrypto.so \
 && cd / \
 && test -x /opt/dell/srvadmin/bin/idracadm7 \
 && ln -s /opt/dell/srvadmin/bin/idracadm7 /usr/local/bin/racadm \
 && apt-get purge -y curl gnupg && apt-get autoremove -y \
 && rm -rf /var/lib/apt/lists/*
# racadm keeps a small cache under $HOME; give the unprivileged user one.
RUN mkdir -p /home/racadm && chown 65534:65534 /home/racadm
ENV HOME=/home/racadm
USER 65534:65534
ENTRYPOINT ["racadm"]
