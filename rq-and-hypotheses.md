## Research question and hypotheses

**Research question.** "Which of the following eight escape
strategies for individual fish leads to the lowest absolute number of catches in the
`Flocking_TrPEsH.nlogo` model?"

| #   | Strategy | Details | References |
| :-- | :------- | :------ | :--------- |
| 1 | Mixed | Turn uniformly randomly at the foremost and backmost 40 degrees of the fish, and turn perpendicular to the threat when the threat to one of the fish's sides. | _1_ |
| 2 | Cooperative-selfish | Unless the threat is very close, try to escape while still flocking with other fish; otherwise escape selfishly (forgetting about flocking) by turning perpendicular from the threat. | _2_ |
| 3 | Zig-zag | Move away from the threat while making lateral deviations in a sine-wave-like motion. | _3_ (p. 2464) |
| 4 | Optimal | Turn away from the threat by `90 + asin(speed / predator-speed)` degrees. | _3_ (p. 2467) |
| 5 | Protean | Turn uniformly randomly, always. | _3_ (p. 2464) |
| 6 | Biased | Opt to turn right 90% of the time. Then turn in said direction by a uniformly randomly generated degree between 0 and 180. | _3_ (p. 2464) |
| 7 | Refuges | If a refuge is near, move to the refuge. Otherwise take no action. | _4_, _3_ (p. 2468) |
| 7 | Refuges with escaping | Like (7), but try to escape by turning away perpendicularly from the threat when no refuge is in sight. | _4_, _3_ (p. 2468) |

**Hypothesis.** Purely following the mathematics, and not considering any other effects,
I would deem the _Optimal_ strategy to be the most effective
in terms of survival rates. However, our model involves more than just chase dynamics;
flocking, confusion, as well as refuges are additionally part of the model. Since
the _Refuges with escaping_ strategy is the only approach that leverages all three
model mechanisms, I hypothesise that it functions best in terms of number of fish caught.

**Corollary to RQ I.** "Which strategy leads to the lowest ratio of catches to lock-ons?"

**Hypothesis (corollary I).** For the same reasoning as provided above, I hypothesise
that the _Refuges with escaping_ strategy performs best in minimising the catches-over-lock-ons
metric.

**Corollary to RQ II.** "Does the size of the fish school impact which strategy is optimal according
to these two criteria, that is, absolute number of fish caught and fish caught over fish locked on to?"

**Hypothesis (corollary II).** Since a relatively large number of fish raises the number of
opportunities for the predator to lock on to and catch fish, I at least hypothesise that
raising the number of fish involved in the model changes the two predator metrics. The actual
question – whether the best performing strategy changes because of a change in fish school size –
I will answer less decidedly. On the one hand, I find it conceivable that a different strategy
becomes more performant at greater fish school sizes, because interactions among the fish may lead to
worse (better) outcomes for the small-size best strategy (a large-size, different strategy).
On the other hand, these group effects may be negligible, which would cause the small-size
best strategy to also be best at large sizes of fish schools.

## Results

Also see `plots/strategies.pdf` and `plots/strategies-together.pdf`. It appears that the _Mixed_ and
_Solitary when nearby_ both reach a shared minimum in number of fish caught, at least so for the fish school size of
100 individuals. Closely following these two are the _Optimal_ and _Refuge-escape_ strategies, with slightly higher
mortality rates.

When looking at the catches-over-lock-ons metric (`C/L`), the same four strategies seem to perform best. Only for
the smallest fish school size considered (100 individuals) the _Solitary when nearby_ method seems to perform
unambiguously best of all four; for greater fish school sizes, all seem to perform relatively similarly.

As for the impact of fish school size on performance, it seems that a strategy either (i) sees no significant difference
in performance as the fish school size varies (_Protean_, _Optimal_, _Refuge-escape_), while for others (ii) a
significant difference arises between fish school sizes of primarily 100 and 200 (_Biased_, _Refuge_, _Zig-zag_,
_Mixed_, _Solitary when nearby_). Still, the _Solitary when nearby_ keeps a mortality-minimising position even at
higher fish school sizes, although it needs to share said place with the other three strategies in the sub-top,
which have been listed in the previous paragraph.

## Conclusions

**Research question.** I reject my hypothesis that the _Refuge-escape_ strategy minimises the number of
caught fish among all eight strategies, because the results pointed out that instead four strategies jointly seem to
perform all similarly well.

Why do _Mixed_, _Solitary when nearby_, _Optimal_ and _Refuge-escape_ perform better than the other four strategies,
but among themselves about equally well?

The answer to the second question may lie in the observation that a lower
mortality rate is almost impossible; the catch rates are already near-zero percent success (as measured by `C/L`). In
other words: the way the four 'best' strategies reach a shared minimum may be different, but all four share the fact
that they reach this near-minimimally possible mortality rate.

Then consider the first question: why do the 'best'
four strategies perform better than the other four (_Biased_, _Refuge_, _Zig-zag_ and _Protean_)?

First I note that,
empirically, the _Biased_ and _Refuge_ strategies have a clear sub-optimal effect on fish school mortality rates:
the _Biased_ strategy may, under bad circumstances, lead fish closer to the predator than away from it (i.e. when
the predator is to the right and the fish turns right), while the _Refuge_ strategy causes fish to passively
'meet their doom' when they are not close to a refuge (which, of course, happens from time to time).

What remains is an explanation for the relatively inferiority of _Zig-zag_ and _Protean_. For both, sub-optimal
escape situations can be conceived. For example, the _Zig-zag_ strategy may perform poorly when a fish has already
commenced a zig-zag manouver, but after making a curve or half-curve, 'returns' close to the predator, who has only
moved slightly forward. In these cases we could say that curves and half-curves produced by the fish are an inefficient
set of movements. (This of ourse assumes the predator does not get confused, which presumably may be a reason why
_Zig-zag_ is better than, say, _Biased_.) Similarly, the _Protean_ strategy may be invoked ineffectively, for instance
when it picks an angle very close to the predator's emergence angle.

**RQ, corollary I.** For exactly the same reason as used in my answer to the research question, I conclude that I must
reject my hypothesis here as well.

**RQ, corollary II.** Since I did not have a clear hypothesis for this corollary, I simply re-iterate my observation for
this last question: fish school size does impact (a subset of) the strategies' mortality rates, although it does
not change the best strategy (or, rather, top four of strategies).

Interestingly, 'impact' cannot clearly be interpreted as a raise or decrease in mortality rates; some strategies seem
to work better (in terms of the `C` and `C/L` metrics) at greater fish school sizes, such as _Biased_, while others
instead fare better at relatively small fish school sizes (_Mixed_, _Solitary when nearby_). For yet others, no
clear effect can be observed. This is my underlying argument for the claim that fish school size only 'impacts'
mortality rates.

Why do the four best strategies remain effective, even if the fish school size increases? If group-level interactions
among the fish are to be considered, then these effects must affect the mortality rates relatively little, so as to
keep the top four strategies in their respective ranks. If instead group-level interactions are not significant, then
since the strategy works best at a low size, and size is not altering this effective working, then it is to be
expected that the top four strategies remain best. Both scenarios are conceivable.
