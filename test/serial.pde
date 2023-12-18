

/*
    Arduino and MPU6050 IMU - 3D Visualization Example 
     by Dejan, https://howtomechatronics.com
*/
import processing.serial.*;
import java.awt.event.KeyEvent;
import java.io.IOException;
import processing.core.*;



Serial myPort;
String data="";
float qw,qx,qy,qz;
PVector vec_w;

String service_uuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
String char_uuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; 
Rot r;
PVector v;

void setup() {
  size (1920, 1080, P3D);
  myPort = new Serial(this, "COM7", 115200); // starts the serial communication
  myPort.bufferUntil('\n');
  
 
}
void draw() {
  
  
  serialEvent(myPort);
  translate(width/2, height/2, 0);
  background(233);
  // textSize(22); //<>// //<>// //<>// //<>// //<>//
  // //text("Roll: " + int(roll) + "     Pitch: " + int(pitch), -100, 265);
  // // Rotate the object

 
  // vec_w = new PVector(1,1,1);
  // r = new Rot(w,x,y,z, false);
  // r.applyTo(vec_w);
  // //rotate(vec_w);
  
  
  // // In most cases the origin will be [0,0,0] this avoids the need to create a
  // // PVector when an origin is not provided
  // float ox = vec_w.x*100, oy = vec_w.y*100, oz = vec_w.z*100;
  
  // float halfMinusQySquared = 0.5f - y * y; // calculate common terms to avoid repeated operations //<>// //<>// //<>//
  
  // float rotx = atan2(w * x + y * z, halfMinusQySquared - x * x);
  // float roty = asin(2.0f * (w * y - z * x));
  // float rotz = atan2(w * z + x * y, halfMinusQySquared - z * z);
  // if(abs((roty - 3.14/2)) < 0.1) {
  //   roty = 3.14/2;
  // }
  
  //println("x: "+ ox +"y: "+ oy +"z: "+ oz);
  pushMatrix();
  float n = 1.0f/sqrt(qx*qx+qy*qy+qz*qz+qw*qw);
  qx *= n;
  qy *= n;
  qz *= n;
  qw *= n;
  applyMatrix(
    1.0f - 2.0f*qy*qy - 2.0f*qz*qz, 2.0f*qx*qy - 2.0f*qz*qw, 2.0f*qx*qz + 2.0f*qy*qw, 0.0f,
    2.0f*qx*qy + 2.0f*qz*qw, 1.0f - 2.0f*qx*qx - 2.0f*qz*qz, 2.0f*qy*qz - 2.0f*qx*qw, 0.0f,
    2.0f*qx*qz - 2.0f*qy*qw, 2.0f*qy*qz + 2.0f*qx*qw, 1.0f - 2.0f*qx*qx - 2.0f*qy*qy, 0.0f,
    0.0f, 0.0f, 0.0f, 1.0f);
  
  //rotateX(rotx);
  //rotateY(rotz);
  //rotateZ(roty);

  
  
// rotateX(PI/3);
// rotateZ(-PI/6);
  // beginShape(); //<>//
  // vertex(ox-200, 0, 0); //<>// //<>//
  // vertex( ox, 0, 0);
  // vertex(   ox-200,    0,  oz);
  
  // vertex( ox, 0, oz);
  // vertex( ox,  oy, 0);
  // vertex(   ox-200,    oy,  0);
  
  // vertex( ox,  oy, oz);
  // vertex(   ox-200,  oy,  oz); //<>//
  // endShape(); //<>// //<>//
  // beginShape();
  // vertex(   0,  0,  0);
  // vertex( 200,  0, 0);
  // vertex( 200,  200, 0);
  // vertex(0,    200,  0);

  // vertex(   0,  0,  200);
  // vertex( 200,  0, 200);
  // vertex( 200,  200, 200);
  // vertex(0,    200,  200);

  // endShape(); //<>// //<>//
//   beginShape();
//   vertex(-100, -100, -100);
// vertex( 100, -100, -100);
// vertex(   0,    0,  100);

// vertex( 100, -100, -100);
// vertex( 100,  100, -100);
// vertex(   0,    0,  100);

// vertex( 100, 100, -100);
// vertex(-100, 100, -100);
// vertex(   0,   0,  100);

// vertex(-100,  100, -100);
// vertex(-100, -100, -100);
// vertex(   0,    0,  100);
// endShape();
box (300, 200, 200);
  popMatrix();
   
  //rotateX(vec_w.x);
  //rotateY(vec_w.y);
  //rotateZ(vec_w.z);

  
  
  
  



   //<>//
   //<>// //<>//
  //delay(10);
 // println("ypr:\t" + roll + "\t" + yaw); // Print the values to check whether we are getting proper values
}
// Read data from the Serial Port
void serialEvent (Serial myPort) { 
  // reads the data from the Serial Port up to the character '.' and puts it into the String variable "data".
  data = myPort.readStringUntil('\n');
  
  // if you got any bytes other than the linefeed: //<>//
  if (data != null) { //<>//
    data = trim(data);
    // split the string at "/"
    String items[] = split(data, '/');
    if (items.length > 1) {
      //--- Roll,Pitch in degrees
      qw = float(items[0]);
      qx = float(items[1]);
      qy = float(items[2]);
      qz = float(items[3]);
    }
  }
}
