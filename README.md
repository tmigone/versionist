# versionist GitHub action

This action provides automatic Semver versioning and changelog generation. Useful to handle versioning in continuous delivery workflows that use NPM or Docker deployments.
 
The following actions are taken sequentially:

- Run `balena-versionist`. This will update `CHANGELOG.md`, `VERSION`, `package.json`, etc files accordingly.
- Add a new commit to the working branch with the versioning changes
- Create a release tag corresponding to the new version
- Push changes and tags to master

Read more about the opinionated versioning here:
- [versionist](https://github.com/balena-io/versionist)
- [balena-versionist](https://github.com/balena-io/balena-versionist)

## Inputs

### `branch`

**Not required** Name of the branch where versioning should be applied. Default: master.

### `github_email`

**Required** The email address to be associated with the generated commits.

### `github_username`

**Required** The username to be associated with the generated commits.

### `github_token`

**Required** The GitHub token to authenticate. Automatically set by `${{ secrets.GITHUB_TOKEN }}`. This is required to push the version update and tag.

## Example usage

Here is a sample action workflow:

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
    - name: Checkout project
      uses: actions/checkout@v2
      with:
        fetch-depth: 0                            # We need all commits and tags
    - name: Run versionist
      uses: tmigone/versionist@master
      with:
        github_email: 'tomasmigone@gmail.com'
        github_username: 'Tomás Migone'
        github_token: ${{ secrets.GITHUB_TOKEN }} # This token is automatically provided by Actions, you do not need to create your own token
```

You should include at least one commit with a `Change-type: patch | minor | major` footer tag in the comments, example:

```
feature: Fixed a bug with xyz

Change-type: patch
```