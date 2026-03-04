# gozba

## Project
Ruby/Jekyll site using Bundler. Lock file: `Gemfile.lock`. Default branch: `master`.
Uses `github-pages` gem which pins many transitive dependencies.

## Security patching (last patched: 2026-03-04)
- `nokogiri` is a **direct** dependency in Gemfile (was `~> 1.18.3`, updated to `~> 1.19`)
- `faraday` is **transitive** (via github-pages -> jekyll-github-metadata -> octokit -> sawyer)

### How to patch future vulnerabilities
```bash
bundle audit                           # check for vulnerabilities (install bundler-audit gem first)
# For direct deps: edit version constraint in Gemfile, then:
bundle update <gem-name>
# For transitive deps:
bundle update <gem-name>               # update specific gem
bundle update                          # update all gems if needed
bundle exec jekyll build --safe        # verify site still builds
```

### Caveats
- The `github-pages` gem tightly constrains many sub-dependencies. If `bundle update` fails due to version conflicts, check if `github-pages` has a newer release that allows the patched version.
- If `github-pages` blocks an update, you can add the gem directly to `Gemfile` with `>=` constraint to override, but test carefully.
