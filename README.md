# versionist GitHub action

This action provides automatic Semver versioning, changelog generation and continuous delivery for NPM and docker projects.
 
The following actions are taken sequentially:

- Run `balena-versionist`. This will update `CHANGELOG.md`, `VERSION`, `package.json`, etc files accordingly.
- Add a new commit to the working branch with the versioning changes
- Create a release tag corresponding to the new version
- Push changes and tags to master
- For node packages, if an NPM auto token is provided: publish package to NPM

Read more about the opinionated versioning here:
- [versionist](https://github.com/balena-io/versionist)
- [balena-versionist](https://github.com/balena-io/balena-versionist)

## Inputs

### `branch`

**Not required** NPM token to use for publishing to the NPM registry.

### `github_email`

**Required** The email address to be associated with the generated commits.

### `github_username`

**Required** The username to be associated with the generated commits.

### `github_token`

**Required** The GitHub token to authenticate. Automatically set with `${{ secrets.GITHUB_TOKEN }}`. This is required to push the version update and tag.

### `npm_token`

**Not required** NPM token to use for publishing to the NPM registry.


## Example usage

```yaml
name: Run versionist
on:
  push:
    branches:
      - master

jobs:
  versionist:
    runs-on: ubuntu-latest
    steps: 
    - uses: actions/checkout@v1
    - uses: tmigone/versionist@master
      with:
        github_email: 'tomasmigone@gmail.com'
        github_username: 'Tomás Migone'
        github_token: ${{ secrets.GITHUB_TOKEN }}
        npm_token: ${{ secrets.NPM_TOKEN }}
```
