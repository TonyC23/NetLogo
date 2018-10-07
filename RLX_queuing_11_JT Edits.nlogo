;; A model to show why cars queue across the train tracks at a railway level crossing
;; Elements are adapted from Traffic Basic from NetLogo models library
globals [
  patches-ahead
]


breed [ eastbound-cars eastbound-car ]
breed [ westbound-cars westbound-car ]


turtles-own [
  speed
  speed-limit
  speed-min
  turn-right?  ;; true if the turtle wants to turn right
  compliant?   ;; true if the turtle waits until the RLX is clear before entering it
]


to setup
  clear-all
  setup-road
  setup-cars
  reset-ticks
end

to setup-road ;; patch procedure

  ask patches [
    set plabel-color red
    ;; main road
    ifelse (pycor > -2 and pycor < 2)
      [set pcolor white ]
      [ set pcolor grey ]
    ;; southbound side-road
    if (pycor < -1 and pxcor = 9)
      [set pcolor white ]
    ;; northbound side-road
    if (pycor > 1 and pxcor = -9)
      [set pcolor white ]
    ;; railway tracks
    if (pxcor > -2 and pxcor < 2)
      [ set pcolor yellow ]
  ]
end

to setup-cars

  set-default-shape turtles "car"

  if not any? turtles-on patch -18 1 and not any? turtles-on patch -17 1
  and not any? turtles-on patch -16 1 and count turtles < max-num-cars [
    create-eastbound-cars 1 [
      set color blue
      set size 1
      set xcor -18
      set ycor 1
      set heading 90
    ;; set initial speed to be in range 0.1 to 1.0
    set speed 0.1 + random-float 0.9
    set speed-limit 1
    set speed-min 0
    separate-cars

    ]
  ]


  if not any? turtles-on patch 18 -1 and not any? turtles-on patch 17 -1
   and not any? turtles-on patch 16 -1 and count turtles < max-num-cars [
    create-westbound-cars 1 [
      set color blue
      set size 1
      set xcor 18
      set ycor -1
      set heading 270
      set shape "left-car"
    ;; set initial speed to be in range 0.1 to 1.0
    set speed 0.1 + random-float 0.9
    set speed-limit 1
    set speed-min 0
    separate-cars
    ]
  ]

end

; this procedure is needed so when we click "Setup" we
; don't end up with any two cars on the same patch
to separate-cars ;; turtle procedure
  if any? other turtles-here [
    fd 1
    separate-cars
  ]
end

to go

  setup-cars

  ask eastbound-cars [
    avoid-queuing
    flag-queuing

    ;; set patches-ahead
    ;; if there is a car right ahead of you, match its speed then slow down
    let car-ahead one-of turtles-on patch-ahead 1
    ifelse car-ahead != nobody
      [ slow-down-car car-ahead ]
      [ speed-up-car ] ;; otherwise, speed up
    ;; don't slow down below speed minimum or speed up beyond speed limit
    if speed < speed-min [ set speed speed-min ]
    if speed > speed-limit [ set speed speed-limit ]
    fd speed

    if (random-float 1 < right-turn) [set turn-right? true]

    if (turn-right? = true and pxcor = 9 and pycor = 1) [
      ifelse (any? turtles-on patch 9 -1 or any? turtles-on patch 10 -1 or any? turtles-on patch 11 -1)
      [ set speed 0 ]
      [set heading 180
      set shape "down-car"
      speed-up-car] ;; Jase - this seems to occur very infrequently - is the intent that it happens more often?
    ]

    if not (pxcor = 9 and pycor = 1) [set turn-right? false]

    ;; to emulate the real world, wrapping is switched off and turtles leave the model at its edges
    if pxcor >= 18 [ die ]
    if pycor <= -18  [ die ]

  ]

  ask westbound-cars [
    avoid-queuing
    flag-queuing

    ;; set patches-ahead
    ;; if there is a car right ahead of you, match its speed then slow down
    let car-ahead one-of turtles-on patch-ahead 1
    ifelse car-ahead != nobody
      [ slow-down-car car-ahead ]
      [ speed-up-car ] ;; otherwise, speed up
    ;; don't slow down below speed minimum or speed up beyond speed limit
    if speed < speed-min [ set speed speed-min ]
    if speed > speed-limit [ set speed speed-limit ]
    fd speed

    ;; decide whether to turn right at side-road based on right-turn slider
    if (random-float 1 < right-turn) [set turn-right? true]
    if turn-right? = true and pxcor = -9 and pycor = -1 [
      ifelse any? turtles-on patch -9 1 or any? turtles-on patch -10 1 or any? turtles-on patch -11 1
      [ set speed 0 ]
      [set heading 0
      set shape "up-car"
      speed-up-car]
    ]

     set turn-right? false

     ;; to emulate the real world, wrapping is switched off and turtles leave the model at its edges
     if pxcor <= -18 [ die ]
     if pycor >= 18  [ die ]
  ]

tick
end

to slow-down-car [ car-ahead ] ;; turtle procedure
  ;; slow down so you are driving more slowly than the car ahead of you
  set speed [ speed ] of car-ahead - deceleration
end

to speed-up-car ;; turtle procedure
  set speed speed + acceleration
end

