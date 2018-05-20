--Punto 1: Vista
--Se desea asignar un avión a un vuelo confirmado, para esto es necesario una vista que dado el id de
--un vuelo confirmado, busque los aviones que se encuentran en el aeropuerto de salida (Utilizando la  
--hora estimada de llegada a esa ciudad / aeropuerto de otros vuelos) 2 horas antes de la fecha estimada de salida

CREATE OR REPLACE VIEW AVIONES_DISPONIBLES AS SELECT VUELOS_PROG.id ID_VUELO_PROGRAMADO,
    A.ID ID_AVION_ASIGNAR    
  FROM ITINERARIOS I
  JOIN VUELOS V
  ON V.ID = I.ID_VUELO
  JOIN rutas R
  ON R.ID = V.ID_RUTA
  JOIN AVIONES A
  ON A.ID = I.ID_AVION
  JOIN --Aeropuerto origen de itinerarios programados
    (SELECT I.id, I.HORA_ESTIMADA_SALIDA,
      R.ID_AEROPUERTO_ORIGEN
    FROM ITINERARIOS I
    JOIN VUELOS V
    ON V.ID = I.ID_VUELO
    JOIN rutas R
    ON R.ID                                 = V.ID_RUTA
    WHERE I.estado                            = 'Programado'
    ) VUELOS_PROG 
    ON VUELOS_PROG.ID_AEROPUERTO_ORIGEN = R.ID_AEROPUERTO_DESTINO 
    -- Uniendo los itinerarios en estado Programado con su aeropuerto ORIGEN con los itinerarios que ya llegaron a la ciudad de ORIGEN 
    --a traves del campo del itinerario DESTINO
  WHERE I.HORA_ESTIMADA_LLEGADA BETWEEN (VUELOS_PROG.HORA_ESTIMADA_SALIDA - interval '2' hour) AND VUELOS_PROG.HORA_ESTIMADA_SALIDA
  AND A.ESTADO = 'Tierra'
  ;
  

  
  ---------------------------------------------
  
--Punto 2:Procedimiento
-- Realice un procedimiento almacenado que programe la tripulación del vuelo 5 horas antes del vuelo así ​(0.5)​:
-- a) Invocar la vista del punto dos y asignar el primer avión encontrado.
-- b) Con la información del vuelo debe asignar:
--    i) El piloto y el copiloto: (1) Para la simplicidad del ejercicio, busque los pilotos que se encuentran 
--	  activos, tienen al menos 2 horas de descanso y se encuentran en la ciudad donde parte el vuelo.
--    ii) La tripulación siguiendo la lógica del taller anterior dependiendo del número de horas del vuelo programado y la cantidad de sillas del avión.
--	  (1) También por simplicidad del ejercicio se debe buscar los auxiliares de vuelo que tienen al menos 2 horas de descanso, que estén activos y que se 
--	   encuentren en la ciudad donde parte el vuelo.
--c) Actualizar el estado del vuelo a “Confirmado”

CREATE OR REPLACE PROCEDURE "SYSTEM"."PROGRAMAR_TRIPULACION_VUELO" (ID_ITINERARIO IN ITINERARIOS.ID%TYPE) AS

  ID_CIUDAD_ACTUAL NUMBER := 0;
  ID_AVION_DISPONIBLE NUMBER := 0;
  TOTAL_ASIENTOS NUMBER := 0;
  ID_PILOTO_ENCONTRADO NUMBER := 0;
  ID_COPILOTO_ENCONTRADO NUMBER := 0;
  TOTAL_TRIPULANTES NUMBER := 0;
  DURACION_REAL NUMBER := 0;
  
  EXISTE_ITINERARIO NUMBER := 0;
  TRIPULANTES_DISPONIBLES number := 0;
  EXISTEN_AVIONES_DISPONIBLES NUMBER := 0;
  EXISTEN_PILOTOS_DISPONIBLES NUMBER := 0;
  EXISTEN_COPILOTOS_DISPONIBLES NUMBER := 0;
  
  --Constantes
  EMPLEADO_ACTIVO VARCHAR2(10) := 'Activo';
