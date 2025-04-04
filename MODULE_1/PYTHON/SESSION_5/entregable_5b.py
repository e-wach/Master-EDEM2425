# 3

from MODULE_1.PYTHON.SESSION_5.entregable_5a import Automovil

class Coche(Automovil):
    n_plazas:int
    n_puertas:int
    caballos:int

    def __init__(self, marca:str, modelo:str, color:str, velocidad:float, n_plazas:int, n_puertas:int, caballos:int):
        super().__init__(marca, modelo, color, velocidad)
        self.n_plazas = n_plazas
        self.n_puertas = n_puertas
        self.caballos = caballos
    
    
class Camion(Automovil):
    carga:float
    n_contenedores:int

    def __init__(self, marca: str, modelo: str, color: str, carga:float, n_contenedores:int):
        super().__init__(marca, modelo, color)
        self.carga = carga
        self.n_contenedores = n_contenedores


class Moto(Automovil):
    tipo_manillar:str
    maletero:bool
    cilindradas:int

    def __init__(self, marca: str, modelo: str, color: str, tipo_manillar:str, maletero:bool, cilindradas:int):
        super().__init__(marca, modelo, color)
        self.tipo_manillar = tipo_manillar
        self.maletero = maletero
        self.cilindradas = cilindradas


