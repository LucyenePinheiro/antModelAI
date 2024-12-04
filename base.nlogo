; === INSTRUÇÕES ===
; === DEFINIÇÃO DE VARIÁVEIS ===

; Variáveis dos patches (espaço onde as formigas se movem)
patches-own [
  chemical             ; quantidade de feromônio neste patch
  food                 ; quantidade de comida neste patch (0, 1 ou 2)
  nest?                ; verdadeiro se o patch é parte do ninho, falso caso contrário
  nest-scent           ; valor numérico maior próximo ao ninho, usado para orientar as formigas
  food-source-number   ; identifica as fontes de alimento (1, 2, 3 ou 4)
]

; === PROCEDIMENTOS DE CONFIGURAÇÃO ===

to setup
  clear-all                             ; limpa o mundo e reinicia a simulação
  ask patches [ set pcolor green ]      ; define o chão verde inicialmente
  set-default-shape turtles "bug"       ; define o formato das formigas como "inseto"
  create-turtles population [           ; cria formigas com base no valor do slider 'population'
    set size 2                          ; aumenta o tamanho para melhor visualização
    set color red                       ; vermelho indica que não está carregando comida
  ]
  setup-patches                         ; chama o procedimento para configurar os patches
  reset-ticks                           ; reinicia o contador de tempo da simulação
end

to setup-patches
  ask patches [
    setup-nest                          ; configura o ninho nos patches
    setup-food                          ; configura as fontes de alimento
    recolor-patch                       ; ajusta a cor inicial dos patches
  ]
end

to setup-nest
  set nest? (distancexy 0 0) < 5         ; define patches dentro de um raio de 5 unidades como ninho
  set nest-scent 200 - distancexy 0 0    ; valor maior próximo ao ninho, decrescendo com a distância
end

to setup-food
  ; Configura fontes de alimento em posições específicas
  if (distancexy (0.6 * max-pxcor) 0) < 5 [
    set food-source-number 1
  ]
  if (distancexy (-0.6 * max-pxcor) (-0.6 * max-pycor)) < 5 [
    set food-source-number 2
  ]
  if (distancexy (-0.6 * max-pxcor) (0.19 * max-pycor)) < 5 [
    set food-source-number 3
  ]
  if (distancexy (-0.8 * max-pxcor) (0.8 * max-pycor)) < 5 [
    set food-source-number 4
  ]
  ; Se o patch faz parte de uma fonte de alimento, atribui uma quantidade de comida (1 ou 2)
  if food-source-number > 0 [
    set food one-of [1 2]
  ]
end

; === PROCEDIMENTOS PRINCIPAIS ===

to go
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
  diffuse chemical (diffusion-rate / 100)  ; difusão do feromônio entre os patches
  ask patches [
    set chemical chemical * (100 - evaporation-rate) / 100  ; evaporação do feromônio
    recolor-patch                       ; atualiza a cor do patch após mudanças
  ]
  tick                                  ; avança o contador de tempo da simulação
end

; === PROCEDIMENTOS DE RECOLORIR ===

to recolor-patch
  ifelse food > 0 [
    ; Patches com comida são coloridos de acordo com a fonte
    if food-source-number = 1 [ set pcolor cyan ]
    if food-source-number = 2 [ set pcolor sky ]
    if food-source-number = 3 [ set pcolor blue ]
    if food-source-number = 4 [ set pcolor red ]
  ] [
    ifelse chemical > 5 [
      set pcolor scale-color yellow chemical 0.1 5  ; Feromônio em amarelo
    ] [
      set pcolor green  ; Patches normais permanecem verdes
    ]
  ]
end


; === COMPORTAMENTOS DAS FORMIGAS ===

to look-for-food
  if food > 0 [
    set color orange + 1                ; muda a cor para indicar que está carregando comida
    set food food - 1                   ; reduz a quantidade de comida no patch
    rt 180                              ; vira 180 graus para retornar ao ninho
    stop                                ; finaliza o procedimento atual
  ]
  if (chemical >= 0.05) and (chemical < 2) [
    uphill-chemical                     ; segue o rastro de feromônio
  ]
end

to return-to-nest
  ifelse nest? [
    set color red                       ; deposita a comida e muda a cor para não carregando
    rt 180                              ; vira 180 graus para sair novamente
  ] [
    set chemical chemical + 60          ; deposita feromônio no caminho de volta
    uphill-nest-scent                   ; move-se em direção ao ninho seguindo o gradiente
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

to wiggle
  rt random 40                           ; vira um ângulo aleatório à direita
  lt random 40                           ; vira um ângulo aleatório à esquerda
  if not can-move? 1 [ rt 180 ]          ; se não puder se mover, vira 180 graus
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
