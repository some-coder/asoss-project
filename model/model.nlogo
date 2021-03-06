;; FlockingTopo.nlogo
;;
;; Flocking model featuring topological interactions
;; Escape strategies
;;
;; Hanno 2016

breed [fish onefish]
breed [predators predator]


fish-own [
  flockmates            ;; agentset of nearby fish
  nearest-neighbor      ;; closest one of our flockmates
  nearest-predator      ;; closest predator in range
  vision                ;; current vision range
  delta-speed           ;; random speed dev. per update
  delta-noise           ;; random rotation per update
  ; New.
  nearest-refuge        ;; closest refuge in user-set range
  last-esc-subtick      ;; Last subtick of a single escape.
  last-esc-dir          ;; Last escape direction. Is an absolute (not relative) heading!
  ; Both are used for the zig-zag method.
  esc-start-subtick     ;; Starting subtick of escape.
  esc-start-heading     ;; Start heading of escape, straight away from the predator.
  is-at-refuge          ;; Whether the fish is at a refuge.
]

predators-own [
  nearest-prey
  locked-on             ;; locked on prey if any
  delta-noise           ;; random rotation per update
  handle-time           ;; count down handle time
]

globals [
  catches
  losts
  lock-ons
  counter
  ordetect
  prevprey
  ; New.
  subticks              ;; Keep track of 'de-facto' ticks, taking into account updating frequency.
]

to create-coral-reefs  ; observer method
  if (escape-strategy = "refuge" or escape-strategy = "refuge-escape") [
    ; Only create coral reefs when the strategy involves them.
    let i number-coral-reefs
    loop [
      if (i <= 0) [
        stop
      ]
      let x random-pxcor
      let y random-pycor
      ask patch x y [
        if is-not-already-coral-reef [
          create-single-refuge
          set i (i - 1)
        ]
      ]
    ]
  ]
end

to-report is-not-already-coral-reef  ; patch reporter
  ; Note that it may be that the patch itself has not already been assigned
  ; to be a coral reef, but that this instead has been done to one of the
  ; (radius-1 Moore) neighbours of the patch at (x, y). In such cases we
  ; also skip said patch, so as to avoid too much overlap between reefs.
  report (([pcolor] of self) != 2) and (all? neighbors [pcolor != 2])
end

to create-single-refuge  ; patch procedure
  ask (n-of refuges-per-coral-reef (patches in-radius 2)) [
    set pcolor 2
  ]
end

to setup
  clear-all
  create-fish population [
    set color yellow - 2 + random 7  ;; random shades look nice ?
    set size 1.5
    set vision max-vision
    setxy random-xcor random-ycor
    ; New.
    set last-esc-subtick -1
    set is-at-refuge false
  ]
  create-coral-reefs
  set counter 0
  set lock-ons 0
  set ordetect 8
  reset-ticks
  set subticks 0
end

to go
  ask fish [
    set delta-speed 0.1 * (random-normal speed (speed * 0.01 * speed-stddev))
    set delta-noise 0.1 * (random-normal 0 noise-stddev)
  ]
  ask predators [
    set delta-noise 0.1 * (random-normal 0 predator-noise-stddev)
  ]
  if ticks = 300 [
   create-predators predator-population [
    set color green
    set size 2.0
    setxy random-xcor random-ycor
    set nearest-prey nobody
    set locked-on nobody
  ]]
  ;let escape-task select-escape-task
  let t 0
  repeat 10 [
    if t mod (11 - update-freq) = 0 [
      let dt 1 / update-freq
      ask fish [
        let weight 1
        find-nearest-predator
        ifelse nearest-predator != nobody [
          find-nearest-refuge  ; Only check for refuges when this is relevant (i.e. during escapes).
          ( select-escape-task dt )
          set weight flocking-weight
        ][
          ; We don't need to escape anymore, so we're not hiding at any refuge (anymore).
          set is-at-refuge false
        ]
        if not ((escape-strategy = "solitary-when-nearby") and ((nearest-predator-distance nearest-predator) < solitary-distance)) [
          ; Skip flocking if we're following the (partially) selfish strategy.
          flock dt * weight
        ]
      ]
    ]
    if t mod (11 - predator-update-freq) = 0 [
      let dt 1 / predator-update-freq
      ask predators [
        select-prey dt
        hunt dt
      ]
    ]
    ask fish [
      rt delta-noise
      fd delta-speed
    ]
    ask predators [
      rt delta-noise
      fd 0.1 * predator-speed
    ]
    set t t + 1
    set subticks (subticks + 1)  ; Update de-facto ticks.
  ]
  if not hunting?
  [set counter counter + 1]
  if counter > 300
  [set hunting? true
   set detection-range ordetect]
  tick
