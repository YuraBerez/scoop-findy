# Scoop bucket for Findy

[Findy](https://github.com/YuraBerez/findy) is a private, local-first kanban board for a
job search. This bucket installs it on Windows 10/11 (64-bit) for your user, without
administrator rights.

```powershell
scoop bucket add findy https://github.com/YuraBerez/scoop-findy
scoop install findy
```

Update with `scoop update findy`. Your board is kept in `%APPDATA%\Findy`: it stays when
you update or uninstall Findy.

## First start

Findy is not code-signed yet, so Windows SmartScreen may ask once: click **More info →
Run anyway**.

## How the manifest is updated

[`update.sh`](update.sh) runs every day ([workflow](.github/workflows/update.yml)). It
reads the latest **published** release of Findy, downloads the portable ZIP, checks it
against the release's `SHA256SUMS.txt`, and commits the new version and hash. A missing
file or a wrong sum stops the update. The first release with a portable build is 0.4.1.

To check a download yourself:
`gh attestation verify Findy-<version>-Windows-portable.zip --repo YuraBerez/findy`.
