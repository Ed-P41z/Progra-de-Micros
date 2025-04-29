import serial


com_arduino = serial.Serial(port = 'COM3', baudrate=9600, timeout=0.1)

while True:
    ingreso = input("Ingresa 1 para encener el led o 2 para apagar el led: ")
    com_arduino.write(bytes(ingreso, 'utf-8'))
    retorno = com_arduino.readline()
    print("Datos recibidos: ", retorno)