end

;; FISH PROCEDURES

to select-escape-task [dt]
  if escape-strategy = "default" [ run   [ [] -> escape-default dt ] ] ;report task escape-default
  if escape-strategy = "turn 90 deg" [ run   [ [] -> escape-90 dt ] ]
  if escape-strategy = "sacrifice" [ run   [ [] -> escape-sacrifice dt ] ]
  if escape-strategy = "sprint" [ run   [ [] ->  escape-sprint dt ] ]
  if escape-strategy = "mixed" [ run   [ [] ->  escape-mixed dt ] ]
  if escape-strategy = "solitary-when-nearby" [ run   [ [] ->  escape-solitary-when-nearby dt ] ]
  if escape-strategy = "zig-zag" [ run   [ [] ->  escape-zig-zag dt ] ]
  if escape-strategy = "optimal" [ run   [ [] ->  escape-optimal dt ] ]
  if escape-strategy = "protean" [ run   [ [] ->  escape-protean dt ] ]
  if escape-strategy = "biased" [ run   [ [] ->  escape-biased dt ] ]
  if escape-strategy = "refuge" [ run   [ [] ->  escape-refuge dt false] ]
  if escape-strategy = "refuge-escape" [ run   [ [] ->  escape-refuge dt true] ]
end


to flock [dt] ;; fish procedure
  find-flockmates
  if any? flockmates [
    find-nearest-neighbor
    ifelse distance nearest-neighbor < minimum-separation
      [separate dt]
      [cohere dt]
    align dt
  ]
end

to find-nearest-predator ;; fish procedure
  set nearest-predator nobody

  if (hunting? or always_react?)
  [
    set nearest-predator min-one-of predators in-cone detection-range FOV [distance myself]
  ]
end

to find-nearest-refuge ;; fish procedure
  set nearest-refuge nobody
  if (escape-strategy = "refuge" or escape-strategy = "refuge-escape") [
    set nearest-refuge min-one-of (patches with [ pcolor = 2 ]) in-cone refuge-detection-range FOV [ distance myself ]
  ]
end

to find-flockmates  ;; fish procedure
  set flockmates other fish in-cone vision FOV
  ;; adjust vision for next update
  let n count flockmates
  ifelse n > topo
    [set vision 0.95 * vision]
    [set vision 1.05 * vision]
  set vision min (list vision max-vision)
end

to find-nearest-neighbor ;; fish procedure
  set nearest-neighbor min-one-of flockmates [distance myself]
end

;;; SEPARATE

to separate [dt] ;; fish procedure
  turn-away ([heading] of nearest-neighbor) max-separate-turn * dt
end

;;; ALIGN

to align [dt] ;; fish procedure
  turn-towards average-flockmate-heading max-align-turn * dt
end

to-report average-flockmate-heading  ;; fish procedure
  ;; We can't just average the heading variables here.
  ;; For example, the average of 1 and 359 should be 0,
  ;; not 180.  So we have to use trigonometry.
  let x-component sum [dx] of flockmates
  let y-component sum [dy] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; COHERE

to cohere [dt]  ;; fish procedure
  turn-towards average-heading-towards-flockmates max-cohere-turn * dt
end

to-report average-heading-towards-flockmates  ;; fish procedure
  ;; "towards myself" gives us the heading from the other turtle
  ;; to me, but we want the heading from me to the other turtle,
  ;; so we add 180
  let x-component mean [sin (towards myself + 180)] of flockmates
  let y-component mean [cos (towards myself + 180)] of flockmates
  ifelse x-component = 0 and y-component = 0
    [ report heading ]
    [ report atan x-component y-component ]
