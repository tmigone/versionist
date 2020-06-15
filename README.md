# balena-versionist GitHub action

This action provides automatic versioning and changelog generation by running `balena-versionist` utility.

In a nutshell, this action will:

- Run `balena-versionist`. This will update `CHANGELOG.md`, `VERSION`, `package.json`, etc files accordingly.
- Commit changes
- Create tag corresponding to the new version
- Push changes and tags to master

Read more about versionist here:
- [versionist](https://github.com/balena-io/versionist)
- [balena-versionist](https://github.com/balena-io/balena-versionist)

## Inputs

### `github_email`

**Required** The email address to be associated with the generated commits.

### `github_username`

**Required** The username to be associated with the generated commits.

### `github_token`

**Required** The GitHub token to authenticate. Can be passed in using `${{ secrets.GITHUB_TOKEN }}`

## Example usage

```yaml
name: Run balena versionist
on:
  push:
    branches:
      - master

jobs:
  balena-versionist:
    runs-on: ubuntu-latest
    steps: 
    - uses: actions/checkout@v1
    - uses: tmigone/balena-versionist-action@latest
      with:
        github_email: 'tomasmigone@gmail.com'
        github_username: 'Tomás Migone'
        github_token: ${{ secrets.GITHUB_TOKEN }}
```
