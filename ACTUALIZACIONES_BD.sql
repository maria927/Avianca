--a) Los directores de tecnología desean saber el estado de un avión, los posibles estados son
--(Vuelo, Tierra, Mantenimiento, Reparación), para esto se pide agregar una nueva columna en
--la tabla donde se almacena la información de los aviones
ALTER TABLE AVIONES
ADD CONSTRAINT CK_ESTADO_AVION CHECK(ESTADO IN ('Vuelo', 'Tierra', 'Mantenimiento', 'Reparación'));


-- b) También desean conocer el aeropuerto dónde se encuentra actualmente, si el avión está en
--vuelo debe registrarse el aeropuerto desde donde despegó y cuando aterriza, se actualiza
--esta información. Si el avión está en mantenimiento o en reparación debe registrar el
--aeropuerto donde se esté realizando esa operación (Usualmente El Dorado)

ALTER TABLE AVIONES
ADD CONSTRAINT FK_AEROPUERTOSM
FOREIGN KEY (ID_AEROPUERTOS)
REFERENCES AEROPUERTOS(ID);



--Asimismo se desea conocer el estado de los vuelos confirmados, los posibles estados son (en
--vuelo, cancelado, retrasado, confirmado, abordando, programado)


ALTER TABLE ITINERARIOS
    ADD CONSTRAINT CK_ESTADO_ITINERARIO CHECK (ESTADO IN ('En_vuelo', 'Cancelado', 'Retrasado', 'Confirmado', 'Abordando', 'Programado'));