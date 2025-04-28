import serial





com_arduino = serial.Serial(port = 'COM3', baudrate=9600, timeout=0.1)

while True:
    ingreso = input("Ingresar un texto: ")
    com_arduino.write(bytes(ingreso, 'utf.8'))
    retorno = com_arduino.readline()
    print("Datos recibidos: ", retorno)