BEGIN
  DBMS_OUTPUT.PUT_LINE('INICIANDO EJECUCIÓN PROCEDIMIENTO...');

  --Validar si el itinerario es válido
  SELECT COUNT(1) INTO EXISTE_ITINERARIO FROM ITINERARIOS WHERE ID = ID_ITINERARIO AND ESTADO = 'Programado';
  IF(EXISTE_ITINERARIO = 0) THEN
    Raise_Application_Error (-20343, 'El id del itinerario no existe.');
  END IF;
  
  --Validar si existen aviones disponibles para el aeropuerto de origen del itinerario programado
  SELECT count(1) into EXISTEN_AVIONES_DISPONIBLES FROM AVIONES_DISPONIBLES WHERE ID_VUELO_PROGRAMADO = ID_ITINERARIO;
  IF(EXISTEN_AVIONES_DISPONIBLES = 0) THEN
    Raise_Application_Error (-20343, 'No existen aviones disponibles para el vuelo.');
  END IF;
  
  --Duración real del vuelo
  --Ciudad actual
  SELECT c.ID, I.DURACION_REAL into ID_CIUDAD_ACTUAL, DURACION_REAL
    FROM ITINERARIOS I
    JOIN VUELOS V
    ON V.ID = I.ID_VUELO
    JOIN rutas R
    ON R.ID = V.ID_RUTA
    join AEROPUERTOS A
    on a.id = R.ID_AEROPUERTO_ORIGEN
    join CIUDADES c
    on c.ID = A.ID_CIUDAD
    WHERE I.ID = ID_ITINERARIO;
  DBMS_OUTPUT.PUT_LINE('CIUDAD ACTUAL: ' || ID_CIUDAD_ACTUAL);  
  DBMS_OUTPUT.PUT_LINE('DURACIÓN REAL DEL VUELO: ' || DURACION_REAL);

  --Validar si existen piloto disponibles
  SELECT COUNT(1) INTO EXISTEN_PILOTOS_DISPONIBLES
    FROM PILOTOS p
    JOIN EMPLEADOS E
    ON E.ID = p.ID_EMPLEADO
    WHERE E.ESTADO = EMPLEADO_ACTIVO AND E.ID_CIUDAD = ID_CIUDAD_ACTUAL 
    AND E.HORAS_DESCANSO_ULTIMO_VUELO >= 2 AND p.CARGO = 'Piloto' AND e.tipo = 'Piloto';
  IF(EXISTEN_PILOTOS_DISPONIBLES = 0) THEN
    Raise_Application_Error (-20343, 'No existen pilotos disponibles para el vuelo.');
  END IF;  
  
  --Validar si existen copilotos disponibles
  SELECT COUNT(1) INTO EXISTEN_COPILOTOS_DISPONIBLES FROM PILOTOS p
    JOIN EMPLEADOS E
    ON E.ID = p.ID_EMPLEADO
    WHERE E.ESTADO = EMPLEADO_ACTIVO AND E.ID_CIUDAD = ID_CIUDAD_ACTUAL 
    AND E.HORAS_DESCANSO_ULTIMO_VUELO >= 2 AND p.CARGO = 'Copiloto' AND e.tipo = 'Piloto';
    
  IF(EXISTEN_COPILOTOS_DISPONIBLES = 0) THEN
    Raise_Application_Error (-20343, 'No existen copilotos disponibles para el vuelo.');
  END IF;   

  --Seleccionar el primer avión disponible de la vista
  SELECT ID_AVION_ASIGNAR, TOTAL_ASIENTOS INTO ID_AVION_DISPONIBLE, TOTAL_ASIENTOS 
    FROM AVIONES_DISPONIBLES WHERE ID_VUELO_PROGRAMADO = ID_ITINERARIO and ROWNUM = 1;
  DBMS_OUTPUT.PUT_LINE('AVIÓN DISPONIBLE: ' || ID_AVION_DISPONIBLE);    
  DBMS_OUTPUT.PUT_LINE('TOTAL ASIENTOS AVIÓN DISPONIBLE: ' || TOTAL_ASIENTOS);

  --Obtener el piloto disponible
  SELECT P.ID INTO ID_PILOTO_ENCONTRADO FROM PILOTOS p
    JOIN EMPLEADOS E
    ON E.ID = p.ID_EMPLEADO
    WHERE 
    E.ESTADO = EMPLEADO_ACTIVO AND E.ID_CIUDAD = ID_CIUDAD_ACTUAL 
    AND E.HORAS_DESCANSO_ULTIMO_VUELO >= 2
    AND p.CARGO = 'Piloto'
    AND e.tipo = 'Piloto'
    AND ROWNUM = 1;
  DBMS_OUTPUT.PUT_LINE('PILOTO ENCONTRADO: ' || ID_PILOTO_ENCONTRADO);
  
  --El copiloto
  SELECT P.ID INTO ID_COPILOTO_ENCONTRADO FROM PILOTOS p
    JOIN EMPLEADOS E
    ON E.ID = p.ID_EMPLEADO
    WHERE 
    E.ESTADO = EMPLEADO_ACTIVO AND E.ID_CIUDAD = ID_CIUDAD_ACTUAL 
    AND E.HORAS_DESCANSO_ULTIMO_VUELO >= 2
    AND p.CARGO = 'Copiloto'
    AND e.tipo = 'Piloto'
    AND ROWNUM = 1;
  DBMS_OUTPUT.PUT_LINE('COPILOTO ENCONTRADO: ' || ID_COPILOTO_ENCONTRADO);  
  
  --Consultar la cantidad de los tripulantes por total asientos
  IF(TOTAL_ASIENTOS > 19) THEN
    TOTAL_TRIPULANTES := 1;
    IF(TOTAL_ASIENTOS >= 50) THEN
      TOTAL_TRIPULANTES := TOTAL_TRIPULANTES + floor(TOTAL_ASIENTOS / 50);
    END IF;
  END IF;
  
  --Si el vuelo dura más de 6 horas debe existir reemplazo
  IF(DURACION_REAL > 6) THEN
    TOTAL_TRIPULANTES := TOTAL_TRIPULANTES + 1;
  END IF;
  DBMS_OUTPUT.PUT_LINE('TOTAL TRIPULANTES POR ASIENTOS: ' || TOTAL_TRIPULANTES);  
  
  --Se valida que existan cantidad de tripulantes para el vuelo, sino se levanta exception
  SELECT COUNT(1) INTO TRIPULANTES_DISPONIBLES FROM EMPLEADOS E
                  WHERE E.TIPO = 'TCP' 
                    and E.ESTADO = EMPLEADO_ACTIVO
                    AND E.ID_CIUDAD = ID_CIUDAD_ACTUAL
                    AND E.HORAS_DESCANSO_ULTIMO_VUELO >= 2;
  
  IF(TRIPULANTES_DISPONIBLES < TOTAL_TRIPULANTES) THEN
    Raise_Application_Error (-20343, 'No existen suficientes tripulantes disponibles para el vuelo.');
  END IF;
  
  --Consultar todos los tripulantes a relacionar    
  FOR loop_emp IN (SELECT E.* FROM EMPLEADOS E
                  WHERE E.TIPO = 'TCP' and e.estado = EMPLEADO_ACTIVO AND E.ID_CIUDAD = ID_CIUDAD_ACTUAL
                    AND E.HORAS_DESCANSO_ULTIMO_VUELO >= 2 AND ROWNUM <= TOTAL_TRIPULANTES) LOOP
    Insert into PROGRAMACION_TRIPULANTES (ID_ITINERARIO, ID_EMPLEADO) values (ID_ITINERARIO, loop_emp.id);
  END LOOP loop_emp;
       
  --Actualizar estado del itinerario a Confirmada
  UPDATE ITINERARIOS SET ESTADO = 'Confirmado', 
    ID_PILOTO = ID_PILOTO_ENCONTRADO, 
    ID_COPILOTO = ID_COPILOTO_ENCONTRADO, 
    ID_AVION = ID_AVION_DISPONIBLE,
	TOTAL_PASAJEROS_PRIMERACLASE = 0,
	TOTAL_PASAJEROS_CLASEECONOMICA = 0
  WHERE ID = ID_ITINERARIO;
  
  DBMS_OUTPUT.PUT_LINE('PROCEDIMIENTO EJECUTADO...');
  
