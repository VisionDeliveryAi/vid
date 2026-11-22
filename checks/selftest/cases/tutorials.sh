#!/bin/sh
# Purpose: selftest case — the tutorials ship whole and read right (0.26.10.28.6, R7; the GitHub auto set and its lab required, 0.26.10.28.8). The release set lists the tutorials folder and the
# README points to it. In the documents a person reads (the folder's README, START-HERE, the overviews, the tutorials and the labs' README
# files, not the product fixtures inside spec/, design/ or a code step), every command is `/vid:vid-<verb>`, a skill the plugin ships, and no
# bare `/vid <verb>` or "say `vid …`" is left but in a row that names it "… is not a command". The mode names are the three the local auto
# overview gives, which are local auto, GitHub auto and GitHub manual (FB-1 C1: GitHub team retired, renamed), and no document names
# another mode. FB-1 C1, D1: the two GitHub manual documents, OVERVIEW-GITHUB-MANUAL.md and TUTORIAL-GITHUB-MANUAL.md, tell GitHub
# manual's flow: no document names the old team files, and a lab README's `../` link names a file of the folder; neither names
# /vid:vid-run, and both name /vid:vid-next; no decision on a pull request (no report id of the pull request form, no `gh pr
# comment`, no `vid: decide` or `vid: decision` beside a pull request, no decision said to be on one); no acceptance before the
# merge (a `gh pr merge` after a `vid: decide` in one stop, or an accepted ticket the team then merges); and the overview's 4.6
# has SR's sort before the one ask, a single numbered step holding `vid: decide`, and, beside the excerpt's `breached test` on
# ROW-003, a sentence naming the lab's `kept`. FB-2 A1: neither GitHub tutorial has the person run `gh repo create`; A2: nor type
# `/vid:vid-plan` or `/vid:vid-mode` (a line that opens with it), and GitHub manual's first typed ViD command is `/vid:vid-next`. Every lab file a tutorial cites
# ships, and nothing ships that is not cited: a document cites a path by naming it in backticks or as a link, relative to its own folder; a
# tutorial cites a lab folder beside it and the paths inside it; a lab's README.md and any README.md inside it that names its folder's own
# entries are that folder's index, every entry of an indexed folder must be cited, a path an index's table lists first or a path inside a
# cited folder must exist, and a folder with no index is cited whole. The case proves the reading on copies: a missing cited file, an
# uncited file, a short command, a fourth mode and each GitHub manual fault above each fail it. Skips where the tutorials folder and the release set are both absent (a
# project's layout); ViD's own tree, which has the set, must hold the tutorials. Env: CHECKS.
set -eu
fail() { echo "tutorials: $*" >&2; exit 1; }
R=$CHECKS/..; D=$R/docs; TU=$D/tutorials; TL=docs; TL=$TL/tutorials
if [ ! -d "$TU" ]; then [ -f "$D/PUBLISH-SET" ] || { echo 'needs the tutorials folder'; exit 77; }; fail 'the release set is here and the tutorials folder is not'; fi
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
if [ -f "$D/PUBLISH-SET" ]; then grep -v '^#' "$D/PUBLISH-SET" | grep -qxF "$TL" || fail 'the release set does not list the tutorials folder'; fi
if [ -f "$R/README.md" ]; then grep -qF "]($TL/" "$R/README.md" || fail 'the README does not point to the tutorials folder'; fi
for f in README.md START-HERE.md OVERVIEW-LOCAL-AUTO.md OVERVIEW-GITHUB-MANUAL.md OVERVIEW-GITHUB-AUTO.md TUTORIAL-LOCAL-AUTO.md TUTORIAL-GITHUB-MANUAL.md TUTORIAL-GITHUB-AUTO.md; do
  [ -f "$TU/$f" ] || fail "the tutorials folder has no $f"; done
