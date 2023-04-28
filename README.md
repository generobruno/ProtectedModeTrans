# ProtectedModeTrans
Código en Assembler para realizar una transición a Modo Protegido en un procesador x86

El codigo linker es un linker script para un programa de arranque para la arquitectura x86.
El propósito de este código es definir cómo el programa de arranque se compila y se enlaza para generar un archivo ejecutable que 
pueda ser cargado por la BIOS de la computadora y que arranque el sistema operativo.

El codigo protected_mode_macros.S utiliza macros para configurar el procesador en modo protegido y mostrar un mensaje en la pantalla.
Utiliza el codigo mycommon en donde se definen macros y definiciones comunes en el codigo.

El codigo protectedModeTransition.S implementa la carga de un sistema operativo en la memoria de la computadora y la transición del modo real al modo protegido.
La siguiente sección, "Enter protected mode", define una tabla de descriptores globales (GDT) para poder cambiar al modo protegido. 
La GDT contiene dos segmentos, uno para código y otro para datos, que cubren todo el espacio de memoria. 
También se habilita el bit PE en el registro CR0, lo que permite el cambio al modo protegido.
Después de la transición al modo protegido, el código continúa en la etiqueta "protected_mode". 
Allí, se inicializan los segmentos de datos y pila, y se salta a la dirección de inicio del sistema operativo.
