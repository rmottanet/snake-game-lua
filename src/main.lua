-- main.lua

-- --- Constantes do Jogo ---
-- Cores
-- Em LÖVE 2D, as cores são geralmente representadas por 4 valores (R, G, B, A) de 0 a 1.
local GREEN = {0, 1, 0, 1}    -- Verde
local RED = {1, 0, 0, 1}      -- Vermelho
local BLACK = {0, 0, 0, 1}    -- Preto
local WHITE = {1, 1, 1, 1}    -- Branco

-- Dimensões da tela e do "tijolo" da cobra
local SCREEN_WIDTH = 600
local SCREEN_HEIGHT = 400
local BOX_SIZE = 20

-- Velocidade da cobra (controla o quão rápido a cobra se move)
local SNAKE_SPEED = 0.15 -- Tempo em segundos entre cada movimento

-- --- Classe SnakeGame ---
-- Em Lua, podemos simular classes usando tabelas e metatabelas.
local SnakeGame = {}
SnakeGame.__index = SnakeGame -- Isso faz com que a tabela se procure por métodos nela mesma

function SnakeGame:new()
    -- Construtor da classe SnakeGame
    local o = {} -- Cria uma nova tabela para a instância
    setmetatable(o, self) -- Define SnakeGame como a metatabela de 'o', o que permite o uso de self:method()

    o.box_size = BOX_SIZE
    o.snake_speed = SNAKE_SPEED
    o.max_length = 5 -- Comprimento inicial da cobra

    -- Inicializa a cobra com um único segmento no centro da tela
    -- A cobra é uma tabela de tabelas, onde cada tabela representa um segmento {x, y}
    local initial_x = math.floor(SCREEN_WIDTH / 2 / o.box_size) * o.box_size
    local initial_y = math.floor(SCREEN_HEIGHT / 2 / o.box_size) * o.box_size
    o.snake = {{x = initial_x, y = initial_y}}

    -- Direção inicial da cobra (movendo para a direita)
    -- (dx, dy) - (20, 0) para direita, (-20, 0) para esquerda, etc.
    o.direction = {dx = o.box_size, dy = 0}

    o.food = nil -- A comida será uma tabela {x, y}
    o:spawn_food() -- Gera a primeira comida

    o.game_over = false -- Flag para controlar o estado do jogo
    o.last_move_time = 0 -- Controla o tempo do último movimento da cobra (em segundos)

    return o
end

function SnakeGame:spawn_food()
    -- Gera uma nova posição aleatória para a comida na tela.
    -- A posição é sempre um múltiplo do tamanho do "tijolo" (BOX_SIZE)
    -- para se alinhar com a grade do jogo.
    while true do
        -- Gera coordenadas aleatórias dentro dos limites da tela, alinhadas à grade
        local x = math.floor(math.random(0, (SCREEN_WIDTH / self.box_size) - 1)) * self.box_size
        local y = math.floor(math.random(0, (SCREEN_HEIGHT / self.box_size) - 1)) * self.box_size
        self.food = {x = x, y = y}

        -- Garante que a comida não apareça dentro do corpo da cobra
        local collision_with_snake = false
        for i, segment in ipairs(self.snake) do
            if segment.x == self.food.x and segment.y == self.food.y then
                collision_with_snake = true
                break
            end
        end
        if not collision_with_snake then
            break
        end
    end
end

function SnakeGame:update(dt)
    -- Atualiza a lógica do jogo: move a cobra e verifica colisões.
    if self.game_over then
        return
    end

    -- Controla a velocidade da cobra usando o tempo
    self.last_move_time = self.last_move_time + dt
    if self.last_move_time >= self.snake_speed then
        self:move_snake()
        self:check_collision()
        self.last_move_time = 0
    end
end

function SnakeGame:move_snake()
    -- Move a cobra: adiciona uma nova cabeça na direção atual
    -- e remove a cauda se a cobra não comeu.

    -- Cria a nova cabeça da cobra na direção atual
    local current_head = self.snake[1]
    local new_head_x = current_head.x + self.direction.dx
    local new_head_y = current_head.y + self.direction.dy
    local new_head = {x = new_head_x, y = new_head_y}

    -- Adiciona a nova cabeça ao início da lista da cobra
    table.insert(self.snake, 1, new_head)

    -- Se a cobra comeu a comida
    if new_head.x == self.food.x and new_head.y == self.food.y then
        self:spawn_food() -- Gera nova comida
        self.max_length = self.max_length + 1 -- Aumenta o comprimento máximo da cobra
    elseif #self.snake > self.max_length then
        table.remove(self.snake) -- Remove a cauda se a cobra não atingiu o comprimento máximo
    end
