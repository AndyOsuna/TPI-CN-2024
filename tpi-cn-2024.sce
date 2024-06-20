clear
clc

//************************************
// CONDICIÓN INICIAL DEL INTERIOR
// -----------------------------------
// SE PUEDE MODIFICAR DENTRO DEL
// INTERVALO ADMITIDO POR EL PROCESO
T_ini = 20;
//************************************

/************************************
 CONDICION FINAL
 ------------------------------------
 AL FINAL DEL DIA LA TEMPERATURA
 INTERNA DEBE SER IGUAL A LA INICIAL

************************************/

/*************************************************
    COEFICIENTE DE TRANSFERENCIA POR CONVECCIÓN
    * Datos experimentales en el archivo CSV
    "datos_coeficiente_h_conveccion.csv"
    * Regresión mediante LSF_Toolbox
        -> COMANDO: leastsqr()
*************************************************/

// PARA MODIFICAR: Colocar el valor de h obtenido
// por regresión de los datos experimentales.
h = 1 // coeficiente de transferencia de calor por convección de la edificación a la velocidad de 3 m/s del aire



TAmbMax = 29 //"Máxima Temperatura Ambiente"
TAmbMin = 7 //"Mínima Temperatura Ambiente"
InicioSubida = 6 //"Hora en la que empieza a incrementar la temperatura"
FinSubida = 11 //"Hora en la que empieza a incrementar la temperatura"
InicioBajada = 14 //"Hora en la que empieza a decrementar la temperatura"
FinBajada = 19 //"Hora en la que empieza a decrementar la temperatura"

superficieEdificacion=100 // [m2]
superficiePiso=70 // [m2]

conductanciaConveccionEdificacion = h * superficieEdificacion;

espesorEdificacion = 0.3 // [m]
coeficienteConductanciaEdificacion = 0.4 / espesorEdificacion // [W/K/m2]
conductanciaEdificacion = coeficienteConductanciaEdificacion * superficieEdificacion // [W/K]

espesorAislacionPiso = 0.05 // [m]
coeficienteConductanciaPiso = 0.02 / espesorAislacionPiso // [W/K/m2]
conductanciaPiso = superficiePiso*coeficienteConductanciaPiso // [W/K]

masaUnitaria = 150 // Masa de edificio por unidad de superficie de construcción [kg/m2]
capacidadCalorificaEspecifica = 800 // Capacidad Calorífica por kg del material de construcción [J/kg/K]
capacidadCalorificaUnitaria = masaUnitaria * capacidadCalorificaEspecifica // [J/K/m2]
capacidadCalorificaEdificio = capacidadCalorificaUnitaria * superficiePiso // [J/K]


/* ------------------------------------------
        CALEFACCIÓN
--------------------------------------------- */
function Pc = potenciaCalefaccionUnitaria(t)
    // PROPUESTA 1
    // minPot = 1.3
    // maxPot = 15
    // if t <= InicioSubida || t >= FinBajada then
    //     Pc = maxPot
    // else
    //     Pc = minPot
    // end
    // // PROPUESTA 2
    // minPot = 0
    // maxPot = 15
    // if t <= InicioSubida || t >= InicioBajada then
    //     Pc = maxPot
    // else
    //     Pc = minPot
    // end
    // PROPUESTA 3
    minPot = 1.3
    maxPot = 16.5
    if t <= InicioSubida || t >= FinBajada then
        Pc = maxPot
    else
        Pc = minPot
    end
endfunction

precioEnergiaCalefaccion = 1.6*0.0045/1000/0.8 // [dólares/Wh]

////////////////////////////////////////////////////////////////////////////////////
//  CALCULO DEL COSTO DE ENERGÍA DE CALEFACCIÓN
poderCalorificoGas = 12 //[kWh/m3]
precioM3Gas = 55 // [$/m3]
precio_energia_Gas_Pesos_kWh = precioM3Gas / poderCalorificoGas
precioDolar_Pesos = 1000
precio_energia_Gas_USD_kWh = precio_energia_Gas_Pesos_kWh / precioDolar_Pesos // SUMAR 60% de IMPUESTOS
precio_energia_Gas_USD_Wh = precio_energia_Gas_USD_kWh / 1000 // SUMAR 60% de IMPUESTOS
/////////////////////////////////////////////////////////////////////////////////////

/* ------------------------------------------
            REFRIGERACIÓN
------------------------------------------ */
function Pr = potenciaRefrigeracionUnitaria(t)
    /*
        PARA MODIFICAR:
        Esta función debe devolver la POTENCIA DE REFRIGERACIÓN por
        m2 de edificio, en función de la HORA.
        IMPORTANTE: Expresamos la potencia con signo POSITIVO, ya que
        se trata del calor que EXTRAE el refrigerador del interior.
    */
    // Pr = 1 // Potencia de refrigeración por metro cuadrado de superficie construida [W/m2]

    // // PROPUESTA 2
    // minPot = 0
    // maxPot = 30
    // if t >= FinSubida && t <= InicioBajada then
    //     Pr = maxPot
    // else
    //     Pr = minPot
    // end
    // PROPUESTA 3
    minPot= 0
    maxPot = 5
    if t<=FinSubida && t <= InicioBajada then
        Pr = maxPot
    else
        Pr = minPot
    end
endfunction

precioEnergiaRefrigeracion = 0.12/1000 // [dólares/Wh]


