; === LUCYENE PINHEIRO NEVES ===
; === INSTRUÇÕES ===
; === DEFINIÇÃO DE VARIÁVEIS ===

breed [tamtams tamtam]


; Variáveis dos patches (espaço onde as formigas se movem)
patches-own [
  chemical             ; quantidade de feromônio neste patch
  food                 ; quantidade de comida neste patch (0, 1 ou 2)
  nest?                ; verdadeiro se o patch é parte do ninho, falso caso contrário
  nest-scent           ; valor numérico maior próximo ao ninho, usado para orientar as formigas
  food-source-number   ; identifica as fontes de alimento (1, 2, 3 ou 4)
  wall?                ; verdadeiro se o patch faz parte da muralha
]

; === PROCEDIMENTOS DE CONFIGURAÇÃO ===

to setup
  clear-all                             ; limpa o mundo e reinicia a simulação
  set evaporation-rate 5                ; Exemplo de taxa de evaporação
  ask patches [ set pcolor brown ]      ; define o chão verde inicialmente
  set-default-shape turtles "bug"       ; define o formato das formigas como "inseto"
  create-turtles population [           ; cria formigas com base no valor do slider 'population'
    set size 2                          ; aumenta o tamanho para melhor visualização
    set color red                       ; vermelho indica que não está carregando comida
  ]

  setup-patches                         ; chama o procedimento para configurar os patches
  move-outside-nest                     ; movimenta todas as formigas para fora do ninho e da muralha

  create-tamtams 1[
    setxy random-xcor random-ycor
    set shape "tamtam"
    set size 10
  ]

  reset-ticks                           ; reinicia o contador de tempo da simulação
end

to setup-patches
  ask patches [
    setup-nest                          ; configura o ninho nos patches
    setup-wall                          ; configura a muralha nos patches
    setup-food                          ; configura as fontes de alimento
    recolor-patch                       ; ajusta a cor inicial dos patches
  ]
end

to setup-nest
  set nest? (distancexy 0 0) < 3         ; define patches dentro de um raio de 3 unidades como ninho
  set nest-scent 200 - distancexy 0 0    ; valor maior próximo ao ninho, decrescendo com a distância
end

to setup-wall
  set wall? (distancexy 0 0) >= 9.2 and (distancexy 0 0) <= 10 ; cria muralha em torno do ninho
end

to setup-food
  ; Configura fontes de alimento em posições específicas
  if (distancexy (0.6 * max-pxcor) 0) < 4 [
    set food-source-number 1

  ]
  if (distancexy (-0.6 * max-pxcor) (-0.6 * max-pycor)) < 2 [
    set food-source-number 2
  ]
  if (distancexy (-0.6 * max-pxcor) (0.19 * max-pycor)) < 3 [
    set food-source-number 3
  ]
  if (distancexy (-0.8 * max-pxcor) (0.8 * max-pycor)) < 2 [
    set food-source-number 4
  ]
  ; Se o patch faz parte de uma fonte de alimento, atribui uma quantidade de comida (1 ou 2)
  if food-source-number > 0 [
    set food one-of [1 2]
  ]
end

; === PROCEDIMENTOS PRINCIPAIS ===

to pickDirection
  let flip random 2
  ifelse flip = 0 [right random 45][left random 45]
end

to go
  ask tamtams [
    forward 1
    pickDirection
  ]
  tick

  ask turtles [
    if who >= ticks [ stop ]             ; sincroniza a saída das formigas do ninho com o tempo
    ifelse color = red [
      look-for-food                      ; procura por comida se não estiver carregando
    ] [
      return-to-nest                     ; retorna ao ninho se estiver carregando comida
    ]
    wiggle                               ; movimento aleatório para simular procura
    fd 1                                 ; move-se para frente
  ]

  ; Verifica se toda a comida foi coletada
  if all? patches [ food = 0 ] [
    setup                                  ; reinicia a simulação
  ]

  diffuse chemical (diffusion-rate / 100)  ; difusão do feromônio entre os patches
  ask patches [
    set chemical chemical * (100 - evaporation-rate) / 100  ; evaporação do feromônio
    recolor-patch                       ; atualiza a cor do patch após mudanças
  ]
  tick                                  ; avança o contador de tempo da simulação
end

; === PROCEDIMENTOS DE RECOLORIR ===