end

;;; PREDATOR PROCEDURES

to select-prey [dt] ;; predator procedure
  set handle-time handle-time - dt

  if handle-time <= 0
  [
    set nearest-prey min-one-of fish in-cone predator-vision predator-FOV [distance myself]
    ifelse locked-on != nobody and
         ((nearest-prey = nobody or distance nearest-prey > lock-on-distance) or
          (nearest-prey != locked-on) or
          (([is-at-refuge] of nearest-prey) = true))
      [
        ;; lost it
        release-locked-on
        set handle-time switch-penalty
        set losts losts + 1
        set color blue
        ;stop
    ]
    [
      set color orange  ;; hunting w/o lock-on
      if nearest-prey != nobody
      [
        if distance nearest-prey < lock-on-distance
        [
          set locked-on nearest-prey
          ask locked-on [set color magenta]
          if nearest-prey != prevprey
          [
            set lock-ons lock-ons + 1
          ]
          set color red
          set prevprey nearest-prey
          set hunting? true
        ]
      ]
    ]
  ]
end

to hunt [dt] ;; predator procedure
  if nearest-prey != nobody [
    turn-towards towards nearest-prey max-hunt-turn * dt
    if locked-on != nobody [
      if locked-on = min-one-of fish in-cone catch-distance 10 [distance myself]
      [
        set catches catches + 1
        release-locked-on
        set hunting? false
        set counter 0
        set detection-range ordetect  ;;;; was: 0
        set handle-time catch-handle-time
        rt random-normal 0 45
        set color green
      ]
    ]
  ]
end

to release-locked-on
  if (locked-on != nobody) [
    ask locked-on [
      set color yellow - 2 + random 7
    ]
  ]
  set locked-on nobody
  set nearest-prey nobody
  set prevprey nobody
end

;;; ESCAPE STRATEGIES

to escape-default [dt]
  ;if color = magenta
  ;  [type who type "=I try " type heading]
  turn-away (towards nearest-predator) max-escape-turn * dt * (1 - flocking-weight)
  ;if color = magenta
  ;  [type " -> " print heading]
end

to escape-90 [dt]
   let dh subtract-headings heading [heading] of nearest-predator
   ifelse dh > 0
     [ turn-towards ([heading] of nearest-predator + 90) max-escape-turn * dt  * (1 - flocking-weight)]
     [ turn-towards ([heading] of nearest-predator - 90) max-escape-turn * dt  * (1 - flocking-weight)]
end

to escape-sacrifice [dt]
  if self != [locked-on] of nearest-predator [escape-default dt]
end

to escape-sprint [dt]
  escape-default dt
  set delta-speed delta-speed + dt * speed  * (1 - flocking-weight)
end

to escape-mixed [dt]
  let front-angle 20
  ifelse ( (predator-in-angular-region (-1 * front-angle) front-angle) or (predator-in-angular-region (180 - front-angle) (-1 * (180 - front-angle))) ) [
    ; predator is at the front or back
    escape-protean dt
  ][
    ; predator is to the left or right
    escape-90 dt
  ]
end

to escape-solitary-when-nearby [dt]
  ; The point of this strategy is that when a predator gets sufficiently close-by,
  ; the `escape-90` gets executed without regard of flocking (cohering, separation,
  ; alignment); fish become selfish. For said mechanism, see the `go` procedure.
  escape-90 dt
end

to escape-zig-zag [dt]
  if last-esc-subtick != (subticks - 1) [
    let rpa relative-predator-angle
    ifelse rpa > 0 [
      set esc-start-heading (heading + (rpa - 180))
    ][
      set esc-start-heading (heading + (rpa + 180))
    ]
    set esc-start-subtick subticks
  ]
  let freq (update-freq * zig-zag-freq)
  let cos-t (360 / freq) * (subticks - esc-start-subtick)
  set last-esc-dir esc-start-heading + (90 * (cos cos-t))
  turn-towards last-esc-dir (max-escape-turn * dt * (1 - flocking-weight))
  set last-esc-subtick subticks
