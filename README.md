# Predation on Fish Schools: Prey Escape Strategies

This is my repository for the final project of Advanced Self-Organisation of Social Systems (ASOSS), year 2021.

**Contact details.** Niels de Jong (s3366235) <a href="mailto:n.a.de.jong@student.rug.nl">mail</a>.

## Research question and strategies

Which of the following eight escape strategies for individual fish leads to the lowest
absolute number of catches in the `Flocking_TrPEsH.nlogo` model?

| #   | Strategy | Details | References |
| :-- | :------- | :------ | :--------- |
| 1 | Mixed | Turn uniformly randomly at the front and back, and turn perpendicular to the threat when the threat is lateral. | _1_ |
| 2 | Cooperative-selfish | Unless the threat is very close, try to escape while following other fish; otherwise escape selfishly by moving directly away from the predator. | _2_ |
| 3 | Zig-zag | Move away from the threat while making lateral deviations. | _3_ (p. 2464) |
| 4 | Optimal | Turn away from the threat by `90 + arcsin(velocity_prey / velocity_predator)` degrees. | _3_ (p. 2467) |
| 5 | Protean | Turn uniformly randomly, always. | _3_ (p. 2464) |
| 6 | Biased | Opt to turn right (left) most of the time. Given a selected direction, turn using a uniformly randomly generated degree between 0 and `max-turn-angle`. | _3_ (p. 2464) |
| 7 | Refuges | If a refuge is near, move to the refuge. Otherwise escape directly away from the predator. | _4_, _3_ (p. 2468) |
| 7 | Weighted refuges | Like (7), but take into account nearby predators even when planning to move to a refuge. | _4_, _3_ (p. 2468) |

**Corollary I.** Which strategy leads to the lowest ratio of catches to lock-ons?

**Corollary II.** Does the size of the fish school impact which strategy is optimal according to these two criteria?

## Methods

I will implement the strategies in the `Flocking_TrPEsH.nlogo` NetLogo model, used in the final
lab of the ASOSS practicals.

I plan to do data collection in a full factorial design: each strategy is combined with multiple fish school
sizes (100, 200, 300 fish) to yield individual experimental conditions. All other model parameters are left
at defaults. Per condition, I collect over 2000 ticks two statistics: (1) absolute number of catches by the
(single) predator of the model, and (2) the ratio of catches to lock-ons of said predator.

## Scheduling and communication

| Week | Start  | End    | Objectives                                                  |
| ---: | :----- | :----- | :---------------------------------------------------------- |
| 23   |  7 Jun | 13 Jun | Implement strategies (1) up until (4).                      |
| 24   | 14 Jun | 20 Jun | Implement strategies (5) up until (8).                      |
| 25   | 21 Jun | 27 Jun | Verify strategies, do experiments with varying group sizes. |
| 26   | 28 Jun |  4 Jul | Create and deliver presentation, hand in work.              |

**Communication.** In weeks 23, 24, and 25, I will notify my project supervisor (Rolf) of
the progress I made in said week via e-mail, and what I am planning to do for upcoming week.

## Data management and analysis

I manage my code via <a href="https://www.github.com/">GitHub</a>, a version control platform
based on <a href="https://en.wikipedia.org/wiki/Git">Git</a>  that allows me to roll back to previous
versions if anything might go wrong.

Since GitHub covers both model as well as data, both are securely kept track of. For additional data
safety, I use a simple file format called
<a href="https://en.wikipedia.org/wiki/Comma-separated_values">comma-separated values (CSV)</a>, to avoid any
unnecessary complexity in the data. Data will be analysed using the statistical scripting language
<a href="https://www.r-project.org/">R</a>.

