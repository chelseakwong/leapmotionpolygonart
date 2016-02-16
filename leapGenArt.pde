import java.util.Map;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

import com.leapmotion.leap.Controller;
import com.leapmotion.leap.Gesture;
import com.leapmotion.leap.Finger;
import com.leapmotion.leap.Frame;
import com.leapmotion.leap.Hand;
import com.leapmotion.leap.HandList;
import com.leapmotion.leap.Tool;
import com.leapmotion.leap.Vector;
import com.leapmotion.leap.processing.LeapMotion;
import com.leapmotion.leap.KeyTapGesture;

import static javax.swing.JOptionPane.*;

import java.util.Date;
import java.text.DateFormat;

import java.util.Timer;
import java.util.TimerTask;

LeapMotion leapMotion;

ConcurrentMap<Integer, Integer> fingerColors;
ConcurrentMap<Integer, Integer> toolColors;
ConcurrentMap<Integer, Vector> fingerPositions;
ConcurrentMap<Integer, Vector> toolPositions;

CopyOnWriteArrayList<major> allMajors = new CopyOnWriteArrayList<major>();

int time;
int wait = 3000; //how much time per major generation

float angle;

boolean rotateOn;
float globalZLevel;


class vertex {
  float x;
  float y;
  float z;
  float radius;
  color c;
  float driftX;
  float driftY;
  float driftZ;
  float driftSpeed;

  Timer stopTimer;

  boolean reachedDest;

  void draw() {     
    fill(c);
    //lights();
    pushMatrix();
    translate(x, y, z);
    noStroke();
    sphere(radius); 
    popMatrix();
  }

  void update() {
    //reached dest, stop
    if (reachedDest) {
      z -= driftSpeed;
      return;
    }

    //update according to final destination
    if ((driftX > 0)&&(x!=driftX)) x += driftSpeed;
    else if ((driftX < 0)&&(x!=driftX)) x -= driftSpeed;

    if ((driftY>0)&&(y!=driftY)) y += driftSpeed;
    else if ((driftY < 0)&&(y!=driftY)) y -= driftSpeed;
    
    if ((driftZ>0)&&(z!=driftZ)) z += driftSpeed;
    else if ((driftZ < 0)&&(z!=driftZ)) z -= driftSpeed;
  }

  public void scheduleStop() {
    stopTimer = new Timer();
    int stopTime = int(random(2, 5));
    reachedDest = false;
    stopTimer.schedule(new stopping(), stopTime*1000);
  }

  class stopping extends TimerTask {
    public void run() {
      reachedDest = true;
      stopTimer.cancel();
    }
  }
}

//majors
class major extends vertex {
  CopyOnWriteArrayList<minor> minors;
  //timer to add minors
  Timer timer;  
  boolean minorsDone;
  boolean minorsReleased;

  public major() {
    radius = 15.0;
    minorsDone = false;
    minors = new CopyOnWriteArrayList<minor>();
    //drift final positions should be range(-30,30)
    driftX = int(random(-30, 30));
    driftY = int(random(-30, 30));
    driftZ = -1;
    driftSpeed = 1.6;
    c = color(255,255,255); //majors are pink
    //scheduleMinors();
    scheduleStop();
  }

  void update() {
    if (!reachedDest) {
      super.update();
    }
  }

  void updateMinors() {
    minorsDone = true;
    for (minor m : minors) {
      if (!m.reachedDest) {
        m.draw();
        m.update();
        minorsDone &= m.reachedDest;
      }
    }
  }

  void draw() {
    super.draw();
  }

  public void releaseMinors() {
    int numMinors = int(random(3, 8));
    for (int i = 0; i < numMinors; i++) {
      minor newMinor = new minor();
      newMinor.x = x;
      newMinor.y = y;
      newMinor.z = z;
      minors.add(newMinor);
    }
    minorsReleased = true;
  }
}

//minors
class minor extends vertex {
  public minor() {
    radius = 5.0;
    //drift final positions in range (-15,15)
    driftX = random(-2, 2);
    driftY = random(-2, 2);
    driftZ = random(-2, 2);
    driftSpeed = random(0.2, 4);
    scheduleStop();
  }

  void update() {
    super.update();
  }
}



void addMajor(float x, float y, float z) {
  major V = new major();
  V.x = x; 
  V.y = y;
  V.z = z;

  allMajors.add(V);
}

void setup()
{
  size(1000, 860, P3D);
  rotateOn = false;
  globalZLevel = 1;
  
  background(20);
  frameRate(60);
  //ellipseMode(CENTER);
  time = millis(); //store current time

  leapMotion = new LeapMotion(this);
  fingerColors = new ConcurrentHashMap<Integer, Integer>();
  toolColors = new ConcurrentHashMap<Integer, Integer>();
  fingerPositions = new ConcurrentHashMap<Integer, Vector>();
  toolPositions = new ConcurrentHashMap<Integer, Vector>();
}