END;



--------------------------------------
--Punto 3: Procedimiento
-- Construya un procedimiento que permita hacer el checking de los pasajeros, para esto se debe pasar
--   el id del vuelo confirmado, el id del pasajero y el tipo de silla que tiene (Ejecutiva, Económica)​(0.5)​. 
--  a) Por cada checking exitoso actualice la cantidad de pasajeros en la tabla del vuelo confirmado   
--   dependiendo de la silla que tenga.
--  b) Se debe validar que la cantidad de pasajeros no supere la cantidad de sillas del avión  
--   asignado. En caso de ser superior el procedimiento simplemente se ejecutará pero no mostrará ningún error y tampoco modificará las tablas existentes.

CREATE OR REPLACE PROCEDURE CHECKING_PARAJEROS (ID_ITINERARIO_CHECKIN IN ITINERARIOS.ID%TYPE, ID_PASAJERO_CHECKIN IN PASAJEROS.ID%TYPE, 
    SILLA VARCHAR2, TIPO_CHECKIN CHECKIN.TIPO%TYPE, CONTACTO_EMERGENCIA_CK CHECKIN.CONTACTO_EMERGENCIA%TYPE,
    CORREO_CONTACTO_EMERGENCIA_CK CHECKIN.CORREO_CONTACTO_EMERGENCIA%TYPE, TEL_CONTACTO_EMERGENCIA_CK CHECKIN.TELEFONO_CONTACTO_EMERGENCIA%TYPE) AS

  ID_CIUDAD_ACTUAL NUMBER := 0;
  SILLAS_AVION NUMBER := 0;
  SILLAS_ACTUALES NUMBER := 0;
  
  EXISTE_ITINERARIO NUMBER := 0;
  EXISTE_PASAJERO number := 0;
