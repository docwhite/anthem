import processing.core.*;
import processing.net.*;
import processing.opengl.*;
import themidibus.*;
import twitter4j.*;
import twitter4j.conf.*;
import java.util.*;

PImage img;     // Image that will act as a texture to the fractal shader
PShader world;  // Shader files under data/
MidiBus my_bus; // MIDI control

int start_time, current_time;
int w = 640, h = 480;
boolean recording = false;

// Default shader uniforms
float[] offset   = {-0.07821107f, 0.02234602f};
float zoom = 0.01f;
float color_power = 4.39f;
float color_mult  = 2.549f;

// Database
String default_image_url = "https://pbs.twimg.com/profile_images/795621490553196544/Y37sDRrt.jpg";
String db_path = "./data/database.json";
processing.data.JSONArray db;

// New tweets will populate it and update the index to latest.
ArrayList<PImage> pool;
int picture_idx;

boolean useServer = true;   // If no server orientaiton won't work
  String[] orientation = {"1.08", "1.1023157", "0.0"}; // Placeholder
  String raspberryPi = "192.168.0.43";  // Raspberry Pi IP
  int portNo  = 7871;                   // Socket port
  Client myClient;                      // To connect to Raspberry Pi socket
  String dataIn;                        // Data from web socket
  boolean firstTime = true;             // For initialization

TwitterStream twitter;
String body;

// Twitter listener will perform actions on received status updates
StatusListener listener = new StatusListener() {
  public void onStatus(Status status) {
    body = status.getText();
    println(status.getUser().getName() + ": " + body);
    if (body.startsWith("#VJNCCA")) {
      try {
        // Try to save the tweet to the JSON database file
        println("Saving tweet to database at " + db_path);
        processing.data.JSONObject tweet = new processing.data.JSONObject();
        tweet.setString("body", status.getText());
        tweet.setString("image", status.getUser().getOriginalProfileImageURL());
        tweet.setString("user", status.getUser().getName());
        tweet.setInt("rating", Integer.parseInt(status.getText().substring(8, 9)));
        db.append(tweet);
        saveJSONArray(db, db_path);
        println("Appending new object parsing the rating from the tweet.");

        // Process the user avatar
        PImage img = loadImage(tweet.getString("image"));
        pool.add(img);
        picture_idx = pool.size() - 1;
      } catch (Exception e) {
        println("Tweet could not be parsed: " + body);
      }
    }
  }

  public void onDeletionNotice(StatusDeletionNotice statusDeletionNotice) {
    System.out.println("Got a status deletion notice id:" + statusDeletionNotice.getStatusId());
  }

  public void onTrackLimitationNotice(int numberOfLimitedStatuses) {
    System.out.println("Got track limitation notice:" + numberOfLimitedStatuses);
  }

  public void onScrubGeo(long userId, long upToStatusId) {
    System.out.println("Got scrub_geo event userId:" + userId + " upToStatusId:" + upToStatusId);
  }

  public void onException(Exception ex) {
    ex.printStackTrace();
  }

  public void onStallWarning(StallWarning warning) {
    System.out.println("Got stall warning:" + warning);
  }
}; // listener

void setupTwitter() {
  ConfigurationBuilder builder = new ConfigurationBuilder();
  builder.setOAuthConsumerKey("ZlE3paY5xEwKL1OO4KeuwADuK");
  builder.setOAuthConsumerSecret("DuK8wbAYfkKmvHPIFdUCbeB1cweI1WzBl3g50DzdFxbVo4TvPR");
  builder.setOAuthAccessToken("165466009-jAUeaWEqQzSSJOiODqyu7xZAkMMOQR0jz1CUFS1D");
  builder.setOAuthAccessTokenSecret("EpB28xxBi7LMbExN50idjyUiqeQInrih8GEjsYPPfS9eL");

  Configuration configuration = builder.build();
  TwitterStreamFactory factory = new TwitterStreamFactory(configuration);

  twitter = factory.getInstance();
  twitter.addListener(listener);

  FilterQuery tweetFilterQuery = new FilterQuery();
  tweetFilterQuery.track(new String[]{"#VJNCCA"});

  twitter.filter(tweetFilterQuery);
} // setupTwitter

