# versionist GitHub action

This action provides automatic Semver versioning, changelog generation and continuous delivery for NPM and docker projects.
 
The following actions are taken sequentially:

- Run `balena-versionist`. This will update `CHANGELOG.md`, `VERSION`, `package.json`, etc files accordingly.
- Add a new commit to the working branch with the versioning changes
- Create a release tag corresponding to the new version
- Push changes and tags to master
- For node projects, publish package to NPM
- For docker projects, publish package to DockerHub

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

**Required** The GitHub token to authenticate. Automatically set by `${{ secrets.GITHUB_TOKEN }}`. This is required to push the version update and tag.

### `npm_token`

**Not required** NPM token to use for publishing to the NPM registry.


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
    - uses: actions/checkout@v1
    - uses: tmigone/versionist@master
      with:
        github_email: 'tomasmigone@gmail.com'
        github_username: 'Tomás Migone'
        github_token: ${{ secrets.GITHUB_TOKEN }}
        npm_token: ${{ secrets.NPM_TOKEN }}
```

You should include at least one commit with a `Change-type: patch | minor | major` footer tag in the comments, example:

```
feature: Fixed a bug with xyz

Change-type: patch
```

### NPM

To enable automatic publishing of your project as an NPM package:
- Ensure your `package.json` is setup correctly
- Create a `repo.yml` file and set the `type` key to `node`: `type: node`
- Provide a valid NPM auth token by setting the `npm_token` action input (best used in combination with GitHub secrets)

On each push to `master` (or whatever branch you choose), your project will now be built and published as an NPM package with automatic Semver versioning and automatic changelog generation.
