/*
    Arduino and MPU6050 IMU - 3D Visualization Example 
     by Dejan, https://howtomechatronics.com
*/
import processing.net.*; 
import java.awt.event.KeyEvent;
import java.io.IOException;

String data="";
Client myClient;
TaskObject rotatingObj;
TaskObject targetObj;
float roll, pitch,yaw;
Rotation rotImu;

String service_uuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
String char_uuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; 

Rotation[] rotations = new Rotation[25];
int taskCounter;
boolean tasksFinished = false;

void setup() {

  size (1920, 1080, P3D);
  float x,y,z;
  //noStroke();
  //myClient = new Client(this, "192.168.4.1", 80); 

  rotatingObj = new TaskObject(color(255, 204, 0), 1 , 2, 3);
  targetObj = new TaskObject(color(255, 255, 255,100), 90,45,90);
  rotImu = new Rotation(0,0,0);

  taskCounter = 0;

  for(int i = 0; i < 25; i++) {
    x = random(-180, 180);
    y = random(-180, 180);
    z = random(-180, 180);
    rotations[i] = new Rotation(x,y,z);
  }

}

void draw() {
  translate(width/2, height/2, 0);
  background(233);
  if(!tasksFinished){
    //readData();
    
    //lights();
    // camera(0, 0, 200, 0, 0, 1, 0, 1, 0);
    textSize(22);
    fill(0);
    text("Roll: " + int(roll) + "\nPitch: " + int(pitch) + "\nYaw: " + int(yaw), -100, 265);
    
    rotatingObj.setRotation(rotImu);
    //rotatingObj.display();
    targetObj.setRotation(rotations[taskCounter]);
    targetObj.display();
  } else {
    textSize(50);
    fill(0);
    text("Done", 0,0);
  }
  //delay(10);
  //println("rpy:\t" + roll + "\t" + pitch + "\t" + yaw); // Print the values to check whether we are getting proper values
}

void keyReleased() {
  if(taskCounter < 24 && checkAccuracy()) {
    taskCounter++;
  } else {
    tasksFinished = true;
  }
}

boolean checkAccuracy() {
  if(abs(roll - rotations[taskCounter].x) < 2 &&
  abs(pitch - rotations[taskCounter].y) < 2 &&
  abs(yaw - rotations[taskCounter].z) < 2) {
    return true;
  }
  return true;
}

// Read data from the Serial Port
void readData () { 
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
        rotImu.x = float(items[0]);
        rotImu.y = float(items[1]);
        rotImu.z = float(items[2]);
        //println("Roll: " + roll + "     Pitch: " + pitch);

       }
    }
  }
}

class TaskObject {
  color c;
  float xpos;
  float ypos;
  float roll;
  float pitch;
  float yaw;

  TaskObject(color objColor, float roll, float pitch, float yaw) {
    this.c = objColor;
    this.xpos = width/2;
    this.ypos = height/2;
    this.roll = roll;
    this.pitch = pitch;
    this.yaw = yaw;
  }

  void display() {
    pushMatrix();
    rotateX(radians(this.roll));
    rotateZ(radians(this.pitch));
    rotateY(radians(this.yaw));
    
    // 3D 0bject
    fill(this.c);
    box (300, 200, 200); // Draw box
    translate(-200,0,0);
    fill(this.c);
    box(100,200,50);
    translate(150,125,0);
    fill(this.c);
    box(400,50,50);
    popMatrix();
  }

  void setRotation(Rotation rot) {
    this.roll = rot.x;
    this.pitch = rot.y;
    this.yaw = rot.z;
  }

}
 class Rotation {
  float x;
  float y;
  float z;

  Rotation(float px, float py, float pz) {
    x = px;
    y = py;
    z = pz;
  }
 }
