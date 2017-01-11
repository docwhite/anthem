#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    orientation[0] = 0.0f;
    orientation[1] = 0.0f;
    orientation[2] = 0.0f;
    
    client.setMessageDelimiter(" ");
    connectionSuccess = client.setup("192.168.43.167", 7871);
    
    
#ifdef TARGET_OPENGLES
    shader.load("shaders_gles/shader");
#else
    if(ofIsGLProgrammableRenderer()){
        shader.load("shaders_gl3/shader");
    }else{
        shader.load("shaders/shader");
    }
#endif

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
void ofApp::keyPressed(int key){

}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y ){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){
    line.clear();

}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mouseEntered(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseExited(int x, int y){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

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
