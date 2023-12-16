/*
    Arduino and MPU6050 IMU - 3D Visualization Example 
     by Dejan, https://howtomechatronics.com
*/
import processing.net.*; 
import java.awt.event.KeyEvent;
import java.io.IOException;

String data="";
Client myClient;
float roll, pitch,yaw;

String service_uuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
String char_uuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; 

void setup() {
  size (1920, 1080, P3D);
  myClient = new Client(this, "192.168.4.1", 80); 
  
}
void draw() {
  serialEvent();
  translate(width/2, height/2, 0);
  background(233);
  textSize(22);
  text("Roll: " + int(roll) + "     Pitch: " + int(pitch), -100, 265);
  // Rotate the object
  rotateX(radians(pitch));
  rotateZ(radians(roll));
  rotateY(radians(yaw));
  
  // 3D 0bject
  textSize(30);  
  fill(0, 76, 153);
  box (386, 40, 200); // Draw box
  textSize(25);
  fill(255, 255, 255);
  text("Rotate that shit", -183, 10, 101);
  //delay(10);
  println("ypr:\t" + roll + "\t" + yaw); // Print the values to check whether we are getting proper values
}
// Read data from the Serial Port
void serialEvent () { 
  // reads the data from the Serial Port up to the character '.' and puts it into the String variable "data".
  if (myClient.available() > 0) { 
    // reads the data from the Serial Port up to the character '.' and puts it into the String variable "data".
    String data = myClient.readStringUntil('\n');
    //println("I'm here");
    // if you got any bytes other than the linefeed:
    if (data != null) {
      data = trim(data);
      // split the string at "/"
      String items[] = split(data, '/');
      if (items.length > 1) {
        //--- Roll,Pitch in degrees
       // println("I'm here 2");
        roll = float(items[0]);
        pitch = float(items[1]);
        yaw = float(items[2]);
        //println("Roll: " + roll + "     Pitch: " + pitch);

       }
    }
  }
}