to recolor-patch
  ifelse wall? [
    set pcolor gray
  ] [
    ifelse nest? [
      set pcolor violet ; ninho em violeta
    ] [
      ifelse food > 0 [
        ; Patches com comida são coloridos de acordo com a fonte
        if food-source-number = 1 [ set pcolor cyan ]
        if food-source-number = 2 [ set pcolor sky ]
        if food-source-number = 3 [ set pcolor blue ]
        if food-source-number = 4 [ set pcolor pink ]
      ] [
        ifelse chemical > 1 [
          set pcolor scale-color yellow chemical 0.1 5  ; Feromônio em amarelo
        ] [
          set pcolor brown  ; Patches normais permanecem verdes
        ]
      ]
    ]
  ]
end

; === COMPORTAMENTOS DAS FORMIGAS ===

to look-for-food
  if food > 0 [
    set color pcolor                      ; muda a cor da formiga para a cor da comida
    set food food - 1                     ; reduz a quantidade de comida no patch
    rt 180                                ; vira 180 graus para retornar ao ninho
    stop                                  ; finaliza o procedimento atual
  ]
  if (chemical >= 0.05) and (chemical < 2) [
    uphill-chemical                       ; segue o rastro de feromônio
  ]
end

to return-to-nest
  ifelse nest? [
    set color red                         ; deposita a comida e muda a cor para não carregando
    rt 180                                ; vira 180 graus para sair novamente
  ] [
    set chemical chemical + 60            ; deposita feromônio no caminho de volta
    uphill-nest-scent                     ; move-se em direção ao ninho seguindo o gradiente
  ]
end

; === MOVIMENTAÇÃO E ORIENTAÇÃO ===

to uphill-chemical
  let scent-ahead chemical-scent-at-angle 0
  let scent-right chemical-scent-at-angle 45
  let scent-left chemical-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead) [
    ifelse scent-right > scent-left [
      rt 45                              ; vira 45 graus à direita
    ] [
      lt 45                              ; vira 45 graus à esquerda
    ]
  ]
end

to uphill-nest-scent
  let scent-ahead nest-scent-at-angle 0
  let scent-right nest-scent-at-angle 45
  let scent-left nest-scent-at-angle -45
  if (scent-right > scent-ahead) or (scent-left > scent-ahead) [
    ifelse scent-right > scent-left [
      rt 45                              ; vira 45 graus à direita
    ] [
      lt 45                              ; vira 45 graus à esquerda
    ]
  ]
end

to wiggle  ;; procedimento das formigas
  rt random 40
  lt random 40
  if not can-move? 1 or [wall?] of patch-ahead 1 [ rt 180 ] ;; evita a muralha
end

; === FUNÇÕES AUXILIARES ===

to-report nest-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]             ; se não houver patch, retorna 0
  report [nest-scent] of p               ; retorna o valor de 'nest-scent' do patch
end

to-report chemical-scent-at-angle [angle]
  let p patch-right-and-ahead angle 1
  if p = nobody [ report 0 ]             ; se não houver patch, retorna 0
  report [chemical] of p                 ; retorna o valor de 'chemical' do patch
end

;;;;;;;;;;;;;;;;;;;;;;;
;;; Funções novas ;;;
;;;;;;;;;;;;;;;;;;;;;;;

to move-outside-nest
  ;; Tenta escolher um patch fora do ninho e da muralha
  let target-patch one-of patches with [nest? = false and wall? = false]

  ;; Se encontrar um patch válido, move a formiga. Caso contrário, não faz nada
  if target-patch != nobody [
    move-to target-patch
  ]
  ;; Caso não encontre um patch válido, move para um patch aleatório fora do ninho e da muralha
  if target-patch = nobody [
    let random-patch one-of patches with [nest? = false and wall? = false]
    move-to random-patch
  ]
end

@#$#@#$#@
GRAPHICS-WINDOW
257
10
1322
516
-1
-1
7.0
1
10
1
1
1
0
0
0
1
-75
75
-35
35
1
1
1
ticks
30.0

BUTTON
46
71
126
104
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

SLIDER
31
106
221
139
diffusion-rate
diffusion-rate
0.0
99.0
1.0
1.0
1
NIL
HORIZONTAL

SLIDER
31
141
221
174
evaporation-rate
evaporation-rate
0.0
99.0
5.0
1.0
1
NIL
HORIZONTAL

BUTTON
136
71
211
104
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
0

