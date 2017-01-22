#include <fstream>
#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){  
    orientation[0] = 0.0f;
    orientation[1] = 0.0f;
    orientation[2] = 0.0f;
    
    ifstream fin;
    fin.open( ofToDataPath("ip.txt").c_str());
    string ip;
    getline(fin, ip);
    
    client.setMessageDelimiter(" ");
    connectionSuccess = client.setup(ip, 7871);
    shader.load("shaders/shader");

}

//--------------------------------------------------------------
void ofApp::update(){
    if (connectionSuccess){
        if (client.isConnected()){
            string str = client.receiveRaw();
            if (str.size()) {
                str = ofSplitString(str, ">")[1];
                string pitch = ofSplitString(str, ",")[0];
                string roll = ofSplitString(str, ",")[1];
                orientation[0] = ofToFloat(pitch);
                orientation[1] = ofToFloat(roll);
            }
            client.send("CONTINUE");
        }
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofSetColor(255);
    shader.begin();
    shader.setUniform1f("Time", ofGetElapsedTimef());
    shader.setUniform1f("Pitch", orientation[0]);
    shader.setUniform1f("Roll", orientation[1]);
    ofDrawRectangle(0, 0, ofGetWidth(), ofGetHeight());
    shader.end();
}

//--------------------------------------------------------------
void ofApp::exit(){
    ofLog(OF_LOG_NOTICE, "Bye");
    
    if (connectionSuccess){
        if (client.isConnected()){
            client.send("FINISHED");
            client.close();
        }
    }
}
