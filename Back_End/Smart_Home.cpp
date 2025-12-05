#include <WiFi.h>
#include <FirebaseESP32.h>

// Wi-Fi credentials
#define WIFI_SSID "Wave Guardian"
#define WIFI_PASSWORD "Abba.2024"

// Firebase project credentials
#define FIREBASE_HOST "bash-smart-home-esp32-default-rtdb.firebaseio.com"
#define FIREBASE_API_KEY "AIzaSyD3yVnEpr-e94BOb9aOWoaGgTnfajyIAqg"

FirebaseConfig firebaseConfig;
FirebaseAuth firebaseAuth;

FirebaseData firebaseData;

#include <DHT.h>

#define DHTPIN 4      // Pin connected to DHT sensor
#define DHTTYPE DHT22 // Type of DHT sensor (DHT11/DHT22)

DHT dht(DHTPIN, DHTTYPE);

void setup() {
    Serial.begin(115200);
    dht.begin();

    // Connect to Wi-Fi
    Serial.print("Connecting to Wi-Fi");
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    while (WiFi.status() != WL_CONNECTED) {
        Serial.print(".");
        delay(300);
    }
    Serial.println("\nWi-Fi connected.");
    Serial.print("IP Address: ");
    Serial.println(WiFi.localIP());

    // Firebase initialization
    ssl.setInsecure();
    initializeApp(client, app, getAuth(noAuth));
    app.getApp<RealtimeDatabase>(Database);
    Database.url(DATABASE_URL);
    client.setAsyncResult(result);
}

void loop() {
    // Get sensor readings
    float temperature = dht.readTemperature(); // Read temperature in Celsius
    float humidity = dht.readHumidity();       // Read humidity

    // Check if the readings are valid
    if (isnan(temperature) || isnan(humidity)) {
    Serial.println("Failed to read from DHT sensor!");
    // Use default values or skip sending to Firebase
    temperature = 0.0; // Default or last known value
    humidity = 0.0;    // Default or last known value
}
    } else {
        Serial.print("Temperature: ");
        Serial.print(temperature);
        Serial.println(" °C");

        Serial.print("Humidity: ");
        Serial.print(humidity);
        Serial.println(" %");

        // Update Firebase with the real readings
        Serial.print("Updating temperature... ");
        if (Firebase.RTDB.setFloat(&firebaseData, "/sensors/temperature", temperature)) {
            Serial.println("Success");
        } else {
            Serial.println("Failed");
        }

        Serial.print("Updating humidity... ");
        if (Firebase.RTDB.setFloat(&firebaseData, "/sensors/humidity", humidity)) {
            Serial.println("Success");
        } else {
            Serial.println("Failed");
        }
    }

    // Your relay state retrieval and other logic
    delay(5000); // Adjust delay as needed
}

