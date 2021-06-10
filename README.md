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

## References

| #   | Full reference |
| --: | :-- |
| _1_ | Nair, Changsing, Stewart and McHenry (2017). _Fish prey change strategy with the direction of a threat._ Proceedings of the Royal Society B, 284(1857), 20170393. DOI: <a href="https://royalsocietypublishing.org/doi/10.1098/rspb.2017.0393">10.1098/rspb.2017.0393</a> |
| _2_ | Zheng, Kashimori, Hoshino, Fujita and Kambara (2004). _Behaviour pattern (innate action) of individuals in fish schools generating efficient collective evasion from predation._ Journal of Theoretical Biology, 235(2), pp. 153–167. DOI: <a href="https://www.sciencedirect.com/science/article/abs/pii/S0022519305000056?via%3Dihub">10.1016/j.jtbi.2004.12.025</a> |
| _3_ | Domenici, Blagburn and Bacon (2011). _Animal escapolog I: theoretical issues and emerging trends in escape trajectories._ The Journal of Experimental Biology, 214(15), pp. 2463–2473. DOI: <a href="https://journals.biologists.com/jeb/article/214/15/2463/10427/Animal-escapology-I-theoretical-issues-and">10.1242/jeb.029652</a> |
| _4_ | Cooper Jr. (2016). _Directional escape strategy by the striped plateau lizard_ (Sceloporus virgatus)_: turning to direct escape away from predators at variable escape angles._ Behaviour 153(4), pp. 401–419. DOI: <a href="https://brill.com/view/journals/beh/153/4/article-p401_2.xml">10.1163/1568539X-00003353</a> |

