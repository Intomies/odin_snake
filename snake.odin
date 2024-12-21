package snake

import rl "vendor:raylib"
import "core:math"

WINDOW_SIZE :: 1000
GRID_SIZE :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_SIZE * CELL_SIZE
Vector2i :: [2]int
SNAKE_MAX :: GRID_SIZE * GRID_SIZE

snake: [SNAKE_MAX]Vector2i
snake_length: int
move_direction: Vector2i
tick_rate: f32 = 0.1
tick_timer := tick_rate
game_over: bool
food_pos: Vector2i

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

    sprites := load_sprites()

    start_game()

    for !rl.WindowShouldClose() {

        handle_input()
        handle_snake_movement()
        handle_food_collision()
        game_over = check_deadly_collisions()

        rl.BeginDrawing()
        rl.ClearBackground({37, 40, 133, 255})
        
        camera := rl.Camera2D {
            zoom = f32(WINDOW_SIZE) / CANVAS_SIZE
        }
        
        rl.BeginMode2D(camera)

        handle_food_draw(sprites.food)
        handle_snake_draw(sprites)

        if game_over {
            handle_game_over()
        }
        
        rl.EndMode2D()
        rl.EndDrawing()

        free_all(context.temp_allocator)
    }
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


start_game :: proc()
{
    create_snake()
    create_food()
    game_over = false
}


handle_input :: proc() 
{
    if rl.IsKeyDown(.UP) && move_direction != move_direction_values[.Down]{
        move_direction = move_direction_values[.Up]
    }
    if rl.IsKeyDown(.DOWN) && move_direction != move_direction_values[.Up] {
        move_direction = move_direction_values[.Down]
    }
    if rl.IsKeyDown(.LEFT) && move_direction != move_direction_values[.Right] {
        move_direction = move_direction_values[.Left]
    }
    if rl.IsKeyDown(.RIGHT) && move_direction != move_direction_values[.Left] {
        move_direction = move_direction_values[.Right]
    }
    if game_over && rl.IsKeyPressed(.ENTER) {
        start_game()  
    }
}


create_snake :: proc()
{
    head_start_pos: Vector2i = { GRID_SIZE / 2, GRID_SIZE / 2 }
    snake[0] = head_start_pos
    snake[1] = head_start_pos - { 0, 1 }
    snake[2] = head_start_pos - { 0, 2 }
    snake_length = 3
    move_direction = move_direction_values[.Down]
}


create_food :: proc()
{
    position_occupied: [GRID_SIZE][GRID_SIZE]bool

    for i in 0..<snake_length {
        position_occupied[snake[i].x][snake[i].y] = true
    }

    free_cells := make([dynamic]Vector2i, context.temp_allocator)

    for x in 0..<GRID_SIZE {
        for y in 0..<GRID_SIZE {
            if !position_occupied[x][y] {
                append(&free_cells, Vector2i {x,y})
            }
        }
        
        if len(free_cells) > 0 {
            food_pos = free_cells[rl.GetRandomValue(0, i32(len(free_cells) - 1))]
        }
    }
}


handle_snake_movement :: proc()
{
    if game_over { return }
    
    tick_timer -= rl.GetFrameTime()
    if tick_timer <= 0 {
        next_part_pos := snake[0]
        snake[0] = snake[0] + move_direction

        for i in 1..<snake_length {
            cur_pos := snake[i]
            snake[i] = next_part_pos
            next_part_pos = cur_pos
        }
        tick_timer = tick_rate + tick_timer
    }
}


handle_snake_draw :: proc(sprites: Sprites)
{
    for i in 0..<snake_length {
        position := snake[i]
        part_sprite := sprites.body
        direction: Vector2i
        
        if i == 0 {
            part_sprite = sprites.head
            direction = position - snake[i + 1]
        } else if i == snake_length - 1 {
            part_sprite = sprites.tail
            direction = snake[i - 1] - position
        } else {
            direction = snake[i - 1] - position
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


handle_food_draw :: proc(sprite: rl.Texture2D) 
{
    position: rl.Vector2 = {f32(food_pos.x), f32(food_pos.y)} * CELL_SIZE
    rl.DrawTextureV(sprite, position, rl.WHITE)
}


check_deadly_collisions :: proc() -> bool
{
    head_pos := snake[0]
    wall_collision := head_pos.x <= -1 || head_pos.y <= -1 || head_pos.x >= GRID_SIZE || head_pos.y >= GRID_SIZE 
    return wall_collision || tail_collision()
}


tail_collision :: proc() -> bool {
    for i in 1..<snake_length-1 {
        if snake[i] == snake[0] { return true }
    }
    return false
}


handle_food_collision :: proc() {
    if snake[0] == food_pos {
        snake_length += 1
        snake[snake_length - 1] = snake[snake_length - 2]
        create_food()
    }
}


handle_game_over :: proc() 
{
    rl.DrawText("Game Over!", 4, 4, 25, rl.RED)
    rl.DrawText("Press Enter to play again", 4, 30, 15, rl.BLACK)
}