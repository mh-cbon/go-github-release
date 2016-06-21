# sample output

```sh
gump minor
git fetch --tags
 ✔ Success
go-fmt-fail ./config/glide_test.go
 ✔ Success
go vet ./config/load.go
 ✔ Success
go-fmt-fail ./stringexec/index.go
 ✔ Success
go vet ./config/glide_test.go
 ✔ Success
go-fmt-fail ./config/load.go
 ✔ Success
go vet ./config/simple_test.go
 ✔ Success
go-fmt-fail ./config/glide.go
 ✔ Success
go vet ./config/simple.go
 ✔ Success
go-fmt-fail ./config/simple_test.go
 ✔ Success
go vet ./config/glide.go
 ✔ Success
go vet ./gump_test.go
 ✔ Success
go-fmt-fail ./gump_test.go
 ✔ Success
go vet ./stringexec/index.go
 ✔ Success
go-fmt-fail ./config/simple.go
 ✔ Success
go vet ./gump/index.go
 ✔ Success
go-fmt-fail ./gump.go
 ✔ Success
go-fmt-fail ./gump/index.go
 ✔ Success
go vet ./gump.go
 ✔ Success
rm-glob -r build/
 ✔ Success
rm-glob -r assets/
file does not exist
 ✔ Success
build-them-all build main.go -o build/&os-&arch/&pkg --ldflags -X main.VERSION=0.1.0
wd=/home/mh-cbon/gow/src/github.com/mh-cbon/gump
> GOOS=darwin GOARCH=386 /home/mh-cbon/.gvm/gos/go1.6.2/bin/go build -o build/darwin-386/main -ldflags -X main.VERSION=0.1.0
Success!

> GOOS=darwin GOARCH=amd64 /home/mh-cbon/.gvm/gos/go1.6.2/bin/go build -o build/darwin-amd64/main -ldflags -X main.VERSION=0.1.0
Success!

> GOOS=linux GOARCH=386 /home/mh-cbon/.gvm/gos/go1.6.2/bin/go build -o build/linux-386/main -ldflags -X main.VERSION=0.1.0
Success!

> GOOS=linux GOARCH=amd64 /home/mh-cbon/.gvm/gos/go1.6.2/bin/go build -o build/linux-amd64/main -ldflags -X main.VERSION=0.1.0
Success!

> GOOS=windows GOARCH=386 /home/mh-cbon/.gvm/gos/go1.6.2/bin/go build -o build/windows-386/main.exe -ldflags -X main.VERSION=0.1.0
Success!

> GOOS=windows GOARCH=amd64 /home/mh-cbon/.gvm/gos/go1.6.2/bin/go build -o build/windows-amd64/main.exe -ldflags -X main.VERSION=0.1.0
Success!

 ✔ Success

Created new tag 0.1.0
git push
Everything up-to-date
 ✔ Success
git push --tags
Total 0 (delta 0), reused 0 (delta 0)
To git@github.com:mh-cbon/gump.git
 * [new tag]         0.1.0 -> 0.1.0
 ✔ Success
philea -s -S -p build/windows*/* 666 archive create -f -o=assets/%dname.zip -C=build/%dname/ .
archive create -f -o=assets/windows-386.zip -C=build/windows-386/ .
✓ assets/windows-386.zip: 1.2 MB
 ✔ Success
archive create -f -o=assets/windows-amd64.zip -C=build/windows-amd64/ .
✓ assets/windows-amd64.zip: 1.3 MB
 ✔ Success
 ✔ Success
philea -s -S -e windows*/** -p build/*/** 666 archive create -f -o=assets/%dname.tar.gz -C=build/%dname/ .
archive create -f -o=assets/darwin-386.tar.gz -C=build/darwin-386/ .
✓ assets/darwin-386.tar.gz: 1.2 MB
 ✔ Success
archive create -f -o=assets/darwin-amd64.tar.gz -C=build/darwin-amd64/ .
✓ assets/darwin-amd64.tar.gz: 1.2 MB
 ✔ Success
archive create -f -o=assets/linux-386.tar.gz -C=build/linux-386/ .
✓ assets/linux-386.tar.gz: 1.2 MB
 ✔ Success
archive create -f -o=assets/linux-amd64.tar.gz -C=build/linux-amd64/ .
✓ assets/linux-amd64.tar.gz: 1.2 MB
 ✔ Success
 ✔ Success
gh-api-cli create-release -n release -o mh-cbon -r gump --ver 0.1.0
{
    "id": 3486994,
    "tag_name": "0.1.0",
    "target_commitish": "master",
    "name": "0.1.0",
    "draft": false,
    "prerelease": false,
    "created_at": "2016-06-21T06:48:24Z",
    "published_at": "2016-06-21T06:49:10Z",
    "url": "https://api.github.com/repos/mh-cbon/gump/releases/3486994",
    "html_url": "https://github.com/mh-cbon/gump/releases/tag/0.1.0",
    "assets_url": "https://api.github.com/repos/mh-cbon/gump/releases/3486994/assets",
    "upload_url": "https://uploads.github.com/repos/mh-cbon/gump/releases/3486994/assets{?name,label}",
    "zipball_url": "https://api.github.com/repos/mh-cbon/gump/zipball/0.1.0",
    "tarball_url": "https://api.github.com/repos/mh-cbon/gump/tarball/0.1.0",
    "author": {}
}
 ✔ Success
gh-api-cli upload-release-asset -n release --glob assets/* -o mh-cbon -r gump --ver 0.1.0
Uploading assets/darwin-386.tar.gz
Done
Uploading assets/darwin-amd64.tar.gz
Done
Uploading assets/linux-386.tar.gz
Done
Uploading assets/linux-amd64.tar.gz
Done
Uploading assets/windows-386.zip
Done
Uploading assets/windows-amd64.zip
Done
Assets uploaded!
 ✔ Success
rm-glob -r build/
 ✔ Success
rm-glob -r assets/
 ✔ Success
go install --ldflags -X main.VERSION=0.1.0
 ✔ Success
```
