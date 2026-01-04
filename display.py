import serial
import pygame

last_dir = None


# ---------- SERIAL ----------
PORT = "COM5"        # change if needed
BAUD = 9600
ser = serial.Serial(PORT, BAUD, timeout=0)

# ---------- GRID ----------
CELL = 40
GRID_W = 16
GRID_H = 12
WIDTH = GRID_W * CELL
HEIGHT = GRID_H * CELL

# ---------- PYGAME ----------
pygame.init()
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Snake Game – Arduino ASM")
clock = pygame.time.Clock()

snake = []
food = None

running = True
while running:
    # -------- EVENTS --------
    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_w and last_dir != 'W':
                print("[KEY] W")
                ser.write(b'W')
                last_dir = 'W'

            elif event.key == pygame.K_d and last_dir != 'D':
                print("[KEY] D")
                ser.write(b'D')
                last_dir = 'D'

            elif event.key == pygame.K_s and last_dir != 'S':
                print("[KEY] S")
                ser.write(b'S')
                last_dir = 'S'

            elif event.key == pygame.K_a and last_dir != 'A':
                print("[KEY] A")
                ser.write(b'A')
                last_dir = 'A'

    # -------- SERIAL READ --------
    while ser.in_waiting:
        line = ser.readline().decode(errors="ignore").strip()
        if not line:
            continue

        # expect: S:...;F:x,y;
        new_snake = []
        new_food = None

        if "S:" in line:
            parts = line.split("F:")
            snake_part = parts[0][2:]  # after 'S:'

            for seg in snake_part.split(";"):
                if "," in seg:
                    xc, yc = seg.split(",", 1)
                    if len(xc) == 1 and len(yc) == 1:
                        x = (ord(xc) - 48) % GRID_W
                        y = (ord(yc) - 48) % GRID_H
                        new_snake.append((x, y))

        if "F:" in line:
            food_part = line.split("F:")[1]
            if "," in food_part:
                fc, fy = food_part.split(",", 1)
                if len(fc) == 1 and len(fy) >= 1:
                    fx = (ord(fc) - 48) % GRID_W
                    fy = (ord(fy[0]) - 48) % GRID_H
                    new_food = (fx, fy)

        if new_snake:
            snake = new_snake
        if new_food:
            food = new_food

    # -------- DRAW --------
    screen.fill((0, 0, 0))

    # grid
    for x in range(GRID_W):
        for y in range(GRID_H):
            pygame.draw.rect(
                screen,
                (30, 30, 30),
                (x * CELL, y * CELL, CELL, CELL),
                1
            )

    # food
    if food:
        fx, fy = food
        pygame.draw.rect(
            screen,
            (255, 60, 60),
            (fx * CELL, fy * CELL, CELL, CELL)
        )

    # snake
    for i, (x, y) in enumerate(snake):
        color = (0, 255, 0) if i == 0 else (0, 180, 0)
        pygame.draw.rect(
            screen,
            color,
            (x * CELL, y * CELL, CELL, CELL)
        )

    pygame.display.flip()
    clock.tick(200)

pygame.quit()
ser.close()