void loadTweetsFromDatabase() {
  int array_size = db.size();
  println("array_size: " + array_size);
  for (int i = 0; i < array_size; i++) {
      processing.data.JSONObject current = db.getJSONObject(i);
      PImage img =  loadImage(current.getString("image"));
      img.resize(w, h);
      pool.add(img);
  }
} // loadTweetsFromDatabase

void exit()
{
  if (useServer) {
    myClient.write("FINISHED");
  }
  super.exit();
} // exit

void controllerChange(int channel, int number, int value) {
  if (number == 0) {
    zoom = map(value, 0.0, 127.0, 0.01, 1.0);
    world.set("Zoom", zoom);
  }
  if (number == 1) {
    offset[0] = map(value, 0, 127, 0.8, -0.8); 
    world.set("Offset", offset[0], offset[1]);
  }
  if (number == 2) {
    offset[1] = map(value, 0, 127, 0.8, -0.8);;
    world.set("Offset", offset[0], offset[1]);
  }
  if (number == 5 && !useServer) {
    orientation[0] = String.valueOf(map(value, 0, 127, 0, 2 * TWO_PI));  
  }
  if (number == 6 && !useServer) {
    orientation[1] = String.valueOf(map(value, 0, 127, 0, 2 * TWO_PI));  
  }
  if (number == 7 && !useServer) {
    orientation[2] = String.valueOf(map(value, 0, 127, 0, 2 * TWO_PI));  
  }
  if (number == 16) {
    color_power = map(value, 0, 127, 0.25, 7.0);;
    world.set("ColorPower", color_power);
  }
  if (number == 17) {
    color_mult = map(value, 0, 127, 0.25, 6.0);
    world.set("ColorMult", color_mult);
  }

  if (number == 45) { // Record circle
    if (value == 127) {
      recording = true;
    } else {
      recording = false;
    }
  }
} // controllerChange

// ==============================SETUP==========================================
void setup() {
  size(640, 480, P3D);
  orientation[0] = "0.0"; // Pitch
  orientation[1] = "0.0"; // Yaw
  orientation[2] = "0.0"; // Roll

  start_time = millis();
  current_time = start_time;
  
  MidiBus.list();
  my_bus = new MidiBus(this, "SLIDER/KNOB", "");
  
  // Start a connection with the Python web socket on the Raspberry Pi
  if (useServer && firstTime) {
    myClient = new Client(this, raspberryPi, portNo );
    myClient.write("INITIALIZING");
    firstTime = false;
  }

  try {
    db = loadJSONArray(db_path);
  } catch(Exception e) {
    println("Creating new JSON object array under " + db_path);
    db = new processing.data.JSONArray();
    saveJSONArray(db, db_path);
  }
    
  setupTwitter();

  picture_idx = 0;
  pool = new ArrayList<PImage>();

  loadTweetsFromDatabase();
    
  world = loadShader("WorldFrag.glsl", "WorldVert.glsl");
  world.set("Time",  (float) 0);
  world.set("Pitch", (float) 1.08);
  world.set("Roll",  (float) 0.0);
  world.set("Yaw",   (float) 1.1023157);
  world.set("Offset", offset[0], offset[1]);
  world.set("Zoom", (float) 0.972067);
  world.set("ColorPower", (float) color_power);
  world.set("ColorMult", (float) color_mult); 
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

  if (pool.size() > 0) {
    img = pool.get(picture_idx);
  } else {
    img = loadImage(default_image_url);
  }

  // World full screen quad
  beginShape(QUADS);
  noStroke();
  texture(img);
  vertex(0, h, 0 ,h);
  vertex(w, h, w, h);
  vertex(w, 0, w, 0);
  vertex(0, 0, 0, 0);
  endShape();

  if (recording) {
    saveFrame("./sequence/fractal.######.png");
  }
}