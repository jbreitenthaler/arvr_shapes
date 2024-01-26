/*
    Arduino and MPU6050 IMU - 3D Visualization Example 
     by Dejan, https://howtomechatronics.com
*/
import processing.net.*; 
import java.awt.event.KeyEvent;
import java.io.IOException;


enum State {
  START,
  TRAINING,
  TRAINING_DONE,
  TASK,
  DONE
}

String data="";
Client myClient;
TaskObject rotatingObj;
TaskObject targetObj;
Rotation rotImu;

String service_uuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
String char_uuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8"; 

int nTasks = 12;
Rotation[] rotations = new Rotation[nTasks];
Rotation[] trainingRotations = new Rotation[10];

int[] completionTimes = new int[nTasks];
float[] completionAngles = new float[nTasks];
int millisStartTask;
int taskCounter;
int[] errors = new int[nTasks];
boolean progressToNext = false;
boolean calibrate = false;

State state = State.START;


void setup() {

  size (1920, 1080, P3D);
  float w,x,y,z;
  //noStroke();
  myClient = new Client(this, "192.168.4.1", 80); 

  rotatingObj = new TaskObject(color(255, 204, 0), 1 ,1, 1,1);
  targetObj = new TaskObject(color(255, 255, 255,100), 0,0,0,0);
  rotImu = new Rotation(1,1,1,1);

  taskCounter = 0;

  randomSeed(10);

  for(int i = 0; i < nTasks; i++) {
    w = random(-1,1);
    x = random(-1,1);
    y = random(-1,1);
    z = random(-1,1);
    rotations[i] = new Rotation(w,x,y,z);
  }

  for(int i = 0; i < 10; i++) {
    w = random(-1,1);
    x = random(-1,1);
    y = random(-1,1);
    z = random(-1,1);
    trainingRotations[i] = new Rotation(w,x,y,z);
  }
  initErrors();

}


void draw() {
  translate(width/2, height/2, 0);
  background(233);
  readData();
  switch(state) {
    case START:
      startWindow();
      break;
    case TRAINING:
      training();
      break;
    case TRAINING_DONE:
      trainingDone();
      break;
    case TASK:
      task();
      break;
    case DONE:
      taskDone();
      break;
  }
}

void startWindow() {
  textSize(50);
  fill(0);
  textAlign(CENTER);
  text("Press ENTER to start training", 0,0);
  textSize(22);
  text("(To finish a task press SPACEBAR, if you were precise enough the next task will show up)", 0, 50);
}

void training() {
  if(calibrate) {
    textSize(50);
    textAlign(CENTER);
    fill(0);
    text("Calibrate by aligning the object and pressing i", 0,0);
  } else {
    rotatingObj.setRotation(rotImu);
    rotatingObj.display();
    targetObj.setRotation(trainingRotations[taskCounter]);
    targetObj.display();
    if(checkAccuracy(trainingRotations[taskCounter])) {
      rotatingObj.c = color(47, 158, 51);
      progressToNext = true;
    } else {
      rotatingObj.c = color(255, 204, 0);
      progressToNext = false;
    }
  }
}

void task() {
  
  if(calibrate) {
    textSize(50);
    textAlign(CENTER);
    fill(0);
    text("Calibrate by aligning the object and pressing i", 0,0);
  } else {
    rotatingObj.setRotation(rotImu);
    rotatingObj.display();
    targetObj.setRotation(rotations[taskCounter]);
    targetObj.display();
    if(checkAccuracy(rotations[taskCounter])) {
      //rotatingObj.c = color(47, 158, 51);
      progressToNext = true;
    } else {
      //rotatingObj.c = color(255, 204, 0);
      progressToNext = false;
    }
  }
}

void trainingDone() {
  textSize(50);
  fill(0);
  textAlign(CENTER);
  text("Congrats you finished the training, press ENTER to start the taskset", 0,0);
  textSize(22);
  text("(To finish a task press SPACEBAR, if you were precise enough the next task will show up)", 0, 50);
}

void taskDone() {
  textSize(50);
  fill(0);
  textAlign(CENTER);
  text("Congrats you finished the taskset", 0,0); //<>// //<>// //<>// //<>//
} //<>// //<>// //<>// //<>//
 //<>// //<>// //<>// //<>//