BEGIN
  DBMS_OUTPUT.PUT_LINE('INICIANDO EJECUCIÓN PROCEDIMIENTO...');

  --Validar si el itinerario es válido
  SELECT COUNT(1) INTO EXISTE_ITINERARIO FROM ITINERARIOS WHERE ID = ID_ITINERARIO_CHECKIN AND ESTADO = 'Confirmado';
  IF(EXISTE_ITINERARIO = 0) THEN
    Raise_Application_Error (-20343, 'El id del itinerario no es válido.');
  END IF;
  
  --Validar si el pasajero si existe
  SELECT COUNT(1) INTO EXISTE_PASAJERO FROM PASAJEROS WHERE ID = ID_PASAJERO_CHECKIN;
  IF(EXISTE_PASAJERO = 0) THEN
    Raise_Application_Error (-20343, 'El id del pasajero no es válido.');
  END IF;
  
  --Validar si la silla si es válida
  IF(SILLA <> 'Ejecutiva' AND SILLA <> 'Económica') THEN
    Raise_Application_Error (-20343, 'La silla no es válida (Opciones: Ejecutiva y Económica).');
  END IF;
  
  --Validar si el tipo checkin es válido
  IF(TIPO_CHECKIN <> 'Virtual' AND TIPO_CHECKIN <> 'Fisico') THEN
    Raise_Application_Error (-20343, 'El tipo de checkin no es válido (Opciones: Virtual y Fisico).');
  END IF;

  --Sillas del avión
  --Ciudad actual
  SELECT c.ID, (A.NUM_ASIENTOS_PRIMERA_CLASE + A.NUM_ASIENTOS_CLASE_ECONOMICA),
    (I.TOTAL_PASAJEROS_PRIMERACLASE + I.TOTAL_PASAJEROS_CLASEECONOMICA) into ID_CIUDAD_ACTUAL, SILLAS_AVION, SILLAS_ACTUALES
    FROM ITINERARIOS I
    JOIN VUELOS V
    ON V.ID = I.ID_VUELO
    JOIN rutas R
    ON R.ID = V.ID_RUTA
    join AEROPUERTOS A
    on a.id = R.ID_AEROPUERTO_ORIGEN
    join CIUDADES c
    on c.ID = A.ID_CIUDAD
    JOIN AVIONES A
    ON A.ID = I.ID_AVION
    WHERE I.ID = ID_ITINERARIO_CHECKIN;
  DBMS_OUTPUT.PUT_LINE('CIUDAD ACTUAL: ' || ID_CIUDAD_ACTUAL);  
  DBMS_OUTPUT.PUT_LINE('SILLAS MÁXIMAS DEL AVIÓN: ' || SILLAS_AVION);
  DBMS_OUTPUT.PUT_LINE('SILLAS ACTUALES: ' || SILLAS_ACTUALES);

  --VALIDAR TOTAL SILLAS ACTUALES DEL VUELO + 1 (MÁS LA QUE SE VA A INSERTAR)
  --NO DEBE SUPERAR EL TOTAL DE SILLAS DEL AVIÓN
  IF( (SILLAS_ACTUALES + 1) <= SILLAS_AVION) THEN
    
    --Realizar el checking (Validar campo TIPO, CONTACTO_EMERGENCIA, CORREO_CONTACTO_EMERGENCIA, TELEFONO_CONTACTO_EMERGENCIA)
    Insert into CHECKIN (TIPO, CONTACTO_EMERGENCIA, CORREO_CONTACTO_EMERGENCIA, TELEFONO_CONTACTO_EMERGENCIA, ID_ITINERARIO, ID_PASAJERO, ID_CIUDAD) 
      values (TIPO_CHECKIN, CONTACTO_EMERGENCIA_CK, CORREO_CONTACTO_EMERGENCIA_CK, TEL_CONTACTO_EMERGENCIA_CK, 
              ID_ITINERARIO_CHECKIN, ID_PASAJERO_CHECKIN, ID_CIUDAD_ACTUAL);
        
    --Actualizar la disponibilidad de sillas
    IF(SILLA = 'Ejecutiva') THEN
      UPDATE ITINERARIOS SET TOTAL_PASAJEROS_PRIMERACLASE = TOTAL_PASAJEROS_PRIMERACLASE + 1 where id = ID_ITINERARIO_CHECKIN;
    ELSE 
      UPDATE ITINERARIOS SET TOTAL_PASAJEROS_CLASEECONOMICA = TOTAL_PASAJEROS_CLASEECONOMICA + 1 where id = ID_ITINERARIO_CHECKIN;
    END IF;

  END IF;

  DBMS_OUTPUT.PUT_LINE('PROCEDIMIENTO EJECUTADO...');
  