SLIDER
31
36
221
69
population
population
0.0
200.0
100.0
1.0
1
NIL
HORIZONTAL

PLOT
5
197
248
476
Food in each pile
time
food
0.0
50.0
0.0
120.0
true
false
"" ""
PENS
"food-in-pile1" 1.0 0 -11221820 true "" "plotxy ticks sum [food] of patches with [pcolor = cyan]"
"food-in-pile2" 1.0 0 -13791810 true "" "plotxy ticks sum [food] of patches with [pcolor = sky]"
"food-in-pile3" 1.0 0 -13345367 true "" "plotxy ticks sum [food] of patches with [pcolor = blue]"

@#$#@#$#@
## WHAT IS IT?

In this project, a colony of ants forages for food. Though each ant follows a set of simple rules, the colony as a whole acts in a sophisticated way.

## HOW IT WORKS

When an ant finds a piece of food, it carries the food back to the nest, dropping a chemical as it moves. When other ants "sniff" the chemical, they follow the chemical toward the food. As more ants carry food to the nest, they reinforce the chemical trail.

## HOW TO USE IT

Click the SETUP button to set up the ant nest (in violet, at center) and three piles of food. Click the GO button to start the simulation. The chemical is shown in a green-to-white gradient.

The EVAPORATION-RATE slider controls the evaporation rate of the chemical. The DIFFUSION-RATE slider controls the diffusion rate of the chemical.

If you want to change the number of ants, move the POPULATION slider before pressing SETUP.

## THINGS TO NOTICE

The ant colony generally exploits the food source in order, starting with the food closest to the nest, and finishing with the food most distant from the nest. It is more difficult for the ants to form a stable trail to the more distant food, since the chemical trail has more time to evaporate and diffuse before being reinforced.

Once the colony finishes collecting the closest food, the chemical trail to that food naturally disappears, freeing up ants to help collect the other food sources. The more distant food sources require a larger "critical number" of ants to form a stable trail.

The consumption of the food is shown in a plot.  The line colors in the plot match the colors of the food piles.

## EXTENDING THE MODEL

Try different placements for the food sources. What happens if two food sources are equidistant from the nest? When that happens in the real world, ant colonies typically exploit one source then the other (not at the same time).

In this project, the ants use a "trick" to find their way back to the nest: they follow the "nest scent." Real ants use a variety of different approaches to find their way back to the nest. Try to implement some alternative strategies.

The ants only respond to chemical levels between 0.05 and 2.  The lower limit is used so the ants aren't infinitely sensitive.  Try removing the upper limit.  What happens?  Why?

In the `uphill-chemical` procedure, the ant "follows the gradient" of the chemical. That is, it "sniffs" in three directions, then turns in the direction where the chemical is strongest. You might want to try variants of the `uphill-chemical` procedure, changing the number and placement of "ant sniffs."

## NETLOGO FEATURES

The built-in `diffuse` primitive lets us diffuse the chemical easily without complicated code.

The primitive `patch-right-and-ahead` is used to make the ants smell in different directions without actually turning.

## HOW TO CITE

If you mention this model or the NetLogo software in a publication, we ask that you include the citations below.

For the model itself:

* Wilensky, U. (1997).  NetLogo Ants model.  http://ccl.northwestern.edu/netlogo/models/Ants.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

Please cite the NetLogo software as:

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit https://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was developed at the MIT Media Lab using CM StarLogo.  See Resnick, M. (1994) "Turtles, Termites and Traffic Jams: Explorations in Massively Parallel Microworlds."  Cambridge, MA: MIT Press.  Adapted to StarLogoT, 1997, as part of the Connected Mathematics Project.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 1998.

<!-- 1997 1998 MIT -->
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

agroboy
false
0
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Polygon -1 true false 60 195 90 210 114 154 120 195 180 195 187 157 210 210 240 195 195 90 165 90 150 105 150 150 135 90 105 90
Circle -7500403 true true 110 5 80
Rectangle -7500403 true true 127 79 172 94
Polygon -1184463 true false 120 90 120 180 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 180 90 172 89 165 135 135 135 127 90
Polygon -16777216 true false 116 4 113 21 71 33 71 40 109 48 117 34 144 27 180 26 188 36 224 23 222 14 178 16 167 0
Line -16777216 false 225 90 270 90
Line -16777216 false 225 15 225 90
Line -16777216 false 270 15 270 90
Line -16777216 false 247 15 247 90
Rectangle -16777216 true false 240 105 255 315

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

