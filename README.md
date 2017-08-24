# go-github-release

HOWTO implement a feature complete release software flow over github.

Aka, s/a software factory/[ma petite entreprise](https://youtu.be/tgOujR6_3Vc?t=37s)/.

Demonstrated with a `go` project,
made with the power of `go`,
built by unix philsophy,
it provides concerns-centric lightweight tools
that can benefit to any project of any language,
[Issue #15](https://github.com/mh-cbon/go-github-release/issues/15)

# TOC
- [TLDR;](#tldr)
- [a dummy project](#a-dummy-project)
- [maintaining a changelog](#maintaining-a-changelog)
  - [In practice](#in-practice)
- [keep your README up to date](#keep-your-readme-up-to-date)
  - [In practice](#in-practice-1)
- [bump a package](#bump-a-package)
  - [In practice](#in-practice-2)
  - [gh-api-cli](#gh-api-cli)
  - [integration](#integration)
- [packaging for debian](#packaging-for-debian)
  - [In practice](#in-practice-3)
- [packaging for rpm](#packaging-for-rpm)
  - [In practice](#in-practice-4)
- [packaging for windows](#packaging-for-windows)
  - [In practice](#in-practice-5)
- [distributing app](#distributing-app)
  - [Windows](#windows)
  - [rpm / debian](#rpm--debian)
- [Oops, it failed :s](#oops-it-failed-s)
- [Errors reference](#errors-reference)
  - [GET https://api.github.com/repo...: 401 Bad credentials []](#get-httpsapigithubcomrepo-401-bad-credentials-)
- [The end !!](#the-end-)

## TLDR;

Throughout this HOWTO several softwares and methods are presented to release a
**ready-to-install** package of a github repository with a two steps command:

```sh
<some changes to the software was made>
$ changelog prepare
<manually edit the changelog>
$ gump <prerelese|patch|minor|major>
<the factory realize all the steps to
publish the new version,
produce the packages,
push them to public cloud service>
```

By then end of this HOWTO you ll acquire reproducible techniques to
- maintain a changelog, with [changelog](https://github.com/mh-cbon/changelog)
- maintain a README, with [emd](https://github.com/mh-cbon/emd)
- bump your package, with [gump](https://github.com/mh-cbon/gump)
- create github release, with [gh-api-cli](https://github.com/mh-cbon/gh-api-cli)
- produce debian packages, with [go-bin-deb](https://github.com/mh-cbon/go-bin-deb)
- produce rpm packages, with [go-bin-rpm](https://github.com/mh-cbon/go-bin-rpm)
- produce windows installers, with [go-msi](https://github.com/mh-cbon/go-msi)
- produce debian repository over `gh-pages`
- produce rpm repository over `gh-pages`

## a dummy project

To illustrate this HOWTO, let s create a dummy application, written in `go`

```sh
$ mkdir $GOPATH/src/github.com/USER/dummy
$ cd $GOPATH/src/github.com/USER/dummy
$ git init

$ cat <<EOT > src/README.md
# dummy

Says hello when invoked on the command line

## Usage

`` `sh
hello - 0.0.1

Say hello.
`` `
EOT

$ git add README.md
$ git commit README.md -m "init: add README"

$ cat <<EOT > src/main.go
// Package hello is a command line program to say hello.
package main

import (
	"fmt"
)

func main() {
	fmt.Println("Hello")
}
EOT

$ git add main.go
$ git commit main.go -m "init: add main"

$ go run main.go
hello

$ git remote add origin git@github.com/USER/dummy
$ curl -u 'USER' https://api.github.com/USER/repos -d '{"name":"dummy"}'
$ git remote add origin git@github.com:USER/dummy.git
$ git push --set-upstream origin master
```

## maintaining a changelog

[wikipedia](https://en.wikipedia.org/wiki/Changelog)

> A changelog is a log or record of all or all notable changes made to a project. The project is often a website or software project, and the changelog usually includes records of changes such as bug fixes, new features, etc. Some open source projects include a changelog as one of the top level files in their distribution.

> A changelog has historically included all changes made to a project. The "Keep a CHANGELOG" site instead advocates that a changelog not include all changes, but that it should instead contain "a curated, chronologically ordered list of notable changes for each version of a project" and should not be a "dump" of a git log "because this helps nobody".[1]

If you have followed the wikipedia link,
you may have noticed that a CHANGELOG is not defined by a file format,
rather than it is a practice to communicate to the community of users.

Problem is that in the wonderful world of software factory, multiple tool,
from multiple different world, with multiple different opinions all desperately
invite or enforce you to produce a changelog file in their own format.

That is why [changelog](https://github.com/mh-cbon/changelog) was written:
- to provide one format to rule them all
- to integrate into a well defined software factory process
- to ease and help the developer in maintaining the CHANGELOG file

#### In practice

For a new repository the `CHANGELOG` file must be initialized, just roll out

```sh
$ changelog init
changelog file created

$ ls -al change.log
-rw-rw-r-- ... change.log

$ cat change.log
UNRELEASED

  * init: add main
  * init: add README

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:41:13 +0200

$ git add change.log
$ git commit change.log -m "init: changelog"
```

`changelog` generates a `change.log` file, it contains the list of tags,
with their associated commits in chronological order.

When a new version is about to release, changes for the next version needs to be prepared, run

```sh
$ changelog prepare
changelog file updated

$ cat change.log
UNRELEASED

  * init: changelog
  * init: add main
  * init: add README

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:41:13 +0200
```

As stated before in the quote, dumping the contents of the commits log is
often not desirable and produces a poorly helpful `CHANGELOG` content.

Let s change the content of the the next release,

```
UNRELEASED

  * Initial release

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:41:13 +0200
```

(not much to say so far, you ll agreed on that)

Finally, let s manually roll out our first version
before we learn how to do that automatically,

```sh
$ changelog finalize --version=0.0.1
changelog file updated

$ cat change.log
0.0.1

  * Initial release

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:41:13 +0200

$ changelog md -o CHANGELOG.md --vars='{"name":"dummy"}'

$ cat CHANGELOG.md
# Changelog - dummy

### 0.0.1

__Changes__

- Initial release

__Contributors__

- USER

Released by USER, Tue 21 Jun 2016
______________

$ git add CHANGELOG.md
$ git commit CHANGELOG.md -m "init: github changelog"

$ git commit change.log -m "tag 0.0.1"
$ git tag 0.0.1
$ git tag
0.0.1
$ git push --all
```

## keep your README up to date

https://en.wikipedia.org/wiki/README

> A README file contains information about other files in a directory or archive of computer software.
> A form of documentation, it is usually a simple plain text file called
> READ.ME, README.TXT, README.md (for a text file using markdown markup),
> README.1ST – or simply README.

The contents typically include one or more of the following:

    - Configuration instructions
    - Installation instructions
    - Operating instructions
    - A file manifest (list of files included)
    - Copyright and licensing information
    - Contact information for the distributor or programmer
    - Known bugs[2]
    - Troubleshooting[2]
    - Credits and acknowledgments
    - A changelog (usually for programmers)
    - A news section (usually for users)

One to many activities and information to perform to maintain a `README`,

Some such as `installation instructions`, `contact` or `licensing` are typically one time information that does not change a lot.

Others such as `file manifest`, `usage`, `code example` are likely to change as the software changes, this is where maintenance need appears.

To help with `emd` provides an enhanced makrdown engine on top of `go` template package,
provided with features specifically designed to help this maintenance task.

Check the detailed documentation at [emd](https://github.com/mh-cbon/emd#toc)

#### In practice

Create a new file where you want to have a README file,

```sh
$ cat <<EOT > src/README.e.md
# {{.Name}}

{{pkgdoc}}

# {{toc 4}}

# Example

#### $ {{exec "go" "run" "main.go" | color "sh"}}
EOT

$ git add README.e.md
$ git commit main.go -m "init: add README"

$ emd gen -in README.e.md -out README.md
$ git add README.md
$ git commit main.go -m "init: generate README"
```

That's it! The new `README` file generated looks likes this,

```md
  # hello

  Package hello is a command line program to say hello.

  # TOC
  - [Example](#example)

  # Example

  #### $ go run main.go
  ` ``sh
  Hello
  ` ``
```

Now it s easier to update the program and to maintain the `README` file.

## bump a package

[stackoverflow](http://stackoverflow.com/a/4181188/4466350)

> Increment the version number to a new, unique value.

In [semver](http://semver.org/) semantics version are expressed such as `<major>.<minor>.<patch>-<prerelease>+<meta>`

> version numbers and the way they change convey meaning about the underlying code and what has been modified from one version to the next.

In practice changing a version number involves numerous side operations.

As presented previously
- `CHANGELOG` needs to be updated,
- the tag needs to be created,
- the remote needs to be synced,
- and many more

That is why [gump](https://github.com/mh-cbon/gump) was written:
- change version using verb rather than numerical values
- run pre/post operations to the version bumping

### In practice

[gump](https://github.com/mh-cbon/gump) provides a very limited set of features,

```sh
$ gump -h
Gump - Bump your package

Usage:
  gump prerelease [-b|--beta] [-a|--alpha] [-d|--dry] [-m <message>]
  gump patch [-d|--dry] [-m <message>]
  gump minor [-d|--dry] [-m <message>]
  gump major [-d|--dry] [-m <message>]

```

However, it provides the ability to declare a file `.version.sh` to define
numerous hooks related to the action of version bumping.

```sh
PREBUMP=
  echo "before bumping"
PREPATCH=
  echo "before bumping to patch"
PREMINOR=
  echo "before bumping to minor"
PREMAJOR=
  echo "before bumping to major"

PREVERSION=
  echo "before bumping the version"
POSTVERSION=
  echo "after version bumped"

POSTMAJOR=
  echo "after version bumped to major"
POSTMINOR=
  echo "after version bumped to minor"
POSTPATCH=
  echo "after version bumped to patch"
POSTBUMP=
  echo "after bumping"
```

Using that file, let s apply process automation to our release process,


```sh
$ cat <<EOT > .version.sh
PREBUMP=
  git fetch --tags origin master
  git pull origin master

PREVERSION=
  go vet ./...
  go fmt ./...
  go run main.go
  changelog finalize --version !newversion!
  git commit change.log -m "changelog: !newversion!"
  emd gen -in README.e.md > README.md
  git commit README.md -m "README: !newversion!"
  changelog md -o CHANGELOG.md --vars='{"name":"dummy"}'
  git commit CHANGELOG.md -m "changelog.md: !newversion!"

POSTVERSION=
  git push
  git push --tags
  gh-api-cli create-release -n release -o USER -r dummy \
   --ver !newversion!  --draft !isprerelease! \
   -c "changelog ghrelease --version !newversion!"
EOT

$ git add .version.sh
$ git commit .version.sh -m "init: bump script"
```

Let s now roll out a new version.

The changelog must be updated,

```sh
$ changelog prepare
changelog file updated

$ cat change.log
UNRELEASED

  * init: release automation

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.1

  * Initial release

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:41:13 +0200
```

- go on and edit the change.log to make it useful,

- The bumper must be invoked,

```sh
$ gump patch
.. commands output
Created new tag 0.0.2
.. commands output
```

That's it!

```sh
$ cat CHANGELOG.md
# Changelog - dummy

### 0.0.2

__Changes__

- init: release automation

__Contributors__

- USER

Released by USER, Tue 21 Jun 2016
______________

### 0.0.1

__Changes__

- Initial release

__Contributors__

- USER

Released by USER, Tue 21 Jun 2016
______________

$ git tag
0.0.2
0.0.1
```

Let s do a quick step-by-step review of this `.version.sh` file.

In first, it worth to note that the syntax is cross-platform,
[stackoverflow](http://stackoverflow.com/a/8055430/4466350).

[gump](https://github.com/mh-cbon/gump) takes care to handle '\' EOL appropriately.

-  Before bumping anything, it is absolutely necessary to sync the local with your remote.

```sh
PREBUMP=
  git fetch --tags origin master
  git pull origin master
```

- For every version to bump, ensure the go looks good, and works.
Its the right place to put your go test,

```sh
PREVERSION=
  go vet ./...
  go fmt ./...
  go run main.go
```

- Finalize and commit the `change.log` file automatically.
This step also make sure you prepared the `change.log`,
so if you stubble upon an error messages, make sure you ran `changelog prepare`!

```sh
PREVERSION=
  changelog finalize --version !newversion!
  git commit change.log -m "changelog: !newversion!"
```


- Generate and commit a markdowned version of the `README`.

```sh
PREVERSION=
  emd gen -in README.e.md -out README.md
  git commit README.md -m "README: !newversion!"
```


- Generate and commit a markdowned version of the `CHANGELOG` for better readability.

```sh
PREVERSION=
  changelog md -o CHANGELOG.md --vars='{"name":"dummy"}'
  git commit CHANGELOG.md -m "changelog.md: !newversion!"
```

- At that moment the new version is created on the vcs.

- Push the changes on the remote !

```sh
POSTVERSION=
  git push
  git push --tags
```

- Create a new github release in the repo `github.com/USER/dummy`,
set it drafted if the version is a prerelease like `beta|alpha`,
attach an extract of the version changes to the new release.


```sh
POSTVERSION=
  gh-api-cli create-release -n release -o USER -r dummy \
   --ver !newversion!  --draft !isprerelease! \
   -c "changelog ghrelease --version !newversion!"
```

### gh-api-cli

Install `gh-api-cli` [from here](https://github.com/mh-cbon/gh-api-cli/),
then add a new `release` personal access token with

```sh
$ gh-api-cli add-auth -n release -r repo
```

### integration

To go further, it is recommended to switch some of those tools to a more appropriate version,
- [philea](https://github.com/mh-cbon/philea) instead of `./...`
- [go-fmt-fail](https://github.com/mh-cbon/go-fmt-fail) instead of `go fmt`
- [commit](https://github.com/mh-cbon/commit) instead of `git commit`
- [666](https://github.com/mh-cbon/666) for better output

But yet, this is all up to your convenience, it would perfetly fit into a `Makefile` too!

## packaging for debian

[debian wiki](https://wiki.debian.org/Packaging)

> A Debian package is a collection of files that allow for applications or libraries to be distributed via the Debian package management system. The aim of packaging is to allow the automation of installing, upgrading, configuring, and removing computer programs for Debian in a consistent manner.

[debian binary package](https://wiki.debian.org/Packaging/BinaryPackage)

> A Debian Package is a file that ends in .deb and contains software for your Debian system.
> A .deb is also known as a binary package. This means that the program inside the package is ready to run on your system.

Ever tried to create a debian package by your own ? I claim this is not an easy task at all.

This HOWTO uncovers solution to automatically produce `binary` debian package out of your repository.

While this is not the holy grail of debian packaging, [go-bin-deb](https://github.com/mh-cbon/go-bin-deb) will be good enough to serve those purposes,
- distribute your application to non go developers
- install / remove your application with ease
- setup services, icons and so on

#### In practice

First things first, you need a debian system to properly and securely package debian software.

While you could use a [vagrant](https://www.vagrantup.com/) box,
a [docker](https://www.docker.com) image,
this HOWTO suggest to use [travis](http://travis-ci.org/)

Let s connect your github account to travis and enable your repository

```sh
xdg-open http://travis-ci.org/
xdg-open https://travis-ci.org/profile/USER
```

The [travis client](https://github.com/travis-ci/travis.rb#installation) will be required,

```sh
$ gem install travis -v 1.8.2 --no-rdoc --no-ri
```

Create a `deb.json` file to describe the package content

```sh
$ cat <<EOT > deb.json
{
  "name": "dummy",
  "maintainer": "USER <email>",
  "description": "Say hello",
  "changelog-cmd": "changelog debian --vars='{\"name\":\"!name!\"}'",
  "homepage": "http://github.com/USER/!name!",
  "files": [
    {
      "from": "build/!arch!/!name!",
      "to": "/usr/bin",
      "base" : "build/!arch!/",
      "fperm": "0755"
    }
  ],
  "copyrights": [
    {
      "files": "*",
      "copyright": "2016 USER <email>",
      "license": "MIT ??",
      "file": "LICENSE"
    }
  ]
}
EOT
```

Short story is,

create a package named `dummy` described as `Say hello`,
the license is `MIT` its content is available in the file `LICENSE`,
there is only one file located at `build/!arch!/dummy` to copy to `/usr/bin`,
and the package `CHANGELOG` is generated with the command `changelog debian --vars='{\"name\":\"dummy\"}'`.

find more information [here](https://github.com/mh-cbon/go-bin-deb#json-file)

Next step is to create a `.travis.yml` file to build the packages then upload the assets to our github release,

```sh
$ cat <<EOT > .travis.yml
  language: go
  go:
  - tip
  env:
    global:
    - MYAPP=dummy
  before_install:
  - sudo apt-get -qq update
  - mkdir -p ${GOPATH}/bin
  install:
  - cd $GOPATH/src/github.com/USER/$MYAPP
  - go install
  script: go run main.go
  before_deploy:
  - mkdir -p build/{386,amd64}
  - GOOS=linux GOARCH=386 go build -o build/386/$MYAPP main.go
  - GOOS=linux GOARCH=amd64 go build -o build/amd64/$MYAPP main.go
  - curl -L https://raw.githubusercontent.com/mh-cbon/go-bin-deb/master/create-pkg.sh
    | GH=mh-cbon/$MYAPP sh -xe
  deploy:
    provider: releases
    api_key:
      secure: xxxxxxx
    file_glob: true
    file:
    - $MYAPP-386.deb
    - $MYAPP-amd64.deb
    skip_cleanup: true
    true:
      tags: true
EOT
```

Generate a secure key, so travis can upload asset to your github repository,

```sh
$ travis setup releases
```

The step-by-step explanations of this `.travis.yml` file,

```yaml
  language: go
  go:
  - tip
```

Install latest go version. it s a simple matrix.

```yaml
  env:
    global:
    - MYAPP=dummy
```

Setup env variable available in the rest of the file.

```yaml
  before_install:
  - sudo apt-get -qq update
  - mkdir -p ${GOPATH}/bin
```

Update the system, make a clean go setup.

```yaml
  install:
  - cd $GOPATH/src/github.com/USER/$MYAPP
  - go install
  script: go run main.go
```

Install your software, make sure it works.

```yaml
  before_deploy:
  - mkdir -p build/{386,amd64}
  - GOOS=linux GOARCH=386 go build -o build/386/$MYAPP main.go
  - GOOS=linux GOARCH=amd64 go build -o build/amd64/$MYAPP main.go
  - curl -L https://raw.githubusercontent.com/mh-cbon/go-bin-deb/master/create-pkg.sh
    | GH=mh-cbon/$MYAPP sh -xe
```

- Generate the files to include into the packages,
this is required step to handle by hands depending
on your requirements. Each desired architecture is built into it s own build folder `build/!arch!/`
- Produce debian packages into the build area `pkg-build/!arch!`,
and output the file to the travis build directory.
- A debian package will be produced for each architecture of {386,amd64}

Version information is taken out of the tag name.

```yaml
  deploy:
    provider: releases
    api_key:
      secure: xxxxxxx
    file_glob: true
    file:
    - $MYAPP-386.deb
    - $MYAPP-amd64.deb
    skip_cleanup: true
    true:
      tags: true
```

This section tells travis system to upload assets listed `file`,
because of `file_glob: true` expand file names,
to a github release and to do that only `on: tags: true`

Thats it!

Let s now roll out a new version to trigger travis build

```sh
$ git add deb.json .travis.yml
$ git commit -m "packaging: add debian package support"

$ changelog prepare
changelog file updated

$ cat change.log
UNRELEASED

  * packaging: add debian package support

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.2

  * init: release automation

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.1

  * Initial release

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:41:13 +0200

<go on and edit the change.log to make it useful>

$ gump patch
.. commands output
Created new tag 0.0.3
.. commands output
```

Within minutes `travis` will create the packages and put them into the
[github release page](https://github.com/mh-cbon/dummy/releases)

## packaging for rpm

[rpm](http://www.rpm.org/)

>  The RPM Package Manager (RPM) is a powerful command line driven package management system capable of installing, uninstalling, verifying, querying, and updating computer software packages. Each software package consists of an archive of files along with information about the package like its version, a description, and the like. There is also a library API, permitting advanced developers to manage such transactions from programming languages such as C or Python.

Much like `go-bin-deb` [go-bin-rpm](https://github.com/mh-cbon/go-bin-rpm) will
help to generate a package for rpm based systems.


#### In practice

First things first, you need a red-hat system to properly and securely package rpm software.

While you could use a [vagrant](https://www.vagrantup.com/) box,
a [docker](https://www.docker.com) image,
this HOWTO suggest to use a docker image over [travis](http://travis-ci.org/)

create an `rpm.json` file to describe the package content

```sh
$ cat <<EOT > rpm.json
{
  "name": "dummy",
  "summary": "Say hello",
  "description": "A command line to say hello",
  "changelog-cmd": "changelog rpm",
  "license": "LICENSE",
  "url": "https://github.com/USER/!name!",
  "files": [
    {
      "from": "build/!arch!/!name!",
      "to": "%{_bindir}/",
      "base": "build/!arch!/",
      "type": ""
    }
  ]
}
EOT
```

Next step is to update the `.travis.yml` file to generate rpm packages,

```sh
$ cat <<EOT > .travis.yml
  sudo: required
  services:
  - docker
  language: go
  go:
  - tip
  env:
    global:
    - MYAPP=gh-api-cli
  before_install:
  - sudo apt-get -qq update
  install:
  - cd $GOPATH/src/github.com/USER/$MYAPP
  - go install
  script: go run main.go
  before_deploy:
  - mkdir -p build/{386,amd64}
  - GOOS=linux GOARCH=386 go build --ldflags "-X main.VERSION=${TRAVIS_TAG}" -o build/386/$MYAPP
    main.go
  - GOOS=linux GOARCH=amd64 go build --ldflags "-X main.VERSION=${TRAVIS_TAG}" -o build/amd64/$MYAPP
    main.go
  - curl -L https://raw.githubusercontent.com/mh-cbon/go-bin-rpm/master/create-pkg.sh
    | GH=mh-cbon/$MYAPP sh -xe
  deploy:
    provider: releases
    api_key:
      secure: xxxx
    file_glob: true
    file:
    - $MYAPP-386.rpm
    - $MYAPP-amd64.rpm
    skip_cleanup: true
    true:
      tags: true
EOT
```

The step-by-step explanations of the changes applied to `.travis.yml` file,

```yaml
  sudo: required
  services:
  - docker
```

This enables `docker` on travis. It requires `sudo`.

```yaml
  before_deploy:
  - mkdir -p build/{386,amd64}
  - GOOS=linux GOARCH=386 go build --ldflags "-X main.VERSION=${TRAVIS_TAG}" -o build/386/$MYAPP
    main.go
  - GOOS=linux GOARCH=amd64 go build --ldflags "-X main.VERSION=${TRAVIS_TAG}" -o build/amd64/$MYAPP
    main.go
  - curl -L https://raw.githubusercontent.com/mh-cbon/go-bin-rpm/master/create-pkg.sh
    | GH=mh-cbon/$MYAPP sh -xe
```

Produce rpm packages into the build area `pkg-build/!arch!`,
and output the file to the travis build directory.

An rpm package will be produced for each architecture of {386,amd64}

Version information is taken out of the tag name.

```yaml
  deploy:
    provider: releases
    api_key:
      secure: xxxx
    file_glob: true
    file:
    - $MYAPP-386.rpm
    - $MYAPP-amd64.rpm
    skip_cleanup: true
    true:
      tags: true
```

Update `file` list of `deploy` section to include the new rpm packages.

Thats it!

Let s now roll out a new version to trigger travis build

```sh
$ git add rpm.json docker.sh
$ git commit -m "packaging: add rpm package support"

$ changelog prepare
changelog file updated

$ cat change.log
UNRELEASED

  * packaging: add rpm package support

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.3

  * packaging: add debian package support

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.2

  * init: release automation

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.1

  * Initial release

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:41:13 +0200

<go on and edit the change.log to make it useful>

$ gump patch
.. commands output
Created new tag 0.0.4
.. commands output
```

Within minutes `travis` will create the packages
and put all rpm and debian packages into the
[github release page](https://github.com/mh-cbon/dummy/releases)


## packaging for windows

[wikipedia](https://en.wikipedia.org/wiki/WiX)

> The Windows Installer XML Toolset (WiX, pronounced "wicks"), is a free software toolset that builds Windows Installer packages from XML code. It consists of a command-line environment that developers may integrate into their build processes to build MSI and MSM packages.

[wix documentation](http://wixtoolset.org/documentation/manual/v3/)

If building rpm or debian package is not an easy task, building windows installer is even more difficult.

It uses a lots of XML tightly linked to windows api, installers are by nature way more complex than previous packages, it is all closed source with fewer documentation.

Nevertheless, like `go-bin-deb` or `go-bin-rpm`, a solution exist [go-msi](https://github.com/mh-cbon/go-msi).

#### In practice

First things first, you need a windows system to create windows installer. the procedure relies on [wix](http://wixtoolset.org/) a software distributed only on windows compatible platform.

While you could use a [vagrant](https://www.vagrantup.com/) box,
(soon) a [docker](https://www.docker.com) image,
this HOWTO suggest to use [appveyor](https://www.appveyor.com/)

Once again, browse to appveyor, connect your github account, and enable your repos

```sh
xdg-open https://ci.appveyor.com/
xdg-open https://ci.appveyor.com/projects/new
```

create an `wix.json` file to describe the package content

```sh
$ cat <<EOT > wix.json
{
  "product": "dummy",
  "company": "USER",
  "license": "LICENSE",
  "upgrade-code": "",
  "files": {
    "guid": "",
    "items": [
      "dummy.exe"
    ]
  },
  "env": {
    "guid": "",
    "vars": [
      {
        "name": "PATH",
        "value": "[INSTALLDIR]",
        "permanent": "no",
        "system": "no",
        "action": "set",
        "part": "last"
      }
    ]
  }
}
EOT
```

Then setup guids with help of `go-msi`

```sh
$ go-msi set-guid
file updated
```

Short story,

create an installer made of `dummy.exe` file,
place it into ~~ `C:\program files\dummy`,
add this path to user environment `PATH` variable.

To perform the build of the package, create an `appveyor.yml` file.

```sh
$ cat <<EOT > appveyor.yml
version: "{build}"
os: Windows Server 2012 R2
clone_folder: c:\gopath\src\github.com\USER\dummy
skip_non_tags: true

environment:
  GOPATH: c:\gopath
  GO15VENDOREXPERIMENT: 1

install:
  - curl -fsSL -o C:\wix310-binaries.zip http://static.wixtoolset.org/releases/v3.10.3.3007/wix310-binaries.zip
  - 7z x C:\wix310-binaries.zip -y -r -oC:\wix310
  - set PATH=C:\wix310;%PATH%
  - set PATH=%GOPATH%\bin;c:\go\bin;%PATH%
  - curl -fsSL -o C:\latest.bat https://raw.githubusercontent.com/mh-cbon/latest/master/latest.bat
  - cmd /C C:\latest.bat mh-cbon go-msi amd64
  - set PATH=C:\Program Files\go-msi\;%PATH%

build_script:
  - set MYAPP=dummy
  - set GOARCH=386
  - go build -o %MYAPP%.exe --ldflags "-X main.VERSION=%APPVEYOR_REPO_TAG_NAME%" main.go
  - go-msi.exe make --msi %APPVEYOR_BUILD_FOLDER%\%MYAPP%-%GOARCH%.msi --version %APPVEYOR_REPO_TAG_NAME% --arch %GOARCH%
  - set GOARCH=amd64
  - go build -o %MYAPP%.exe --ldflags "-X main.VERSION=%APPVEYOR_REPO_TAG_NAME%" main.go
  - go-msi.exe make --msi %APPVEYOR_BUILD_FOLDER%\%MYAPP%-%GOARCH%.msi --version %APPVEYOR_REPO_TAG_NAME% --arch %GOARCH%

test: off

artifacts:
  - path: '*-386.msi'
    name: msi-x86
  - path: '*-amd64.msi'
    name: msi-x64

deploy:
  - provider: GitHub
    artifact: msi-x86, msi-x64
    draft: false
    prerelease: false
    description: "Release %APPVEYOR_REPO_TAG_NAME%"
    auth_token:
      secure: xxxx
    on:
      branch:
        - master
        - /v\d\.\d\.\d/
        - /\d\.\d\.\d/
      appveyor_repo_tag: true
EOT
```

Go to your github account, and generate a new `personal access token` to read/write `repo`

```sh
xdg-open https://github.com/settings/tokens
```

Generate a secure deploy key for appveyor with the new github token value,

```sh
xdg-open https://ci.appveyor.com/tools/encrypt
```

Set the secure key into the `appveyor.yml` file.


The step-by-step explanations of this `appveyor.yml` file,

```yaml
  version: '{build}'
  os: Windows Server 2012 R2
  clone_folder: c:\gopath\src\github.com\USER\dummy
  skip_non_tags: true
```

Defines the windows version to run, it does not matter much.
sets the clone path, tells appveyor to skip non tag commits
as this is a build only `appveyor.yml` file.

```yaml
  environment:
    GOPATH: c:\gopath
    GO15VENDOREXPERIMENT: 1
```

Set some required ENV for the go setup.

```yaml
  install:
  - curl -fsSL -o C:\wix310-binaries.zip http://static.wixtoolset.org/releases/v3.10.3.3007/wix310-binaries.zip
  - 7z x C:\wix310-binaries.zip -y -r -oC:\wix310
  - set PATH=C:\wix310;%PATH%
  - set PATH=%GOPATH%\bin;c:\go\bin;%PATH%
  - curl -fsSL -o C:\latest.bat https://raw.githubusercontent.com/mh-cbon/latest/master/latest.bat
  - cmd /C C:\latest.bat mh-cbon go-msi amd64
  - set PATH=C:\Program Files\go-msi\;%PATH%
```

Install wix binaries, register their path to PATH

Install `go-msi` on the machine, registers its path to PATH.

```yaml
  build_script:
  - set MYAPP=dummy
  - set GOARCH=386
  - go build -o %MYAPP%.exe --ldflags "-X main.VERSION=%APPVEYOR_REPO_TAG_NAME%" main.go
  - go-msi.exe make --msi %APPVEYOR_BUILD_FOLDER%\%MYAPP%-%GOARCH%.msi --version %APPVEYOR_REPO_TAG_NAME%
    --arch %GOARCH%
  - set GOARCH=amd64
  - go build -o %MYAPP%.exe --ldflags "-X main.VERSION=%APPVEYOR_REPO_TAG_NAME%" main.go
  - go-msi.exe make --msi %APPVEYOR_BUILD_FOLDER%\%MYAPP%-%GOARCH%.msi --version %APPVEYOR_REPO_TAG_NAME%
    --arch %GOARCH%
```

Create binaries for each architecture and create the windows installer.
Save resulting file into `APPVEYOR_BUILD_FOLDER` to be able to upload them afterward.

```yaml
  artifacts:
  - path: '*-386.msi'
    name: msi-x86
  - path: '*-amd64.msi'
    name: msi-x64
```

Define a bunch of assets (name <> path).
Where path is always relative to `APPVEYOR_BUILD_FOLDER`

```yaml
  deploy:
  - provider: GitHub
    artifact: msi-x86, msi-x64
    draft: false
    prerelease: false
    description: Release %APPVEYOR_REPO_TAG_NAME%
    auth_token:
      secure: xxxx
    true:
      branch:
      - master
      - /v\d\.\d\.\d/
      - /\d\.\d\.\d/
      appveyor_repo_tag: true
```

Tells `appveyor` to take `msi-x86`, `msi-x64` artifacts and upload them to the github release page.

If a release does not exists, create it.

Do it only for tag commits, on branch looking like a semver commit (this is tricky may need refinements).

Thats it!

Let s now roll out a new version to trigger appveyor build

```sh
$ git add wix.json appveyor.yml
$ git commit -m "packaging: add msi package support"

$ changelog prepare
changelog file updated

$ cat change.log
UNRELEASED

  * packaging: add msi package support

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.4

  * packaging: add rpm package support

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.3

  * packaging: add debian package support

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.2

  * init: release automation

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.1

  * Initial release

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:41:13 +0200

<go on and edit the change.log to make it useful>

$ gump patch
.. commands output
Created new tag 0.0.5
.. commands output
```

Within minutes both `appveyor` and `travis` will create the packages
and put all of them into the
[github release page](https://github.com/mh-cbon/dummy/releases)

# distributing app

To distribute your application several cases and ways are possible.

#### Windows

On windows, for a regular user, a link to the MSI package
and the `click-click-click` practice is enough.

#### rpm / debian

__One time setup__

To easily install your package, you can use that snippet in your repo,

```sh
curl -L https://raw.githubusercontent.com/mh-cbon/latest/master/install.sh \
| GH=USER/dummy sh -xe
# or
wget -q -O - --no-check-certificate \
https://raw.githubusercontent.com/mh-cbon/latest/master/install.sh \
| GH=USER/dummy sh -xe
```

Which will detect the running system, detect the last version of the repo `USER/dummy`,
download a deb or rpm package for the given system,
and run the appropriate command to install the package.

__setup a regular package source__

For a better integration and ease package update, you can also create
source package repositories and host them on `gh-pages` branch of your github repository.

Lets update the `.travis.yml` file.

Add a secure environment variable containing the value of a github personal access token,

Create a personal access token on github, save its value to your clipboard,

```sh
$ xdg-open https://github.com/settings/tokens
```

Update `env` section of the `.travis.yml` file, using `travis cli client`, to create a secure variable

```sh
$ travis encrypt --add -r USER/dummy GH_TOKEN=<token>
```

If you use [gh-api-cli](https://github.com/mh-cbon/gh-api-cli),

```sh
travis encrypt --add -r USER/dummy GH_TOKEN=`gh-api-cli get-auth -n <auth name>`
```

The env section should now look like this

```yaml
  env:
    global:
    - MYAPP=dummy
    - secure: xxxxx
```

Now add a new section `after_deploy`, to generate the repositories into `gh-pages` after the release is updated,

```yaml
  after_deploy:
  - curl -L https://raw.githubusercontent.com/mh-cbon/go-bin-deb/master/setup-repository.sh
    | GH=USER/$MYAPP EMAIL=your@email.com sh -xe
  - curl -L https://raw.githubusercontent.com/mh-cbon/go-bin-rpm/master/setup-repository.sh
    | GH=USER/$MYAPP EMAIL=your@email.com sh -xe
```

Last step, update the `README.md` to add instructions to setup the new source,

```sh
wget -O - https://raw.githubusercontent.com/mh-cbon/latest/master/source.sh \
| GH=USER/dummy sh -xe
# or
curl -L https://raw.githubusercontent.com/mh-cbon/latest/master/source.sh \
| GH=USER/dummy sh -xe
```

Thats it!

Let s now roll out a last version to generates the repositories

```sh
$ git commit -am "packaging: add deb/rpm source repositories"

$ changelog prepare
changelog file updated

$ cat change.log
UNRELEASED

  * packaging: add deb/rpm source repositories

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.5

  * packaging: add msi package support

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.4

  * packaging: add rpm package support

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.3

  * packaging: add debian package support

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.2

  * init: release automation

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:42:13 +0200

0.0.1

  * Initial release

  - USER <email>

-- USER <email>; Tue, 21 Jun 2016 11:41:13 +0200

<go on and edit the change.log to make it useful>

$ gump major
.. commands output
Created new tag 1.0.0
.. commands output
```

# Oops, it failed :s

For various reasons the build might fail, on bump or during the ci,
in such case you are left with a project in a loosy state.

For example, you might end up with,
- a git tag
- a gh release
- failed ci did not produce packages

The simplest solution is to simply remove traces of that broken release,
fix the bump pipeline, then bump again.

```sh
$ gump patch
...
failure
....
$ VERSION=x.x.x
# revert, fix then restart
$ git tag -d $VERSION
$ git push origin :$VERSION
$ gh-api-cli rm-release --tag -n <auth name> -o USER -r dummy --ver $VERSION
# rename last release to UNRELEASED
$ changelog rename
# fix to the pipeline
$ gump patch # again
```

# Errors reference

Find various errors messages and their quick solution

### GET https://api.github.com/repo...: 401 Bad credentials []

__Reference__

```sh
$ gh-api-cli rm-assets --guess --ver 1.0.0 -t $GH_TOKEN --glob "*.deb"
GET https://api.github.com/repos/mh-cbon/go-bin-rpm/releases?page=1&per_page=200: 401 Bad credentials []
panic: exit status 1
goroutine 1 [running]:
...
> The command "curl -L https://raw.githubusercontent.com/mh-cbon/go-bin-deb/master/create-pkg.sh | GH=$GH sh -xe" failed and exited with 2 during .
```

__Reason__

`$GH_TOKEN` passed to `gh-api-cli` is wrong (empty, revocated, not exisitng).

__Solution__

Using `travis` client re generate the `secure environment variable` that you should find into the `.travis.yml` file.

```yml
env:
  global:
    - secure: StXdvc/gCv6u/hIqw0clmV0xsgcjUSMwo.....
```

__Procedure__

```sh
$ travis encrypt --add -r USER/dummy GH_TOKEN=<token>
# or
$ travis encrypt --add -r USER/dummy GH_TOKEN=`gh-api-cli get-auth -n <auth name>`
```

see also [gh-api-cli](https://github.com/mh-cbon/gh-api-cli)

# The end !!

This is it, with some tools and cloud services,
the releases of the software are kept up to date with a two step commands,

```sh
$ changelog prepare
$ gump <patch|minor|major>
```

Enjoy the reusable and modular system those tools provide you to feet your own
vision, contribute and report your success.

~~ Happy coding!
