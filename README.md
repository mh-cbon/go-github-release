# go-github-release: Making it simple with go

A quick document to establish simple and easy practice to release `go` projects on `github`.

### Why this document

I often find myself confronted to `go` repositories which does not provide any tag or release.

I feel its a lack which could be easily improved.

### why tagging ?

People use this functionality to mark release points.

It gives consumer of your code the ability to refer to a precise, stable and meaningful point in the history of your repository.

Throughout this document i will be using [semver](http://semver.org/) as a convention to tag the software as its widely spread, adapted to software management and it s designed to address dependency difficulties.

# How

I will introduce a simple solution I came up with, you are free to reproduce it, adapt it or create a new one.

### A bumper

To make this process of creating tags easy and reliable I believe it should be automated.

For that matter I created [gump](https://github.com/mh-cbon/gump) a `go` program which the main purpose is to speak `semver` with you and speak `version` and `tags` with your vcs.

It takes commands such `prerelease`, `patch`, `minor`, `major` and produces out a new version number which is used to generate a new tag on your underlying VCS.

In other word, it bumps your repository / package.

To make it clear about the meaning of bump verbs, let s take those examples,

given a current version
- `0.0.1` => `gump patch      ` => `0.0.2`
- `0.0.1` => `gump minor      ` => `0.1.0`
- `0.0.1` => `gump major      ` => `1.0.0`
- `1.0.1` => `gump pre-release` => `1.0.2-alpha`

### It s not only about bumping the version

Creating a release is not only about making a new version and tagging the vcs history, its about making it publicly available for other developers.

In that matters, its important that some quality indicators are met before a new release is made.

To meet those requirements, the process should be as automated as possible.

In that attempt your bumper software must give you the ability to hook the pre / post phases of the version creation.

# A step by step

Now that a quick overview of the theory has been provided, Let s jump into the practice on top of `gump` .

### A dummy project

A dummy project has been init, and commits have been made

```sh
git init
touch README.md
git add -A
git commit -m "my dummy commit"
git remote add origin https://github.com/user/dummy.git
git pull origin master
git push --set_upstream origin master
# yeay : D
```

To implement the release script, we have to declare a file on the root of the repository.

```sh
touch .version
```

`.version` follows a simplistic syntax to declare the hooks, a bit like `json`, it takes pairs of `key:value`.

Values are the actual script to execute on your underlying shell.

```sh
preversion: git fetch --tags && go test && got vet && go fmt
postversion: git push && git push --tags
```

Thats it for a simple version !

A detailed description of the whole process :

- fetch the tags from the remote,
- test the code
- lint the code
- determine the new version
- ensure that the vcs status is clean
- apply the new tag
- push to the remote

As a result, by now at every release you are certain that you are sync with the remote, the tests are passing, the code is formatted and that no tag will be created on a dirty vcs which has uncommitted changes.

All the commands must succeed in order to completely run the release process, if one fails, the process stops.

As you can see you are all free to script it the way you likes it.

It is completely open to your customizations.

### Going further

Let s now jump into a more complicated release script, it s the one used to release `gump` project itself.

```sh
preversion: 666 git fetch --tags \
&& philea -s "666 go vet %s" "666 go-fmt-fail %s" \
&& 666 rm-glob -r build/ \
&& 666 rm-glob -r assets/ \
&& 666 build-them-all build main.go -o "build/&os-&arch/&pkg" --ldflags "-X main.VERSION=!newversion!"

postversion: 666 git push && 666 git push --tags \
&& 666 philea -s -S -p "build/windows*/*" "666 archive create -f -o=assets/%dname.zip -C=build/%dname/ ." \
&& 666 philea -s -S -e windows*/** -p "build/*/**" "666 archive create -f -o=assets/%dname.tar.gz -C=build/%dname/ ." \
&& 666 gh-api-cli create-release -n release -o mh-cbon -r gump --ver !newversion! \
&& 666 gh-api-cli upload-release-asset -n release --glob "assets/*" -o mh-cbon -r gump --ver !newversion! \
&& 666 rm-glob -r build/ \
&& 666 rm-glob -r assets/ \
&& 666 go install --ldflags "-X main.VERSION=!newversion!"
```

A detailed description of the whole process :

- fetch the tags from the remote,
- recursively apply `go vet` and `go fmt` on the sources
- clean existing build folders
- rebuild the binary and place results into `build/`
- determine the new version
- ensure that the vcs status is clean
- apply the new tag
- push to the remote
- create archive out of built files
- create a new github release
- upload release assets to the new release
- clean the build folders
- locally install the latest version of the program

#### quick notes

- ` \`: This is a line continuation which when parsed means, get ride of the `\n` and of the ` \` to constitute a single line
- `go test`: is missing in this script, the reason is that it s using a fairly heavy test environment to run, so i prefer to execute it on demand in this case.

#### 666

this is a bin util which has for purpose to visually display execution result of a command.

This is really just eye candy for my taste.

```sh
$ 666 git fetch --tags
✔ Success

$ 666 ls nosuchfolder
ls nosuchfolder
ls: no such folder: nosuchfolder
exit status 2
 ✘ Failed
```

Find more about [666](https://github.com/mh-cbon/666)

#### philea

Which stands for file apply. Glob files, then apply commands on them. Take advantage of some tags to personalize the commands.

I initially came to do that because `go fmt` would not recursively scan my projects.

Doing so `philea -s "666 go vet %s" "666 go-fmt-fail %s"`, I ask `philea` to recursively scan the current folder for `**/*.go`, excluding `vendors/**`.

For each file found, apply `go vet`, `go-fmt-fail` commands, replace `%s` by the actual file path.

`-s` option stands for `--short` output.

`-d` option would run dry, print out all the commands, but do not execute any.

Find more about [philea](https://github.com/mh-cbon/philea)

#### go-fmt-fail

`go-fmt-fail` an addition to `go fmt` command.

`go fmt` is great, except one thing, if it reformats a file, it won t return an `exit code=1`.

Which in the case of the release script is not a very good behavior as the process will continue even though the vcs status is dirty with uncommitted changes.

So `go-fmt-fail` came in to quit the release process early when unformatted files are met.

Find more about [go-fmt-fail](https://github.com/mh-cbon/go-fmt-fail)

#### rm-glob

A cross-platform `rm` like command. The purpose of this command is to improve the portability of such script between unice and non unice OSes.

It s not exactly like `rm -fr`, but close enough to feel at home.

It takes patterns to glob, and deletes resulting items of the scan.

Find more about [rm-glob](https://github.com/mh-cbon/rm-glob)

#### build-them-all

Its really just about building go program to multiple targets with ease.

Find more about [build-them-all](https://github.com/mh-cbon/build-them-all)

#### archive

Create `zip` / `tar.gz` files easily. Once again this helps to improve portability of such script.

Find more about [archive](https://github.com/mh-cbon/archive)

#### gh-api-cli

Query `github` rest api to apply modifications on your repositories.

Currently it is used to create releases and upload the new assets to the newly created release.

Find more about [gh-api-cli](https://github.com/mh-cbon/gh-api-cli)

#### The results

With that script setup on my repository the results are like [this](https://github.com/mh-cbon/gump/releases).

The entire script can be changed easily and quickly if an update needs to be applied, the output is tasty as I like.

A sample output is available [here](https://github.com/mh-cbon/go-github-release/blob/master/sample-output.md)

# That's it !

I hope you ll find interest into those techniques and that you will apply them to your own projects.

You are warmly invited to improve this or come up with better alternatives.

~~ Happy coding !