apple
false
0
Polygon -2674135 true false 33 58 0 150 30 240 105 285 135 285 150 270 165 285 195 285 255 255 300 150 268 62 226 43 194 36 148 32 105 35
Line -16777216 false 106 55 151 62
Line -16777216 false 157 62 209 57
Polygon -6459832 true false 152 62 158 62 160 46 156 30 147 18 132 26 142 35 148 46
Polygon -16777216 false false 132 25 144 38 147 48 151 62 158 63 159 47 155 30 147 18

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
Polygon -1184463 true false 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -1184463 true false 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -1184463 true false 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -1184463 true false 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -8630108 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -13345367 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

cactus
false
0
Polygon -14835848 true false 130 300 124 206 110 207 94 201 81 183 75 171 74 95 79 79 88 74 97 79 100 95 101 151 104 169 115 180 126 169 129 31 132 19 145 16 153 20 158 32 162 142 166 149 177 149 185 137 185 119 189 108 199 103 212 108 215 121 215 144 210 165 196 177 176 181 164 182 159 302
Line -16777216 false 142 32 146 143
Line -16777216 false 148 179 143 300
Line -16777216 false 123 191 114 197
Line -16777216 false 113 199 96 188
Line -16777216 false 95 188 84 168
Line -16777216 false 83 168 82 103
Line -16777216 false 201 147 202 123
Line -16777216 false 190 162 199 148
Line -16777216 false 174 164 189 163

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

fire
false
0
Polygon -7500403 true true 151 286 134 282 103 282 59 248 40 210 32 157 37 108 68 146 71 109 83 72 111 27 127 55 148 11 167 41 180 112 195 57 217 91 226 126 227 203 256 156 256 201 238 263 213 278 183 281
Polygon -955883 true false 126 284 91 251 85 212 91 168 103 132 118 153 125 181 135 141 151 96 185 161 195 203 193 253 164 286
Polygon -2674135 true false 155 284 172 268 172 243 162 224 148 201 130 233 131 260 135 282

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -8630108 true false 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
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
Circle -1184463 true false 85 132 38
Circle -1184463 true false 130 147 38
Circle -1184463 true false 192 85 38
Circle -1184463 true false 85 40 38
Circle -1184463 true false 177 40 38
Circle -1184463 true false 177 132 38
Circle -1184463 true false 70 85 38
Circle -1184463 true false 130 25 38
Circle -955883 true false 96 51 108
Circle -1184463 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

folha
false
0
Rectangle -6459832 true false 144 218 156 298
Polygon -13840069 true false 150 263 133 276 102 276 58 242 35 176 33 139 43 114 54 123 62 87 75 53 94 30 104 39 120 9 155 31 180 68 191 56 216 85 235 125 240 173 250 165 248 205 225 247 200 271 176 275
Line -6459832 false 75 75 120 195
Line -6459832 false 210 120 165 240
Line -6459832 false 60 120 105 240
Line -6459832 false 195 75 150 195

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

lanche
false
0
Polygon -955883 true false 30 105 45 255 105 255 120 105
Rectangle -16777216 true false 15 90 135 105
Polygon -1 true false 75 90 105 15 120 15 90 90
Polygon -8630108 true false 135 225 150 240 195 255 225 255 270 240 285 225 150 225
Polygon -8630108 true false 135 180 150 165 195 150 225 150 270 165 285 180 150 180
Rectangle -1184463 true false 135 195 285 210

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
Rectangle -10899396 true false 135 90 165 300
Polygon -14835848 true false 135 255 90 210 45 195 75 255 135 285
Polygon -10899396 true false 165 270 210 225 255 210 225 270 165 300
Polygon -13840069 true false 135 180 90 135 45 120 75 180 135 210
Polygon -13840069 true false 165 180 165 210 225 180 255 120 210 135
Polygon -14835848 true false 135 105 90 60 45 45 75 105 135 135
Polygon -13840069 true false 165 105 165 135 225 105 255 45 210 60
Polygon -13840069 true false 135 90 120 45 150 15 180 45 165 90

