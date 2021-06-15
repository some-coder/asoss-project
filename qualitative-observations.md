## Qualitative observations

Below, I note qualitatively what I observe when running a single model configuration (2000 ticks, 200 fish) for each
strategy. I concentrate on both the individual behaviours of fish, as well as any group dynamics or emergent properties
of the strategy I observe.

### Mixed

**Individuals.** When the predator draws near, an individual seems to take relatively little action if the hunter
approaches from the front or back; if the predator instead emerges from one of the fish's sides, then it makes a
swift 90-degree turn around the predator.

**Fish schools.** Fish tend to turn to similar directions when the predator emerges from any side. Whether this can
be attributed to behavioural interactions among fish (due to flocking), or whether this simply is so because fish
follow the same strategy (and thus turn similarly, without any reliance on other fish for determining their direction)
is not fully clear. Regardless of attribution, the effect of the _Mixed_ strategy at the group level seems to be
primarily that splits take place when the predator steers into the school at certain angles.

## Solitary when nearby

**Individuals.** Individual fish always seem to turn 90 degrees from the threat. (This is to be expected: the fish
should do this both when the predator is close and when the predator is still at a distance; the difference between
the two is the stance towards flocking they take.)

**Fish schools.** It is difficult to see how this strategy is different from simply turning 90 degrees: even if
fish turn 90 degrees selfishly, fish around them take a similar turn, which causes the group to remain cohesive even
though they behave selfishly.

This strategy is perhaps only truly different from the turning 90 degrees strategy when
individual fish near the outskirts of a school get targeted. In those cases, only said fish flees selfishly while
the rest keeps flocking together. As a consequence, a fish 'chips off' from the group and keeps circling around the
predator until it gets eaten or until the predator gets distracted (by e.g. a different school) or confused.

Most of the time, schools seem to retain their 'geometrical integrity' (i.e. they stay as one relatively concentrated
group), although they rapidly change direction: flash turnings take place.

## Zig-zag

**Individuals.** Each fish starts to zig-zag away from the predator, as the name of the strategy suggests. During a
zig-zag manouver, fish seem to pay less attention to flocking.

**Fish schools.** When a predator draws close to a group of fish, the fish scatter and move about in a sinusoidal
pattern. Once their zig-zag manouver has ended, often a school has split into around five to six sub-schools that
eventually aggregate together again. Thus, importantly, the predator can effectively split up large groups
(which could be named splits, flash-expansions), which is not the case for other strategies such as _Mixed_.

Also, when a school gets split up, the predator succeeds relatively frequently in isolating one fish which subsequently
gets eaten. This strategy thus seems relatively ineffective because of this side-effect of zig-zagging.

## Optimal

**Individuals.** Because of the default difference in speed between the predator and the prey fish – 0.6 patches/tick
versus 0.4 patches/tick, respectively – the optimal turning angle for the fish is determined to be
`asin (4e-1 / 6e-1)`, or about 41 degrees. What this means is that, if the predator is at the back of the fish
(180 degrees, or six o' clock) the fish will opt to turn to 49 degrees, or to around two o' clock. Compare this with
a different strategy – turning 90 degrees (or, to three o' clock); the prey more likely stays in sight, but
as its movement speed is sufficiently high, it should be able to keep the predator at bay.

**Fish schools.** Very similar to the _Turn 90 degrees_ strategy, complete schools turn to the same direction, albeit
not 90 degrees to the right (or left) this time around, but instead 48 degrees. After the manouver has been performed,
flocking continues. Since for each fish the emergence angle of the predator is slightly different, the fish schools
tend to scatter (split and flash-expand), similar to (but not as heavily as in) the zig-zag strategy.

## Protean

**Individuals.** The fish swim in random angles that are not within a certain angular range of the predator's emergence
angle. (To be precise, `relative-predator-angle +/- danger-half-angle`.)

**Fish schools.** Interestingly, as the Protean strategy leads to such widely diverging angles of escaping prey,
it appears as if a kind of flash expansion occurs when a predator homes in on a group of fish. Once the predator has
continued its hunt, the school recollects after some time.

## Biased

**Individuals.** Fish frequently choose to turn right when encountering a predator, but on occasion turn left instead.

**Fish schools.** As the predator often enters from one of the sides of a fish school, only the fish at the periphery
initiate an escape. Depending on how large this group is, the complete school may start to move as a consequence of
its individuals all reacting to their neighbours, which leads to a kind of 'group-level push' to a side. During
such pushes, however, the group stays intact. In very rare occasions, a flash expansion occurs because of the predator
being inside the school, motivating the surrounding fish to move rightwards in all their varying headings.

Still, in most cases I observe that only a few fish perform an escape and consequently get picked off by the predator.

## Refuge

**Individuals.** When a fish is sufficiently close to a refuge, it tries to enter the refuge before the predator
manages to catch it. If no refuge is available, the fish does not act.

**Fish schools.** Generally, the predator picks off prey without any action on the preys' side. In the case that the
school swims close to a refuge (determined by `refuge-detection-range`), the fish form a tight ball around a single
refuge location and stay there until the predator swims away. None of the other strategies – except _Refuge-escape_ –
seem to cause schools to concentrate instead of diverge or malform in some way.

## Refuge-escape

**Individuals.** Fish exhibit very similar behaviour as in the _Refuge_ strategy. This time I note that fish actively
turn away from the predator when it draws close; they do so by means of making near-90 degree turns.

**Fish schools.** Macro-level phenomena are largely identical to the _Refuge_ strategy, except that the
'scattering' (flash expansion) phenomenon can occasionally be observed when the predator is near a school of fish.
Additionally interesting is that when such a scattering event takes place, fish whose scattering direction points to
a nearby refuge concetrate in such refuges.
