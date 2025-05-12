import serial

com_arduino = serial.Serial(port = 'COM3', baudrate=9600, timeout=0.1)

while True:
    ingreso = input("Ingrese el valor de los potenciómetros 1, 2, 3 y 4 respectivamente, separados por comas (0-255): ")
    com_arduino.write(bytes(ingreso, 'utf-8'))
    retorno = com_arduino.readline()
    print("Datos recibidos: ", retorno)