queen
true
0
Polygon -8630108 true false 150 19 120 30 120 45 130 66 144 81 127 96 129 113 144 134 136 185 121 195 114 217 120 255 135 270 165 270 180 255 188 218 181 195 165 184 157 134 170 115 173 95 156 81 171 66 181 42 180 30
Polygon -13345367 true false 150 167 159 185 190 182 225 212 255 257 240 212 200 170 154 172
Polygon -1184463 true false 161 167 201 150 237 149 281 182 245 140 202 137 158 154
Polygon -2674135 true false 155 135 185 120 230 105 275 75 233 115 201 124 155 150
Line -2064490 false 120 36 75 45
Line -5825686 false 75 45 90 15
Line -2064490 false 180 35 225 45
Line -5825686 false 225 45 210 15
Polygon -2674135 true false 145 135 115 120 70 105 25 75 67 115 99 124 145 150
Polygon -1184463 true false 139 167 99 150 63 149 19 182 55 140 98 137 142 154
Polygon -13345367 true false 150 167 141 185 110 182 75 212 45 257 60 212 100 170 146 172

rio
false
9
Circle -6459832 true false 15 15 270
Circle -13791810 true true 30 30 240

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

tamtam
false
0
Polygon -8630108 true false 87 267 106 290 145 292 157 288 175 292 209 292 207 281 190 276 174 277 156 271 154 261 157 245 151 230 156 221 171 209 214 165 231 171 239 171 263 154 281 137 294 136 297 126 295 119 279 117 241 145 242 128 262 132 282 124 288 108 269 88 247 73 226 72 213 76 208 88 190 112 151 107 119 117 84 139 61 175 57 210 65 231 79 253 65 243 46 187 49 157 82 109 115 93 146 83 202 49 231 13 181 12 142 6 95 30 50 39 12 96 0 162 23 250 68 275
Polygon -16777216 true false 237 85 249 84 255 92 246 95
Line -16777216 false 221 82 213 93
Line -16777216 false 253 119 266 124
Line -16777216 false 278 110 278 116
Line -16777216 false 149 229 135 211
Line -16777216 false 134 211 115 207
Line -16777216 false 117 207 106 211
Line -16777216 false 91 268 131 290
Line -16777216 false 220 82 213 79
Line -16777216 false 286 126 294 128
Line -16777216 false 193 284 206 285

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
Circle -13840069 true false 118 3 94
Rectangle -955883 true false 120 195 180 300
Circle -14835848 true false 65 21 108
Circle -10899396 true false 116 41 127
Circle -13840069 true false 45 90 120
Circle -14835848 true false 104 74 152

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
Polygon -7500403 true true 75 225 97 249 112 252 122 252 114 242 102 241 89 224 94 181 64 113 46 119 31 150 32 164 61 204 57 242 85 266 91 271 101 271 96 257 89 257 70 242
Polygon -7500403 true true 216 73 219 56 229 42 237 66 226 71
Polygon -7500403 true true 181 106 213 69 226 62 257 70 260 89 285 110 272 124 234 116 218 134 209 150 204 163 192 178 169 185 154 189 129 189 89 180 69 166 63 113 124 110 160 111 170 104
Polygon -6459832 true true 252 143 242 141
Polygon -6459832 true true 254 136 232 137
Line -16777216 false 75 224 89 179
Line -16777216 false 80 159 89 179
Polygon -6459832 true true 262 138 234 149
Polygon -7500403 true true 50 121 36 119 24 123 14 128 6 143 8 165 8 181 7 197 4 233 23 201 28 184 30 169 28 153 48 145
Polygon -7500403 true true 171 181 178 263 187 277 197 273 202 267 187 260 186 236 194 167
Polygon -7500403 true true 187 163 195 240 214 260 222 256 222 248 212 245 205 230 205 155
Polygon -7500403 true true 223 75 226 58 245 44 244 68 233 73
Line -16777216 false 89 181 112 185
Line -16777216 false 31 150 47 118
Polygon -16777216 true false 235 90 250 91 255 99 248 98 244 92
Line -16777216 false 236 112 246 119
Polygon -16777216 true false 278 119 282 116 274 113
Line -16777216 false 189 201 203 161
Line -16777216 false 90 262 94 272
Line -16777216 false 110 246 119 252
Line -16777216 false 190 266 194 274
Line -16777216 false 218 251 219 257
Polygon -16777216 true false 230 67 228 54 222 62 224 72
Line -16777216 false 246 67 234 64
Line -16777216 false 229 45 235 68
Line -16777216 false 30 150 30 165

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
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
