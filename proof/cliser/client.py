import socket
import time


# On startup RPi shows the IP on the LED screen, it's the one to be used
raspberry_pi_address = "192.168.0.43"
raspberry_pi_port = 7871

# Establish connection
client_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
client_socket.connect((raspberry_pi_address, raspberry_pi_port))

while True:
    try:
        # Keep connection alive
        client_socket.send("CONTINUE")

        # Read rotation from raspberry pi
        result = client_socket.recv(2048)

        # Sanitize and parse it
        result = result.split('>')[1]
        pitch, yaw, roll = map(lambda x: float(x), result.split(','))
        
        print "pitch:\t{:10.4f}".format(pitch)
        print "yaw:\t{:10.4f}".format(yaw)
        print "roll:\t{:10.4f}".format(roll)

    except (KeyboardInterrupt, SystemExit):
        # If we kill the client we want to make sure the server is aware
        print "Ending connection"
        client_socket.send("FINISHED")
        client_socket.close()
        break
