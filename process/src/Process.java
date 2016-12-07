import processing.core.*;
import processing.net.*;
import processing.opengl.*;
import themidibus.*;
import twitter4j.*;
import twitter4j.conf.*;
import java.util.*;


public class Process extends PApplet{
	// Full screen quad shader
	PShader world;

	// For intercepting MIDI
	MidiBus myBus;
	
	// Timer in milliseconds
	long startTime;
	long currentTime;
	
	// Screen dimensions
	int w = 450;
	int h = 450;
	
	// Uniforms
	float[] Offset = {-0.07821107f, 0.02234602f};
	float ColorPower = 4.39f;
	float ColorMult = 2.549f;
	
	// Database
	String dbPath = "database.json";
	processing.data.JSONArray db;
	
	// Scene
	ArrayList<PImage> pool;
	int pictureIdx;

	boolean useServer = true;                // If no server pitch yaw and roll will be 0
		Client myClient;                      // To connect to Raspberry Pi socket
		String dataIn;                        // Data from web socket
		String[] orientation = new String[3]; // Orientation data will be placed here
		String raspberryPi = "192.168.0.43";  // Address of Raspberry Pi
		int portNo  = 7871;                   // Socket port
		boolean firstTime = true;             // For initialization purposes
		
	StatusListener listener = new StatusListener() {
	    public void onStatus(Status status) {
	        body = status.getText();
	        System.out.println(status.getUser().getName() + " : " + body);
	        if (body.startsWith("#SonarPivis")) {
	            try {
	                println("Saving tweet to database at " + dbPath);
	                processing.data.JSONObject tweet = new processing.data.JSONObject();
	                tweet.setString("body", status.getText());
	                tweet.setString("image", status.getUser().getOriginalProfileImageURL());
	                tweet.setString("user", status.getUser().getName());
	                tweet.setInt("rating", Integer.parseInt(status.getText().substring(12, 13)));
	                db.append(tweet);
	                saveJSONArray(db, dbPath);

	                println("Appending new object parsing the rating from the tweet.");
	                PImage img = loadImage(tweet.getString("image"));
	                pool.add(img);
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
	};

	TwitterStream twitter;
	String body;

    public static void main(String[] args) {
        PApplet.main("Process"); // Initialize PApplet
    }

    public void settings(){
    	orientation[0] = "0.0"; // Pitch
    	orientation[1] = "0.0"; // Yaw
    	orientation[2] = "0.0"; // Roll
        size(w,h, P3D);     // Window
    }

    public void setup(){
    	startTime = System.currentTimeMillis();
    	currentTime = startTime;
    	
    	// Setup MIDI
    	MidiBus.list();
    	myBus = new MidiBus(this, 1, 0);
    	
    	// Start a connection with the web socket
    	if (useServer && firstTime) {
            myClient = new Client(this, raspberryPi, portNo );
            myClient.write("INITIALIZING");
            firstTime = false;
        }
    	
    	// Setup DB
        try {
            db = loadJSONArray(dbPath);
        } catch(Exception e) {
            println("creating new JSON object array under " + dbPath);
            db = new processing.data.JSONArray();
            saveJSONArray(db, dbPath);
        }
        
        // Setup Twitter
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
        tweetFilterQuery.track(new String[]{"#SonarPivis"});

        twitter.filter(tweetFilterQuery);
    	
        // Scene setup
        pictureIdx = 0;
        pool = new ArrayList<PImage>();
        loadTweetsFromDatabase();
        
        // Shader
    	world = loadShader("WorldFrag.glsl", "WorldVert.glsl");
    	world.set("Time",  (float) 0);
    	world.set("Pitch", (float) 1.08);
    	world.set("Roll",  (float) 0.0);
    	world.set("Yaw",   (float) 1.1023157);
    	world.set("ImgResolution", (float) 512.0, (float) 512.0);
    	world.set("Offset", Offset[0], Offset[1]);
    	world.set("Zoom", (float) 0.972067);
    	world.set("ColorPower", (float) ColorPower);
    	world.set("ColorMult", (float) ColorMult); 
    	world.set("Resolution", (float) w, (float) h);
        
    	

    	
    	
    	
    	// It's better to fix a frame rate for the Time uniform to be consistent
    	frameRate(24);
    }
    
    public void loadTweetsFromDatabase() {
	    int array_size = db.size();
	    println("array_size: " + array_size);
	    for (int i = 0; i < array_size; i++) {
	        processing.data.JSONObject current = db.getJSONObject(i);
	        PImage img =  loadImage(current.getString("image"));
	        img.resize(w, h);
	        pool.add(img);
	    }
    }

    public void draw(){
    	// Draw the image
    	image(pool.get(pictureIdx), 0, 0, w, h);
    	
        // Bind the shader and set uniforms
    	shader(world);
    	world.set("Time", (float)((currentTime - startTime)/1000.0));
    	
    	if (useServer && frameCount % 3 != 0) {
    		if (myClient.available() > 0) {
    			dataIn = myClient.readString();
        		orientation = dataIn.split(">")[1].split(",");
             	world.set("Pitch", Float.parseFloat(orientation[0]));
            	world.set("Roll",  Float.parseFloat(orientation[1]));
            	world.set("Yaw",   Float.parseFloat(orientation[2]));
    		}
    		
    		myClient.write("CONTINUE");

    	}

        currentTime = System.currentTimeMillis();

    	// World full screen quad
        beginShape(QUADS);
        noStroke();
        texture(pool.get(0));
        vertex(0, h, 0 ,h);
        vertex(w, h, w, h);
        vertex(w, 0, w, 0);
        vertex(0, 0, 0, 0);
        endShape();
    }
    
    public void exit()
    {
    	if (useServer) {
    		myClient.write("FINISHED");
    		super.exit();
    	}
    }
    
    public void controllerChange(int channel, int number, int value) {
    	if (number == 0) {
    		float t = (float) value / (float) 127.0;
    		float result = 0.01f*t + 1.1f * (1.0f-t); 
    		world.set("Zoom", result);
    	}
    	if (number == 1) {
    		float t = (float) value / (float) 127.0;
    		float result = 0.8f*(1.0f-t) + t*(-0.8f);
    		Offset[0] = result;
    		world.set("Offset", Offset[0], Offset[1]);
    	}
    	if (number == 2) {
    		float t = (float) value / (float) 127.0;
    		float result = 0.8f*(1.0f-t) + t*(-0.8f);
    		Offset[1] = result;
    		world.set("Offset", Offset[0], Offset[1]);
    	}
    	if (number == 3) {
    		float t = (float) value / (float) 127.0;
    		float result = 0.25f*(1.0f-t) + t*(7.0f);
    		ColorPower = result;
    		world.set("ColorPower", ColorPower);
    	}
    	if (number == 4) {
    		float t = (float) value / (float) 127.0;
    		float result = 0.25f*(1.0f-t) + t*(6.0f);
    		ColorMult = result;
    		world.set("ColorMult", ColorMult);
    	}
    }

}