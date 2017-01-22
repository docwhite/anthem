#pragma once

#include "ofMain.h"
#include "ofxTCPClient.h"

class ofApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();
        void exit();
    
        ofShader shader;
        ofxTCPClient client;
        bool connectionSuccess;
        float orientation[3];
		
};