void keyReleased() { //<>// //<>// //<>// //<>//
  if(key == 'i') {
    sendInit(); //<>// //<>// //<>// //<>//
    calibrate = false;  //<>// //<>// //<>// //<>//
    millisStartTask = millis();    
    //printDistances(); //<>//
  } //<>// //<>// //<>// //<>//
 //<>// //<>// //<>//
  if(key == ENTER && state == State.START) {
    state = State.TRAINING;
    //trainingRotations[taskCounter] = new Rotation(rotImu.qw + random(-0.1,0.1),rotImu.qx + random(-0.1,0.1),rotImu.qy + random(-0.1,0.1),rotImu.qz + random(-0.1,0.1) );
    millisStartTask = millis();
    return;
  } //<>//
  if(key == ENTER && state == State.TRAINING_DONE) { //<>// //<>//
    state = State.TASK; //<>// //<>// //<>// //<>// //<>//
    millisStartTask = millis(); //<>// //<>//
    return; //<>// //<>// //<>// //<>// //<>//
  } //<>// //<>// //<>// //<>//
  if(key == ' ' && progressToNext) { //<>// //<>// //<>// //<>// //<>//
    progressToNext = false; //<>// //<>//
    rotatingObj.c = color(255, 204, 0); //<>// //<>// //<>// //<>//
    switch(state) { //<>// //<>// //<>// //<>// //<>//
      case TRAINING: //<>//
         //<>//
        calibrate = true; //<>// //<>// //<>//
        if (taskCounter < 9) {
          saveData(trainingRotations[taskCounter]);
          taskCounter++;
          //trainingRotations[taskCounter] = new Rotation(rotImu.qw + random(-0.2,0.2),rotImu.qx + random(-0.2,0.2),rotImu.qy + random(-0.2,0.2),rotImu.qz + random(-0.2,0.2) );
        } else {
          state = State.TRAINING_DONE;
          saveData(trainingRotations[taskCounter]); //<>//
          writeDataToFile("training"); //<>// //<>// //<>// //<>//
          initErrors(); //<>//
          taskCounter = 0; //<>// //<>// //<>// //<>// //<>//
        } //<>// //<>// //<>// //<>//
        break; //<>// //<>// //<>//
      case TASK:
        calibrate = true; //<>//
        if (taskCounter < (nTasks - 1)) { //<>// //<>// //<>// //<>//
          saveData(rotations[taskCounter]); //<>// //<>// //<>//
          taskCounter++; //<>//
        } else { //<>// //<>// //<>// //<>// //<>// //<>// //<>//
          state = State.DONE; //<>// //<>// //<>// //<>// //<>// //<>//
          saveData(rotations[taskCounter]);
          writeDataToFile("task");
        }
        break;
      default:
        break;
    }
  } else if (key == ' ') {
    errors[taskCounter]++;
    
  }
}
void printDistances() {
  println("Distances");
  Rotation calibratedRot = rotImu;
  for(int i = 0; i < nTasks; i++) {
    println("Task " + (i + 1));
    println(convertToDegrees(getDistance(calibratedRot, rotations[i])));
  }
} //<>//
 //<>//
boolean checkAccuracy(Rotation target) { //<>//
  if(getDistance(target, rotImu) < 0.08) { //<>//
    return true;
  } //<>//
  return false; //<>//
}
 //<>//
float getDistance(Rotation q1, Rotation q2) { //<>// //<>// //<>// //<>//
  q1.normalize(); //<>// //<>// //<>// //<>//
  q2.normalize(); //<>// //<>// //<>// //<>//
  return 2*acos(abs(q1.qx*q2.qx + q1.qy*q2.qy + q1.qz*q2.qz + q1.qw*q2.qw)); //<>// //<>// //<>//
}
 //<>// //<>// //<>//
void initErrors() { //<>// //<>// //<>//
  for(int i = 0; i < nTasks; i++) {
    errors[i] = 0; //<>// //<>// //<>//
  } //<>// //<>// //<>//
} //<>// //<>// //<>// //<>//
 //<>// //<>// //<>// //<>//
// Read data from the Serial Port //<>//
void readData () { //<>//
  // reads the data from the Serial Port up to the character '.' and puts it into the String variable "data". //<>//
  if (myClient.available() > 0) {  //<>//
    // reads the data from the Serial Port up to the character '.' and puts it into the String variable "data". //<>//
    String data = myClient.readStringUntil('\n'); //<>//
    //println("I'm here"); //<>//
    // if you got any bytes other than the linefeed: //<>// //<>// //<>// //<>//
    if (data != null) { //<>// //<>// //<>//
      data = trim(data); //<>// //<>// //<>// //<>//
      // split the string at "/" //<>// //<>//
      String items[] = split(data, '/'); //<>// //<>// //<>// //<>// //<>//
      if (items.length > 1) { //<>// //<>//
        //--- Roll,Pitch in degrees //<>// //<>// //<>// //<>//
       // println("I'm here 2"); //<>// //<>// //<>//
        rotImu.qw = float(items[0]); //<>//
        rotImu.qx = float(items[1]); //<>// //<>// //<>// //<>//
        rotImu.qy = float(items[2]);
        rotImu.qz = float(items[3]); //<>// //<>// //<>// //<>//
        //println("Roll: " + roll + "     Pitch: " + pitch); //<>// //<>// //<>// //<>//
 //<>// //<>// //<>// //<>// //<>//
      } //<>// //<>//
    } //<>//
  }
} //<>//

