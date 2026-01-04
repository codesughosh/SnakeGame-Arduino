extern "C" {
  void snake_init();
  void snake_loop(uint8_t key);
}

void setup() {
  Serial.begin(9600);
  snake_init();
}

void loop() {
  uint8_t key = 0;
  if (Serial.available()) {
    key = Serial.read();
  }
  snake_loop(key);
}