end

to escape-optimal [dt]
  let delta subtract-headings heading [heading] of nearest-predator
  let optimal-turn (90 - (asin (speed / predator-speed)))
  ifelse (delta > 0) [
    turn-towards ([heading] of nearest-predator + optimal-turn) (max-escape-turn * dt * (1 - flocking-weight))
  ][
    turn-towards ([heading] of nearest-predator - optimal-turn) (max-escape-turn * dt * (1 - flocking-weight))
  ]
end

to escape-set-direction [dt direction]
  ; Escape in the absolute heading `direction`. In subsequent ticks of a single escape,
  ; the direction does not change. Only if a temporal gap of at least one tick is
  ; detected between two escape attempts, the `direction` is used to re-orient the fish.
  if last-esc-subtick != (subticks - 1) [
    ; The fish is in a new escape sequence. Set up the specified escape direction.
    set last-esc-dir direction
  ]
  turn-towards last-esc-dir (max-escape-turn * dt * (1 - flocking-weight))
  set last-esc-subtick subticks
end

to escape-protean [dt]
  if (last-esc-subtick != (subticks - 1)) or ((subticks - esc-start-subtick) > (update-freq * protean-turn-interval)) [
    ; If the fish needs to do a new escape manouver, or if it is time to
    ; update the escape direction, draw a new pseudo-random direction.
    ;   The direction can be any absolute angle in 360 degrees, except
    ; the direction from which the predator is heading plus and minus
    ; a 'danger-half-angle' range around this angle; these angles
    ; are clearly suboptimal to swim towards to.
    set esc-start-heading ((relative-predator-angle + danger-half-angle + (random (360 - 2 * danger-half-angle))) mod 360)
    set esc-start-subtick subticks
  ]
  turn-towards esc-start-heading (max-escape-turn * dt * (1 - flocking-weight))
  set last-esc-subtick subticks
end

to escape-biased [dt]
  let go-right (random 100) <= 90  ; go right 90% of the time
  let rpa relative-predator-angle
  let ang (biased-angle go-right rpa)
  if (last-esc-subtick != (subticks - 1)) [
    print go-right
    print (rpa mod 360)
    print heading
    print ang
  ]
  escape-set-direction dt ang
end

to escape-refuge [dt also-escape]
  ifelse (nearest-refuge != nobody) [
    ; go to the refuge
    ifelse (([pcolor] of (patch xcor ycor)) = 2) [
      ; already at a refuge, so stay here
      set is-at-refuge true
      set delta-speed (0.01 * delta-speed)  ; slow down rapidly
    ][
      turn-towards (heading + relative-refuge-angle) (max-escape-turn * dt * (1 - flocking-weight))
    ]
  ][
    if also-escape [
      escape-90 dt
    ]
  ]
end

;;; HELPER PROCEDURES

to turn-towards [new-heading max-turn]  ;; fish procedure
  turn-at-most (subtract-headings new-heading heading) max-turn
end

to turn-away [new-heading max-turn]  ;; fish procedure
  turn-at-most (subtract-headings heading new-heading) max-turn
end

;; turn right by "turn" degrees (or left if "turn" is negative),
;; but never turn more than "max-turn" degrees
to turn-at-most [turn max-turn]  ;; turtle procedure
  ifelse abs turn > max-turn
    [ ifelse turn > 0
        [ rt max-turn ]
        [ lt max-turn ] ]
    [ rt turn ]
end


;;; EXTRA HELPER PROCEDURES


to-report relative-predator-angle  ; fish reporter
  let x [xcor] of nearest-predator
  let y [ycor] of nearest-predator
  set x (x - xcor)
  set y (y - ycor)
  ; get normalised angular position of the predator
  let pred-angle atan x y
  set pred-angle subtract-headings pred-angle heading  ; negative: to the left, positive: to the right
  report pred-angle
end

