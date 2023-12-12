/*********
  Rui Santos
  Complete project details at https://randomnerdtutorials.com
*********/
#include "LSM6DS3.h"
#include "Wire.h"
// Load Wi-Fi library
#include <WiFi.h>

// Replace with your network credentials
const char *ssid = "ESP32-Access-Point";
const char *password = "123456789";

// Set web server port number to 80
WiFiServer server(80);


// Create a instance of class LSM6DS3
LSM6DS3 myIMU(I2C_MODE, 0x6A); // I2C device address 0x6A
                               //  put your setup code here, to run once:
float AccX, AccY, AccZ;
float GyroX, GyroY, GyroZ;
float accAngleX, accAngleY, gyroAngleX, gyroAngleY, gyroAngleZ;
float roll, pitch, yaw;
float AccErrorX, AccErrorY, GyroErrorX, GyroErrorY, GyroErrorZ;
float elapsedTime, currentTime, previousTime;
int c = 0;

void setup()
{
    Serial.begin(115200);

    while (!Serial);
    // Call .begin() to configure the IMUs
    if (myIMU.begin() != 0)
    {
        Serial.println("Device error");
    }
    else
    {
        Serial.println("Device OK!");
    }
    calculate_IMU_error();

    // Connect to Wi-Fi network with SSID and password
    Serial.print("Setting AP (Access Point)…");
    // Remove the password parameter, if you want the AP (Access Point) to be open
    WiFi.softAP(ssid, password);

    IPAddress IP = WiFi.softAPIP();
    Serial.print("AP IP address: ");
    Serial.println(IP);

    server.begin();
}

void loop()
{
    WiFiClient client = server.available(); // Listen for incoming clients

    if (client)
    {                                  // If a new client connects,
        Serial.println("New Client."); // print a message out in the serial port
        while (client.connected())
        { 
            calcRollPitchYaw();
            client.write(roll);
            client.write("/");
            client.write(pitch);
            client.write("/");
            client.write(yaw);
            client.write("\n");

            Serial.print(roll);
            Serial.print("/");
            Serial.print(pitch);
            Serial.print("/");
            Serial.println(yaw);
        }
    }
}

void calculate_IMU_error()
{
    // We can call this funtion in the setup section to calculate the accelerometer and gyro data error. From here we will get the error values used in the above equations printed on the Serial Monitor.
    // Note that we should place the IMU flat in order to get the proper values, so that we then can the correct values
    // Read accelerometer values 200 times
    while (c < 200)
    {
        AccX = myIMU.readFloatAccelX();
        AccY = myIMU.readFloatAccelY();
        AccZ = myIMU.readFloatAccelZ();
        // Sum all readings
        AccErrorX = AccErrorX + ((atan((AccY) / sqrt(pow((AccX), 2) + pow((AccZ), 2))) * 180 / PI));
        AccErrorY = AccErrorY + ((atan(-1 * (AccX) / sqrt(pow((AccY), 2) + pow((AccZ), 2))) * 180 / PI));
        c++;
    }
    // Divide the sum by 200 to get the error value
    AccErrorX = AccErrorX / 200;
    AccErrorY = AccErrorY / 200;
    c = 0;
    // Read gyro values 200 times
    while (c < 200)
    {
        // Sum all readings
        GyroX = myIMU.readFloatGyroX();
        GyroY = myIMU.readFloatGyroY();
        GyroZ = myIMU.readFloatGyroZ();

        GyroErrorX = GyroErrorX + (GyroX / 131.0);
        GyroErrorY = GyroErrorY + (GyroY / 131.0);
        GyroErrorZ = GyroErrorZ + (GyroZ / 131.0);
        c++;
    }
    // Divide the sum by 200 to get the error value
    GyroErrorX = GyroErrorX / 200;
    GyroErrorY = GyroErrorY / 200;
    GyroErrorZ = GyroErrorZ / 200;
    // Print the error values on the Serial Monitor
    Serial.print("AccErrorX: ");
    Serial.println(AccErrorX);
    Serial.print("AccErrorY: ");
    Serial.println(AccErrorY);
    Serial.print("GyroErrorX: ");
    Serial.println(GyroErrorX);
    Serial.print("GyroErrorY: ");
    Serial.println(GyroErrorY);
    Serial.print("GyroErrorZ: ");
    Serial.println(GyroErrorZ);
}

void calcRollPitchYaw() {
    AccX = myIMU.readFloatAccelX();
            AccY = myIMU.readFloatAccelY();
            AccZ = myIMU.readFloatAccelZ();
            // Calculating Roll and Pitch from the accelerometer data
            accAngleX = (atan(AccY / sqrt(pow(AccX, 2) + pow(AccZ, 2))) * 180 / PI) - 0.58;      // AccErrorX ~(0.58) See the calculate_IMU_error()custom function for more details
            accAngleY = (atan(-1 * AccX / sqrt(pow(AccY, 2) + pow(AccZ, 2))) * 180 / PI) + 1.58; // AccErrorY ~(-1.58)
            // === Read gyroscope data === //
            previousTime = currentTime;                        // Previous time is stored before the actual time read
            currentTime = millis();                            // Current time actual time read
            elapsedTime = (currentTime - previousTime) / 1000; // Divide by 1000 to get seconds
            GyroX = myIMU.readFloatGyroX();
            GyroY = myIMU.readFloatGyroY();
            GyroZ = myIMU.readFloatGyroZ();
            // Correct the outputs with the calculated error values
            GyroX = GyroX + 0.56; // GyroErrorX ~(-0.56)
            GyroY = GyroY - 2;    // GyroErrorY ~(2)
            GyroZ = GyroZ + 0.79; // GyroErrorZ ~ (-0.8)
            // Currently the raw values are in degrees per seconds, deg/s, so we need to multiply by sendonds (s) to get the angle in degrees
            gyroAngleX = gyroAngleX + GyroX * elapsedTime; // deg/s * s = deg
            gyroAngleY = gyroAngleY + GyroY * elapsedTime;
            yaw = yaw + GyroZ * elapsedTime;
            // Complementary filter - combine acceleromter and gyro angle values
            roll = 0.96 * gyroAngleX + 0.04 * accAngleX;
            pitch = 0.96 * gyroAngleY + 0.04 * accAngleY;

}