"""Tiny pygame fixture for LiveNiro's self-test: a paddle (arrow keys) and bouncing balls."""
import math
import random

import pygame

W, H = 720, 420


def main():
    pygame.init()
    screen = pygame.display.set_mode((W, H))
    pygame.display.set_caption("LiveNiro Bouncer")
    clock = pygame.time.Clock()
    font = pygame.font.SysFont(None, 32)
    rng = random.Random(7)

    balls = [
        [rng.uniform(80, W - 80), rng.uniform(60, 200), rng.choice([-1, 1]) * rng.uniform(3, 5), rng.uniform(2, 4),
         pygame.Color(c)]
        for c in ("#ff5d8f", "#ffd166", "#06d6a0", "#4cc9f0")
    ]
    paddle = pygame.Rect(W // 2 - 60, H - 36, 120, 14)
    score, t = 0, 0.0
    running = True
    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
        keys = pygame.key.get_pressed()
        paddle.x += (keys[pygame.K_RIGHT] - keys[pygame.K_LEFT]) * 9
        paddle.clamp_ip(screen.get_rect())

        for b in balls:
            b[0] += b[2]
            b[1] += b[3]
            if b[0] < 14 or b[0] > W - 14:
                b[2] *= -1
            if b[1] < 14:
                b[3] *= -1
            if paddle.collidepoint(b[0], b[1] + 14) and b[3] > 0:
                b[3] *= -1
                score += 1
            if b[1] > H + 20:
                b[0], b[1], b[3] = rng.uniform(80, W - 80), 40, abs(b[3])

        t += 1 / 60
        top = pygame.Color("#1b1035").lerp("#2d1b69", (math.sin(t) + 1) / 2)
        screen.fill(top)
        for b in balls:
            pygame.draw.circle(screen, b[4], (int(b[0]), int(b[1])), 14)
        pygame.draw.rect(screen, "#f8f7ff", paddle, border_radius=7)
        screen.blit(font.render(f"Score {score}", True, "#f8f7ff"), (16, 14))
        pygame.display.flip()
        clock.tick(60)
    pygame.quit()


if __name__ == "__main__":
    main()
