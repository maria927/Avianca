--a) Los directores de tecnolog�a desean saber el estado de un avi�n, los posibles estados son
--(Vuelo, Tierra, Mantenimiento, Reparaci�n), para esto se pide agregar una nueva columna en
--la tabla donde se almacena la informaci�n de los aviones
ALTER TABLE AVIONES
ADD CONSTRAINT CK_ESTADO_AVION CHECK(ESTADO IN ('Vuelo', 'Tierra', 'Mantenimiento', 'Reparaci�n'));


-- b) Tambi�n desean conocer el aeropuerto d�nde se encuentra actualmente, si el avi�n est� en
--vuelo debe registrarse el aeropuerto desde donde despeg� y cuando aterriza, se actualiza
--esta informaci�n. Si el avi�n est� en mantenimiento o en reparaci�n debe registrar el
--aeropuerto donde se est� realizando esa operaci�n (Usualmente El Dorado)

ALTER TABLE AVIONES
ADD CONSTRAINT FK_AEROPUERTOSM
FOREIGN KEY (ID_AEROPUERTOS)
REFERENCES AEROPUERTOS(ID);



--Asimismo se desea conocer el estado de los vuelos confirmados, los posibles estados son (en
--vuelo, cancelado, retrasado, confirmado, abordando, programado)


ALTER TABLE ITINERARIOS
    ADD CONSTRAINT CK_ESTADO_ITINERARIO CHECK (ESTADO IN ('En_vuelo', 'Cancelado', 'Retrasado', 'Confirmado', 'Abordando', 'Programado'));