to-report relative-refuge-angle  ; fish reporter
  let x [pxcor] of nearest-refuge
  let y [pycor] of nearest-refuge
  set x (x - xcor)
  set y (y - ycor)
  let refuge-angle atan x y
  set refuge-angle subtract-headings refuge-angle heading
  report refuge-angle
end

to-report predator-in-angular-region [angle-start angle-stop]  ; fish reporter
  ; A `fish` procedure that determines whether the nearest predator's
  ; relative angular position w.r.t. the fish lies within the specified
  ; angular range.
  ;
  ; :param angle-start: The starting angle relative to the fish. Inclusive.
  ; :param angle-stop: The stopping angle relative to the fish. Inclusive.
  ; get relative position of the predator w.r.t. the fish
  let pred-angle relative-predator-angle
  ; check whether predator is in specified angle
  ifelse angle-start > angle-stop [
    report ((pred-angle >= angle-start) or (pred-angle <= angle-stop))
  ][
    report ((pred-angle >= angle-start) and (pred-angle <= angle-stop))
  ]
end

to-report nearest-predator-distance [np]  ; fish procedure
  ifelse (np = nobody) [
    report 1e6  ; just a large value
  ][
    let pred-x [xcor] of np
    let pred-y [ycor] of np
    let delta-x abs(xcor - pred-x)
    let delta-y abs(ycor - pred-y)
    report (delta-x * delta-x) + (delta-y * delta-y)
  ]
end

to-report biased-angle [go-right rpa]  ; fish reporter
  ; This reporter computes the heading a fish should swim to, supplied that
  ; it strictly needs to go right (left if `go-right` is set to `false`).
  ;   The complexity of this reporter comes from it taking into account
  ; that it should not choose 'predator angles', i.e. the direction the
  ; predator comes from, plus a range of +/- `danger-half-angle` degrees.
  ; By doing so, many more logical checks need to be made.
  let abs-rpa-min ((rpa - danger-half-angle) mod 360)
  let abs-rpa-max ((rpa + danger-half-angle) mod 360)
  let delta 0  ; only to be changed if we need to go left
  if (not go-right) [
    set delta 180
  ]
  ifelse (
    (go-right and abs-rpa-min <= 0 and abs-rpa-max >= 180) or
    ((not go-right) and abs-rpa-min >= 0 and abs-rpa-max <= 180)) [
    ; predator is fully out of the half-circle we want to move in
    report (random-normal (180 / 2) biased-angle-std-dev) + delta
  ][
    ifelse (
      (go-right and (abs-rpa-min <= 0 or abs-rpa-max >= 180)) or
      ((not go-right) and (abs-rpa-min >= 0 or abs-rpa-max <= 180))) [
      ; predator is in view, but not with twice the danger-half angle.
      let strt 0 + delta
      let stp 180 + delta
      if ((strt >= abs-rpa-min) and (strt <= abs-rpa-max)) [
        ; Starting angle is in the predator range of degrees, so shift forward.
        set strt abs-rpa-max
      ]
      if ((stp >= abs-rpa-min) and (stp <= abs-rpa-max)) [
        ; Ending angle is in the predator range of degrees, so shift backward.
        set stp abs-rpa-min
      ]
      report (strt + (random-normal ((180 - (stp - delta) - (strt - delta)) / 2) biased-angle-std-dev))
    ][
      ; predator is fully in view, with twice the danger-half angle.
      let strt 0 + delta
      let stp 180 + delta
      let middle-start abs-rpa-min
      let ang ((random-normal ((180 - ((abs-rpa-max - delta) - (abs-rpa-min - delta))) / 2) biased-angle-std-dev) + delta)
      ifelse ((ang >= abs-rpa-min) and (ang <= abs-rpa-max)) [
        ; our random angle is in the dangerous semicircle, so we need to shift it forward
        report ang + (abs-rpa-max - abs-rpa-min)
      ][
        report ang
      ]
    ]
  ]
end


; Copyright 1998 Uri Wilensky.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
250
0
770
521
-1
-1
7.2113
1
10
1
1
1
0
1
1
1
-35
35
-35
35
1
1
1
ticks
30.0

