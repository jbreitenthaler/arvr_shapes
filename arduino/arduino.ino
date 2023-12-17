/*********
  Rui Santos
  Complete project details at https://randomnerdtutorials.com
*********/
#include "LSM6DS3.h"
#include "Wire.h"
// Load Wi-Fi library
#include <WiFi.h>

// #include <MadgwickAHRS.h>
// #include "Adafruit_AHRS_Mahony.h"
#include "Fusion.h"

const char *ssid = "ESP32-Access-Point";
const char *password = "123456789";

// Set web server port number to 80
WiFiServer server(80);
WiFiClient client;

// Create a instance of class LSM6DS3
LSM6DS3 myIMU(I2C_MODE, 0x6A); // I2C device address 0x6A
                               //  put your setup code here, to run once:
FusionAhrs ahrs;
    

#define SAMPLE_PERIOD (0.1f) // replace this with actual sample period

unsigned long microsPerReading, microsPrevious;
float accelScale, gyroScale;

float AccX, AccY, AccZ;
float GyroX, GyroY, GyroZ;
float accAngleX, accAngleY, gyroAngleX, gyroAngleY, gyroAngleZ;
int aix, aiy, aiz;
int gix, giy, giz;
float roll, pitch, yaw;
float AccErrorX, AccErrorY, GyroErrorX, GyroErrorY, GyroErrorZ;
float elapsedTime, currentTime, previousTime;
int c = 0;

void setup()
{
    Serial.begin(115200);
    Serial.println("IT WORKS");
    while (!Serial)
        ;
    // Call .begin() to configure the IMUs
    if (myIMU.begin() != 0)
    {
        Serial.println("Device error");
    }
    else
    {
        Serial.println("Device OK!");
    }
    myIMU.settings.gyroRange = 245;
    myIMU.settings.gyroSampleRate = 833;
    myIMU.settings.accelRange = 2;
    myIMU.settings.accelSampleRate = 833;

    FusionAhrsInitialise(&ahrs);
    
    //    calculate_IMU_error();
    microsPerReading = 16000;
    microsPrevious = micros();
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
    //    calcRollPitchYaw();
    aix = myIMU.readRawAccelX();
    aiy = myIMU.readRawAccelY();
    aiz = myIMU.readRawAccelZ();
    gix = myIMU.readRawGyroX();
    giy = myIMU.readRawGyroY();
    giz = myIMU.readRawGyroZ();

    calcRollPitchYawMadgwick(aix, aiy, aiz, gix, giy, giz);
    

    const FusionEuler euler = FusionQuaternionToEuler(FusionAhrsGetQuaternion(&ahrs));


    roll = euler.angle.roll;
    pitch = euler.angle.pitch;
    yaw = euler.angle.yaw;

    // sendData();
    Serial.print(roll);
    Serial.print("/");
    Serial.print(pitch);
    Serial.print("/");
    Serial.println(yaw);
    delay(16);
    client = server.available(); // Listen for incoming clients

    if (client)
    {                                  // If a new client connects,
        Serial.println("New Client."); // print a message out in the serial port
        while (client.connected())
        {
            unsigned long microsNow;
            microsNow = micros();
            if (microsNow - microsPrevious >= microsPerReading)
            {

                microsPrevious = microsPrevious + microsPerReading;
            }

            // delay(16);
        }
    }
}

void calcRollPitchYawMadgwick(int &aix, int &aiy, int &aiz, int &gix, int &giy, int &giz)
{
    float ax, ay, az;
    float gx, gy, gz;
    ax = convertRawAcceleration(aix);
    ay = convertRawAcceleration(aiy);
    az = convertRawAcceleration(aiz);
    gx = convertRawGyro(gix);
    gy = convertRawGyro(giy);
    gz = convertRawGyro(giz);
    const FusionVector gyroscope = {gx, gy, gz}; // replace this with actual gyroscope data in degrees/s
    const FusionVector accelerometer = {ax, ay, az}; // replace this with actual accelerometer data in g

    FusionAhrsUpdateNoMagnetometer(&ahrs, gyroscope, accelerometer, SAMPLE_PERIOD);
    // gyroScale = 1;
    // // update the filter, which computes orientation
    // filter.updateIMU(gx * gyroScale, gy * gyroScale, gz * gyroScale, ax, ay, az);
}

float convertRawAcceleration(int aRaw)
{
    // since we are using 2 g range
    // -2 g maps to a raw value of -32768
    // +2 g maps to a raw value of 32767

    float a = (aRaw * 2.0) / 32768.0;
    return a;
}

float convertRawGyro(int gRaw)
{
    // since we are using 250 degrees/seconds range
    // -250 maps to a raw value of -32768
    // +250 maps to a raw value of 32767

    float g = (gRaw * 245.0) / 32768.0;
    return g;
}

void sendData()
{
    char buf[11];
    memset(buf, 0, sizeof(buf));
    dtostrf(roll, 6, 3, buf);
    client.write((const uint8_t *)&buf, sizeof(buf));
    client.write("/");
    memset(buf, 0, sizeof(buf));
    dtostrf(pitch, 6, 3, buf);
    client.write((const uint8_t *)&buf, sizeof(buf));
    client.write("/");
    memset(buf, 0, sizeof(buf));
    dtostrf(yaw, 6, 3, buf);
    client.write((const uint8_t *)&buf, sizeof(buf));
    client.write("\n");

    Serial.print(roll);
    Serial.print("/");
    Serial.print(pitch);
    Serial.print("/");
    Serial.println(yaw);
}