function T_ext = T_exterior(t)
    /*
        Función que toma el tiempo en HORAS y devuelve
        la TEMPERATURA EXTERIOR en C°
    */
    if t <= InicioSubida then
        T_ext = TAmbMin;
    elseif t <= FinSubida then
        T_ext = ((TAmbMax - TAmbMin)/(FinSubida - InicioSubida))*(t - InicioSubida) + TAmbMin;
    elseif t <= InicioBajada then
        T_ext = TAmbMax;
    elseif t <= FinBajada then
        T_ext = ((TAmbMin - TAmbMax)/(FinBajada - InicioBajada))*(t - InicioBajada) + TAmbMax;
    else
        T_ext = TAmbMin;
    end
endfunction

function Qp = Q_piso(T_int)
    /*
        Función que toma la TEMPERATURA INTERIOR y
        devuelve el FLUJO DE CALOR entre a traves del piso
        medido en Watts [Joule/segundo]
    */
    Qp = conductanciaPiso * (15 - T_int);
endfunction

function Qe = Q_edif(t, T_int)
    /*
        Función que cálcula para cada HORA y TEMPERATURA INTERIOR
        el valor del FLUJO DE CALOR que atraviesa las paredes y techo
        tel edificio, el cual se mide en Watts [Joule/segundo].
    */
    T_ext = T_exterior(t)
    Re = 1/conductanciaEdificacion; // Resistencia a la transferencia de calor por la pared de la edificación
    Rc = 1/conductanciaConveccionEdificacion; // Resistencia a la transferencia de calor por convección en la edificación
    conductanciaTotalEdificacion = 1/(Re + Rc);
    Qe = conductanciaTotalEdificacion * (T_ext - T_int)
endfunction
// Integral de esto en las 24 horas del día, multiplicando dentro de la integral a Qc x 3600 para obtener el costo en Wh
function Qc = Q_calef(t)
    /*
        Función que devuelve la POTENCIA DE CALEFACCIÓN
        programada para cada HORA para el edificio en Watts [Joule/segundo]
    */
    potenciaCalefaccion = potenciaCalefaccionUnitaria(t) * superficiePiso // [W]
    Qc = potenciaCalefaccion;
endfunction

function Qr = Q_refri(t)
    /*
        Función que devuelve la POTENCIA DE REFRIGERACIÓN
        programada para cada HORA para el edificio en Watts [Joule/segundo]
    */
    potenciaRefrigeracion = potenciaRefrigeracionUnitaria(t) * superficiePiso // [W]
    Qr = potenciaRefrigeracion;
endfunction


function Qt = Q_total(t, T_int)
    /*
        Función que devuelve el CALOR TOTAL transferido
        hacia el interior del edificio.
        (Si el Calor va hacia adentro, el signo es positivo)
    */
    Qp = Q_piso(T_int);
    Qe = Q_edif(t,T_int);
    Qc = Q_calef(t)
    Qr = Q_refri(t)
    Qt = Qp + Qe + Qc - Qr;
endfunction

function dT = f(t,T_int)
    /*
        Función que devuelve la DERIVADA DE LA TEMPERATURA
        RESPECTO DEL TIEMPO.
    */
    dT = Q_total(t,T_int) / capacidadCalorificaEdificio;
endfunction


// Funcion que calcula el calor de calefaccion el Wh
function Cc= CalorCalefaccion()
    // Calcular la integral desde 0 hasta 24
    Cc = integrate('Q_calef(t)','t', 0, 24);
    disp (Cc)
endfunction

// Funcion que calcula el calor de refrigeracion en Wh



function Cr= CalorRefrigeracion()
    // Calcular la integral desde 0 hasta 24
    Cr = integrate('Q_refri(t)','t', 0, 24);
endfunction

precio_calefacion_diario = CalorCalefaccion() * precio_energia_Gas_USD_Wh
precio_calefacion_diario_con_impuestos = precio_calefacion_diario + precio_calefacion_diario * 0.6
precio_refrigeracion_diario = CalorRefrigeracion() * precioEnergiaRefrigeracion


/*******************************************
   CALCULOS:
        (1) Ajustar los valores experimentales
            del coeficiente de transferencia por
            convección.
            Y obtener el coeficiente para la
            velocidad del aire del lugar. (2.5 Puntos) ✅
        (2) Obtener la Temperatura Interior
            (Verificar que se cumplan las
             condiciones necesarias del proceso
             y que la temperatura al final
             del día sea igual a la inicial) (2.5 Puntos)
        (3) Calcular el calor de calefacción y refrigeración. (2.5 Puntos)
        (4) Calcular los costos de calefacción y refrigeración (2.5 Puntos)
*******************************************/
function y=h_viento(v)
    /* Función obtenida del leastsqr() )*/
    y = 4.79*. v + 3.67
endfunction

clf

t = [0]
T_ext = [T_exterior(0)]

Dt = 1/60;

N = 24/Dt ; // Numero de pasos


for i = 1:N,
    t = [t, t($)+Dt]
    T_ext = [T_ext, T_exterior(t($))]
end

plot(t,T_ext)
//objeto_grafico = gca()
//objeto_grafico.data_bounds = [0,24,0,35]
//xlabel("hora")
//ylabel("temperatura exterior")

t = [0]
T = [T_ini]

for i = 1:N,
    Ti = T($)+Dt*3600*f(t($), T($))
    t = [t, t($)+Dt]
    T = [T,Ti]
end

plot(t,T,'r')
plot(t,18,":g")
plot(t,20,":g")
plot(t,22,":g")
disp("Precio de calefacion mensual: "+ string (precio_calefacion_diario_con_impuestos*30) + " USD")
disp("Precio de refrigeracion mensual: "+ string (precio_refrigeracion_diario*30) + " USD")
