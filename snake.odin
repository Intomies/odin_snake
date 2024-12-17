package snake

import rl "vendor:raylib"

WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
Vector2i :: [2]int
SNAKE_MAX :: GRID_WIDTH * GRID_WIDTH

snake: [SNAKE_MAX]Vector2i
move_direction: Vector2i
tick_rate: f32 = 0.13
tick_timer := tick_rate
snake_length: int

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

    create_snake()

    for !rl.WindowShouldClose() {

        handle_input()
        handle_movement()

        rl.BeginDrawing()
        rl.ClearBackground({37, 40, 133, 255})
        
        camera := rl.Camera2D {
            zoom = f32(WINDOW_SIZE) / CANVAS_SIZE
        }
        rl.BeginMode2D(camera)

        handle_snake()
        
        rl.EndMode2D()
        rl.EndDrawing()
    }
    rl.CloseWindow()
}

create_snake :: proc()
{
    head_start_pos: Vector2i = { GRID_WIDTH / 2, GRID_WIDTH / 2 }
    snake[0] = head_start_pos
    snake[1] = head_start_pos - { 0, 1 }
    snake[2] = head_start_pos - { 0, 2 }
    snake_length = 3
    move_direction = move_direction_values[.Down]
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
}

handle_movement :: proc() 
{
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

handle_snake :: proc()
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