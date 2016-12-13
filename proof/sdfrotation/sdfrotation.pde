import processing.core.*;
import processing.net.*;
import processing.opengl.*;
import themidibus.*;

PImage img;     // Image that will act as a texture to the fractal shader
PShader world;  // Shader files under data/

int start_time, current_time;
int w = 640, h = 480;

// Default shader uniforms
// TODO


// Raspberry Pi Web Socket configuration
boolean useServer = true;   // If no server orientaiton won't work
  String[] orientation = {"0.0", "0.0", "0.0"}; // Placeholder
  String raspberryPi = "192.168.0.43";  // Raspberry Pi IP
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


// ==============================SETUP==========================================
void setup() {
  size(640, 480, P3D);
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
    
  world = loadShader("WorldFrag.glsl", "WorldVert.glsl");
  world.set("Time",  (float) 0);
  world.set("Resolution", (float) w, (float) h);
    
  frameRate(20);
}

// ===============================DRAW==========================================
void draw(){  
  shader(world);
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
  world.set("Yaw",   Float.parseFloat(orientation[2]));

  current_time = millis();

  // World full screen quad
  beginShape(QUADS);
  noStroke();
  vertex(0, h, 0 ,h);
  vertex(w, h, w, h);
  vertex(w, 0, w, 0);
  vertex(0, 0, 0, 0);
  endShape();
}