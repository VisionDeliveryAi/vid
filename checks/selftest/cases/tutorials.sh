#!/bin/sh
# Purpose: selftest case — the tutorials ship whole and read right (0.26.10.28.6, R7; the GitHub auto set and its lab required, 0.26.10.28.8). The release set lists the tutorials folder and the
# README points to it. In the documents a person reads (the folder's README, START-HERE, the overviews, the tutorials and the labs' README
# files, not the product fixtures inside spec/, design/ or a code step), every command is `/vid:vid-<verb>`, a skill the plugin ships, and no
# bare `/vid <verb>` or "say `vid …`" is left but in a row that names it "… is not a command". The mode names are the three the local auto
# overview gives, which are local auto, GitHub auto and GitHub team, and no document names another mode. Every lab file a tutorial cites
# ships, and nothing ships that is not cited: a document cites a path by naming it in backticks or as a link, relative to its own folder; a
# tutorial cites a lab folder beside it and the paths inside it; a lab's README.md and any README.md inside it that names its folder's own
# entries are that folder's index, every entry of an indexed folder must be cited, a path an index's table lists first or a path inside a
# cited folder must exist, and a folder with no index is cited whole. The case proves the reading on copies: a missing cited file, an
# uncited file, a short command and a fourth mode each fail it. Skips where the tutorials folder and the release set are both absent (a
# project's layout); ViD's own tree, which has the set, must hold the tutorials. Env: CHECKS.
set -eu
fail() { echo "tutorials: $*" >&2; exit 1; }
R=$CHECKS/..; D=$R/docs; TU=$D/tutorials; TL=docs; TL=$TL/tutorials
if [ ! -d "$TU" ]; then [ -f "$D/PUBLISH-SET" ] || { echo 'needs the tutorials folder'; exit 77; }; fail 'the release set is here and the tutorials folder is not'; fi
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
if [ -f "$D/PUBLISH-SET" ]; then grep -v '^#' "$D/PUBLISH-SET" | grep -qxF "$TL" || fail 'the release set does not list the tutorials folder'; fi
if [ -f "$R/README.md" ]; then grep -qF "]($TL/" "$R/README.md" || fail 'the README does not point to the tutorials folder'; fi
for f in README.md START-HERE.md OVERVIEW-LOCAL-AUTO.md OVERVIEW-GITHUB-TEAM.md OVERVIEW-GITHUB-AUTO.md TUTORIAL-LOCAL-AUTO.md TUTORIAL-GITHUB-TEAM.md TUTORIAL-GITHUB-AUTO.md; do
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
  [ "$n" = 'GitHub auto;GitHub team;local auto;' ] || { echo "the overview's modes are not the owner's three: $n"; return 1; }
  grep -qi 'local auto' "$1/START-HERE.md" && grep -qi 'GitHub auto' "$1/START-HERE.md" && grep -qi 'GitHub team' "$1/START-HERE.md" || { echo 'START-HERE does not name the three modes'; return 1; }
  readable "$1" > "$T/read"; bad=0
  while IFS= read -r f; do b=${f#"$1"/}
    perl -ne 'while (/\b([A-Za-z]+)[*_\s]+modes?\b/g) { my $w = $1; my ($a) = substr($_, 0, $-[1]) =~ /([A-Za-z]+)\W*$/; $a = "" unless defined $a; next if $w =~ /^(this|that|each|every|any|one|which|either|a|an|the|its|same|other|own|three|two|both|all|these|those|what|whichever|in|of|to|and|or)$/i; next if "$a $w" =~ /^(local auto|GitHub auto|GitHub team)$/i; print "$.: $a $w mode\n" }' "$f" | sed "s|^|$b:|" > "$T/mode"
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
# the shipped files pass
commands "$TU" > "$T/out" || { cat "$T/out" >&2; fail 'a document names a command that is not /vid:vid-<verb>'; }
modes "$TU" > "$T/out" || { cat "$T/out" >&2; fail 'the mode names are not the three'; }
cites "$TU" > "$T/out" || { cat "$T/out" >&2; fail 'a cited lab file does not ship, or a shipped one is not cited'; }
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
copy; printf 'In ticket mode, too.\n' >> "$T/c/OVERVIEW-GITHUB-TEAM.md"; expect 'a fourth mode name' 'a mode the owner did not name: OVERVIEW-GITHUB-TEAM.md' modes
echo 'tutorials: ok'
