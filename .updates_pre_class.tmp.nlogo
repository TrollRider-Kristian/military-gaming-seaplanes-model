 breed [seaplanes seaplane]
 breed [bombers bomber]
 breed [red_scouts red_scout]
 breed [red_bombers red_bomber]
 breed [tenders  tender]
 breed [bases base]
 breed [red_bases red_base]
 breed [seaplane_bases seaplane_base]

globals[ B_17 tonnage_B_17 tonnage_PBY red_target]

bases-own[ health_land planes_land notFound ]
seaplane_bases-own[ health_sea planes_sea notFound ]
bombers-own [fuel bombs land_home_base]
tenders-own[health]
seaplanes-own[fuel bombs sea_home_base]
red_bases-own[no_red_scouts no_red_bombers]
red_scouts-own[fuel scout_base]
red_bombers-own[fuel red_bomber_base target_base]

to setup
  clear-all
  resize-world 0 97 0 160 ; 0 193 0 318 ;; fixed map bug
  import-pcolors "AOO2.png"
  ;import-drawing "overlay.png"
  reset-ticks
  setup_bases_historical
  setup_red_base
  setup_seaplane_bases
  setup_tenders
  set tonnage_PBY 0
end

to setup_bases_historical
  ;; blue base setup
  ; Clark Field
  set-default-shape bases "house"
    create-bases 1[ ;; create the sheep
    ;; then initialize their variables
    set color blue
    set size 2.5  ;; easier to see
    set label-color blue - 2
    setxy 36 114
    set notFound false
    set planes_land 35
  ]
end

to setup_red_base
    ;; red base setup
    set-default-shape red_bases "house"
    create-red_bases 1 [
      set color red
      set size 2.5
    set label-color red
    setxy 31 147
    set no_red_scouts 10
    set no_red_bombers 10
  ]
end

;sets up seaplane bases and randomly generates them on coast line
to setup_seaplane_bases
  set-default-shape seaplane_bases "house"
  let no_seaplane_bases 5 ;define on home screen
  ask n-of no_seaplane_bases patches with [(pycor < 134 and pycor > 71) and (pcolor = 8.7 or pcolor = 8 or pcolor = 4.2 or pcolor = 8.2 or pcolor = 8.6 or pcolor = 8.8)] [sprout-seaplane_bases 1 [
    set color green
    set size 2.5  ;; easier to see
    set label-color green
    set planes_sea ((PBY / no_seaplane_bases))
    ;set PBY (PBY - planes_sea)
    set health_sea 100
    set notFound true
      ] ; 240 to 140
  ]
  set PBY 45 ; define on home screen
end

;sets up seaplane tenders and randomly generates them in Phillippine archipilego
to setup_tenders
set-default-shape tenders "circle"
  let no_tenders 3
  ask n-of no_tenders patches with [(pycor < 110 and pycor > 71 and pxcor > 32 and pxcor < 60 ) and (pcolor = 9.9)] [sprout-tenders 1 [
      set color green
    set size 3  ;; easier to see
    set label-color green


      ] ; 240 to 140
  ]
end



;; end of setup code


to go
  if ticks >= 10000 [stop]
  seaplane_generate
  bomber_generate
  red_generate
  ;generate seaplanes, bombers, and japanese reconnaissance planes at their respective bases
  red_go
  seaplane_go
  bomber_go
  seaplane_rebase
    if ticks > 0 and ticks mod 288 = 0
  [
    scout_track ;scout tracking algorithm runs once a "day" (288 ticks) to save resources, and doesn't run at time = 0 because the Americans were historically in the air first

  ]
  ;below line is the result of a lot of optimization tweaks to the japanese invasion
  ifelse ticks < 4000 [japan_invasion_first_phase] [japan_invasion_second_phase] ;do the invasion with hopefully fewer checks
  tick
end

to seaplane_generate
  set-default-shape seaplanes "airplane"
  ask seaplane_bases [ hatch-seaplanes round(planes_sea / 2) [  ;;hatches half the seaplanes at the base- need to calibrate with historical sortie data
    set color green
    set size 2.5  ;; easier to see
    set label-color green
    set fuel 120
    set sea_home_base patch-here
    ]
  set  planes_sea planes_sea -  round(planes_sea / 2)
  ]
end

to seaplane_go
  ask seaplanes [
    ifelse fuel > 60 ; checks to see if fuel is available, changed to 60/120 instead of 50/100 to reflect PBY combat radius of 1000 miles
    [
      let target-patch one-of (patches with [ pcolor = red or (pycor > 133 and pycor < 142 and pxcor > 15 and pxcor < 60)]) ;sets target for mission to a red occupied patch or shipping
    face target-patch
      seaplane_move ] ; this block if still has fuel
    [let target-patch sea_home_base ; if fuel is not available, it returns to base
    face target-patch
      seaplane_move
    if patch-here = target-patch ; this block adds the seaplanes back to the base
          [ set tonnage_PBY (tonnage_PBY + 2000)
            let blah one-of seaplane_bases-here                    ;; gets the base (with temporary variable blah)
            ifelse blah != nobody [                                 ;; error handling for engineers
            ask blah [
                set planes_sea planes_sea + 1 ]
              die
              ]
              [die]
      ]

    ]
  ]

