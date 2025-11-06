int ledRojo = 14;
int ledAmarillo = 4;
int ledVerde = 5;

void setup() {
  pinMode(ledRojo, OUTPUT);
  pinMode(ledAmarillo, OUTPUT);
  pinMode(ledVerde, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  if (Serial.available()) {
    String data = Serial.readStringUntil('\n');
    int valores[3];
    int index = 0;
    char *token = strtok((char*)data.c_str(), ",");

    while (token != NULL && index < 3) {
      valores[index++] = constrain(atoi(token), 0, 255);
      token = strtok(NULL, ",");
    }

    if (index == 3) {
      analogWrite(ledRojo, valores[0]);
      analogWrite(ledAmarillo, valores[1]);
      analogWrite(ledVerde, valores[2]);
    }
  }
}
