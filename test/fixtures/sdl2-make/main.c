/* LiveNiro fixture: SDL2 + Makefile. Catch the falling blocks with the paddle (arrow keys). */
#include <SDL2/SDL.h>
#include <stdlib.h>

#define W 720
#define H 420

int main(void) {
    if (SDL_Init(SDL_INIT_VIDEO) != 0) return 1;
    SDL_Window *win = SDL_CreateWindow("LiveNiro SDL2 Blocks", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, W, H, 0);
    SDL_Renderer *r = SDL_CreateRenderer(win, -1, SDL_RENDERER_SOFTWARE);
    SDL_Rect paddle = {W / 2 - 60, H - 30, 120, 14};
    SDL_Rect blocks[8];
    SDL_Color cols[8];
    srand(7);
    for (int i = 0; i < 8; i++) {
        blocks[i] = (SDL_Rect){40 + i * 82, -(rand() % 400), 34, 34};
        cols[i] = (SDL_Color){(Uint8)(80 + rand() % 175), (Uint8)(80 + rand() % 175), (Uint8)(120 + rand() % 135), 255};
    }
    int caught = 0, running = 1;
    while (running) {
        SDL_Event e;
        while (SDL_PollEvent(&e)) if (e.type == SDL_QUIT) running = 0;
        const Uint8 *k = SDL_GetKeyboardState(NULL);
        paddle.x += (k[SDL_SCANCODE_RIGHT] - k[SDL_SCANCODE_LEFT]) * 8;
        if (paddle.x < 0) paddle.x = 0;
        if (paddle.x > W - paddle.w) paddle.x = W - paddle.w;
        SDL_SetRenderDrawColor(r, 18, 22, 38, 255);
        SDL_RenderClear(r);
        for (int i = 0; i < 8; i++) {
            blocks[i].y += 3 + i % 3;
            if (SDL_HasIntersection(&blocks[i], &paddle)) { caught++; blocks[i].y = -40; }
            if (blocks[i].y > H) blocks[i].y = -40;
            SDL_SetRenderDrawColor(r, cols[i].r, cols[i].g, cols[i].b, 255);
            SDL_RenderFillRect(r, &blocks[i]);
        }
        SDL_SetRenderDrawColor(r, 245, 245, 255, 255);
        SDL_RenderFillRect(r, &paddle);
        for (int i = 0; i < caught && i < 40; i++) {  /* score as a row of pips */
            SDL_Rect pip = {12 + i * 12, 12, 8, 8};
            SDL_SetRenderDrawColor(r, 255, 209, 102, 255);
            SDL_RenderFillRect(r, &pip);
        }
        SDL_RenderPresent(r);
        SDL_Delay(16);
    }
    SDL_Quit();
    return 0;
}
