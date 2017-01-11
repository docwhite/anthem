import processing.core.*;
import processing.net.*;
import processing.opengl.*;
import themidibus.*;
import codeanticode.syphon.*;

SyphonServer sserver;
PGraphics canvas;

PImage img;     // Image that will act as a texture to the fractal shader
PShader world;  // Shader files under data/

int start_time, current_time;
int w = 640, h = 480;

// Default shader uniforms
// TODO


// Raspberry Pi Web Socket configuration
boolean useServer = true;   // If no server orientaiton won't work
  String[] orientation = {"0.0", "0.0", "0.0"}; // Placeholder
  String raspberryPi = "192.168.1.168";  // Raspberry Pi IP
  int portNo  = 7871;                   // Socket port
  Client myClient;                      // To connect to Raspberry Pi socket
  String dataIn;                        // Data from web socket
  boolean firstTime = true;             // For initialization


void exit()
{
  if (useServer) {
    myClient.write("FINISHED");
  }
  super.exit();
} // exit


void settings() {
  size(640, 480, P3D);
  PJOGL.profile=1;
}

// ==============================SETUP==========================================
void setup() {
  canvas = createGraphics(640, 480, P3D);
  sserver = new SyphonServer(this, "SDF Rotation");
  orientation[0] = "0.0"; // Pitch
  orientation[1] = "0.0"; // Yaw
  orientation[2] = "0.0"; // Roll

  start_time = millis();
  current_time = start_time;
  
  // Start a connection with the Python web socket on the Raspberry Pi
  if (useServer && firstTime) {
    myClient = new Client(this, raspberryPi, portNo );
    myClient.write("INITIALIZING");
    firstTime = false;
  }
    
  world = canvas.loadShader("WorldFrag.glsl", "WorldVert.glsl");
  world.set("Time",  (float) 0);
  world.set("Resolution", (float) w, (float) h);
    
  frameRate(20);
}

// ===============================DRAW==========================================
void draw(){  
  canvas.shader(world);
  world.set("Time", (float)((current_time - start_time)/1000.0));
  
  if (useServer) {
    if (myClient.available() > 0) {
      dataIn = myClient.readString();
      orientation = dataIn.split(">")[1].split(",");
    }
    
    myClient.write("CONTINUE");
  }

  world.set("Pitch", Float.parseFloat(orientation[0]));
  world.set("Roll",  Float.parseFloat(orientation[1]));

  current_time = millis();

  // World full screen quad
  canvas.beginDraw();
  canvas.beginShape(QUADS);
  canvas.noStroke();
  canvas.vertex(0, h, 0 ,h);
  canvas.vertex(w, h, w, h);
  canvas.vertex(w, 0, w, 0);
  canvas.vertex(0, 0, 0, 0);
  canvas.endShape();
  canvas.endDraw();

  image(canvas, 0, 0);

  sserver.sendImage(canvas);
  
}