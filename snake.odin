package snake

import rl "vendor:raylib"

WINDOW_SIZE :: 1000
GRID_SIZE :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_SIZE * CELL_SIZE
Vector2i :: [2]int
SNAKE_MAX :: GRID_SIZE * GRID_SIZE

snake: [SNAKE_MAX]Vector2i
snake_length: int
move_direction: Vector2i
tick_rate: f32 = 0.17
tick_timer := tick_rate
game_over: bool

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

    start_game()

    for !rl.WindowShouldClose() {

        handle_input()
        handle_snake_movement()

        rl.BeginDrawing()
        rl.ClearBackground({37, 40, 133, 255})
        
        camera := rl.Camera2D {
            zoom = f32(WINDOW_SIZE) / CANVAS_SIZE
        }
        
        rl.BeginMode2D(camera)

        handle_snake_draw()

        if game_over {
            handle_game_over()
        }
        
        rl.EndMode2D()
        rl.EndDrawing()
    }
    rl.CloseWindow()
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


start_game :: proc()
{
    create_snake()
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
    } else {
        tick_timer -= rl.GetFrameTime()
    }
}


handle_snake_movement :: proc()
{
    tick_timer -= rl.GetFrameTime()
    if tick_timer <= 0 {
        next_part_pos := snake[0]
        snake[0] = snake[0] + move_direction
        head_pos := snake[0]
        game_over = handle_collision(head_pos)

        for i in 1..<snake_length {
            cur_pos := snake[i]
            snake[i] = next_part_pos
            next_part_pos = cur_pos
        }
        tick_timer = tick_rate + tick_timer
    }
}


handle_snake_draw :: proc()
{
    for i in 0..<snake_length {
        snake_rect := rl.Rectangle {
            f32(snake[i].x) * CELL_SIZE,
            f32(snake[i].y) * CELL_SIZE,
            CELL_SIZE,
            CELL_SIZE,
        }
        rl.DrawRectangleRec(snake_rect, rl.BLUE)
    }
}


handle_collision :: proc(head_pos: Vector2i) -> bool
{
    return head_pos.x < 0 || head_pos.y < 0 || head_pos.x >= GRID_SIZE || head_pos.y > GRID_SIZE
}


handle_game_over :: proc() 
{
    rl.DrawText("Game Over!", 4, 4, 25, rl.RED)
    rl.DrawText("Press Enter to play again", 4, 30, 15, rl.BLACK)
}