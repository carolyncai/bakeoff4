import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;
import ketai.camera.*;
import processing.video.*;

KetaiSensor sensor;
KetaiCamera cam;

float cursorX, cursorY;
float light = 0; 
float proxSensorThreshold = 20; //you will need to change this per your device.

private class Target
{
  int target = 0;
  int action = 0;
}

int trialCount = 5; //** it was 5 before. this will be set higher for the bakeoff
int trialIndex = 0;
ArrayList<Target> targets = new ArrayList<Target>();

int startTime = 0; // time starts when the first click is captured
int finishTime = 0; //records the time of the final click
boolean userDone = false;

boolean isTarget = true; // target or action?

void setup() {
  size(480, 480); //you can change this to be fullscreen
  frameRate(60);
  sensor = new KetaiSensor(this);
  sensor.start();
  
  cam = new KetaiCamera(this, 640, 480, 15);
  // uhh
  println("camera list: " +  cam.list());
  cam.setCameraID(0); // back facing
  //cam.setCameraID(1); // front facing
  cam.start();
  
  //orientation(LANDSCAPE);
  orientation(PORTRAIT);

  rectMode(CENTER);
  textFont(createFont("Arial", 40)); //sets the font to Arial size 20
  textAlign(CENTER);

  for (int i=0; i<trialCount; i++)  //don't change this!
  {
    Target t = new Target();
    t.target = ((int)random(1000))%4;
    t.action = ((int)random(1000))%2;
    targets.add(t);
    println("created target with " + t.target + "," + t.action);
  }

  Collections.shuffle(targets); // randomize the order of the button;
}

void drawFour() {
  int index = trialIndex;
  int target = targets.get(index).target;
  
  // top
  if (target == 0) fill(0,0,255);
  else fill(180);
  rect(0,10,2*width,30);
  
  // right
  if (target == 1) fill(0,0,255);
  else fill(180);
  rect(width - 10,0,30,2*height);
  
  // bottom
  if (target == 2) fill(0,0,255);
  else fill(180);
  rect(0,height - 10,2*width,30);
  
  // left
  if (target == 3) fill(0,0,255);
  else fill(180);
  rect(10,0,30,2*height);
    
  // just for the visual to help emphasize the convention
  fill(255);
  ellipse(cursorX, cursorY, 50, 50);
  
  println("ax = " + ax + " , ay = " + ay, width/2, 140);
  
  checkFour();
}

void checkFour() {
  int index = trialIndex;
  int target = targets.get(index).target;
  
  float tol = 4;
  
  // top = 0
  // ay < 0
  if (ay < -1*tol) {
    if (target == 0)
      isTarget = false; //move on to second part
    else if (trialIndex > 0)
      trialIndex--; //move back one trial as penalty!
  }
  
  // right = 1
  // ax < 0
  else if (ax < -1*tol) {
    if (target == 1)
      isTarget = false; //move on to second part
    else if (trialIndex > 0)
      trialIndex--; //move back one trial as penalty!
  }
  
  // bottom = 2
  // ay > 0
  else if (ay > tol) {
    if (target == 2)
      isTarget = false; //move on to second part
    else if (trialIndex > 0)
      trialIndex--; //move back one trial as penalty!
  }
  
  // left = 3
  // ax > 0
  else if (ax > tol) {
    if (target == 3)
      isTarget = false; //move on to second part
    else if (trialIndex > 0)
      trialIndex--; //move back one trial as penalty!
  }
}

boolean inRect(int x, int y, int w, int h) {
  return cursorX > x && cursorX < x + w && cursorY > y && cursorY < y + h;
}

color col0 = color(0,255,0); // for now, green
color col1 = color(255,0,0); // for now, red
void drawTwo() {
  int index = trialIndex;
  int action = targets.get(index).action;
  
  // fill the background of the screen with the target color
  if (action == 0) {
    fill(col0);
    rect(0, 0, 2*width, 2*height);
  }
  else {
    fill(col1);
    rect(0, 0, 2*width, 2*height);
  }
  
  //checkColor(avgCol, action);
  
}

