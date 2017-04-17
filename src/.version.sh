PREBUMP=
  git fetch --tags origin master
  git pull origin master

PREVERSION=
  go vet ./...
  go fmt ./...
  go run main.go
  changelog finalize --version !newversion!
  git commit change.log -m "changelog: !newversion!"
  emd gen README.e.md > README.md
  git commit README.md -m "README: !newversion!"
  changelog md -o CHANGELOG.md --vars='{"name":"dummy"}'
  git commit CHANGELOG.md -m "changelog.md: !newversion!"

POSTVERSION=
  git push
  git push --tags
  gh-api-cli create-release -n release -o USER -r dummy \
   --ver !newversion!  --draft !isprerelease! \
   -c "changelog ghrelease --version !newversion!"
