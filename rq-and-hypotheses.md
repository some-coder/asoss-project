## Hypotheses

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
