## 1
while (True):
        inicio = input(
'''Hola. Bienvenido al sistema de cálculo de inversiones. 
¿Qué quieres hacer?
[1] Calcular una inversión
[X] Salir
'''               
)
        if (inicio == '1'):
              from MODULE_1.PYTHON.entregable_2 import *
              calculo_inversion(inversion, interes, years)
              break
        elif (inicio == 'X'):
             print('¡Nos vemos!')
             break
        
        else:
              print(inicio)

