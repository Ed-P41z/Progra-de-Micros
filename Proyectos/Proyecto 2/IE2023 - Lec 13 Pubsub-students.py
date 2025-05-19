# Import standard python modules.
import sys
import time
import serial

# This example uses the MQTTClient instead of the REST client
from Adafruit_IO import MQTTClient
from Adafruit_IO import Client, Feed

# holds the count for the feed
run_count = 0

# Set to your Adafruit IO username and key.
# Remember, your key is a secret,
# so make sure not to publish it when you publish this code!
ADAFRUIT_IO_USERNAME = "Ed_P41z"
ADAFRUIT_IO_KEY = ""

# Set to the ID of the feed to subscribe to for updates.
FEED_ID_servo1_TX = 'Servo1_TX'
FEED_ID_servo2_TX = 'Servo2_TX'
FEED_ID_servo3_TX = 'Servo3_TX'
FEED_ID_servo4_TX = 'Servo4_TX'
FEED_ID_servo1_RX = 'proyecto-2.servo-1rx'
FEED_ID_servo2_RX = 'proyecto-2.servo-2rx'
FEED_ID_servo3_RX = 'proyecto-2.servo-3rx'
FEED_ID_servo4_RX = 'proyecto-2.servo-4rx'
FEED_ID_EEPROM_TX = 'EEPROM_TX'
FEED_ID_Mode_TX   = 'Mode_TX'

# Define "callback" functions which will be called when certain events 
# happen (connected, disconnected, message arrived).
def connected(client):
    """Connected function will be called when the client is connected to
    Adafruit IO.This is a good place to subscribe to feed changes. The client
    parameter passed to this function is the Adafruit IO MQTT client so you
    can make calls against it easily.
    """
    # Subscribe to changes on a feed named Counter.
    print('Subscribing to Feeds... ')
    client.subscribe(FEED_ID_servo1_TX)
    client.subscribe(FEED_ID_servo2_TX)
    client.subscribe(FEED_ID_servo3_TX)
    client.subscribe(FEED_ID_servo4_TX)
    client.subscribe(FEED_ID_EEPROM_TX)
    client.subscribe(FEED_ID_Mode_TX)
    print('Waiting for feed data...')

def disconnected(client):
    """Disconnected function will be called when the client disconnects."""
    sys.exit(1)

def message(client, feed_id, payload):
    """Message function will be called when a subscribed feed has a new value.
    The feed_id parameter identifies the feed, and the payload parameter has
    the new value.
    """
    
    print('Feed {0} received new value: {1}'.format(feed_id, payload))
    # Publish or "send" message to corresponding feed    
    if feed_id == FEED_ID_servo1_TX:
        prefijo = 'S1:'
    elif feed_id == FEED_ID_servo2_TX:
        prefijo = 'S2:'
    elif feed_id == FEED_ID_servo3_TX:
        prefijo = 'S3:'
    elif feed_id == FEED_ID_servo4_TX:
        prefijo = 'S4:'
    elif feed_id == FEED_ID_EEPROM_TX:
        prefijo = 'EP:'
    elif feed_id == FEED_ID_Mode_TX:
        prefijo = 'MD:'
    else:
        return  # Si llega otro feed, ignorarlo
    miarduino.write(bytes(f"{prefijo}{payload}\n", 'utf-8'))
    print(f'Sending data back: {prefijo}{payload}')


miarduino = serial.Serial(port = 'COM3', baudrate=9600, timeout=0.1)

# Create an MQTT client instance.
client = MQTTClient(ADAFRUIT_IO_USERNAME, ADAFRUIT_IO_KEY)

# Setup the callback functions defined above.
client.on_connect = connected
client.on_disconnect = disconnected
client.on_message = message

# Connect to the Adafruit IO server.
client.connect()

# The first option is to run a thread in the background so you can continue
# doing things in your program.
client.loop_background()

mensaje = 1

while True:
    """ 
    # Uncomment the next 3 lines if you want to constantly send data
    # Adafruit IO is rate-limited for publishing
    # so we'll need a delay for calls to aio.send_data()
    run_count += 1
    print('sending count: ', run_count)
    client.publish(FEED_ID_Send, run_count)
    """
    if (mensaje == 1):
        print('Running "main loop" ')
        mensaje = 0

    if miarduino.in_waiting > 0:
        # Leer los valores enviados por el Arduino
        data = miarduino.readline().decode('utf-8').strip()  # Lee la línea y elimina saltos de línea
        print(f'Datos recibidos del Arduino: {data}')
        
        value = 0

        if data.startswith("S1:"):
            value = data[3:]
            print(f"Valor de S1:{value}\n")
            client.publish(FEED_ID_servo1_RX, value)
        elif data.startswith("S2:"):
            value = data[3:]
            print(f"Valor de S2: {value}\n")
            client.publish(FEED_ID_servo2_RX, value)
        elif data.startswith("S3:"):
            value = data[3:]
            print(f"Valor de S3: {value}\n")
            client.publish(FEED_ID_servo3_RX, value)
        elif data.startswith("S4:"):
            value = data[3:]
            print(f"Valor de S4: {value}\n")
            client.publish(FEED_ID_servo4_RX, value)
        
        print(f"Publicando en Adafruit: '{value}'")
