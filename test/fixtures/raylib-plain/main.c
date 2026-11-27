// LiveNiro fixture: raylib, a single source file and no build system.
#include "raylib.h"
#include <math.h>

int main(void) {
    InitWindow(720, 420, "LiveNiro raylib Comet");
    SetTargetFPS(60);
    Vector2 ball = {360, 210}, vel = {4.2f, 3.1f};
    Vector2 trail[24] = {0};
    int score = 0;
    while (!WindowShouldClose()) {
        if (IsKeyDown(KEY_SPACE)) { vel.x *= 1.02f; vel.y *= 1.02f; }
        ball.x += vel.x; ball.y += vel.y;
        if (ball.x < 16 || ball.x > 704) { vel.x = -vel.x; score++; }
        if (ball.y < 60 || ball.y > 404) { vel.y = -vel.y; score++; }
        for (int i = 23; i > 0; i--) trail[i] = trail[i - 1];
        trail[0] = ball;
        BeginDrawing();
        ClearBackground((Color){16, 12, 32, 255});
        DrawText("raylib + LiveNiro", 20, 16, 28, (Color){245, 243, 255, 255});
        DrawText(TextFormat("bounces: %d", score), 560, 22, 20, (Color){183, 172, 207, 255});
        for (int i = 23; i >= 0; i--)
            DrawCircleV(trail[i], 16 - i * 0.6f, Fade((Color){236, 72, 153, 255}, 1.0f - i / 24.0f));
        DrawCircleV(ball, 16, (Color){139, 92, 246, 255});
        DrawRing((Vector2){360, 230}, 60, 64, GetTime() * 90, GetTime() * 90 + 270, 40, (Color){52, 211, 153, 255});
        EndDrawing();
    }
    CloseWindow();
    return 0;
}
