package snake

import rl "vendor:raylib"
import "core:math"

WINDOW_SIZE :: 1000
GRID_SIZE :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_SIZE * CELL_SIZE
Vector2i :: [2]int
SNAKE_MAX :: GRID_SIZE * GRID_SIZE

GameState :: struct {
    tick_rate: f32,
    tick_timer: f32,
    snake: [SNAKE_MAX]Vector2i,
    snake_length: int,
    move_direction: Vector2i,
    next_move_direction: Vector2i,
    game_over: bool,
    food_pos: Vector2i,
}

Sprites :: struct {
    food: rl.Texture2D,
    head: rl.Texture2D,
    body: rl.Texture2D,
    tail: rl.Texture2D,
}

Move_Direction :: enum {
    Up,
    Down,
    Left,
    Right,
}

move_direction_values := [Move_Direction]Vector2i {
    .Up = { 0, -1 },
    .Down = { 0, 1 },
    .Left = { -1, 0 },
    .Right = { 1, 0 },
}


main :: proc() 
{
    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake")
    rl.SetConfigFlags({ .VSYNC_HINT })

    state := GameState{}
    sprites := load_sprites()

    start_game(&state)

    for !rl.WindowShouldClose() {

        handle_input(&state)
        handle_snake_movement(&state)
        handle_food_collision(&state)
        state.game_over = check_deadly_collisions(&state)

        rl.BeginDrawing()
        rl.ClearBackground({37, 40, 133, 255})
        
        camera := rl.Camera2D {
            zoom = f32(WINDOW_SIZE) / CANVAS_SIZE
        }
        
        rl.BeginMode2D(camera)

        handle_food_draw(&state, sprites.food)
        handle_snake_draw(&state, sprites)

        if state.game_over {
            handle_game_over()
        }
        
        rl.EndMode2D()
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
    unload_sprites(sprites)
    rl.CloseWindow()
}


load_sprites :: proc() -> Sprites {
    
    return {
        rl.LoadTexture("./assets/graphics/food.png"),
	    rl.LoadTexture("./assets/graphics/head.png"),
	    rl.LoadTexture("./assets/graphics/body.png"),
	    rl.LoadTexture("./assets/graphics/tail.png")
    }
}


unload_sprites :: proc(sprites: Sprites)
{
    rl.UnloadTexture(sprites.food)
    rl.UnloadTexture(sprites.head)
    rl.UnloadTexture(sprites.body)
    rl.UnloadTexture(sprites.tail)
}


start_game :: proc(state: ^GameState)
{
    state.tick_rate = 0.1
    state.tick_timer = state.tick_rate
    create_snake(state)
    create_food(state)
    state.next_move_direction = state.move_direction
    state.game_over = false
}


handle_input :: proc(state: ^GameState) 
{
    if rl.IsKeyDown(.UP) && state.move_direction != move_direction_values[.Down]{
        state.next_move_direction = move_direction_values[.Up]
    }
    if rl.IsKeyDown(.DOWN) && state.move_direction != move_direction_values[.Up] {
        state.next_move_direction = move_direction_values[.Down]
    }
    if rl.IsKeyDown(.LEFT) && state.move_direction != move_direction_values[.Right] {
        state.next_move_direction = move_direction_values[.Left]
    }
    if rl.IsKeyDown(.RIGHT) && state.move_direction != move_direction_values[.Left] {
        state.next_move_direction = move_direction_values[.Right]
    }
    if state.game_over && rl.IsKeyPressed(.ENTER) {
        start_game(state)  
    }
}


create_snake :: proc(state: ^GameState)
{
    head_start_pos: Vector2i = { GRID_SIZE / 2, GRID_SIZE / 2 }
    state.snake[0] = head_start_pos
    state.snake[1] = head_start_pos - { 0, 1 }
    state.snake[2] = head_start_pos - { 0, 2 }
    state.snake_length = 3
    state.move_direction = move_direction_values[.Down]
}


create_food :: proc(state: ^GameState)
{
    position_occupied: [GRID_SIZE][GRID_SIZE]bool

    for i in 0..<state.snake_length {
        position_occupied[state.snake[i].x][state.snake[i].y] = true
    }

    free_cells := make([dynamic]Vector2i, context.temp_allocator)

    for x in 0..<GRID_SIZE {
        for y in 0..<GRID_SIZE {
            if !position_occupied[x][y] {
                append(&free_cells, Vector2i {x,y})
            }
        }
        
        if len(free_cells) > 0 {
            state.food_pos = free_cells[rl.GetRandomValue(0, i32(len(free_cells) - 1))]
        }
    }
}


handle_snake_movement :: proc(state: ^GameState)
{
    if state.game_over { return }
    
    state.tick_timer -= rl.GetFrameTime()
    if state.tick_timer <= 0 {
        state.move_direction = state.next_move_direction
        next_part_pos := state.snake[0]
        state.snake[0] = state.snake[0] + state.move_direction

        for i in 1..<state.snake_length {
            cur_pos := state.snake[i]
            state.snake[i] = next_part_pos
            next_part_pos = cur_pos
        }
        state.tick_timer = state.tick_rate + state.tick_timer
    }
}


handle_snake_draw :: proc(state: ^GameState, sprites: Sprites)
{
    for i in 0..<state.snake_length {
        position := state.snake[i]
        part_sprite := sprites.body
        direction: Vector2i
        
        if i == 0 {
            part_sprite = sprites.head
            direction = position - state.snake[i + 1]
        } else if i == state.snake_length - 1 {
            part_sprite = sprites.tail
            direction = state.snake[i - 1] - position
        } else {
            direction = state.snake[i - 1] - position
        }

        rotate := rotate_sprite(direction)
        source := get_source_rect(part_sprite)
        destination := get_destination_rect(position)
    
        rl.DrawTexturePro(part_sprite, source, destination, {CELL_SIZE, CELL_SIZE}*0.5, rotate, rl.WHITE)
    }

}


rotate_sprite :: proc(direction: Vector2i) -> f32
{
    return math.atan2(f32(direction.y), f32(direction.x)) * math.DEG_PER_RAD
}


get_source_rect :: proc(part_sprite: rl.Texture2D) -> rl.Rectangle 
{
    return rl.Rectangle {
        0,0,
        f32(part_sprite.width),
        f32(part_sprite.height)
    }
}


get_destination_rect :: proc(position: Vector2i) -> rl.Rectangle
{
    return rl.Rectangle {
        f32(position.x) * CELL_SIZE + 0.5 * CELL_SIZE, 
        f32(position.y) * CELL_SIZE + 0.5 * CELL_SIZE,
        CELL_SIZE,
        CELL_SIZE,
    }
}


handle_food_draw :: proc(state: ^GameState, sprite: rl.Texture2D) 
{
    position: rl.Vector2 = {f32(state.food_pos.x), f32(state.food_pos.y)} * CELL_SIZE
    rl.DrawTextureV(sprite, position, rl.WHITE)
}


check_deadly_collisions :: proc(state: ^GameState) -> bool
{
    head_pos := state.snake[0]
    wall_collision := head_pos.x <= -1 || head_pos.y <= -1 || head_pos.x >= GRID_SIZE || head_pos.y >= GRID_SIZE 
    return wall_collision || tail_collision(state)
}


tail_collision :: proc(state: ^GameState) -> bool {
    for i in 1..<state.snake_length-1 {
        if state.snake[i] == state.snake[0] { return true }
    }
    return false
}


handle_food_collision :: proc(state: ^GameState) {
    if state.snake[0] == state.food_pos {
        state.snake_length += 1
        state.snake[state.snake_length - 1] = state.snake[state.snake_length - 2]
        create_food(state)
    }
}


handle_game_over :: proc() 
{
    rl.DrawText("Game Over!", 4, 4, 25, rl.RED)
    rl.DrawText("Press Enter to play again", 4, 30, 15, rl.BLACK)
}