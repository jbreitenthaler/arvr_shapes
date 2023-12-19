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

const char *ssid = "ESP32-Cubocta";
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

int aix, aiy, aiz;
int gix, giy, giz;
float elapsedTime, currentTime, previousTime;
int c = 0;

void setup()
{
    Serial.begin(115200);
    //Serial.println("IT WORKS");
    
    //while (!Serial)
      //  ;

    initSensorFilter();
    

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
    // delay(16);
    client = server.available(); // Listen for incoming clients

    calcRollPitchYawMadgwick(aix, aiy, aiz, gix, giy, giz);

    const FusionEuler euler = FusionQuaternionToEuler(FusionAhrsGetQuaternion(&ahrs));

            // Serial.print(quat.element.w);
            // Serial.print("/");
            Serial.print(euler.angle.roll);
            Serial.print("/");
            Serial.print(euler.angle.pitch);
            Serial.print("/");
            Serial.println(euler.angle.yaw);

    if (client)
    {                                  // If a new client connects,
        Serial.println("New Client."); // print a message out in the serial port
        while (client.connected())
        {
            if(client.available()){
                char c = client.read();
                if(c == 'i') {
                    initSensorFilter();
                }
            }

            calcRollPitchYawMadgwick(aix, aiy, aiz, gix, giy, giz);

            const FusionQuaternion quat = FusionAhrsGetQuaternion(&ahrs);

            // Serial.print(quat.element.w);
            // Serial.print("/");
            // Serial.print(quat.element.x);
            // Serial.print("/");
            // Serial.print(quat.element.y);
            // Serial.print("/");
            // Serial.println(quat.element.z);

            sendData(quat);

            // microsPrevious = microsPrevious + microsPerReading;

            delay(16);
        }
    }
}

void initSensorFilter()
{
    // myIMU.settings.gyroRange = 245;
    // myIMU.settings.gyroSampleRate = 104;
    // myIMU.settings.accelRange = 2;
    // myIMU.settings.accelSampleRate = 104;
    
    if (myIMU.begin() != 0)
    {
        Serial.println("IMU init error");
        
    }
    else
    {
        Serial.println("IMU OK!");
        uint8_t accelgyrodata = 0;
        myIMU.readRegister(&accelgyrodata, LSM6DS3_ACC_GYRO_CTRL1_XL);
        Serial.println(accelgyrodata);
        accelgyrodata = 0;
        myIMU.readRegister(&accelgyrodata, LSM6DS3_ACC_GYRO_CTRL2_G);
        Serial.println(accelgyrodata);
        
    }    

    FusionAhrsInitialise(&ahrs);

    // const FusionAhrsSettings settings = {
    //         .convention = FusionConventionNwu,
    //         .gain = 0.1f,
    //         .gyroscopeRange = 245.0f, /* replace this with actual gyroscope range in degrees/s */
    //         .accelerationRejection = 10.0f,
    //         .magneticRejection = 10.0f,
    //         .recoveryTriggerPeriod = 5 * SAMPLE_PERIOD, /* 5 seconds */
    // };
    // FusionAhrsSetSettings(&ahrs, &settings);
}

void calcRollPitchYawMadgwick(int &aix, int &aiy, int &aiz, int &gix, int &giy, int &giz)
{
    float ax, ay, az;
    float gx, gy, gz;
    aix = myIMU.readRawAccelX();
    aiy = myIMU.readRawAccelY();
    aiz = myIMU.readRawAccelZ();
    gix = myIMU.readRawGyroX();
    giy = myIMU.readRawGyroY();
    giz = myIMU.readRawGyroZ();

    ax = convertRawAcceleration(aix);
    ay = convertRawAcceleration(aiy);
    az = convertRawAcceleration(aiz);
    gx = convertRawGyro(gix);
    gy = convertRawGyro(giy);
    gz = convertRawGyro(giz);
    // ax = myIMU.readFloatAccelX();
    // ay = myIMU.readFloatAccelY();
    // az = myIMU.readFloatAccelZ();
    // gx = myIMU.readFloatGyroX();
    // gy = myIMU.readFloatGyroY();
    // gz = myIMU.readFloatGyroZ();
    const FusionVector gyroscope = {gx, gy, gz};     // replace this with actual gyroscope data in degrees/s
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

    float a = (aRaw * 2.0) / (32767.0);
    return a;
}

float convertRawGyro(int gRaw)
{
    // since we are using 250 degrees/seconds range
    // -250 maps to a raw value of -32768
    // +250 maps to a raw value of 32767

    float g = (gRaw * 500.0) / 32767.0;
    return g;
}

void sendData(FusionQuaternion quat)
{
    char buf[11];
    memset(buf, 0, sizeof(buf));
    dtostrf(quat.element.w, 6, 3, buf);
    client.write((const uint8_t *)&buf, sizeof(buf));
    client.write("/");
    memset(buf, 0, sizeof(buf));
    dtostrf(quat.element.x, 6, 3, buf);
    client.write((const uint8_t *)&buf, sizeof(buf));
    client.write("/");
    memset(buf, 0, sizeof(buf));
    dtostrf(quat.element.y, 6, 3, buf);
    client.write((const uint8_t *)&buf, sizeof(buf));
    client.write("/");
    memset(buf, 0, sizeof(buf));
    dtostrf(quat.element.z, 6, 3, buf);
    client.write((const uint8_t *)&buf, sizeof(buf));
    client.write("\n");
}
