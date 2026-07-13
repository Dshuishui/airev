# Publishing airev

`airev` ships three ways: `curl | bash` (works today), **npm**, and **Homebrew**.
Keep the version in three places in sync when you cut a release:

- `airev` → `AIREV_VERSION="X.Y.Z"`
- `package.json` → `"version": "X.Y.Z"`
- `Formula/airev.rb` → `url` tag + `version` + `test` string

## Cut a release

```bash
git tag vX.Y.Z && git push --tags
```

## npm

The `bin` field installs the `airev` script as a global command — no build step.

```bash
npm pack --dry-run          # sanity-check the tarball contents
npm publish                 # requires `npm login`
```

Then users install with:

```bash
npm install -g airev        # or: npx airev review
```

> If the name `airev` is already taken on the npm registry, publish under a scope
> (`@dshuishui/airev`) — the installed command stays `airev` either way, since it
> comes from the `bin` map, not the package name.

## Homebrew

Homebrew needs the sha256 of the **GitHub-generated** release tarball (not a local
`git archive` — the bytes differ). After pushing the tag:

```bash
curl -fsSL https://github.com/Dshuishui/airev/archive/refs/tags/vX.Y.Z.tar.gz \
  | shasum -a 256
```

Paste that into `Formula/airev.rb` (`sha256`) and bump its `url`/`version`.

Serve it from a tap repo named `homebrew-tap`:

```bash
# one-time: create github.com/Dshuishui/homebrew-tap, then
cp Formula/airev.rb /path/to/homebrew-tap/Formula/airev.rb
# commit + push the tap
```

Users then install with:

```bash
brew install Dshuishui/tap/airev
```

`brew audit --new --formula Formula/airev.rb` before publishing catches most issues.