end

to seaplane_move
  fd 1                        ;in a twist of fate, at our chosen scale of 1 tick = 5 minutes and 1 patch = 16.5 miles, PBY Catalinas actually fly at almost exactly 1 patch/tick
  set fuel (fuel - 1)
  if 10 > random 10000 ;probability of dying, TO BE CALIBRATED
  [set PBY PBY - 1
    die]
end

to seaplane_rebase
  ask seaplane_bases [
    if pcolor = red and ticks > 1440 [
      move-to one-of (patches with [pcolor != white and pcolor != red and pycor < 120 and pycor > 100])
      if 10 < random 50[           ;; chance of death on rebase- this is the main cost of mobile basing, needs to be calibrated
        die
      ]
    ]
  ]
end

to bomber_generate
  set-default-shape bombers "airplane"
  ask bases [ hatch-bombers (planes_land / 2) [
    set color blue
    set size 2.5  ;; easier to see
    set label-color blue
    set land_home_base patch-here
    set fuel 120
    ]
  set  planes_land planes_land -  (planes_land / 2)
  ]


end

to bomber_go
  ask bombers [
    ifelse fuel > 60 ; B-17s had more fuel but were used in the same combat radius (citation needed)
    [
      let target-patch one-of (patches with [ pcolor = red or (pycor > 133 and pycor < 142 and pxcor > 15 and pxcor < 60)]) ;sets target for mission to a red occupied patch or shipping
    face target-patch
      bomber_move ] ; this block if still has fuel
    [let target-patch land_home_base ; if fuel is not available, it returns to base
    face target-patch
      bomber_move
    if patch-here = target-patch ; this block adds the seaplanes back to the base
          [ set tonnage_B_17 (tonnage_B_17 + 3000)
            let blah one-of bases-here                    ;; gets the base
            ifelse blah != nobody [
            ask blah [
                set planes_land planes_land + 1 ]
              die
              ]
              [die]
      ]

    ]
  ]

end

to bomber_move
  fd 1.33 ; apparently you can move fractions? TBD
  set fuel (fuel - 1)
  if 10 > random 10000 ;probability of dying
  [set B_17 B_17 - 1
    die]
end


to red_generate
  set-default-shape red_scouts "airplane"
  set-default-shape red_bombers "airplane"
  if [pcolor] of patch 43 80 != red [     ;;stop scouting flights if the Phillipines are fully occupied by the Japanese
  ask red_bases [ hatch-red_scouts round (no_red_scouts / 10) [ ;;waaaaay fewer scouts
    set color yellow
    set size 2.5  ;; easier to see
    set label-color yellow
    set fuel 100
    set scout_base patch-here
    let target-patch one-of (patches with [(pcolor != 9.9) and pxcor > 30 and pxcor < 60 and pycor < 129]) ;sets target for mission
    face target-patch
    ]
    set  no_red_scouts no_red_scouts - round (no_red_scouts / 10)]

   ; ask red_bases [ hatch-red_bombers round (no_red_bombers / 2) [
   ; set color red
   ; set size 2.5  ;; easier to see
   ; set label-color red
   ; set fuel 100
   ; set red_bomber_base patch-here
   ; set target_base patch-here
   ; ]
   ; ]
  ]

end

to red_go
  ask red_scouts [
    ifelse fuel > 50 ; checks to see if fuel is available
    [
      scout_move ] ; this block if still has fuel
    [let target-patch scout_base ; if fuel is not available, it returns to base
    face target-patch
      scout_move
    if patch-here = target-patch ; this block adds the seaplanes back to the base
          [
            let blah one-of red_bases-here                    ;; gets the base
            ask blah [
                set no_red_scouts no_red_scouts + 1 ]
              die

      ]

    ]
  ]

ask red_bombers [
    ifelse fuel > 50 [
  red_bombers_move
    ]
    [ ; if fuel is not available, it returns to base
    face red_bomber_base
      scout_move
    if patch-here = red_bomber_base ; this block adds the seaplanes back to the base
          [
            let blah one-of red_bases-here                    ;; gets the base
            ask blah [
                set no_red_bombers no_red_bombers + 1 ]
              die

      ]
    ]
    ]

end

