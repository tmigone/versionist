# versionist GitHub action
![DockerHub](https://img.shields.io/docker/v/tmigone/versionist?sort=semver&&logo=docker&logoColor=2496ED&label=Docker+image&color=2496ED)

This action uses a service account to provide automatic Semver versioning and changelog generation. Useful to handle versioning in continuous delivery workflows that use NPM or Docker deployments for example.
 
The following actions are taken sequentially:

- Run `balena-versionist`. This will update `CHANGELOG.md`, `VERSION`, `package.json`, etc files accordingly.
- Add a new commit to the working branch with the versioning changes
- Create a release tag corresponding to the new version
- Push changes and tags to master

Read more about the opinionated versioning here:
- [versionist](https://github.com/balena-io/versionist)
- [balena-versionist](https://github.com/balena-io/balena-versionist)

**Action's inputs and outputs**
| Input / Output | Name | Description |
| ------------- | ------------- | ------------- |
| Input  | `branch` | **Not required** Name of the branch where versioning should be applied. Default: master. | 
| Input  | `github_email` | **Required** The service account's email address. | 
| Input  | `github_username` | **Required** The service account's username. | 
| Input  | `github_token` | **Required** A Personal Access Token for the GitHub service account. We recommend to set this using secrets, for example: `${{ secrets.GH_VERSIONIST_TOKEN }}`. | 
| Output  | `version` | The project's version after running versionist. |
| Output  | `updated` | Returns `true` if the version was bumped by versionist, `false` otherwise. |

## Example usage

### GitHub Service account
First you'll need to create a GitHub service account and grant it `Collaborator` access to the target repository. This can be any GitHub account though we recommend to use a dedicated one just for this task. You'll need to take note of the account's email address, username and create a GitHub [Personal Access Token](https://docs.github.com/en/free-pro-team@latest/github/authenticating-to-github/creating-a-personal-access-token) with `repo` access.

### Configuring the workflow
Next, configure your workflow. Here is an example:

```yaml
name: Run versionist
on:
  push:
    branches:
      - master

jobs:

  versionist:
    name: Run versionist
    if: "!contains(github.event.head_commit.author.name, 'versionist')"   # Ignore push events made by the service account
    runs-on: ubuntu-latest
    outputs:                                              # (optional) Only if you want to use them in next jobs
      version: ${{ steps.versionist.outputs.version }}    # version: project's version after running versionist
      updated: ${{ steps.versionist.outputs.updated }}    # updated: true if the version has been updated
    steps: 
    - name: Checkout project
      uses: actions/checkout@v2
      with:
        fetch-depth: 0                                    # We need all commits and tags
        persist-credentials: false                        # Next step needs to use service account's token
    - name: Run versionist
      id: versionist                                      # (optional) Only needed if using outputs
      uses: tmigone/versionist@master
      with:
        # Provide your versionist service account details
        github_email: 'tmigone.versionist@gmail.com'
        github_username: 'versionist'
        github_token: ${{ secrets.GH_VERSIONIST_TOKEN }}


    # You can now use any other action to package and distribute your new release (NPM, docker, etc)
    # If you set up the outputs you can use them here
    output:
      name: A job to echo versionist's outputs
      needs: versionist
      if: needs.versionist.outputs.updated == 'true'
      runs-on: ubuntu-latest
      steps:
      - name: Echo version number
        run: echo "Version is ${{ needs.versionist.outputs.version }}"
      - name: Echo updated
        run: echo "Updated is ${{ needs.versionist.outputs.updated }}"

```

### Tagging commits

If you want to trigger the workflow you only need to include a `Change-type: patch | minor | major` footer tag in a commit's comments. Note that at least one commit needs to contain the `Change-type` footer tag, otherwise the workflow will exit.

 A commit example:

```
feature: Fixed a bug with xyz

Change-type: patch
```

### Branch protection

Currently it's not possible to use versionist on branches that have branch protection enabled. It might be possible to do so if the repository is part of an organization and not a personal one, but I haven't tested it yet. 