end

function SnakeGame:check_collision()
    -- Verifica se a cobra colidiu com as bordas da tela ou com seu próprio corpo.
    local head = self.snake[1]

    -- Colisão com as bordas da tela
    if (head.x < 0 or head.x >= SCREEN_WIDTH or
        head.y < 0 or head.y >= SCREEN_HEIGHT) then
        self.game_over = true
        print("Game Over! Colisão com a borda.")
        return
    end

    -- Colisão com o próprio corpo
    -- Começa a verificar do segundo segmento para evitar colisão com a própria cabeça
    for i = 2, #self.snake do
        local segment = self.snake[i]
        if head.x == segment.x and head.y == segment.y then
            self.game_over = true
            print("Game Over! Colisão com o próprio corpo.")
            return
        end
    end
end

function SnakeGame:keypressed(key)
    -- Processa os eventos de entrada do usuário (teclado).
    if self.game_over then
        -- Se o jogo acabou, permite reiniciar com 'R'
        if key == "r" then
            self = SnakeGame:new() -- Reinicia o jogo
            -- Precisa de uma forma de substituir a instância global do game
            -- Para simplicidade aqui, faremos a instância 'game' no love.load
            -- ser reiniciada fora da classe.
            -- Para o exemplo atual, se o jogo acaba, ele espera que o usuário feche a janela.
        end
        return
    end

    -- Muda a direção da cobra, evitando que ela vire 180 graus
    if key == "up" and self.direction.dy ~= self.box_size then
        self.direction.dx = 0
        self.direction.dy = -self.box_size
    elseif key == "down" and self.direction.dy ~= -self.box_size then
        self.direction.dx = 0
        self.direction.dy = self.box_size
    elseif key == "left" and self.direction.dx ~= self.box_size then
        self.direction.dx = -self.box_size
        self.direction.dy = 0
    elseif key == "right" and self.direction.dx ~= -self.box_size then
        self.direction.dx = self.box_size
        self.direction.dy = 0
    end
end

function SnakeGame:draw()
    -- Desenha todos os elementos do jogo na tela.
    love.graphics.setBackgroundColor(unpack(BLACK)) -- Preenche o fundo da tela com preto

    -- Desenha a cobra
    love.graphics.setColor(unpack(GREEN)) -- Define a cor de desenho para verde
    for i, segment in ipairs(self.snake) do
        love.graphics.rectangle("fill", segment.x, segment.y, self.box_size, self.box_size) -- Desenha um retângulo preenchido
    end

    -- Desenha a comida
    if self.food then
        love.graphics.setColor(unpack(RED)) -- Define a cor de desenho para vermelho
        love.graphics.rectangle("fill", self.food.x, self.food.y, self.box_size, self.box_size)
    end

    -- Exibe "Game Over" se o jogo tiver acabado
    if self.game_over then
        love.graphics.setColor(unpack(WHITE))
        love.graphics.setFont(love.graphics.newFont(30)) -- Cria uma nova fonte
        love.graphics.printf("GAME OVER!", 0, SCREEN_HEIGHT / 2 - 15, SCREEN_WIDTH, "center")
        love.graphics.setFont(love.graphics.newFont(15)) -- Volta para um tamanho menor
        love.graphics.printf("Pressione 'R' para reiniciar ou feche a janela.", 0, SCREEN_HEIGHT / 2 + 20, SCREEN_WIDTH, "center")
    end
end

-- --- Funções de callback do LÖVE 2D ---
local game -- Declara a instância do jogo globalmente para as callbacks do LÖVE

function love.load()
    -- Configura a janela do jogo
    love.window.setTitle("Snake Game (LÖVE 2D)")
    love.window.setMode(SCREEN_WIDTH, SCREEN_HEIGHT)

    -- Inicializa a instância do jogo
    game = SnakeGame:new()
end

function love.update(dt)
    -- Chama o método de atualização da instância do jogo
    game:update(dt)
end

function love.draw()
    -- Chama o método de desenho da instância do jogo
    game:draw()
end

function love.keypressed(key)
    -- Lida com a entrada do teclado
    if key == "escape" then -- Permite fechar o jogo com a tecla ESC
        love.event.quit()
    elseif key == "r" and game.game_over then
        game = SnakeGame:new() -- Reinicia o jogo se 'R' for pressionado e o jogo estiver em Game Over
    else
        game:keypressed(key) -- Passa a tecla pressionada para a lógica do jogo
    end
end