to japan_invasion_first_phase
  if ticks = 288 [ask patch 38 138 [set pcolor red]] ;;advance landing at Batan Island on 8th December
  if ticks = 864 [ask (patch-set patch 38 131 patch 38 129 patch 34 127) [set pcolor red]]  ;;inital landings at Aparri, Vigan, and Camiguin Island on Dec 10 - 5 minutes per tick, first tick 7am Dec 7
  if ticks = 1440[ask (patches with [pcolor != white and ((pycor >= 125 and pycor < 138) or (pxcor = 49 and pycor = 107))]) [set pcolor red]] ;;landing at Legaspi on 12th December and initial advance
  if ticks = 2880 [ask (patch-set patch 34 123 patch 34 124) [set pcolor red]]
  if ticks = 3744[ask patch 58 81 [set pcolor red]] ;;landing at Davao on 20th Dec
end

to japan_invasion_second_phase
  if ticks = 4320[ask (patch-set patch 34 121 patch 34 122 patch 42 111 patch 41 111 patch 40 111 patch 40 112 patch 40 113) [set pcolor red]]
  if ticks = 5472[ask (patches with [(pcolor != white and pycor >= 120 and pycor < 140) or ((pxcor = 41 or pxcor = 42) and pycor = 77)]) [set pcolor red]]
  if ticks = 6336 [ask (patches with [pcolor != white and ((pycor >= 117 and pycor < 140) or (pycor >= 105 and pycor <= 111 and pxcor >= 43 and not (pxcor = 43 and pycor = 105)))]) [set pcolor red]] ;december 29th
  if ticks = 5472[ask (patches with [pcolor != white and pycor >= 120 and pycor < 140]) [set pcolor red]]
  if ticks = 7488[ask (patches with [pcolor != white and pycor >= 109 and pycor < 140]) [set pcolor red]]
end

to scout_move
  fd 1.5
  set fuel (fuel - 0.75)
end

to red_bombers_move
  ask red_bombers
  [
    if target_base != nobody
    [
      facexy (item 1 target_base) (item 0 target_base)
      fd 1
      set fuel (fuel - 1)
      if patch-here = (patch (item 1 target_base) (item 0 target_base)) [
        print "at target"
      let store one-of bases-here
      ifelse store = nobody
        [set store one-of seaplane_bases-here
          ifelse store = nobody
          [set fuel 49]
            [ask store
            set PBY round(PBY - (planes_sea * 0.5))
        set planes_sea round(planes_sea * 0.5)]
          ]
        [ask store [
          set B_17 round(B_17 - (planes_land * 0.5))
      set planes_land round(planes_land * 0.5)
        ]
        ]
        set fuel 49
      ; what do I do if I arrive at the base?  currently they sit there.  I reckon the bases have health that needs subtracting and some much needed deaths and returning to base, but I'll ask you all first.
        ]
        ]
    ]

end

to scout_track
  tracking_helper bases
  ifelse ticks < 2000
  [
    tracking_helper seaplane_bases with [ ycor > 105 ]
  ]
  [
    tracking_helper seaplane_bases
  ]
end

to tracking_helper [given_bases]
  ask given_bases with [notFound = true]
  [
    let dist_to_base distance red_base 1
    ; assume for the sake of the model that the chances of spotting an enemy base are proportional to our distance from the base
    ; this isn't about search, it's about the overall tonnage delivered when comparing pby and b-17
    let denom sqrt (97 * 97 + 160 * 160)
    let prob (1 - (dist_to_base / denom)) * 100

    if random 100 < prob
    [let target self
    ask target
      [
        set notFound false
      ]
    ]
  ]
      ask red_bases
      [
        hatch-red_bombers 1
        [
        set color red
        set size 2.5  ;; easier to see
        set label-color red
        set fuel 100
        set red_bomber_base patch-here
        ifelse (one-of given_bases with [notFound = false]) != nobody
        [
        set target_base ([list pycor pxcor] of (one-of given_bases with [notFound = false]))
        ]
        [
          die
          ask one-of red_bases   [                 ;; gets the base
                set no_red_bombers no_red_bombers + 1
]
        ]

      ]
    ]


end
@#$#@#$#@
GRAPHICS-WINDOW
210
10
1492
2112
-1
-1
13.0
1
10
1
1
1
0
0
0
1
0
97
0
160
0
0
1
ticks
30.0

BUTTON
41
26
147
62
Setup World
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
8
86
184
122
NIL
setup_bases_historical
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
12
146
182
180
NIL
setup_seaplane_bases
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
36
206
157
242
NIL
setup_tenders
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
20
268
174
302
NIL
seaplane_generate
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
44
360
154
394
NIL
seaplane_go
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
1564
96
1628
130
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

PLOT
1522
164
2170
538
PBY vs. B-17 Tonnage Delivered
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"PBY" 1.0 0 -13840069 true "" "plot tonnage_PBY"
"B-17" 1.0 0 -13345367 true "" "plot tonnage_B_17"

MONITOR
1586
616
1657
661
Number of PBYs Remaining
PBY
17
1
11

SLIDER
11
424
183
457
PBY
PBY
0
100
4.0
1
1
planes
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
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
0
@#$#@#$#@
