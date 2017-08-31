# PREBUMP runs for all kinds of bump
PREBUMP=
  # it is usefull to make sure local is in sync with remote
  git fetch --tags origin master
  git pull origin master

# PREVERSION runs for any kinds of bump, it the last pre-hook
PREVERSION=
  # use it to declare tasks that should run for any kind of bump
  go vet ./...
  go fmt ./...
  go run main.go # alike tests when you don t have tests
  # finalize the changelog
  changelog finalize --version !newversion!
  git commit change.log -m "changelog: !newversion!"
  # update the README
  emd gen -in README.e.md > README.md
  git commit README.md -m "README: !newversion!"
  # generate a markdwon version of your changelog
  changelog md -o CHANGELOG.md --vars='{"name":"dummy"}'
  git commit CHANGELOG.md -m "changelog.md: !newversion!"

# POSTVERSION runs for any kind of bumps
POSTVERSION=
  # use it to sync your local to the remote
  git push
  git push --tags
  # create a github release
  gh-api-cli create-release -n release -o USER -r dummy \
   --ver !newversion!  --draft !isprerelease! \
   -c "changelog ghrelease --version !newversion!"