void writeDataToFile(String filename) { //<>//
  Table table = new Table(); //<>//
  
  table.addColumn("taskNum"); //<>// //<>// //<>// //<>// //<>//
  table.addColumn("completionTime"); //<>// //<>// //<>// //<>//
  table.addColumn("angleDiff"); //<>// //<>// //<>// //<>//
  table.addColumn("errors"); //<>//
   //<>// //<>// //<>// //<>//
  for (int i = 0; i < taskCounter + 1; i++) {
    TableRow newRow = table.addRow(); //<>// //<>// //<>//
    newRow.setInt("taskNum", i + 1); //<>// //<>// //<>//
    newRow.setInt("completionTime", completionTimes[i]);
    newRow.setFloat("angleDiff", completionAngles[i]); //<>// //<>// //<>//
    newRow.setInt("errors", errors[i]);
  } //<>// //<>// //<>// //<>//
  saveTable(table, "data/" + filename + ".csv"); //<>// //<>// //<>// //<>// //<>//
} //<>// //<>// //<>// //<>//

void saveData(Rotation target) {
  completionTimes[taskCounter] = millis() - millisStartTask;
  completionAngles[taskCounter] = convertToDegrees(getDistance(target, rotImu));
  millisStartTask = millis();
}

float convertToDegrees(float rad) {
  return rad * 180 / PI;
}

class TaskObject {
  color c;
  float xpos;
  float ypos;
  float qx,qy,qz,qw;

  TaskObject(color objColor, float pw, float px, float py, float pz) {
    this.c = objColor;
    this.xpos = width/2;
    this.ypos = height/2;
    this.qw = qw;
    this.qx = qx;
    this.qy = qy;
    this.qz = qz;
  }

  void display() {
    pushMatrix();
    this.normalize();
    // m_00 = 1.0f - 2.0f*this.qy*this.qy - 2.0f*this.qz*this.qz;
    // m_01 = 2.0f*this.qx*this.qy - 2.0f*this.qz*this.qw;
    // m_02 = 2.0f*this.qx*this.qz + 2.0f*this.qy*this.qw;
    // m_10 = 2.0f*this.qx*this.qy + 2.0f*this.qz*this.qw;
    // m_11 = 1.0f - 2.0f*this.qx*this.qx - 2.0f*this.qz*this.qz;
    // m_12 = 2.0f*this.qy*this.qz - 2.0f*this.qx*this.qw;
    // m_20 = 2.0f*this.qx*this.qz - 2.0f*this.qy*this.qw;
    // m_21 = 2.0f*this.qy*this.qz + 2.0f*this.qx*this.qw;
    // m_22 = 1.0f - 2.0f*this.qx*this.qx - 2.0f*this.qy*this.qy;
    normal(1, 0, 0);
    float m_00 = pow(this.qw,2) + pow(this.qx,2) - pow(this.qy,2) - pow(this.qz,2);
    float m_01 = 2*(this.qx*this.qy - this.qz*this.qw);
    float m_02 = 2*(this.qx*this.qz + this.qy*this.qw);
    float m_10 = 2*(this.qx*this.qy + this.qz*this.qw);
    float m_11 = pow(this.qw,2) - pow(this.qx,2) + pow(this.qy,2) - pow(this.qz,2);
    float m_12 = 2*(this.qy*this.qz - this.qx*this.qw);
    float m_20 = 2*(this.qx*this.qz - this.qy*this.qw);
    float m_21 = 2*(this.qy*this.qz + this.qx*this.qw);
    float m_22 = pow(this.qw,2) - pow(this.qx,2) - pow(this.qy,2) + pow(this.qz,2);
    ///////////////////////////////////
    // Sphere
    // applyMatrix(
    //   -m_00, -m_01, -m_02, 0.0f,
    //   m_10, m_11, m_12, 0.0f,
    //   m_20, m_21, m_22, 0.0f,
    //   0.0f, 0.0f, 0.0f, 1.0f);
      ////////////////////////////
     /////////////////////////////
     //Cubocta
    applyMatrix(
      m_00, m_01, m_02, 0.0f,
      -m_10, -m_11, -m_12, 0.0f,
      m_20, m_21, m_22, 0.0f,
      0.0f, 0.0f, 0.0f, 1.0f);
    /////////////////////////////
      
    
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
    this.qx = rot.qx;
    this.qy = rot.qy;
    this.qz = rot.qz;
    this.qw = rot.qw;
  }
  void normalize() {
    float n = 1.0f/sqrt(this.qx*this.qx+this.qy*this.qy+this.qz*this.qz+this.qw*this.qw);
    this.qx *= n;
    this.qy *= n;
    this.qz *= n;
    this.qw *= n;    
  }

}
class Rotation {
  float qx;
  float qy;
  float qz;
  float qw;

  Rotation(float pw, float px, float py, float pz) {
    this.qx = px;
    this.qy = py;
    this.qz = pz;
    this.qw = pw;
  }

  void normalize() {
    float n = 1.0f/sqrt(this.qx*this.qx+this.qy*this.qy+this.qz*this.qz+this.qw*this.qw);
    this.qx *= n;
    this.qy *= n;
    this.qz *= n;
    this.qw *= n;    
  }
}

void sendInit() {
   myClient.write("i");
}
