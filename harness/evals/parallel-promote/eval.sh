#!/usr/bin/env bash
set -uo pipefail
cd "$EVAL_TMP"; "$PIPELINE_ROOT/bin/new-project" p --name P >/dev/null || exit 1
cd p; W=./.aicodepipeline/bin/wo
printf '#!/usr/bin/env bash\nexit 0\n' > ok.sh; chmod +x ok.sh
git add -A >/dev/null; git -c user.email=e@x -c user.name=e commit -q -m base
fill() { # number: spec through promote in the given worktree
  local dir="$1" n="$2"
  ( cd "$dir" && ./.aicodepipeline/bin/wo verify "$n" --run ./ok.sh >/dev/null \
    && perl -pi -e 's/\[Lesson 1\]/Suites clean up after themselves/; s/\[Lesson 2\]/Assert on what you created/; s/\[Lesson 3\]/Re-run after every fix/' Workspace/Docs/WorkOrders/WO-$n-*/WO-$n-CLOSEOUT.md 2>/dev/null; true )
}
a="$($W new "Alpha module" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"; a="${a#WO-}"
b="$($W new "Beta module" --size small --area backend | grep -o 'WO-[0-9]*' | head -1)"; b="${b#WO-}"
git add -A >/dev/null; git -c user.email=e@x -c user.name=e commit -q -m "two work orders"
git worktree add -q -b wa ../wa HEAD; git worktree add -q -b wb ../wb HEAD
cp ok.sh ../wa/ 2>/dev/null; cp ok.sh ../wb/ 2>/dev/null
for pair in "../wa $a" "../wb $b"; do set -- $pair
  ( cd "$1" && ./.aicodepipeline/bin/wo verify "$2" --run ./ok.sh >/dev/null 2>&1
    perl -pi -e 's/\[Lesson 1\]/Suites clean up after themselves/; s/\[Lesson 2\]/Assert on what you created/; s/\[Lesson 3\]/Re-run after every fix/' "$1"/Workspace/Docs/WorkOrders/WO-"$2"-*/WO-"$2"-CLOSEOUT.md 2>/dev/null || true )
done
for pair in "../wa $a" "../wb $b"; do set -- $pair
  ( cd "$1" && ./.aicodepipeline/bin/wo close "$2" >/dev/null 2>&1
    perl -pi -e 's/\[Lesson 1\]/Suites clean up after themselves/; s/\[Lesson 2\]/Assert on what you created/; s/\[Lesson 3\]/Re-run after every fix/' Workspace/Docs/WorkOrders/WO-"$2"-*/WO-"$2"-CLOSEOUT.md 2>/dev/null || true
    ./.aicodepipeline/bin/wo promote "$2" >/dev/null || { echo "promote failed in $1"; exit 1; }
    git add -A >/dev/null; git -c user.email=e@x -c user.name=e commit -q -m "WO-$2 promoted" ) || exit 1
done
git merge --no-edit wa >/dev/null 2>&1 || { echo "first merge failed"; exit 1; }
git ls-files --error-unmatch .aicodepipeline/packs/p/CATALOG.md >/dev/null 2>&1 && { echo "CATALOG.md is tracked; it is generated and must be ignored"; exit 1; }
if ! git merge --no-edit wb >/dev/null 2>&1; then
  echo "CONFLICT merging the second parallel promotion:"; git diff --name-only --diff-filter=U | sed 's/^/    /'; git merge --abort 2>/dev/null; exit 1
fi
[ -f ".aicodepipeline/packs/p/catalog/WO-$a.md" ] && [ -f ".aicodepipeline/packs/p/catalog/WO-$b.md" ] || { echo "both catalog entries should survive the merge"; ls .aicodepipeline/packs/p/catalog 2>/dev/null; exit 1; }
./.aicodepipeline/bin/pack catalog >/dev/null
cat_txt="$(cat .aicodepipeline/packs/p/CATALOG.md)"; case "$cat_txt" in *"WO-$a"*) ;; *) echo "regenerated CATALOG.md missing WO-$a"; exit 1;; esac
case "$cat_txt" in *"WO-$b"*) ;; *) echo "regenerated CATALOG.md missing WO-$b"; exit 1;; esac
out="$(./.aicodepipeline/bin/pack search "Alpha" 2>&1)"; case "$out" in *"WO-$a"*) ;; *) echo "pack search does not find the entry:"; echo "$out"; exit 1;; esac
exit 0
