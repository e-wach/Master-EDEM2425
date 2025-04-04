from SESSION_3.entregable_3b import esPrimo

# 1 A partir de las respuestas de los dos últimos ejercicios de la Sesión 3:
## 1
def numerosPrimos(start, end) -> None:
    for numero in range(start, end):
        if esPrimo(numero):
            print(numero)

numerosPrimos(0,51)


## 2
number = int(input('Introduce un número: '))

def numberPrimo(number):
    esPrimo(number)

numberPrimo(number)


## 3
from SESSION_3.entregable_3b import esBisiesto

year = int(input('Introduce un año: '))

def yearBisiesto(year):
    esBisiesto(year)

yearBisiesto(year)