# 0.26.10.28.8: the GitHub auto set, its documents and its lab, required as the other two modes' are
[ -f "$TU/github-auto-lab/README.md" ] || fail 'the tutorials folder has no github-auto-lab/ with its README.md'
# the documents a person reads: the folder's own .md files and the labs' README files outside the product fixtures
readable() { find "$1" -name '*.md' | sort | while IFS= read -r f; do r=${f#"$1"/}
  case /$r in /*/*/README.md|/*/README.md) ;; /*/*) continue ;; esac
  case /$r in */spec/*|*/design/*) continue ;; */code/README.md) ;; */code/*) continue ;; esac
  printf '%s\n' "$f"; done; }
V='init|create-prd|test-inventory|design|stage|develop|plan|run|grade|fix|add|deploy|view|help'
commands() { readable "$1" > "$T/read"; [ -s "$T/read" ] || { echo 'no document to read'; return 1; }; bad=0
  while IFS= read -r f; do b=${f#"$1"/}
    grep -nE '[Ss]ay `vid [a-z]|`vid ('"$V"')`|(^|[^:a-z-])/vid ('"$V"')([^a-z-]|$)|(^|[^:a-z])/vid-('"$V"')([^a-z-]|$)' "$f" | grep -v 'is not a command' | sed "s|^|$b:|" > "$T/short" || true
    [ ! -s "$T/short" ] || { echo "a short command: $(head -n 1 "$T/short")"; bad=1; }
    if [ -d "$R/skills" ]; then for c in $(grep -oE '/vid:vid-[a-z-]+' "$f" | sort -u); do v=${c#/vid:}; [ -f "$R/skills/$v/SKILL.md" ] || { echo "$b names $c, which is no skill of the plugin"; bad=1; continue; }
      ! grep -qE '^description: *"?Internal' "$R/skills/$v/SKILL.md" || { echo "$b names $c, an internal skill, not a verb"; bad=1; }; done; fi
  done < "$T/read"; return $bad; }
# the mode names: the three the local auto overview gives, in its line on the three modes; any other "<name> mode" fails
modes() { o=$1/OVERVIEW-LOCAL-AUTO.md; l=$(grep -m 1 'three modes' "$o" || true); [ -n "$l" ] || { echo 'the overview names no three modes'; return 1; }
  n=$(printf '%s\n' "$l" | perl -ne 'print "$1\n" while /(?<!\*)\*([^*]+)\*(?!\*)/g' | sort | tr '\n' ';')
  [ "$n" = 'GitHub auto;GitHub manual;local auto;' ] || { echo "the overview's modes are not the owner's three: $n"; return 1; }
  grep -qi 'local auto' "$1/START-HERE.md" && grep -qi 'GitHub auto' "$1/START-HERE.md" && grep -qi 'GitHub manual' "$1/START-HERE.md" || { echo 'START-HERE does not name the three modes'; return 1; }
  readable "$1" > "$T/read"; bad=0
  while IFS= read -r f; do b=${f#"$1"/}
    perl -ne 'while (/\b([A-Za-z]+)[*_\s]+modes?\b/g) { my $w = $1; my ($a) = substr($_, 0, $-[1]) =~ /([A-Za-z]+)\W*$/; $a = "" unless defined $a; next if $w =~ /^(this|that|each|every|any|one|which|either|a|an|the|its|same|other|own|three|two|both|all|these|those|what|whichever|in|of|to|and|or)$/i; next if "$a $w" =~ /^(local auto|GitHub auto|GitHub manual)$/i; print "$.: $a $w mode\n" }' "$f" | sed "s|^|$b:|" > "$T/mode"
    [ ! -s "$T/mode" ] || { echo "a mode the owner did not name: $(head -n 1 "$T/mode")"; bad=1; }; done < "$T/read"; return $bad; }
# the cites, read as the header says; prints each fault and exits 1 on any
cat > "$T/cites.pl" <<'PL'
use strict; use warnings;
my $top = shift; my $bad = 0;
sub fault { print "$_[0]\n"; $bad = 1 }
sub entries { my $d = shift; opendir(my $h, $d) or return (); my @e = grep { $_ ne '.' && $_ ne '..' } readdir $h; closedir $h; return sort @e }
sub slurp { my $f = shift; open(my $h, '<', $f) or return ''; local $/; my $s = <$h>; close $h; return $s }
sub tokens { my $s = shift; my @t;
  while ($s =~ /`([^`\n]+)`/g) { push @t, $1 } while ($s =~ /\]\(([^)\s]+)\)/g) { push @t, $1 }
  return map { s{^\./}{}; s{/+$}{}; $_ } grep { !/[<>*\$\s]|^\.\.|^#|:\/\/|^\// } @t }
sub firstcol { my $s = shift; my @t;
  for my $l (split /\n/, $s) { next unless $l =~ /^\|([^|]*)\|/; my $c = $1; while ($c =~ /`([^`]+)`/g) { push @t, $1 } }
  return map { s{^\./}{}; s{/+$}{}; $_ } grep { !/[<>*\$\s]|^\.\./ } @t }
sub walk { my ($d, $name, $extra, $must) = @_; my %ent = map { $_ => 1 } grep { $_ ne 'README.md' } entries($d);
  my $ix = -f "$d/README.md" ? slurp("$d/README.md") : ''; my @own = tokens($ix);
  my $isidx = grep { my ($f) = split m{/}; $ent{$f} } @own;
  if (!$isidx) { fault("$name has no index README.md naming its entries") if $must; return }
  my @all = (@own, @$extra);
  for my $p (firstcol($ix)) { fault("$name/README.md lists $p, which does not ship") unless -e "$d/$p" }
  for my $p (@all) { my ($f) = split m{/}, $p; next unless $p =~ m{/} && $ent{$f}; fault("$name cites $p, which does not ship") unless -e "$d/$p" }
  my %cited = map { my ($f) = split m{/}; $f => 1 } @all;
  for my $e (sort keys %ent) { fault("$name/$e ships and nothing cites it") unless $cited{$e} }
  for my $e (sort keys %ent) { next unless -d "$d/$e" && $cited{$e};
    my @sub = map { my $q = $_; $q =~ s{^\Q$e\E/}{}; $q } grep { m{^\Q$e\E/.} } @all; walk("$d/$e", "$name/$e", \@sub, 0) } }
my @docs = grep { /\.md$/ && -f "$top/$_" } entries($top); my %txt = map { $_ => slurp("$top/$_") } @docs;
my %ent = map { $_ => 1 } entries($top);
for my $doc (@docs) { while ($txt{$doc} =~ /\]\(([^)\s#]+)\)/g) { my $p = $1; next if $p =~ m{://}; fault("$doc links $p, which does not ship") unless -e "$top/$p" } }
for my $e (sort keys %ent) { next if $e eq 'README.md'; my $hit = 0;
  for my $doc (@docs) { next if $doc eq $e; $hit = 1 if grep { my ($f) = split m{/}; $f eq $e } tokens($txt{$doc}) }
  fault("$e ships and no document of the folder cites it") unless $hit }
for my $doc (grep { /^TUTORIAL-/ } @docs) { my @labs = grep { -d "$top/$_" && $txt{$doc} =~ /`\Q$_\E\/?`/ } keys %ent;
  fault("$doc cites no lab folder beside it") unless @labs }
for my $lab (sort grep { -d "$top/$_" } keys %ent) { my @x;
  for my $doc (@docs) { for my $q (grep { m{^\Q$lab\E/.} } tokens($txt{$doc})) { (my $r = $q) =~ s/#.*//; fault("$doc cites $q, which does not ship") unless -e "$top/$r" }   # a path named with its lab
    next unless $txt{$doc} =~ /`\Q$lab\E\/?`/; push @x, grep { !m{^\Q$lab\E(/|$)} } tokens($txt{$doc}); push @x, map { my $q = $_; $q =~ s{^\Q$lab\E/}{}; $q } grep { m{^\Q$lab\E/.} } tokens($txt{$doc}) }
  walk("$top/$lab", $lab, \@x, 1) }