to avoid-queuing
  if (random-float 1 < compliance) [set compliant? true]
  if compliant? = true [
    ifelse ([pcolor] of patch-ahead 1 = yellow and [pcolor] of patch-ahead 1 = yellow
      and any? turtles-on patch-ahead 3) ;; Jason - not sure what this is doing as the command seems to repeat? I deleted one of
    ;;the repeated commands and nothing changes. I think it is also creating artificial behaviour in the vehicles - This is the main bit to get right.
    ;;I think what you want to identify is whether the space immediately after the rail line is empty so that you can slip into it. The judgement would be made in 2 ways. Either it is not empty but you
    ;;predict that it is going to be empty in the future because you are moving at a certain speed and so are the cars in front of you that you can see, OR you can see that it is empty so you move across.
    ;; the issue seems to be that people get stuck when their prediction of movement is wrong, no?
    ;; so, this could be done in a few ways - each car could monitor the spaces after the rail line and determine whether they 'think' the behaviour of cars in those spaces will result,
    ;;or has already resulted in a space opening up on the other side of the rail line for them to occupy. The accuracy of their perception of the spaces could be flat or could reduce with greater distance
    ;; or obscurity asymptotically to virtually zero after 5 or so cars given that their line of sight is blocked. i.e., you can see the first car great but the 5th in front of you is basically impossible.
    ;; this would npt be very hard to implement.
      [set speed 0]
      [speed-up-car]
  ]
  set compliant? false
end

to flag-queuing
  ifelse any? (turtles-on patches with [pcolor = yellow]) with [speed = 0] [
    ask patch 7 4 [ set plabel "QUEUING" ]
  ]
  [ask patch 7 4 [ set plabel "" ]]
end
@#$#@#$#@
GRAPHICS-WINDOW
364
4
753
394
-1
-1
10.3242
1
10
1
1
1
0
0
0
1
-18
18
-18
18
1
1
1
ticks
30.0

SLIDER
6
94
181
127
acceleration
acceleration
0
0.0099
0.005
0.0001
1
NIL
HORIZONTAL

SLIDER
6
138
181
171
deceleration
deceleration
0
0.099
0.05
0.001
1
NIL
HORIZONTAL

BUTTON
255
95
319
129
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
255
150
319
184
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
5
50
180
83
max-num-cars
max-num-cars
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
5
225
177
258
compliance
compliance
0
1.0
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
5
180
177
213
right-turn
right-turn
0
1.0
0.82
0.01
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

This model aims to reveal factors that can cause cars to queue on railway level crossings. Queuing occurs when one or more cars stop on the crossing for any length of time. Queuing has led to a small number of cases where trains have collided with cars.

The model used elements of the Traffic Basic model from the NetLogo library. This model retains code from the Traffic Basic model to keep cars separate and to adjust their speed to avoid colliding with the car in front. Cars attempt to maintain a minimum speed and avoid exceeding the speed limit. 

Cars traverse the main road travelling either east or the west. At the mid-point they cross the railway level crossing (RLX). Some drivers will comply with the clearway signals to avoid stopping on the RLX, others will not. Some cars will turn right into the side-street downsteam of the RLX. Depending on teffic density, this may cause traffic jams to back up to the RLX.


## HOW TO USE IT

Select values for the maximum number of cars, acceleration, deceleration, percentage of cars that will turn right downstream of the crossing, and percentage of cars that will comply with the signalled requirement to not stop on the railway level crossing.

Press the Setup button, then press the Go button.

## THINGS TO NOTICE

How does traffic density affect the frequncy of queuing?
How does frequency of cars stopping downstream to turn right affect the frequncy of queuing?
How does the precentage of compliant drivers affect the frequency of queuing? Is this in turn affected by acceleration and deceleration values?


## THINGS TO TRY

Run the model with the max-num-cars set to a high number and then to a low number. This emulates traffic density at peak and non-peak times. Does queing still happen at non-peak times?

Run the model with compliance set to a high number and then to a low number. Does queuing still happen when compliance is high?
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

down-car
false
0
Polygon -7500403 true true 120 300 136 279 156 261 165 240 168 226 194 213 216 203 237 185 250 159 250 135 240 75 150 0 135 0 75 0 75 300 120 300
Circle -16777216 true false 30 180 90
Circle -16777216 true false 30 30 90
Polygon -16777216 true false 220 162 222 132 165 134 165 209 195 194 204 189 211 180
Circle -7500403 true true 47 47 58
Circle -7500403 true true 47 195 58

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

left-car
false
0
Polygon -7500403 true true 0 180 21 164 39 144 60 135 74 132 87 106 97 84 115 63 141 50 165 50 225 60 300 150 300 165 300 225 0 225 0 180
Circle -16777216 true false 30 180 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 138 80 168 78 166 135 91 135 106 105 111 96 120 89
Circle -7500403 true true 195 195 58
Circle -7500403 true true 47 195 58

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

up-car
false
0
Polygon -7500403 true true 180 0 164 21 144 39 135 60 132 74 106 87 84 97 63 115 50 141 50 165 60 225 150 300 165 300 225 300 225 0 180 0
Circle -16777216 true false 180 30 90
Circle -16777216 true false 180 180 90
Polygon -16777216 true false 80 138 78 168 135 166 135 91 105 106 96 111 89 120
Circle -7500403 true true 195 195 58
Circle -7500403 true true 195 47 58

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
NetLogo 6.0.4
@#$#@#$#@
import-pcolors-rgb "earth.gif"
@#$#@#$#@
@#$#@#$#@
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
1
@#$#@#$#@