BUTTON
38
53
115
86
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
125
52
206
85
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
12
10
235
43
population
population
1.0
1000.0
100.0
1.0
1
NIL
HORIZONTAL

SLIDER
11
294
235
327
max-align-turn
max-align-turn
0.0
20.0
5.0
0.25
1
degrees
HORIZONTAL

SLIDER
11
328
236
361
max-cohere-turn
max-cohere-turn
0.0
20.0
4.0
0.25
1
degrees
HORIZONTAL

SLIDER
11
362
235
395
max-separate-turn
max-separate-turn
0.0
20.0
2.0
0.25
1
degrees
HORIZONTAL

SLIDER
12
94
235
127
max-vision
max-vision
0.0
20.0
10.0
0.5
1
patches
HORIZONTAL

SLIDER
12
176
235
209
minimum-separation
minimum-separation
0.0
5.0
1.75
0.25
1
patches
HORIZONTAL

SLIDER
9
451
236
484
speed-stddev
speed-stddev
0
100
10.0
1
1
% of speed
HORIZONTAL

SLIDER
12
210
235
243
FOV
FOV
0
360
360.0
10
1
degrees
HORIZONTAL

SLIDER
9
414
236
447
noise-stddev
noise-stddev
0
5
1.0
0.1
1
degrees
HORIZONTAL

SLIDER
12
130
235
163
topo
topo
1
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
12
244
235
277
speed
speed
0
2
0.4
0.1
1
patches/tick
HORIZONTAL

SLIDER
793
13
992
46
predator-population
predator-population
0
5
1.0
1
1
NIL
HORIZONTAL

SLIDER
795
142
993
175
predator-vision
predator-vision
0
100
16.0
1
1
NIL
HORIZONTAL

SLIDER
795
219
993
252
predator-speed
predator-speed
0
5
0.6
0.1
1
patches/tick
HORIZONTAL

SLIDER
794
256
994
289
max-hunt-turn
max-hunt-turn
0
20
10.0
0.25
1
degrees
HORIZONTAL

SLIDER
793
449
994
482
predator-noise-stddev
predator-noise-stddev
0
5
2.0
0.1
1
degrees
HORIZONTAL

SLIDER
794
182
993
215
predator-FOV
predator-FOV
0
360
270.0
1
1
degrees
HORIZONTAL

SWITCH
794
54
897
87
hunting?
hunting?
0
1
-1000

SLIDER
794
298
993
331
catch-handle-time
catch-handle-time
0
1000
50.0
1
1
ticks
HORIZONTAL

CHOOSER
11
501
234
546
update-freq
update-freq
1 2 5 10
3

CHOOSER
793
492
996
537
predator-update-freq
predator-update-freq
1 2 5 10
3

SLIDER
794
376
994
409
lock-on-distance
lock-on-distance
0
5
5.0
0.1
1
NIL
HORIZONTAL

SLIDER
793
413
993
446
catch-distance
catch-distance
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
794
334
994
367
switch-penalty
switch-penalty
0
50
5.0
1
1
ticks
HORIZONTAL

BUTTON
924
54
990
87
reset
set catches 0\nset losts 0
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
794
90
860
135
NIL
catches
17
1
11

MONITOR
863
89
927
134
NIL
losts
17
1
11

CHOOSER
10
559
233
604
escape-strategy
escape-strategy
"default" "turn 90 deg" "sacrifice" "sprint" "mixed" "solitary-when-nearby" "zig-zag" "optimal" "protean" "biased" "refuge" "refuge-escape"
5

SLIDER
11
645
234
678
max-escape-turn
max-escape-turn
0
180
180.0
1
1
degrees
HORIZONTAL

SLIDER
10
607
234
640
detection-range
detection-range
0
50
8.0
1
1
patches
HORIZONTAL

SLIDER
10
681
234
714
flocking-weight
flocking-weight
0
1
0.9
0.1
1
NIL
HORIZONTAL

MONITOR
933
90
991
135
NIL
lock-ons
17
1
11