exit $bad;
PL
cites() { perl "$T/cites.pl" "$1"; }
# FB-1 C1, D1: GitHub manual's flow in its two documents, read as the header says; prints each fault and exits 1 on any
cat > "$T/flow.pl" <<'PL'
use strict; use warnings;
my $top = shift; my $bad = 0;
sub fault { print "$_[0]\n"; $bad = 1 }
sub slurp { my $f = shift; open(my $h, '<', $f) or return undef; local $/; my $s = <$h>; close $h; return $s }
opendir(my $dh, $top) or die; my @all = sort grep { !/^\./ } readdir $dh; closedir $dh;
my @read = grep { /\.md$/ && -f "$top/$_" } @all;
for my $lab (grep { -d "$top/$_" && -f "$top/$_/README.md" } @all) { push @read, "$lab/README.md" }
for my $d (@read) { my $s = slurp("$top/$d"); my $n = 0;
  for my $l (split /\n/, $s) { $n++; fault("$d:$n names the retired team file $1") while $l =~ /\b((OVERVIEW|TUTORIAL)-GITHUB-TEAM\.md)/g;
    next unless $d =~ m{/};
    while ($l =~ m{(?:`|\]\()\.\./([^`)\s#]+)}g) { my $p = $1; fault("$d:$n links ../$p, which is not there") unless -e "$top/$p" } } }
for my $f ('OVERVIEW-GITHUB-MANUAL.md', 'TUTORIAL-GITHUB-MANUAL.md') { my $s = slurp("$top/$f"); defined $s or next; my $n = 0; my ($ask, $sec) = (0, '');
  fault("$f names no /vid:vid-next") unless $s =~ m{/vid:vid-next\b};
  for my $l (split /\n/, $s) { $n++;
    if ($l =~ /^#{2,3} /) { $sec = $l; $ask = 0 }
    fault("$f:$n names /vid:vid-run") if $l =~ m{/vid:vid-run\b};
    fault("$f:$n a report id of the pull request form") if $l =~ /\b(?:grade-|sort-)?pr-(?:<|\$|[0-9])/;
    fault("$f:$n a comment on a pull request: gh pr comment") if $l =~ /\bgh pr comment\b/;
    fault("$f:$n a decision beside a pull request") if $l =~ /vid: decid/ && $l =~ /pull request/i;
    fault("$f:$n a decision on a pull request") if $l =~ /\b(?:decides?|decided|decision|answers)\b[^.|]*\bon the pull request/i;
    fault("$f:$n an acceptance before the merge") if $l =~ /\baccepted\b[^.|]*\b(?:team|you|MR)\b[^.|]*\bmerges?\b/i;
    $ask = 1 if $l =~ /vid: decide/;
    fault("$f:$n an acceptance before the merge: gh pr merge after vid: decide in $sec") if $ask && $l =~ /\bgh pr merge\b/ } }
# FB-2 A1: ViD makes every repository the setup names, so neither GitHub tutorial has the person run gh repo create
for my $f ('TUTORIAL-GITHUB-AUTO.md', 'TUTORIAL-GITHUB-MANUAL.md') { my $s = slurp("$top/$f"); defined $s or next; my $n = 0;
  my $first = '';
  for my $l (split /\n/, $s) { $n++; fault("$f:$n has the person make a repository: gh repo create") if $l =~ /\bgh repo create\b/;
    # FB-2 A2: the run or the call plans first, so neither tutorial types /vid:vid-plan or /vid:vid-mode to begin
    fault("$f:$n types $1 to begin") if $l =~ m{^(/vid:vid-(?:plan|mode))\b}; $first ||= $1 if $l =~ m{^(/vid:vid-[a-z-]+)} }
  fault("$f: its first typed ViD command is $first, not /vid:vid-next") if $f =~ /MANUAL/ && $first ne '/vid:vid-next' }
my $o = slurp("$top/OVERVIEW-GITHUB-MANUAL.md");
if (defined $o) { my ($s46) = $o =~ /^### 4\.6 [^\n]*\n(.*?)(?=^### |\z)/ms;
  if (!defined $s46) { fault('OVERVIEW-GITHUB-MANUAL.md has no section 4.6') }
  else { my @st = grep { /^\d+\. / } split /\n/, $s46; my ($i, $so, $as, $na) = (0, -1, -1, 0);
    for my $l (@st) { $i++; $so = $i if $so < 0 && $l =~ /`SR`/ && $l =~ /\bsort/i; if ($l =~ /vid: decide/) { $na++; $as = $i if $as < 0 } }
    fault('4.6: no numbered step where SR sorts') if $so < 0; fault('4.6: no numbered step that asks with vid: decide') if $as < 0;
    fault('4.6: the ask comes before the sort') if $so > 0 && $as > 0 && $as < $so;
    fault("4.6: $na numbered steps ask with vid: decide, not one") if $na > 1;
    if ($s46 =~ /ROW-003 breached test/) { fault("4.6: the excerpt's breached test on ROW-003, and no sentence naming the lab's kept")
      unless grep { /ROW-003/ && /`kept`/ && /\blab\b/ } split /\n/, $s46 } } }
exit $bad;
PL
flow() { perl "$T/flow.pl" "$1"; }
# the shipped files pass
commands "$TU" > "$T/out" || { cat "$T/out" >&2; fail 'a document names a command that is not /vid:vid-<verb>'; }
modes "$TU" > "$T/out" || { cat "$T/out" >&2; fail 'the mode names are not the three'; }
cites "$TU" > "$T/out" || { cat "$T/out" >&2; fail 'a cited lab file does not ship, or a shipped one is not cited'; }
flow "$TU" > "$T/out" || { cat "$T/out" >&2; fail 'the GitHub documents do not tell their flow (above)'; }
# the reading proved on copies: each change below must fail its check, naming what it found
copy() { rm -rf "$T/c"; cp -R "$TU" "$T/c"; }
expect() { what=$1; pat=$2; shift 2; if "$@" "$T/c" > "$T/out" 2>&1; then fail "$what passed"; fi; grep -qF "$pat" "$T/out" || { cat "$T/out" >&2; fail "$what failed for another reason"; }; }
copy; rm "$T/c/local-auto-lab/seed.md"; expect 'the local lab without seed.md' 'lists seed.md, which does not ship' cites
copy; rm -r "$T/c/local-auto-lab/ten-requirements"; expect 'the local lab without ten-requirements' 'lists ten-requirements, which does not ship' cites
copy; rm "$T/c/jobdigest-lab/reports/1-skeleton/grade.txt"; expect 'the team lab without a hand-written grade' 'cites 1-skeleton/grade.txt, which does not ship' cites
copy; rm "$T/c/jobdigest-lab/env/push-report.sh"; expect 'the team lab without push-report.sh' 'push-report.sh, which does not ship' cites
copy; rm -r "$T/c/local-auto-lab"; expect 'the folder without the local lab' 'cites no lab folder beside it' cites
copy; printf 'x\n' > "$T/c/local-auto-lab/notes.md"; expect 'an uncited file in the local lab' 'local-auto-lab/notes.md ships and nothing cites it' cites
copy; printf '# A plan\n' > "$T/c/LOCAL-AUTO-PLAN.md"; expect 'an uncited plan beside the tutorials' 'LOCAL-AUTO-PLAN.md ships and no document' cites
copy; printf 'Type `/vid plan` next.\n' >> "$T/c/START-HERE.md"; expect 'a short command in START-HERE' 'a short command: START-HERE.md' commands
copy; printf 'Then say `vid init`.\n' >> "$T/c/jobdigest-lab/README.md"; expect 'a short command in a lab README' 'a short command: jobdigest-lab/README.md' commands
copy; printf 'Open `local-auto-lab/brief-zz.md` next.\n' >> "$T/c/TUTORIAL-LOCAL-AUTO.md"; expect 'a lab file named with its lab, missing' 'cites local-auto-lab/brief-zz.md, which does not ship' cites
copy; printf 'See [the answers](local-auto-lab/README.md#how-to-use-the-answers).\n' >> "$T/c/START-HERE.md"; cites "$T/c" > "$T/out" || { cat "$T/out" >&2; fail 'a link to a lab file with a heading fragment was refused'; }
copy; printf 'Type `/vid:vid-build`.\n' >> "$T/c/START-HERE.md"; [ ! -d "$R/skills" ] || expect 'an internal skill as a command' 'names /vid:vid-build, an internal skill' commands
copy; printf 'Type `/vid:vid-replot`.\n' >> "$T/c/TUTORIAL-LOCAL-AUTO.md"; [ ! -d "$R/skills" ] || expect 'a command that is no skill' 'names /vid:vid-replot' commands
copy; printf 'Type `/vid init` here.\n' >> "$T/c/jobdigest-lab/spec/PRD.md"; commands "$T/c" > "$T/out" || { cat "$T/out" >&2; fail 'a lab fixture is checked for commands'; }
copy; printf 'In ticket mode, too.\n' >> "$T/c/OVERVIEW-GITHUB-MANUAL.md"; expect 'a fourth mode name' 'a mode the owner did not name: OVERVIEW-GITHUB-MANUAL.md' modes
copy; printf 'Read GitHub team mode.\n' >> "$T/c/START-HERE.md"; expect 'the retired mode name' 'a mode the owner did not name: START-HERE.md' modes
# FB-1 C1, D1: each GitHub manual fault fails the flow, naming what it found
copy; printf 'See `../TUTORIAL-GITHUB-TEAM.md`.\n' >> "$T/c/jobdigest-lab/README.md"; expect 'the lab README naming the team tutorial' 'names the retired team file TUTORIAL-GITHUB-TEAM.md' flow
copy; printf 'See `../TUTORIAL-GITHUB-GONE.md`.\n' >> "$T/c/jobdigest-lab/README.md"; expect 'a lab README link to no file' 'links ../TUTORIAL-GITHUB-GONE.md, which is not there' flow
copy; printf 'Then type `/vid:vid-run`.\n' >> "$T/c/TUTORIAL-GITHUB-MANUAL.md"; expect 'the run in the manual tutorial' 'TUTORIAL-GITHUB-MANUAL.md:' flow
grep -q 'names /vid:vid-run' "$T/out" || { cat "$T/out" >&2; fail 'the run in the manual tutorial failed for another reason'; }
copy; printf '```bash\ngh repo create $REPO --private\n```\n' >> "$T/c/TUTORIAL-GITHUB-AUTO.md"; expect 'a repository made by hand in the auto tutorial' 'TUTORIAL-GITHUB-AUTO.md:' flow
grep -q 'gh repo create' "$T/out" || { cat "$T/out" >&2; fail 'the repository made by hand failed for another reason'; }
copy; printf '```\n/vid:vid-mode manual\n```\n' >> "$T/c/TUTORIAL-GITHUB-MANUAL.md"; expect 'the switch typed in the manual tutorial' 'types /vid:vid-mode to begin' flow
copy; printf '```bash\ngh pr comment $P --body "vid: decide $SHA"\n```\n' >> "$T/c/TUTORIAL-GITHUB-MANUAL.md"; expect 'an ask on a pull request' 'a comment on a pull request: gh pr comment' flow
copy; printf 'ViD reads the reports and answers on the pull request.\n' >> "$T/c/OVERVIEW-GITHUB-MANUAL.md"; expect 'a decision on a pull request' 'a decision on a pull request' flow
copy; printf 'The head report is `pr-<pull request>-<head12>-<k>`.\n' >> "$T/c/OVERVIEW-GITHUB-MANUAL.md"; expect 'a pull request report id' 'a report id of the pull request form' flow
copy; printf 'On `ticket: accepted`, for that exact head, your team merges the pull request.\n' >> "$T/c/OVERVIEW-GITHUB-MANUAL.md"; expect 'an acceptance before the merge' 'an acceptance before the merge' flow
copy; printf '### Stop 99. Late\n\nAsk with `vid: decide $SHA`, then:\n\n```bash\ngh pr merge $P --merge\n```\n' >> "$T/c/TUTORIAL-GITHUB-MANUAL.md"; expect 'a merge after the ask' 'gh pr merge after vid: decide' flow
copy; perl -0pi -e 's/(^### 4\.6 [^\n]*\n)/$1\n1. **`MR` asks first** with `vid: decide <the commit>`.\n/m' "$T/c/OVERVIEW-GITHUB-MANUAL.md"; expect 'an ask before the sort in 4.6' '4.6: the ask comes before the sort' flow
copy; perl -0pi -e 's/(^### 4\.6 [^\n]*\n.*?)(^### )/$1\n99. **`MR` asks again**: the same `vid: decide <commit>` comment.\n\n$2/ms' "$T/c/OVERVIEW-GITHUB-MANUAL.md"; expect 'two asks in 4.6' 'numbered steps ask with vid: decide, not one' flow
copy; perl -ni -e 'print unless /ROW-003/ && /`kept`/ && /\blab\b/' "$T/c/OVERVIEW-GITHUB-MANUAL.md"; expect 'the excerpt without the lab'"'"'s kept' 'no sentence naming the lab'"'"'s kept' flow
echo 'tutorials: ok'
