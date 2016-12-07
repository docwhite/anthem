import processing.core.*;
import processing.net.*;
import processing.opengl.*;
import twitter4j.*;
import twitter4j.conf.*;
import java.util.*;


public class Process extends PApplet{
	PShader world; // Full screen quad shader
	
	// Screen dimensions
	int w = 640;
	int h = 468;
	
	// Database
	String dbPath = "database.json";
	processing.data.JSONArray db;
	
	// Scene
	ArrayList<PImage> pool;
	int pictureIdx;

	boolean useServer = false;                // If no server pitch yaw and roll will be 0
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
    	// Start a connection with the web socket
    	if (useServer && firstTime) {
            myClient = new Client(this, raspberryPi, portNo ); 
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
    	world.set("Pitch", (float) 0);
    	world.set("Roll",  (float) 0);
    	world.set("Yaw",   (float) 0);
    	world.set("Resolution", (float) w, (float) h);
        
    	// It's better to fix a frame rate for the Time uniform to be consistent
    	frameRate(30);
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
    	
    	// Parse data from socket message (as Strings)
        if (useServer) {
        	if (myClient.available() > 0) {
        		dataIn = myClient.readString();
        		orientation = dataIn.split(">")[1].split(",");        		
        	}
        }
    	
        // Bind the shader and set uniforms
    	shader(world);
    	world.set("Time", (float) frameCount / (float) frameRate);
    	world.set("Pitch", Float.parseFloat(orientation[0]));
    	world.set("Roll",  Float.parseFloat(orientation[1]));
    	world.set("Yaw",   Float.parseFloat(orientation[2]));
    	
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

}