void checkColor() {
  int index = trialIndex;
  int action = targets.get(index).action;
  
  // don't show the text until we actually hit this part of the trial
  textFont(createFont("Arial", 30));
  fill(0);
  if (action == 0) {
    text("show me GREEN", width/2, 100);
  }
  else {
    text("show me RED", width/2, 100);
  }
  
  // once we hit this part of the trial, display a box in the middle of the screen that has the current average color in it
  rectMode(CENTER);
  color col = getAvgColor();
  fill(col);
  rect(width/2, height/2, 200, 200);
  rectMode(CORNER);
  
  textFont(createFont("Arial", 20));
  fill(255); //white
  println("current color = " + red(col) + ", " + green(col) + ", " + blue(col), width/2, 200);
  
  color target;
  color other;
  if (action == 0) {
    target = col0;
    other = col1;
  }
  else {
    target = col1;
    other = col0;
  }
  
  float tolerance = 130; // hmm....
  float dist_to_target = colorDist(col, target);
  float dist_to_other = colorDist(col, other);
  
  if (dist_to_target < tolerance) // advance trial
  {
    trialIndex++;
    isTarget = true;
  }
  else if (dist_to_other < tolerance) // go back a trial
  {
    if (trialIndex > 0) trialIndex--;
    isTarget = true;
  }
  
  textFont(createFont("Arial", 20));
  fill(0);
  println("dist to target = " + dist_to_target, width/2, 390);
  println("dist to other = " + dist_to_other, width/2, 410);
  
}

float colorDist(color c1, color c2) { // from wikipedia
  return sqrt(
    pow((red(c1) - red(c2)), 2) +
    pow((green(c1) - green(c2)), 2) +
    pow((blue(c1) - blue(c2)), 2)
  );
}

color getAvgColor() {
  if (cam.isStarted()) {
    int red_sum = 0;
    int green_sum = 0;
    int blue_sum = 0;
    int total = 0;
    
    // just sample some pixels in the center i guess
    for (int x = 310; x < 330; x++) {
      for (int y = 230; y < 250; y++) {
        color pixelColor = cam.get(x, y);
        red_sum += red(pixelColor);
        green_sum += green(pixelColor);
        blue_sum += blue(pixelColor);
        total++;
      }
    }
    
    int r = red_sum / total;
    int g = green_sum / total;
    int b = blue_sum / total;
    
    return color(r,g,b);
  }
  
  return color(0,0,0);
}



void draw() {
  int index = trialIndex;

  //uncomment line below to see if sensors are updating
  //println("light val: " + light +", cursor accel vals: " + cursorX +"/" + cursorY);
  background(80); //background is light grey
  noStroke(); //no stroke

  if (startTime == 0)
    startTime = millis();

  if (index>=targets.size() && !userDone)
  {
    userDone=true;
    finishTime = millis();
  }

  if (userDone)
  {
    text("User completed " + trialCount + " trials", width/2, 50);
    text("User took " + nfc((finishTime-startTime)/1000f/trialCount, 1) + " sec per target", width/2, 150);
    return;
  }

  drawTwo();
  if (isTarget) drawFour();
  else checkColor();
  
  textFont(createFont("Arial", 20));
  fill(180);
  text("Trial " + (index+1) + " of " + trialCount, width/2, 50);
}

float ax = 0;
float ay = 0;
float az = 0;
void onAccelerometerEvent(float x, float y, float z)
{
  
  ax = x;
  ay = y;
  az = z;
  int index = trialIndex;

  if (userDone || index>=targets.size())
    return;
  
  if (!isTarget) return;

  cursorX = (width/2)+x*30; //cented to window and scaled
  cursorY = (height/2)+y*30; //cented to window and scaled

}

void onCameraPreviewEvent() {
   cam.read();
}
