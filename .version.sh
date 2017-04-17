PREBUMP=
  666 rm -fr src/.git
  666 git init src
  666 emd gen README.e.md > README.md
  666 commit -q -m "README: !newversion!" -f README.md