void draw() {
  background(220);
  //hint(ENABLE_DEPTH_SORT);
  //blendMode(ADD);
  pointLight(51, 102, 255, 65, 60, 100);
  pointLight(200, 40, 60, -65, -60, -150);
  //rotateY(map(mouseX,0,width,-PI,PI));
  //rotateX(map(mouseY,0,height,-PI,PI)); 
  
  //translate(0,0, -globalZLevel *50);
  camera(width/2.0, height/2.0, mouseY*12, 
         width/2.0, height/2.0, 0.0, 
         0.0, 1.0, 0.0);
  
  globalZLevel += 0.01;
  
  if (rotateOn){
    // Rotate around y and x axes
    //translate(width/2, height/2, -600 + mouseX*0.65);
    rotateY(radians(angle));
    rotateX(radians(angle));
    // Used in rotate function calls above
    angle += 0.2;
  }

  ambientLight(70,70,10);
  
  /* draw the actual fingers */
  for (Map.Entry entry : fingerPositions.entrySet()) {
   Integer fingerId = (Integer) entry.getKey();
   Vector position = (Vector) entry.getValue();
   lights();
   pushMatrix();
   float x = position.getX();
   float y = position.getY();
   float z = position.getZ();
   //fill(fingerColors.get(fingerId));
   translate(leapMotion.leapToScreenX(x,y,z), 
     leapMotion.leapToScreenY(x,y,z), 
     0);
     
   sphere(10); 
   popMatrix();
  }
  if (millis()-time >= wait) {
    time = millis();
  }

  for (major v : allMajors) {
    v.draw();
    if (!v.reachedDest){
      v.update();
    }

    else {
      v.z -= v.driftSpeed;
      if (!v.minorsReleased) {
        v.releaseMinors();
      }

      if (!v.minorsDone) {
        v.updateMinors();
      }
      
      //remove this v from list. delete
      if (v.z < -4000){
        allMajors.remove(v);
      }
    }
  }

  drawShapes();
}

void drawShapes() {
  //connecting all majors
  stroke(180);
  strokeWeight(3);
  fill(23, 30);
  beginShape();
  //colorMode(RGB,255);

  for (major m : allMajors) {
    vertex(m.x, m.y, m.z);
  }
  endShape(CLOSE);

  //connect each minor to its major
  stroke(50);
  strokeWeight(2);
  noFill();
  for (major maj : allMajors) {
    beginShape();
    vertex(maj.x, maj.y, maj.z);
    for (minor min : maj.minors) {
      vertex(min.x, min.y, min.z);
    }
    endShape(CLOSE);
  }
}

void onInit(final Controller controller)
{
  controller.enableGesture(Gesture.Type.TYPE_CIRCLE);
  controller.enableGesture(Gesture.Type.TYPE_KEY_TAP);
  controller.enableGesture(Gesture.Type.TYPE_SCREEN_TAP);
  controller.enableGesture(Gesture.Type.TYPE_SWIPE);
  // enable background policy
  controller.setPolicyFlags(Controller.PolicyFlag.POLICY_BACKGROUND_FRAMES);
}

void keyPressed(){
  if (key == 'r') {
    rotateOn = !rotateOn;
  }
}

void onFrame(final Controller controller)
{
  Frame frame = controller.frame();
  fingerPositions.clear();
  for (Finger finger : frame.fingers())
  {
    int fingerId = finger.id();
    color c = color(random(0, 255), random(0, 255), random(0, 255));
    fingerColors.putIfAbsent(fingerId, c);
    fingerPositions.put(fingerId, finger.tipPosition());
  }
  for (Tool tool : frame.tools())
  {
    int toolId = tool.id();
    color c = color(random(0, 255), random(0, 255), random(0, 255));
    toolColors.putIfAbsent(toolId, c);
    toolPositions.put(toolId, tool.tipPosition());
  }
  for (Gesture gesture : frame.gestures()) {
    if ("TYPE_SCREEN_TAP".equals(gesture.type().toString()) && "STATE_STOP".equals(gesture.state().toString())) {
      println("screen tapped");
    } else if ("TYPE_KEY_TAP".equals(gesture.type().toString()) && "STATE_STOP".equals(gesture.state().toString())) {
      println("key tap");
      if (gesture.type() == KeyTapGesture.classType()) {
        KeyTapGesture keytapGesture = new KeyTapGesture(gesture);
        Vector position = keytapGesture.position();  
        float x = position.getX();
        float y = position.getY();
        float z = position.getZ();
        float inX = leapMotion.leapToSketchX(x);
        float inY = leapMotion.leapToSketchY(y);
        addMajor(inX, inY, 0);
        globalZLevel += 0.5;
        //showMessageDialog(null, "inX ="+inX+" inY= "+inY, 
        //"Alert", ERROR_MESSAGE);
      }
    }
  }
}