BUTTON
300
588
363
621
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
374
589
493
622
NIL
repeat 10 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
506
589
632
622
NIL
repeat 4000 [go]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
799
577
934
610
always_react?
always_react?
1
1
-1000

SLIDER
1037
40
1271
73
solitary-distance
solitary-distance
0.0
5.0
1.0
0.1
1
patches
HORIZONTAL

TEXTBOX
1038
18
1188
36
Extra strategy variables
12
0.0
1

SLIDER
1037
80
1270
113
zig-zag-freq
zig-zag-freq
5
40
20.0
1
1
ticks
HORIZONTAL

SLIDER
1037
362
1269
395
number-coral-reefs
number-coral-reefs
0
10
8.0
1
1
refuges
HORIZONTAL

TEXTBOX
1038
344
1247
374
Extra environment variables
12
0.0
1

SLIDER
1037
452
1270
485
refuge-detection-range
refuge-detection-range
0
10
5.0
1
1
patches
HORIZONTAL

SLIDER
1037
407
1269
440
refuges-per-coral-reef
refuges-per-coral-reef
0
10
6.0
1
1
refuges
HORIZONTAL

SLIDER
1037
121
1270
154
protean-turn-interval
protean-turn-interval
0
8
4.0
1
1
ticks
HORIZONTAL

SLIDER
1037
163
1270
196
danger-half-angle
danger-half-angle
0
40
20.0
1
1
degrees
HORIZONTAL

SLIDER
1037
204
1270
237
biased-right-probability
biased-right-probability
0
100
90.0
1
1
%
HORIZONTAL

SLIDER
1037
247
1270
280
biased-angle-std-dev
biased-angle-std-dev
0
40
30.0
1
1
degrees
HORIZONTAL