END;


EXEC CHECKING_PARAJEROS(7, 1, 'Ejecutiva', 'Virtual', 'Juamchjit', 'juan@gmail.com', 25556695);


--------------------------------------
-- Punto 4: Vista
--Construya una vista que dado un id de un vuelo pasado o confirmado, muestre el listado de personal     
--  asignado al vuelo, tanto pilotos como auxiliares de vuelo). Debe haber una columna que identifique   
--quien es el piloto, quién es el copiloto y quienes son los auxiliares de vuelo. ​(0.2) 

CREATE OR REPLACE VIEW PERSONAL_ASIGNADO_VUELO AS select p.ID_ITINERARIO, 'Tripulante' TIPO_EMPLEADO, E.*
  from empleados e 
  join PROGRAMACION_TRIPULANTES p
  on p.ID_EMPLEADO = e.ID
  join ITINERARIOS i
  on i.id = p.ID_ITINERARIO
  where i.ESTADO IN ('Confirmado', 'Aterrizado')
union
select i.id, 'Piloto' TIPO_EMPLEADO , e.*
  from PILOTOS P
  JOIN empleados e 
  ON E.ID = P.ID_EMPLEADO
  join ITINERARIOS i
  on i.ID_PILOTO = P.id
 where i.ESTADO IN ('Confirmado', 'Aterrizado')
