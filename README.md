# racadm

Dell remote RACADM (`idracadm7`) in a container, installed from Dell's public
[OpenManage apt repository](https://linux.dell.com/repo/community/openmanage/).
Used by the homelab to push certificates into iDRACs.

| Tag | OpenManage | Base | Notes |
| --- | --- | --- | --- |
| `9.5.0`, `latest` | 9.5.0 | Ubuntu 20.04 | Last release documenting iDRAC7/8 (12G/13G) support |
| `11.0.1` | 11.0.1.0 | Ubuntu 22.04 | Current line, iDRAC9 |

```
docker run --rm ghcr.io/lfprocks/racadm:9.5.0 -r 10.0.0.9 -u root -p '...' --nocertwarn getsysinfo
```

Runs as uid 65534; `racadm` is the entrypoint. Rebuilt weekly.
