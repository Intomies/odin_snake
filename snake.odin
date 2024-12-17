package snake

import rl "vendor:raylib"

WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
Vector2i :: [2]int

snake_head_pos: Vector2i
move_direction: Vector2i
tick_rate: f32 = 0.13
tick_timer := tick_rate 

main :: proc() 
{
    rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake")
    rl.SetConfigFlags({ .VSYNC_HINT })

    snake_head_pos = { GRID_WIDTH / 2, GRID_WIDTH / 2 }
    move_direction = { 0, 1 }

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

handle_input :: proc() 
{
    if rl.IsKeyDown(.UP) {
        move_direction = { 0, -1 }
    }
    if rl.IsKeyDown(.DOWN) {
        move_direction = { 0, 1 }
    }
    if rl.IsKeyDown(.LEFT) {
        move_direction = { -1, 0 }
    }
    if rl.IsKeyDown(.RIGHT) {
        move_direction = { 1, 0 }
    }
}

handle_movement :: proc() 
{
    tick_timer -= rl.GetFrameTime()
    if tick_timer <= 0 {
        snake_head_pos += move_direction
        tick_timer = tick_rate + tick_timer
    }
}

handle_snake :: proc()
{
    head_rect := rl.Rectangle {
        f32(snake_head_pos.x) * CELL_SIZE,
        f32(snake_head_pos.y) * CELL_SIZE,
        CELL_SIZE,
        CELL_SIZE,
    }
    rl.DrawRectangleRec(head_rect, rl.BLUE)
}