union 
select i.id, 'Copiloto' TIPO_EMPLEADO , E.*
  from PILOTOS P
  JOIN empleados e 
  ON E.ID = P.ID_EMPLEADO
  join ITINERARIOS i
  on i.ID_COPILOTO = P.id
  where i.ESTADO IN ('Confirmado', 'Aterrizado')
;

SELECT * FROM PERSONAL_ASIGNADO_VUELO WHERE ID_ITINERARIO = 7;



-----------------------------------------------
--Punto 5: Vista
-- Construya una vista que dado un aeropuerto origen y un aeropuerto destino (Ruta), muestre todos los 
-- vuelos programados desde el momento en que se está ejecutando el query hasta 2 semanas  
-- después, debe mostrar el número del vuelo, la hora y la fecha programada de salida ​(0.2) 

CREATE OR REPLACE VIEW VUELOS_POR_ORIGEN_DESTINO AS SELECT I.ID,
    TO_CHAR(I.HORA_ESTIMADA_SALIDA, 'HH24:MI:SS A.M.') HORA_PROGRAMADA_SALIDA,
    TO_CHAR(I.HORA_ESTIMADA_SALIDA, 'MM/DD/YYYY') FECHA_PROGRAMADA_SALIDA,
    r.ID_AEROPUERTO_ORIGEN,
    r.ID_AEROPUERTO_DESTINO
  FROM ITINERARIOS I
  JOIN VUELOS v
  ON v.id = I.ID_VUELO
  JOIN rutas r
  ON r.ID = v.ID_RUTA
  WHERE I.HORA_ESTIMADA_SALIDA BETWEEN sysdate AND sysdate + 14;
  
  
  SELECT * FROM VUELOS_POR_ORIGEN_DESTINO WHERE ID_AEROPUERTO_ORIGEN = 4 AND ID_AEROPUERTO_DESTINO = 45;
  
  
  
  -- Realizar un EXPLAIN PLAN de las vistas. ​(0.3) 

EXPLAIN PLAN
SET STATEMENT_ID = 'VISTA_AVIONES_DISPONIBLES'
INTO PLAN_TABLE FOR
  SELECT *
  FROM AVIONES_DISPONIBLES;
 
-- Mostramos el plan de ejecución que se ha introducido en la tabla PLAN_TABLE

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'VISTA_AVIONES_DISPONIBLES', 'TYPICAL'));



EXPLAIN PLAN
SET STATEMENT_ID = 'VISTA_PERSONAL_ASIGNADO_VUELO'
INTO PLAN_TABLE FOR
  SELECT *
  FROM PERSONAL_ASIGNADO_VUELO;
 
-- Mostramos el plan de ejecución que se ha introducido en la tabla PLAN_TABLE

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'VISTA_PERSONAL_ASIGNADO_VUELO', 'TYPICAL'));


EXPLAIN PLAN
SET STATEMENT_ID = 'VISTA_VUELOS_ORIGEN_DESTINO'
INTO PLAN_TABLE FOR
  SELECT *
  FROM VUELOS_POR_ORIGEN_DESTINO;
 
-- Mostramos el plan de ejecución que se ha introducido en la tabla PLAN_TABLE

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY('PLAN_TABLE', 'VISTA_VUELOS_ORIGEN_DESTINO', 'TYPICAL'));