import java.util.ArrayList;
import java.util.Collections;
import ketai.sensors.*;

KetaiSensor sensor;

float cursorX, cursorY;
float light = 0; 
float proxSensorThreshold = 20; //you will need to change this per your device.

private class Target
{
  int target = 0;
  int action = 0;
}

int trialCount = 5; //this will be set higher for the bakeoff
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
  //println("is orientation available: " + sensor.isOrientationAvailable());
  //println("is gyroscope available: " + sensor.isGyroscopeAvailable());
  //println("is rotation vector available: " + sensor.isRotationVectorAvailable());
  //println("is mag field available: " + sensor.isMagenticFieldAvailable());
  //println("is game rotation available: " + sensor.isGameRotationAvailable());
  sensor.start();
  orientation(LANDSCAPE);

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
  if (target == 0) fill(0,255,0);
  else fill(180);
  rect(0,10,2*width,20);
  
  // right
  if (target == 1) fill(0,255,0);
  else fill(180);
  rect(width - 10,0,20,2*height);
  
  // bottom
  if (target == 2) fill(0,255,0);
  else fill(180);
  rect(0,height - 10,2*width,20);
  
  // left
  if (target == 3) fill(0,255,0);
  else fill(180);
  rect(10,0,20,2*height);
  
  textFont(createFont("Arial", 30));
  fill(255); //white
  text("Trial " + (index+1) + " of " + trialCount, width/2, 100);
  
  fill(255, 0, 0);
  ellipse(cursorX, cursorY, 50, 50);
  
  checkFour();
}

void checkFour() {
  int index = trialIndex;
  int target = targets.get(index).target;
  
  // top = 0
  if (inRect(0,10,2*width,20)) {
    if (target == 0)
      isTarget = false; //move on to second part
    else if (trialIndex > 0)
      trialIndex--; //move back one trial as penalty!
  }
  // right = 1
  else if (inRect(width - 10,0,20,2*height)) {
    if (target == 1)
      isTarget = false; //move on to second part
    else if (trialIndex > 0)
      trialIndex--; //move back one trial as penalty!
  }
  // bottom = 2
  else if (inRect(0,height - 10,2*width,20)) {
    if (target == 2)
      isTarget = false; //move on to second part
    else if (trialIndex > 0)
      trialIndex--; //move back one trial as penalty!
  }
  // left = 3
  else if (inRect(10,0,20,2*height)) {
    if (target == 3)
      isTarget = false; //move on to second part
    else if (trialIndex > 0)
      trialIndex--; //move back one trial as penalty!
  }
}

boolean inRect(int x, int y, int w, int h) {
  return cursorX > x && cursorX < x + w && cursorY > y && cursorY < y + h;
}

void drawTwo() {
  int index = trialIndex;
  int action = targets.get(index).action;
  
  fill(0);
  rect(0, 0, 2*width, 2*height);
  
  textFont(createFont("Arial", 30));
  fill(255); //white
  text("Trial " + (index+1) + " of " + trialCount, width/2, 100);
  text("Action " + action, width/2, 140);
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

  if (isTarget) drawFour();
  else drawTwo();

  //for (int i=0; i<4; i++)
  //{
  //  if (targets.get(index).target==i)
  //    fill(0, 255, 0);
  //  else
  //    fill(180, 180, 180);
  //  ellipse(300, i*150+100, 100, 100);
  //}

  //if (light>proxSensorThreshold)
  //  fill(180, 0, 0);
  //else
  //  fill(255, 0, 0);
  //ellipse(cursorX, cursorY, 50, 50);

  //fill(255);//white
  //text("Trial " + (index+1) + " of " +trialCount, width/2, 50);
  //text("Target #" + (targets.get(index).target)+1, width/2, 100);

  //if (targets.get(index).action==0)
  //  text("UP", width/2, 150);
  //else
  //  text("DOWN", width/2, 150);
}

void onAccelerometerEvent(float x, float y, float z)
{
  int index = trialIndex;

  if (userDone || index>=targets.size())
    return;

  cursorX = (width/2)+y*30; //cented to window and scaled
  cursorY = (height/2)+x*30; //cented to window and scaled

  Target t = targets.get(index);
  if (t==null)
    return;
}



void onLightEvent(float v) //this just updates the light value
{
  light = v;
}
