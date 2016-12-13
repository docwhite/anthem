import math
import socket
import sys

from sense_hat import SenseHat

# Minimum luminosity value
min_light = 51.0

# Instance of the Pi Sense Hat
sense = SenseHat()

# For the messages on LED panel
scroll_speed = 0.05

# Create the socket
server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

# Address and port where raspberry pi serves
address = ('192.168.0.43', 7871)

# Bind to device
server_socket.bind(address)

# Listen up to 5 connections
server_socket.listen(5)

# Accepts a connection and returns connection and address
def establish_connection():
    sense.show_message("Listening", scroll_speed=scroll_speed)
    conn, address = server_socket.accept()
    sense.show_message("Connected", scroll_speed=scroll_speed)
    return conn, address

# Needed for the first time
conn, address = establish_connection()

while True:
    # If client finished connection we listen for a new one
    if conn.recv(2048) == "FINISHED":
        sense.show_message("Disconnecting", scroll_speed=scroll_speed)
        conn.close()
        conn, address = establish_connection()

    else:
        # Get orientation in radians
        orientation = sense.get_orientation_radians()
	
	
        # I paint on LED screen for visual debugging
        color = [
            int(min_light + (255.0 - min_light) * (0.5 + 0.5 * math.sin(float(orientation['pitch'])))),
            int(min_light + (255.0 - min_light) * (0.5 + 0.5 * math.cos(float(orientation['roll'])))),
            int(min_light + (255.0 - min_light) * (0.5 + 0.5 * math.cos(float(orientation['yaw'])))),
        ]
        sense.set_pixels([color for i in range(64)])
        conn.send(">{pitch},{roll},{yaw}".format(**orientation))

sense_hat.show_message("Bye!")