BUTTON
300
645
633
708
Go (2000 ticks)
repeat 2000 [\n  go\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model is an attempt to mimic the flocking of birds.  (The resulting motion also resembles schools of fish.)  The flocks that appear in this model are not created or led in any way by special leader birds.  Rather, each bird is following exactly the same set of rules, from which flocks emerge.

## HOW IT WORKS

The birds follow three rules: "alignment", "separation", and "cohesion".

"Alignment" means that a bird tends to turn so that it is moving in the same direction that nearby birds are moving.

"Separation" means that a bird will turn to avoid another bird which gets too close.

"Cohesion" means that a bird will move towards other nearby birds (unless another bird is too close).

When two birds are too close, the "separation" rule overrides the other two, which are deactivated until the minimum separation is achieved.

The three rules affect only the bird's heading.  Each bird always moves forward at the same constant speed.

## HOW TO USE IT

First, determine the number of birds you want in the simulation and set the POPULATION slider to that value.  Press SETUP to create the birds, and press GO to have them start flying around.

The default settings for the sliders will produce reasonably good flocking behavior.  However, you can play with them to get variations:

Three TURN-ANGLE sliders control the maximum angle a bird can turn as a result of each rule.

VISION is the distance that each bird can see 360 degrees around it.

## THINGS TO NOTICE

Central to the model is the observation that flocks form without a leader.

There are no random numbers used in this model, except to position the birds initially.  The fluid, lifelike behavior of the birds is produced entirely by deterministic rules.

Also, notice that each flock is dynamic.  A flock, once together, is not guaranteed to keep all of its members.  Why do you think this is?

After running the model for a while, all of the birds have approximately the same heading.  Why?

Sometimes a bird breaks away from its flock.  How does this happen?  You may need to slow down the model or run it step by step in order to observe this phenomenon.

## THINGS TO TRY

Play with the sliders to see if you can get tighter flocks, looser flocks, fewer flocks, more flocks, more or less splitting and joining of flocks, more or less rearranging of birds within flocks, etc.

You can turn off a rule entirely by setting that rule's angle slider to zero.  Is one rule by itself enough to produce at least some flocking?  What about two rules?  What's missing from the resulting behavior when you leave out each rule?

Will running the model for a long time produce a static flock?  Or will the birds never settle down to an unchanging formation?  Remember, there are no random numbers used in this model.

## EXTENDING THE MODEL

Currently the birds can "see" all around them.  What happens if birds can only see in front of them?  The `in-cone` primitive can be used for this.

Is there some way to get V-shaped flocks, like migrating geese?

What happens if you put walls around the edges of the world that the birds can't fly into?

Can you get the birds to fly around obstacles in the middle of the world?

What would happen if you gave the birds different velocities?  For example, you could make birds that are not near other birds fly faster to catch up to the flock.  Or, you could simulate the diminished air resistance that birds experience when flying together by making them fly faster when in a group.

Are there other interesting ways you can make the birds different from each other?  There could be random variation in the population, or you could have distinct "species" of bird.

## NETLOGO FEATURES

Notice the need for the `subtract-headings` primitive and special procedure for averaging groups of headings.  Just subtracting the numbers, or averaging the numbers, doesn't give you the results you'd expect, because of the discontinuity where headings wrap back to 0 once they reach 360.

## RELATED MODELS

* Moths
* Flocking Vee Formation
* Flocking - Alternative Visualizations

## CREDITS AND REFERENCES

This model is inspired by the Boids simulation invented by Craig Reynolds.  The algorithm we use here is roughly similar to the original Boids algorithm, but it is not the same.  The exact details of the algorithm tend not to matter very much -- as long as you have alignment, separation, and cohesion, you will usually get flocking behavior resembling that produced by Reynolds' original model.  Information on Boids is available at http://www.red3d.com/cwr/boids/.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1998).  NetLogo Flocking model.  http://ccl.northwestern.edu/netlogo/models/Flocking.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1998 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2002.

<!-- 1998 2002 -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.0
@#$#@#$#@
set population 200
setup
repeat 200 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="4" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="4000"/>
    <metric>catches</metric>
    <metric>losts</metric>
    <enumeratedValueSet variable="population">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="topo">
      <value value="1"/>
      <value value="2"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flocking-weight">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catch-distance">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-vision">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noise-stddev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-separate-turn">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lock-on-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-FOV">
      <value value="270"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catch-handle-time">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="update-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-hunt-turn">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-noise-stddev">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-stddev">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-align-turn">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-update-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunting?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-escape-turn">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="escape-strategy">
      <value value="&quot;default&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cohere-turn">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-penalty">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-range">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-speed">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-separation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FOV">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="always_react?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_4strat" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="4000"/>
    <metric>catches</metric>
    <metric>losts</metric>
    <metric>lock-ons</metric>
    <enumeratedValueSet variable="population">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="topo">
      <value value="1"/>
      <value value="2"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flocking-weight">
      <value value="0"/>
      <value value="0.1"/>
      <value value="0.5"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catch-distance">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-vision">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noise-stddev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-separate-turn">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lock-on-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-FOV">
      <value value="270"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catch-handle-time">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="update-freq">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-hunt-turn">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-noise-stddev">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-stddev">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-align-turn">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-update-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunting?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-escape-turn">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="escape-strategy">
      <value value="&quot;default&quot;"/>
      <value value="&quot;turn 90 deg&quot;"/>
      <value value="&quot;sacrifice&quot;"/>
      <value value="&quot;sprint&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cohere-turn">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-penalty">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-range">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-speed">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-separation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FOV">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="always_react?">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment_defaultstrat" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="4000"/>
    <metric>catches</metric>
    <metric>losts</metric>
    <metric>lock-ons</metric>
    <enumeratedValueSet variable="population">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="topo">
      <value value="1"/>
      <value value="2"/>
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="flocking-weight">
      <value value="0.3"/>
      <value value="0.7"/>
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-population">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catch-distance">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-vision">
      <value value="16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="noise-stddev">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-separate-turn">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lock-on-distance">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-FOV">
      <value value="270"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="catch-handle-time">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="update-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-hunt-turn">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-noise-stddev">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed-stddev">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-vision">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-align-turn">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-update-freq">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunting?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-escape-turn">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="escape-strategy">
      <value value="&quot;default&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cohere-turn">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="switch-penalty">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detection-range">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="predator-speed">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="minimum-separation">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="speed">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="FOV">
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="always_react?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
