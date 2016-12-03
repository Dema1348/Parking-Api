create or replace PROCEDURE ESTADO_PAGOS(ID_OPERACION out number,salida out sys_refcursor)
IS
BEGIN

open salida for  
 select
  (select count(*) 
 from servicio S where ( S.ESTADO_PAGO='A' or  S.ESTADO_PAGO='R') ) TOTAL,
 (select count(*) TOTAL
 from servicio S where ( S.ESTADO_PAGO='A')) APROVADOS,
 (select count(*) TOTAL
 from servicio S where ( S.ESTADO_PAGO='R')) RECHAZADOS
 from dual;
  ID_OPERACION := 2;

EXCEPTION

WHEN NOT_LOGGED_ON THEN
DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
ID_OPERACION := 5;
WHEN VALUE_ERROR THEN
DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
ID_OPERACION := 6;
END  ESTADO_PAGOS;






create or replace PROCEDURE LISTAR_PAGOS(ID_OPERACION out number,salida out sys_refcursor)
IS
BEGIN

open salida for SELECT 
S.ID,
P.RUT,
P.DIV,
P.NOMBRE,
P.AP_PATERNO,
P.AP_MATERNO,
S.TOTAL TOTAL,
S.ESTADO_PAGO ESTADO_PAGO,
S.HORA_ENTRADA FECHA_PAGO
from SERVICIO S
JOIN AUTO A 
ON A.PATENTE =S.AUTO_PATENTE
JOIN PERSONA P 
ON P.RUT=A.PERSONA_RUT and  (S.ESTADO_PAGO='A' or  S.ESTADO_PAGO='R');
  ID_OPERACION := 2;

EXCEPTION

WHEN NOT_LOGGED_ON THEN
DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
ID_OPERACION := 5;
WHEN VALUE_ERROR THEN
DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
ID_OPERACION := 6;
END LISTAR_PAGOS;

create or replace PROCEDURE LOGIN_ADMIN_F(E_CORREO IN USUARIO.CORREO%TYPE, E_PW IN USUARIO.PASSWORD%TYPE, respuesta out number, salida out sys_refcursor)
as
x INTEGER;
BEGIN
SELECT count(*) INTO x from usuario u
WHERE u.correo = E_CORREO and  u.PASSWORD=E_PW and u.ROL_ID = 3;
IF x = 1 THEN
  respuesta :=1;
  OPEN salida FOR
    SELECT 
          p.NOMBRE,
          p.AP_PATERNO,
          p.AP_MATERNO,
          u.correo
    FROM persona p 
    JOIN usuario u ON u.persona_rut= p.rut 
    JOIN rol r ON u.ROL_ID = r.id_rol 
    WHERE u.correo = E_CORREO;
ELSE
  respuesta:=-1;
end if;

END LOGIN_ADMIN_F;


create or replace PROCEDURE UPDATE_ESTADO_USER( P_PERSONA_RUT PERSONA.RUT%type,
                                                P_ESTADO USUARIO.ESTADO%type,
                                                ID_OPERACION out number)
IS
count_usuario INTEGER;
BEGIN


SELECT count(*) into count_usuario from PERSONA where RUT= P_PERSONA_RUT;



IF count_usuario = 1 THEN
  
   UPDATE usuario set ESTADO=P_ESTADO  where PERSONA_RUT=P_PERSONA_RUT;
     ID_OPERACION := 2;
    DBMS_OUTPUT.PUT_LINE('EL USUARIO UPDATEADO CON EXITO');
ELSE   
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO EXISTE');
  ID_OPERACION := 1;
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END UPDATE_ESTADO_USER;





create or replace PROCEDURE UPDATE_CALIFICACION(  P_RATE CALIFIC.PUNTOS%TYPE,
                                            P_ID CALIFIC.ID%TYPE,
                                            P_COMENTARIO CALIFIC.COMENTARIO%TYPE,
                                            P_PERSONA_RUT AUTO.PERSONA_RUT%type ,                                          
                                           ID_OPERACION out number)
IS
count_calificacion INTEGER;
rol_user NUMBER(8,2);
BEGIN

SELECT COUNT(*) INTO count_calificacion FROM CALIFIC WHERE ID = P_ID;
SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;

IF count_calificacion = 0 THEN
  DBMS_OUTPUT.PUT_LINE('LA CALIFICACION NO SE ENCUENTRA REGISTRADO EN LA BASE DE DATOS');
  ID_OPERACION := 0; 
ELSIF rol_user != 0 and rol_user != 1  THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 1; 
ELSIF P_RATE<0 or P_RATE>5 THEN
  DBMS_OUTPUT.PUT_LINE('LA CALIFICACION DEBE ESTAR ENTRE 1 y 5');
  ID_OPERACION := 3; 
ELSE 
 UPDATE CALIFIC SET PUNTOS = P_RATE , COMENTARIO= P_COMENTARIO, REALIZADO=1
 WHERE ID= P_ID;
   ID_OPERACION := 2; 
END IF;


EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END UPDATE_CALIFICACION;




create or replace PROCEDURE LISTAR_CALIFICACIONESP_USUARIO(E_RUT IN USUARIO.PERSONA_RUT%type, ID_OPERACION out number,salida out sys_refcursor)
IS
isDueno INTEGER;
count_usuario INTEGER;
BEGIN
SELECT count(*) into count_usuario from PERSONA where RUT= E_RUT ;
IF  count_usuario = 0 THEN
  ID_OPERACION := 1;
  DBMS_OUTPUT.PUT_LINE('NO EXISTE EL RUT');
ELSE
open salida for SELECT C.ID, S.HORA_ENTRADA, S.HORA_SALIDA,P.NOMBRE,P.AP_MATERNO,P.AP_PATERNO from CALIFIC C
JOIN SERVICIO S
ON  C.ID_SERVICIO=S.ID
JOIN USUARIO U
ON C.USUARIO_ID=U.ID
JOIN PERSONA P
ON U.PERSONA_RUT=P.RUT
WHERE C.RUT_CALIFICADOR=E_RUT and C.REALIZADO=0 and ROWNUM <= 5;
  ID_OPERACION := 2;

END IF;
EXCEPTION

WHEN NOT_LOGGED_ON THEN
DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
ID_OPERACION := 5;
WHEN VALUE_ERROR THEN
DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
ID_OPERACION := 6;
END LISTAR_CALIFICACIONESP_USUARIO;




create or replace PROCEDURE CREATE_CALIFIC
AS
cursor data is    select
  S.ID ID,
  DUENO.RUT RUT_DUENO,
  U_DUENO.ID ID_DUENO,
  CLIENTE.RUT RUT_ARRENDADOR,
  U_CLIENTE.ID  ID_ARRENDADOR,
  S.ESTADO_PAGO ESTADO_PAGO
  from SERVICIO S
  JOIN AUTO A 
  ON A.PATENTE =S.AUTO_PATENTE
  JOIN HORARIO H
  ON H.ID_HORARIO=S.HORARIO_ID
  JOIN ESTACIONAMIENTO E
  ON E.ID=H.ESTACIONAMIENTO_ID
  JOIN PERSONA CLIENTE
  ON CLIENTE.RUT= A.PERSONA_RUT
  JOIN PERSONA DUENO
  ON DUENO.RUT= E.PERSONA_RUT
  JOIN USUARIO U_DUENO
  ON U_DUENO.PERSONA_RUT=DUENO.RUT 
  JOIN USUARIO U_CLIENTE
  ON U_CLIENTE.PERSONA_RUT=CLIENTE.RUT 
  where (S.ESTADO_PAGO='A' OR S.ESTADO_PAGO='R') and S.ESTADO!=1 AND (SELECT COUNT(*) FROM CALIFIC  C WHERE C.ID_SERVICIO != S.ID)=0;
  


BEGIN
FOR servicio_completo in data
LOOP
   INSERT
    INTO CALIFIC
      (
        ID ,
        REALIZADO ,
        USUARIO_ID ,
        ID_SERVICIO,
        RUT_CALIFICADOR
      )
      VALUES
      (
        1 ,
        0 ,
       servicio_completo.ID_DUENO,
        servicio_completo.ID,
        servicio_completo.RUT_ARRENDADOR 
      );
    DBMS_OUTPUT.PUT_LINE('Creada 2 cal');

    INSERT
    INTO CALIFIC
      (
        ID ,
        REALIZADO ,
        USUARIO_ID ,
        ID_SERVICIO,
        RUT_CALIFICADOR
      )
      VALUES
      (
        1 ,
        0 ,
       servicio_completo.ID_ARRENDADOR,
        servicio_completo.ID,
        servicio_completo.RUT_DUENO
        
      );
END LOOP;
END CREATE_CALIFIC;

CREATE SEQUENCE calificacion_sequence;


create or replace TRIGGER calificacion_on_insert
  BEFORE INSERT ON CALIFIC
  FOR EACH ROW
BEGIN
  SELECT calificacion_sequence.nextval
  INTO :new.id
  FROM dual;
END;


create or replace PROCEDURE LISTAR_PAGOS_USUARIO(E_RUT IN USUARIO.PERSONA_RUT%type, ID_OPERACION out number,salida out sys_refcursor)
IS
isDueno INTEGER;
count_usuario INTEGER;
BEGIN
SELECT count(*) into count_usuario from PERSONA where RUT= E_RUT ;
IF  count_usuario = 0 THEN
  ID_OPERACION := 1;
  DBMS_OUTPUT.PUT_LINE('NO EXISTE EL RUT');
ELSE
open salida for SELECT 
S.HORA_ENTRADA HORA_ENTRADA,
S.HORA_SALIDA HORA_SALIDA,
S.TOTAL TOTAL,
S.ESTADO_PAGO ESTADO_PAGO,
(CASE WHEN A.PERSONA_RUT = E_RUT THEN 'ARRENDADOR'  ELSE 'DUEÑO'  END) TIPO
from SERVICIO S
JOIN AUTO A 
ON A.PATENTE =S.AUTO_PATENTE
JOIN HORARIO H
ON H.ID_HORARIO=S.HORARIO_ID
JOIN ESTACIONAMIENTO E 
ON H.ESTACIONAMIENTO_ID=E.ID
where ( A.PERSONA_RUT=E_RUT or E.PERSONA_RUT=E_RUT ) and S.ESTADO_PAGO='A' or  S.ESTADO_PAGO='R'; 
  ID_OPERACION := 2;

END IF;
EXCEPTION

WHEN NOT_LOGGED_ON THEN
DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
ID_OPERACION := 5;
WHEN VALUE_ERROR THEN
DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
ID_OPERACION := 6;
END LISTAR_PAGOS_USUARIO;






-- funcion para simular el exito o el fracaso de un pago con el banco
create or replace function exito_pago(porcentaje IN NUMBER)
return number
 IS 
 exito NUMBER(11,2);
begin
  select (case  WHEN round(DBMS_RANDOM.VALUE (0, 100)) >porcentaje THEN 1  ELSE 0  END ) INTO exito from dual;
   RETURN(exito); 
end;




create or replace PROCEDURE LISTAR_RESERVAS_USUARIO(E_RUT IN USUARIO.PERSONA_RUT%type, ID_OPERACION out number,salida out sys_refcursor)
IS
isDueno INTEGER;
count_usuario INTEGER;
BEGIN
SELECT count(*) into count_usuario from PERSONA where RUT= E_RUT ;
IF  count_usuario = 0 THEN
  ID_OPERACION := 1;
  DBMS_OUTPUT.PUT_LINE('NO EXISTE EL RUT');
ELSE
open salida for SELECT 
S.ID ID,
S.HORA_ENTRADA HORA_ENTRADA,
S.HORA_SALIDA HORA_SALIDA,
S.TOTAL TOTAL,
S.FECHA FECHA,
S.AUTO_PATENTE AUTO_PATENTE,
U.CORREO CORREO,
U.TELEFONO TELEFONO,
P.NOMBRE NOMBRE,
P.AP_PATERNO AP_PATERNO,
P.AP_MATERNO AP_MATERNO from SERVICIO S
JOIN AUTO A 
ON A.PATENTE =S.AUTO_PATENTE
JOIN HORARIO H
ON H.ID_HORARIO=S.HORARIO_ID
JOIN ESTACIONAMIENTO E 
ON H.ESTACIONAMIENTO_ID=E.ID
JOIN PERSONA P
ON E.PERSONA_RUT=P.RUT
JOIN USUARIO U ON
U.PERSONA_RUT = P.RUT
where  A.PERSONA_RUT=E_RUT and S.ESTADO!=1;
  ID_OPERACION := 2;

END IF;
EXCEPTION

WHEN NOT_LOGGED_ON THEN
DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
ID_OPERACION := 5;
WHEN VALUE_ERROR THEN
DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
ID_OPERACION := 6;
END LISTAR_RESERVAS_USUARIO;


create or replace PROCEDURE ELIMINAR_RESERVA(   P_ID_SERVICIO        SERVICIO.ID%type ,
                                                P_PERSONA_RUT      ESTACIONAMIENTO.PERSONA_RUT%type ,
                                                ID_OPERACION out number)
IS
rol_user NUMBER(8,2);
count_servicio INTEGER;
hora_inicio DATE;
is_dueno INTEGER;
BEGIN

SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;

SELECT count(*) into count_servicio from servicio  where ID =  P_ID_SERVICIO;



IF rol_user != 1 THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 0;  
ELSIF count_servicio = 0 THEN
  DBMS_OUTPUT.PUT_LINE('NO EXISTE  LA RESERVA QUE DESEA ELIMINAR ');
  ID_OPERACION := 1; 
ELSE 
  SELECT count(*)into is_dueno from HORARIO H  
  JOIN SERVICIO S ON H.ID_HORARIO=S.HORARIO_ID 
  JOIN ESTACIONAMIENTO E ON H.ESTACIONAMIENTO_ID=E.ID 
  JOIN AUTO A ON A.PATENTE= S.AUTO_PATENTE
  where S.ID=P_ID_SERVICIO and  (E.PERSONA_RUT=P_PERSONA_RUT or A.PERSONA_RUT=P_PERSONA_RUT);

  SELECT HORA_ENTRADA into hora_inicio from servicio  where ID = P_ID_SERVICIO;
  IF (sysdate + 1 > hora_inicio) THEN
     DBMS_OUTPUT.PUT_LINE('PARA ELIMINAR UNA RESERVA DEBE HACERLO CON 24 HORAS DE ANTICIPACIÓN');
    ID_OPERACION := 3; 
  ELSIF is_dueno=0 THEN
   DBMS_OUTPUT.PUT_LINE('NO ES EL DUENO O ARRENDADOR DEL ESTACIONAMIENTO');
  ID_OPERACION := 4;
  ELSE
  UPDATE servicio
    SET ESTADO = 1
   where   ID=P_ID_SERVICIO; 
   ID_OPERACION := 2;
   END IF;
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END ELIMINAR_RESERVA;


create or replace PROCEDURE INSERTAR_RESERVA(   P_HORA_ENTRADA        SERVICIO.HORA_ENTRADA%type ,
                                                P_HORA_SALIDA        SERVICIO.HORA_SALIDA%type ,
                                                P_HORARIO_ID         SERVICIO.HORARIO_ID%type ,
                                                P_PATENTE           SERVICIO.AUTO_PATENTE%type,
                                                P_PERSONA_RUT      ESTACIONAMIENTO.PERSONA_RUT%type ,
                                                ID_OPERACION out number)
IS
rol_user NUMBER(8,2);
costo NUMBER(8,2);
count_horario INTEGER;
isOcupado INTEGER;
is_auto_reserva INTEGER;
BEGIN

SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;

SELECT count(*) into count_horario from horario  where ID_HORARIO =  P_HORARIO_ID and HORA_INICIO<=P_HORA_ENTRADA and HORA_TERMINO>=P_HORA_SALIDA;
SELECT count(*) into is_auto_reserva from horario h join ESTACIONAMIENTO E ON h.ESTACIONAMIENTO_ID= E.ID  where H.ID_HORARIO =  P_HORARIO_ID and E.PERSONA_RUT=P_PERSONA_RUT;

SELECT count(*) into isOcupado from HORARIO H  JOIN SERVICIO S ON H.ID_HORARIO=S.HORARIO_ID
 where H.ID_HORARIO =P_HORARIO_ID and S.ESTADO!=1  and (S.HORA_ENTRADA BETWEEN TO_DATE ('1900/01/01', 'yyyy/mm/dd') AND P_HORA_SALIDA) and (S.HORA_SALIDA BETWEEN P_HORA_ENTRADA and TO_DATE ('2100/01/01', 'yyyy/mm/dd'));
IF rol_user!= 0 and rol_user != 1 THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 0;  
ELSIF count_horario = 0 THEN
  DBMS_OUTPUT.PUT_LINE('NO EXISTE  EL HORARIO PARA REGISTRAR LA RESERVA ');
  ID_OPERACION := 1; 
ELSIF isOcupado !=0 THEN
    DBMS_OUTPUT.PUT_LINE('YA TIENE RESERVAR REGISTRADOS EN ESE HORARIO ');
    ID_OPERACION := 3; 
ELSIF  is_auto_reserva> 0 THEN  
  DBMS_OUTPUT.PUT_LINE('NO PUEDE AUTO RESERVARSE');
    ID_OPERACION := 4; 
ELSE 
  select TRUNC((P_HORA_SALIDA -
            P_HORA_ENTRADA ) * 24 * E.COSTO) into costo
       from HORARIO H JOIN ESTACIONAMIENTO E ON H.ESTACIONAMIENTO_ID=E.ID where ID_HORARIO=P_HORARIO_ID;
        DBMS_OUTPUT.PUT_LINE(costo);
  INSERT
    INTO SERVICIO
      (
        TOTAL ,
        ESTADO ,
        AUTO_PATENTE ,
        HORA_ENTRADA ,
        FECHA ,
        HORARIO_ID ,
        ID ,
        HORA_SALIDA,
        ESTADO_PAGO
      )
      VALUES
      (
         costo,
        0 ,
        P_PATENTE ,
        P_HORA_ENTRADA ,
        sysdate ,
        P_HORARIO_ID ,
        0 ,
        P_HORA_SALIDA,
        'P'
      );
   ID_OPERACION := 2; 
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END INSERTAR_RESERVA;



CREATE SEQUENCE servicio_sequence;

--CREACION DE TRIGGER PARA CADA VEZ QUE SE INSERTE UN DATO AVANCE EN EL ID
CREATE OR REPLACE TRIGGER servicio_on_insert
  BEFORE INSERT ON SERVICIO
  FOR EACH ROW
BEGIN
  SELECT servicio_sequence.nextval
  INTO :new.id
  FROM dual;
END;

create or replace PROCEDURE DETALLE_RESERVA(E_RUT IN USUARIO.PERSONA_RUT%type,E_ID_SERVICIO IN SERVICIO.ID%type ,ID_OPERACION out number, salida out sys_refcursor)
IS
count_servicio INTEGER;
is_dueno INTEGER;
BEGIN
SELECT count(*) into count_servicio from SERVICIO S
JOIN AUTO A 
ON A.PATENTE =S.AUTO_PATENTE
JOIN PERSONA P
ON P.RUT=A.PERSONA_RUT
JOIN USUARIO U 
ON P.RUT =U.PERSONA_RUT
where S.ID = E_ID_SERVICIO;

IF count_servicio = 0 THEN
  DBMS_OUTPUT.PUT_LINE('NO EXISTE LA RESERVA BUSCADA');
  ID_OPERACION := 1;
ELSE
  SELECT count(*)into is_dueno from HORARIO H  
  JOIN SERVICIO S ON H.ID_HORARIO=S.HORARIO_ID 
  JOIN ESTACIONAMIENTO E ON H.ESTACIONAMIENTO_ID=E.ID 
  JOIN AUTO A ON A.PATENTE= S.AUTO_PATENTE
  where S.ID=E_ID_SERVICIO and  (E.PERSONA_RUT=E_RUT or A.PERSONA_RUT=E_RUT);
  
  IF is_dueno = 0 THEN
   DBMS_OUTPUT.PUT_LINE('NO ES EL DUENO O ARRENDADOR DEL ESTACIONAMIENTO');
  ID_OPERACION := 4;
  ELSE 
  open salida for SELECT 
  S.ID ID,
  S.HORA_ENTRADA HORA_ENTRADA,
  S.HORA_SALIDA HORA_SALIDA,
  S.TOTAL TOTAL,
  S.FECHA FECHA,
  S.AUTO_PATENTE AUTO_PATENTE,
  U.CORREO CORREO,
  U.TELEFONO TELEFONO,
  P.NOMBRE NOMBRE,
  P.AP_PATERNO AP_PATERNO,
  P.AP_MATERNO AP_MATERNO from SERVICIO S
  JOIN AUTO A 
  ON A.PATENTE =S.AUTO_PATENTE
  JOIN PERSONA P
  ON P.RUT=A.PERSONA_RUT
  JOIN USUARIO U 
  ON P.RUT =U.PERSONA_RUT
  where S.ID = E_ID_SERVICIO;
    ID_OPERACION := 2;
  END IF;
END IF;
EXCEPTION

WHEN NOT_LOGGED_ON THEN
DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
ID_OPERACION := 5;
WHEN VALUE_ERROR THEN
DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
ID_OPERACION := 6;
END DETALLE_RESERVA;



create or replace PROCEDURE LISTAR_HORARIO_ESTA(E_RUT IN USUARIO.PERSONA_RUT%type,
                                                E_ESTA IN ESTACIONAMIENTO.ID%type,
                                               ID_OPERACION out number, salida out sys_refcursor)
IS
count_esta INTEGER;
isDueno INTEGER;
BEGIN
SELECT count(*) into count_esta from ESTACIONAMIENTO where ID =E_ESTA;
IF  count_esta > 0 THEN
 open salida for SELECT  H.FECHA, H.HORA_TERMINO, H.HORA_INICIO , H.ID_HORARIO , 
(CASE WHEN S.ESTADO  = 1 THEN null ELSE S.HORA_SALIDA  END) as HORA_SALIDA  ,
(CASE WHEN S.ESTADO  = 1 THEN null ELSE S.HORA_ENTRADA  END) as HORA_ENTRADA ,
(CASE WHEN S.ESTADO  = 1 THEN null ELSE S.ID  END) ID from 
ESTACIONAMIENTO E  
JOIN HORARIO H ON E.ID = H.ESTACIONAMIENTO_ID
 LEFT  JOIN SERVICIO S ON S.HORARIO_ID=H.ID_HORARIO
 where H.ESTACIONAMIENTO_ID=E_ESTA  and H.ESTADO!=1 order by H.ID_HORARIO  ;
  ID_OPERACION := 1;
ELSE 
  ID_OPERACION := 4;
    DBMS_OUTPUT.PUT_LINE('NO EXISTE EL ESTACIONAMIENTO');
END IF;
EXCEPTION

WHEN NOT_LOGGED_ON THEN
DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
ID_OPERACION := 5;
WHEN VALUE_ERROR THEN
DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
ID_OPERACION := 6;
END LISTAR_HORARIO_ESTA;


create or replace PROCEDURE ELIMINAR_ESTA(           P_ID_ESTA ESTACIONAMIENTO.ID%type,
                                                     P_PERSONA_RUT PERSONA.RUT%type,
                                                     ID_OPERACION out number)
IS
rol_user NUMBER(8,2);
count_esta INTEGER;
BEGIN

SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;


SELECT count(*) into count_esta from ESTACIONAMIENTO where ID= P_ID_ESTA and PERSONA_RUT=P_PERSONA_RUT ;


IF rol_user != 0 and rol_user != 1   THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 0; 

ELSIF count_esta = 0 THEN
  DBMS_OUTPUT.PUT_LINE('NO EXISTE El ESTACIONAMIENTO QUE QUIERE SER ELIMINADO');
  ID_OPERACION := 2; 
ELSE 
  UPDATE ESTACIONAMIENTO set ELIMINADO=1 where ID=P_ID_ESTA;
   ID_OPERACION := 3; 
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END ELIMINAR_ESTA;









create or replace PROCEDURE UPDATE_AUTO(  P_PATENTE     AUTO.PATENTE%type ,
                                            P_COLOR       AUTO.COLOR%type DEFAULT NULL ,
                                            P_MARCA       AUTO.MARCA%type ,
                                            P_MOTOR       AUTO.MOTOR%type DEFAULT NULL ,
                                            P_PERSONA_RUT AUTO.PERSONA_RUT%type ,
                                            P_CHASIS      AUTO.CHASIS%type DEFAULT NULL ,
                                            ID_OPERACION out number
                                                                                   )
IS
count_patente INTEGER;
rol_user NUMBER(8,2);
BEGIN

SELECT COUNT(*) INTO count_patente FROM AUTO WHERE PATENTE = P_PATENTE;
SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;

IF count_patente = 0 THEN
  DBMS_OUTPUT.PUT_LINE('EL AUTO NO SE ENCUENTRA REGISTRADO EN LA BASE DE DATOS');
  ID_OPERACION := 0; 
ELSIF rol_user != 0 and rol_user != 1  THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 1; 
ELSE 
 UPDATE AUTO SET COLOR = p_COLOR , MARCA= p_MARCA, MOROT =p_MOTOR ,CHASIS=p_CHASIS WHERE PATENTE= P_PATENTE;

   ID_OPERACION := 2; 
END IF;


EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END UPDATE_AUTO;




create or replace PROCEDURE ELIMINAR_AUTO(          P_ID_AUTO AUTO.PATENTE%type,
                                                     P_PERSONA_RUT PERSONA.RUT%type,
                                                     ID_OPERACION out number)
IS
rol_user NUMBER(8,2);
count_auto INTEGER;
BEGIN

SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;


SELECT count(*) into count_auto from auto where auto.PATENTE= P_ID_AUTO and auto.persona_rut=P_PERSONA_RUT ;


IF rol_user != 0 and rol_user != 1 THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 0; 

ELSIF count_auto = 0 THEN
  DBMS_OUTPUT.PUT_LINE('NO EXISTE El AUTO QUE QUIERE SER ELIMINADO');
  ID_OPERACION := 2; 
ELSE 
  UPDATE AUTO set ELIMINADO=1 where PATENTE=P_ID_AUTO;
   ID_OPERACION := 3; 
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END ELIMINAR_AUTO;



create or replace PROCEDURE LISTAR_AUTO_USUARIO(E_RUT IN USUARIO.PERSONA_RUT%type, ID_OPERACION out number, salida out sys_refcursor)
IS
count_usuario INTEGER;
BEGIN
SELECT count(*) into count_usuario from PERSONA where RUT= E_RUT ;
IF  count_usuario = 1 THEN
 open salida for SELECT  A.PATENTE,A.MARCA , A.COLOR, A.MOTOR , A.CHASIS from AUTO A  JOIN PERSONA P ON A.PERSONA_RUT = P.RUT
 where  A.PERSONA_RUT= E_RUT and A.ELIMINADO=0;
  ID_OPERACION := 1;
ELSE 
  ID_OPERACION := 4;
    DBMS_OUTPUT.PUT_LINE('NO EXISTE EL RUT');
END IF;
EXCEPTION

WHEN NOT_LOGGED_ON THEN
DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
ID_OPERACION := 5;
WHEN VALUE_ERROR THEN
DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
ID_OPERACION := 6;
END LISTAR_AUTO_USUARIO;


create or replace PROCEDURE UPDATE_ROL( P_PERSONA_RUT PERSONA.RUT%type,
                                        ID_OPERACION out number)
IS
rol_user NUMBER(8,2);
count_usuario INTEGER;
BEGIN


SELECT count(*) into count_usuario from PERSONA where RUT= P_PERSONA_RUT;



IF count_usuario = 1 THEN

  SELECT  r.ID_ROL into rol_user
  FROM usuario u , rol r
  WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;
  
  IF rol_user = 1 THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO YA TIENE EL PERFIL DE DUEÑO');
  ID_OPERACION := 2;
  
  ELSE 
    UPDATE usuario set ROL_ID=1 where PERSONA_RUT=PERSONA_RUT;
     ID_OPERACION := 3;
  END IF;
ELSE   
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO EXISTE');
  ID_OPERACION := 1;
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END UPDATE_ROL;







create or replace PROCEDURE LISTAR_ESTA_USUARIO(E_RUT IN USUARIO.PERSONA_RUT%type, ID_OPERACION out number, salida out sys_refcursor)
IS
count_usuario INTEGER;
BEGIN
SELECT count(*) into count_usuario from PERSONA where RUT= E_RUT ;
IF  count_usuario = 1 THEN
 open salida for SELECT  e.ID,e.costo, e.LATITUD, e.LOGITUD, e.COMUNA_ID , e.ESTADO ,(select count(*) from horario where ESTADO!=1 and ESTACIONAMIENTO_ID =E.ID )as horarios from HORARIO H RIGHT JOIN ESTACIONAMIENTO E ON H.ESTACIONAMIENTO_ID = E.ID
 where  e.PERSONA_RUT= E_RUT and  e.ELIMINADO=0  GROUP BY e.costo , e.ID, e.LATITUD, e.LOGITUD, e.COMUNA_ID , e.ESTADO HAVING COUNT(H.ESTADO) != 1 order by E.ID ;
  ID_OPERACION := 1;
ELSE 
  ID_OPERACION := 4;
    DBMS_OUTPUT.PUT_LINE('NO EXISTE EL RUT');
END IF;
EXCEPTION

WHEN NOT_LOGGED_ON THEN
DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
ID_OPERACION := 5;
WHEN VALUE_ERROR THEN
DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
ID_OPERACION := 6;
END LISTAR_ESTA_USUARIO;


create or replace PROCEDURE LOGIN_LISTAR_USUARIO(E_CORREO IN USUARIO.CORREO%TYPE, E_PW IN USUARIO.PASSWORD%TYPE, respuesta out number, salida out sys_refcursor)
as
x INTEGER;
BEGIN
SELECT count(*) INTO x from usuario u
WHERE u.correo = E_CORREO and  u.PASSWORD=E_PW and u.ROL_ID = 2;
IF x = 1 THEN
  respuesta :=1;
  open salida for
  SELECT  u.PERSONA_RUT,  p.DIV,  p.NOMBRE, p.AP_PATERNO, p.AP_MATERNO, u.CORREO, u.TELEFONO, u.estado
  FROM persona p 
JOIN usuario u ON u.persona_rut= p.rut 
JOIN rol r ON u.ROL_ID = r.id_rol
WHERE  r.ID_ROL!=2;

ELSE
  respuesta:=-1;
end if;

END LOGIN_LISTAR_USUARIO;





create or replace function login(l_correo in varchar2,l_password in varchar2)
return varchar2
as
  match_count number;
begin
  select count(*)
    into match_count
    from usuario
    where correo=l_correo
    and password=l_password and ESTADO=1;
  if match_count = 0 then
    return'false';
  elsif match_count = 1 then
    return 'true';
  end if;
end;


create or replace function calcular_rate(id_user IN NUMBER)
return number
 IS 
 rate NUMBER(11,2);
begin
  select NVL(round(SUM(c.PUNTOS)/ count(*)), -1) into rate from usuario u join CALIFIC c on u.ID= c.USUARIO_ID and c.REALIZADO=1 and u.ID=id_user;

   RETURN(rate); 
end;


create or replace PROCEDURE GET_USUARIO(E_CORREO in varchar2 ,salida out sys_refcursor)
AS
BEGIN
OPEN salida FOR
SELECT 
      u.PERSONA_RUT, 
      p.DIV, 
      p.NOMBRE,
      p.AP_PATERNO,
      p.AP_MATERNO, 
      u.CORREO, 
      u.TELEFONO,  
      p.SEXO,  
      p.NUM_TARJETA,
      p.CV,
      r.ID_ROL,
      calcular_rate(u.ID)
      
      
      

FROM persona p 
JOIN usuario u ON u.persona_rut= p.rut 
JOIN rol r ON u.ROL_ID = r.id_rol 
WHERE u.correo = E_CORREO;
end;







create or replace function VALIDARUT
(p_dig_rut in VARCHAR2,
p_rut in VARCHAR2)
return VARCHAR2
is

v_rut varchar2(10) := substr(lpad(p_rut,9,'0'),1,10);
v_res number(2);
v_val varchar2(10);
v_dig varchar2(1);
begin
v_res := 11 - mod(to_number(substr(v_rut,1,1)) * 4 + to_number(substr(v_rut,2,1)) * 3 + to_number(substr(v_rut,3,1)) * 2 + to_number(substr(v_rut,4,1)) * 7 + to_number(substr(v_rut,5,1)) * 6 + to_number(substr(v_rut,6,1)) * 5 + to_number(substr(v_rut,7,1)) * 4 + to_number(substr(v_rut,8,1)) * 3 + to_number(substr(v_rut,9,1)) * 2, 11); 
if v_res = 10 then
v_dig := 'K';
elsif v_res = 11 then
v_dig := '0';
else
v_dig := ltrim(v_res);
end if;

if v_dig = p_dig_rut then
v_val:='SI';
else
v_val:='NO';
end if;

return v_val;
exception
when others then
return 'NO';

end VALIDARUT;


create or replace PROCEDURE INSERTAR_PERSONA_Y_USUARIO(E_RUT  PERSONA.RUT%TYPE, DIV PERSONA.DIV%TYPE, 
                                                      FECHA_NAC PERSONA.FECHA_NAC%TYPE, NOMBRE  PERSONA.NOMBRE%TYPE, 
                                                      AP_PATERNO  PERSONA.AP_PATERNO%TYPE, AP_MATERNO PERSONA.AP_MATERNO%TYPE,
                                                      SEXO  PERSONA.SEXO%TYPE, CV PERSONA.CV%TYPE, NUM_TARJETA  PERSONA.NUM_TARJETA%TYPE,
                                                      --AQUI COMIENZAN LOS DATOS DE USUARIO
                                                      E_CORREO  USUARIO.CORREO%TYPE,
                                                      PASSWORD  USUARIO.PASSWORD%TYPE, TELEFONO USUARIO.TELEFONO%TYPE,
                                                      ESTADO  USUARIO.ESTADO%TYPE, ROL_ID USUARIO.ROL_ID%TYPE, ID_OPERACION out number)
is
count_rut INTEGER;
count_correo INTEGER;
emailregexp constant varchar2(100) := '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$';
BEGIN

SELECT COUNT(*) INTO count_rut FROM PERSONA WHERE RUT = E_RUT;
SELECT COUNT(*) INTO count_correo FROM USUARIO WHERE CORREO = E_CORREO;

IF count_rut  > 0 THEN
  DBMS_OUTPUT.PUT_LINE('EL RUT YA SE ENCUENTRA REGISTRADO EN LA BASE DE DATOS');
  ID_OPERACION := 0; 
ELSIF count_correo > 0 THEN
  DBMS_OUTPUT.PUT_LINE('EL CORREO YA SE ENCUENTRA REGISTRADO EN LA BASE DE DATOS');
  ID_OPERACION := 1; 
ELSIF NOT regexp_like(E_CORREO,emailregexp) THEN
  DBMS_OUTPUT.PUT_LINE('EL CORREO TIENE UN FORMATO INVALIDO');
  ID_OPERACION := 7;
ELSIF VALIDARUT(DIV, TO_CHAR(E_RUT)) ='NO' THEN
  DBMS_OUTPUT.PUT_LINE('EL RUT TIENE UN FORMATO INVALIDO');
  ID_OPERACION := 8;
ELSIF SEXO != 'M' and SEXO != 'F' THEN
  DBMS_OUTPUT.PUT_LINE('INCORRECTO FORMATO DE SEXO');
  ID_OPERACION := 2;
ELSIF ROL_ID !=0  And ROL_ID != 1 THEN
  DBMS_OUTPUT.PUT_LINE('INCORRECTO ROL DEL USUARIO');
  ID_OPERACION := 3;
ELSE 
  INSERT INTO PERSONA VALUES(E_RUT, DIV, FECHA_NAC, NOMBRE, AP_PATERNO, AP_MATERNO, SEXO, CV, NUM_TARJETA);  
  INSERT INTO USUARIO VALUES(0, E_CORREO, PASSWORD, TELEFONO, ESTADO, E_RUT, ROL_ID);
  ID_OPERACION := 4; 
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END INSERTAR_PERSONA_Y_USUARIO;



CREATE SEQUENCE user_sequence;

--CREACION DE TRIGGER PARA CADA VEZ QUE SE INSERTE UN DATO AVANCE EN EL ID
CREATE OR REPLACE TRIGGER user_on_insert
  BEFORE INSERT ON USUARIO
  FOR EACH ROW
BEGIN
  SELECT user_sequence.nextval
  INTO :new.id
  FROM dual;
END;





create or replace PROCEDURE INSERTAR_AUTO(  P_PATENTE     AUTO.PATENTE%type ,
                                            P_COLOR       AUTO.COLOR%type DEFAULT NULL ,
                                            P_MARCA       AUTO.MARCA%type ,
                                            P_MOTOR       AUTO.MOTOR%type DEFAULT NULL ,
                                            P_PERSONA_RUT AUTO.PERSONA_RUT%type ,
                                            P_CHASIS      AUTO.CHASIS%type DEFAULT NULL ,
                                            ID_OPERACION out number
                                                                                   )
IS
count_patente INTEGER;
rol_user NUMBER(8,2);
BEGIN

SELECT COUNT(*) INTO count_patente FROM AUTO WHERE PATENTE = P_PATENTE;
SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;

IF count_patente > 0 THEN
  DBMS_OUTPUT.PUT_LINE('EL AUTO YA SE ENCUENTRA REGISTRADO EN LA BASE DE DATOS');
  ID_OPERACION := 0; 
ELSIF rol_user != 0 and rol_user != 1  THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 1; 
ELSE 
 INSERT INTO AUTO (
        PATENTE ,
        COLOR ,
        MARCA ,
        MOTOR ,
        PERSONA_RUT ,
        CHASIS,
        ELIMINADO
      )
      VALUES
      (
        UPPER(p_PATENTE ),
        p_COLOR ,
        p_MARCA ,
        p_MOTOR ,
        p_PERSONA_RUT ,
        p_CHASIS,
        0
      );
   ID_OPERACION := 2; 
END IF;


EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END INSERTAR_AUTO;



CREATE SEQUENCE estacionamiento_sequence;

create or replace TRIGGER estacionamiento_on_insert
  BEFORE INSERT ON ESTACIONAMIENTO
  FOR EACH ROW
BEGIN
  SELECT estacionamiento_sequence.nextval
  INTO :new.id
  FROM dual;
END;

create or replace PROCEDURE INSERTAR_ESTACIONAMIENTO(P_COSTO      ESTACIONAMIENTO.COSTO%type ,
                                                     P_COMUNA_ID   ESTACIONAMIENTO.COMUNA_ID%type ,
                                                     P_PERSONA_RUT ESTACIONAMIENTO.PERSONA_RUT%type ,
                                                    
                                                     P_LOGITUD     ESTACIONAMIENTO.LOGITUD%type ,
                                                     P_LATITUD   ESTACIONAMIENTO.LATITUD%type ,
                                                     P_ESTADO ESTACIONAMIENTO.ESTADO%type,
                                                     ID_OPERACION out number,
                                                     ID_ESTACIONAMIENTO out number,
                                                     NOMBRE_COMUNA out COMUNA.NOMBRE%type)
IS
rol_user NUMBER(8,2);
count_comuna INTEGER;
id_number INTEGER;
BEGIN

SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;

SELECT count(*) into count_comuna from comuna where comuna.ID= P_COMUNA_ID ;

IF rol_user != 1 THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 0; 
ELSIF P_COSTO < 0 THEN
  DBMS_OUTPUT.PUT_LINE('EL COSTO DEBE SER POSITIVO');
  ID_OPERACION := 1; 
ELSIF count_comuna = 0 THEN
  DBMS_OUTPUT.PUT_LINE('NO EXISTE LA COMUNA REGISTRADA');
  ID_OPERACION := 2; 
ELSE 
 INSERT
    INTO ESTACIONAMIENTO
      (
      
        ID ,
        ESTADO ,
        COSTO ,
        COMUNA_ID ,
        PERSONA_RUT ,
        LOGITUD ,
        LATITUD,
        ELIMINADO
      )
      VALUES
      (
        0,
        P_ESTADO,
        P_COSTO,
        P_COMUNA_ID,
        P_PERSONA_RUT,
        P_LOGITUD,
        P_LATITUD,
        0
      ) return ID into id_number;
   SELECT nombre into  NOMBRE_COMUNA from comuna where comuna.ID= P_COMUNA_ID  ;

   ID_ESTACIONAMIENTO:=id_number;
   ID_OPERACION := 3; 
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END INSERTAR_ESTACIONAMIENTO;



create or replace PROCEDURE HABILITAR_ESTACIONAMIENTO(
                                                     P_ID_ESTACIONAMIENTO ESTACIONAMIENTO.ID%type,
                                                     P_PERSONA_RUT PERSONA.RUT%type,
                                                     ID_OPERACION out number)
IS
rol_user NUMBER(8,2);
count_estacionamiento INTEGER;
BEGIN

SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;


SELECT count(*) into count_estacionamiento from estacionamiento where estacionamiento.ID= P_ID_ESTACIONAMIENTO and estacionamiento.persona_rut=P_PERSONA_RUT ;


IF rol_user != 1  THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 0; 

ELSIF count_estacionamiento = 0 THEN
  DBMS_OUTPUT.PUT_LINE('NO EXISTE El ESTACIONAMIENTO QUE QUIERE SER ACTUALIZADO');
  ID_OPERACION := 2; 
ELSE 
  UPDATE ESTACIONAMIENTO set ESTADO=1 where ID=P_ID_ESTACIONAMIENTO;
   ID_OPERACION := 3; 
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END HABILITAR_ESTACIONAMIENTO;



create or replace PROCEDURE DESABILITAR_ESTACIONAMIENTO(
                                                     P_ID_ESTACIONAMIENTO ESTACIONAMIENTO.ID%type,
                                                     P_PERSONA_RUT PERSONA.RUT%type,
                                                     ID_OPERACION out number)
IS
rol_user NUMBER(8,2);
count_estacionamiento INTEGER;
BEGIN

SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;


SELECT count(*) into count_estacionamiento from estacionamiento where estacionamiento.ID= P_ID_ESTACIONAMIENTO and estacionamiento.persona_rut=P_PERSONA_RUT ;


IF rol_user != 1  THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 0; 

ELSIF count_estacionamiento = 0 THEN
  DBMS_OUTPUT.PUT_LINE('NO EXISTE El ESTACIONAMIENTO QUE QUIERE SER ACTUALIZADO');
  ID_OPERACION := 2; 
ELSE 
  UPDATE ESTACIONAMIENTO set ESTADO=0 where ID=P_ID_ESTACIONAMIENTO;
   ID_OPERACION := 3; 
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END DESABILITAR_ESTACIONAMIENTO;




CREATE SEQUENCE horario_sequence;

create or replace TRIGGER horario_on_insert
  BEFORE INSERT ON HORARIO
  FOR EACH ROW
BEGIN
  SELECT horario_sequence.nextval
  INTO :new.id_horario
  FROM dual;
END;


create or replace PROCEDURE INSERTAR_HORARIO(   P_HORA_TERMINO        HORARIO.HORA_TERMINO%type ,
                                                P_HORA_INICIO        HORARIO.HORA_INICIO%type ,
                                                P_ESTACIONAMIENTO_ID  HORARIO.ESTACIONAMIENTO_ID%type ,
                                                P_PERSONA_RUT      ESTACIONAMIENTO.PERSONA_RUT%type ,
                                                ID_OPERACION out number)
IS
rol_user NUMBER(8,2);
count_estacionamiento INTEGER;
isOcupado INTEGER;
BEGIN

SELECT  r.ID_ROL into rol_user
FROM usuario u , rol r
WHERE u.ROL_ID = r.ID_ROL  and u.PERSONA_RUT = P_PERSONA_RUT;

SELECT count(*) into count_estacionamiento from estacionamiento where estacionamiento.ID=  P_ESTACIONAMIENTO_ID;

SELECT count(*) into isOcupado from ESTACIONAMIENTO E  JOIN HORARIO H ON E.ID = H.ESTACIONAMIENTO_ID
 where E.ID =P_ESTACIONAMIENTO_ID  and H.ESTADO!=1  and (H.HORA_INICIO BETWEEN TO_DATE ('1900/01/01', 'yyyy/mm/dd') AND P_HORA_TERMINO) and (H.HORA_TERMINO BETWEEN P_HORA_INICIO and TO_DATE ('2100/01/01', 'yyyy/mm/dd'));
IF rol_user != 1 THEN
  DBMS_OUTPUT.PUT_LINE('EL USUARIO NO TIENE PERMISOS PARA ESTA SOLICITUD');
  ID_OPERACION := 0;  
ELSIF count_estacionamiento = 0 THEN
  DBMS_OUTPUT.PUT_LINE('NO EXISTE  EL ESTACIONAMIENTO PARA REGISTRAR EL HORARIO ');
  ID_OPERACION := 1; 
ELSIF isOcupado > 0 THEN
    DBMS_OUTPUT.PUT_LINE('YA TIENE BLOQUES REGISTRADOS EN ESE HORARIO ');
    ID_OPERACION := 3; 
    
ELSIF (SYSDATE-1)>=P_HORA_INICIO THEN
    DBMS_OUTPUT.PUT_LINE('NO PUEDE REGISTRAR ESTE HORARIO EN UN DIA INFERIOR A LA FECHA ACTUAL ');
    ID_OPERACION := 4; 
ELSE 
 INSERT
  INTO HORARIO
      (
        ID_HORARIO,
        FECHA,
        HORA_TERMINO ,
        HORA_INICIO ,
        ESTACIONAMIENTO_ID,
        ESTADO
      )
      VALUES
      (
        0,
        SYSDATE,
        P_HORA_TERMINO ,
        P_HORA_INICIO ,
        P_ESTACIONAMIENTO_ID,
        0
      );
   ID_OPERACION := 2; 
END IF;
EXCEPTION

  WHEN NOT_LOGGED_ON THEN
  DBMS_OUTPUT.PUT_LINE('El programa efectuó una llamada a Oracle sin estar conectado');
  ID_OPERACION := 5;
  WHEN VALUE_ERROR THEN
  DBMS_OUTPUT.PUT_LINE('Uno de los datos ingresados no tiene el formato correcto');
  ID_OPERACION := 6;
END INSERTAR_HORARIO;


INSERT INTO ROL VALUES(0,'Cliente');
INSERT INTO ROL VALUES(1,'Dueno');
INSERT INTO ROL VALUES(2,'Admin');
INSERT INTO ROL VALUES(3,'AdminF');

INSERT INTO PERSONA VALUES(18975459,'0',SYSDATE,'Francisco','Labra','Seguel','M','5501A224D50',114324950);
INSERT INTO PERSONA VALUES(12345678,'K',SYSDATE,'Manuel','Urrejola','Arriaga','M','NN3KK5D53',4455230);
INSERT INTO PERSONA VALUES(6546893,'2',SYSDATE,'Nicole','Flores','Cadenas','F','94947249FF',7624645);
INSERT INTO PERSONA VALUES(21404591,'5',SYSDATE,'Juanito','Pérz','Del Arce','M','94947249FF',2343244);

INSERT INTO USUARIO VALUES (0,'cliente@gmail.com','123',5291593,1,18975459,0);
INSERT INTO USUARIO VALUES (1,'dueno@gmail.com','123',55511123,1,12345678,1);
INSERT INTO USUARIO VALUES (2,'admin@gmail.com','123',98239403,1,6546893,2);
INSERT INTO USUARIO VALUES (3,'financiamiento@gmail.com','123',21404591,1,21404591,3);



INSERT INTO REGION  VALUES (1,'Arica y Parinacota','XV');
INSERT INTO REGION  VALUES (2,'Tarapacá','I');
INSERT INTO REGION  VALUES (3,'Antofagasta','II');
INSERT INTO REGION  VALUES (4,'Atacama','III');
INSERT INTO REGION  VALUES (5,'Coquimbo','IV');
INSERT INTO REGION  VALUES (6,'Valparaiso','V');
INSERT INTO REGION  VALUES (7,'Metropolitana de Santiago','RM');
INSERT INTO REGION  VALUES (8,'Libertador General Bernardo OHiggins','VI');
INSERT INTO REGION  VALUES (9,'Maule','VII');
INSERT INTO REGION  VALUES (10,'Biobío','VIII');
INSERT INTO REGION  VALUES (11,'La Araucanía','IX');
INSERT INTO REGION  VALUES (12,'Los Ríos','XIV');
INSERT INTO REGION  VALUES (13,'Los Lagos','X');
INSERT INTO REGION  VALUES (14,'Aisén del General Carlos Ibáñez del Campo','XI');
INSERT INTO REGION  VALUES (15,'Magallanes y de la Antártica Chilena','XII');


INSERT INTO PROVINCIA VALUES (1,'Arica',1);
INSERT INTO PROVINCIA VALUES (2,'Parinacota',1);
INSERT INTO PROVINCIA VALUES (3,'Iquique',2);
INSERT INTO PROVINCIA VALUES (4,'El Tamarugal',2);
INSERT INTO PROVINCIA VALUES (5,'Antofagasta',3);
INSERT INTO PROVINCIA VALUES (6,'El Loa',3);
INSERT INTO PROVINCIA VALUES (7,'Tocopilla',3);
INSERT INTO PROVINCIA VALUES (8,'Chañaral',4);
INSERT INTO PROVINCIA VALUES (9,'Copiapó',4);
INSERT INTO PROVINCIA VALUES (10,'Huasco',4);
INSERT INTO PROVINCIA VALUES (11,'Choapa',5);
INSERT INTO PROVINCIA VALUES (12,'Elqui',5);
INSERT INTO PROVINCIA VALUES (13,'Limarí',5);
INSERT INTO PROVINCIA VALUES (14,'Isla de Pascua',6);
INSERT INTO PROVINCIA VALUES (15,'Los Andes',6);
INSERT INTO PROVINCIA VALUES (16,'Petorca',6);
INSERT INTO PROVINCIA VALUES (17,'Quillota',6);
INSERT INTO PROVINCIA VALUES (18,'San Antonio',6);
INSERT INTO PROVINCIA VALUES (19,'San Felipe de Aconcagua',6);
INSERT INTO PROVINCIA VALUES (20,'Valparaiso',6);
INSERT INTO PROVINCIA VALUES (21,'Chacabuco',7);
INSERT INTO PROVINCIA VALUES (22,'Cordillera',7);
INSERT INTO PROVINCIA VALUES (23,'Maipo',7);
INSERT INTO PROVINCIA VALUES (24,'Melipilla',7);
INSERT INTO PROVINCIA VALUES (25,'Santiago',7);
INSERT INTO PROVINCIA VALUES (26,'Talagante',7);
INSERT INTO PROVINCIA VALUES (27,'Cachapoal',8);
INSERT INTO PROVINCIA VALUES (28,'Cardenal Caro',8);
INSERT INTO PROVINCIA VALUES (29,'Colchagua',8);
INSERT INTO PROVINCIA VALUES (30,'Cauquenes',9);
INSERT INTO PROVINCIA VALUES (31,'Curicó',9);
INSERT INTO PROVINCIA VALUES (32,'Linares',9);
INSERT INTO PROVINCIA VALUES (33,'Talca',9);
INSERT INTO PROVINCIA VALUES (34,'Arauco',10);
INSERT INTO PROVINCIA VALUES (35,'Bio Bío',10);
INSERT INTO PROVINCIA VALUES (36,'Concepción',10);
INSERT INTO PROVINCIA VALUES (37,'Ñuble',10);
INSERT INTO PROVINCIA VALUES (38,'Cautín',11);
INSERT INTO PROVINCIA VALUES (39,'Malleco',11);
INSERT INTO PROVINCIA VALUES (40,'Valdivia',12);
INSERT INTO PROVINCIA VALUES (41,'Ranco',12);
INSERT INTO PROVINCIA VALUES (42,'Chiloé',13);
INSERT INTO PROVINCIA VALUES (43,'Llanquihue',13);
INSERT INTO PROVINCIA VALUES (44,'Osorno',13);
INSERT INTO PROVINCIA VALUES (45,'Palena',13);
INSERT INTO PROVINCIA VALUES (46,'Aisén',14);
INSERT INTO PROVINCIA VALUES (47,'Capitán Prat',14);
INSERT INTO PROVINCIA VALUES (48,'Coihaique',14);
INSERT INTO PROVINCIA VALUES (49,'General Carrera',14);
INSERT INTO PROVINCIA VALUES (50,'Antártica Chilena',15);
INSERT INTO PROVINCIA VALUES (51,'Magallanes',15);
INSERT INTO PROVINCIA VALUES (52,'Tierra del Fuego',15);
INSERT INTO PROVINCIA VALUES (53,'Última Esperanza',15);




INSERT INTO COMUNA VALUES (1,'Arica',1);
INSERT INTO COMUNA VALUES (2,'Camarones',1);
INSERT INTO COMUNA VALUES (3,'General Lagos',2);
INSERT INTO COMUNA VALUES (4,'Putre',2);
INSERT INTO COMUNA VALUES (5,'Alto Hospicio',3);
INSERT INTO COMUNA VALUES (6,'Iquique',3);
INSERT INTO COMUNA VALUES (7,'Camiña',4);
INSERT INTO COMUNA VALUES (8,'Colchane',4);
INSERT INTO COMUNA VALUES (9,'Huara',4);
INSERT INTO COMUNA VALUES (10,'Pica',4);
INSERT INTO COMUNA VALUES (11,'Pozo Almonte',4);
INSERT INTO COMUNA VALUES (12,'Antofagasta',5);
INSERT INTO COMUNA VALUES (13,'Mejillones',5);
INSERT INTO COMUNA VALUES (14,'Sierra Gorda',5);
INSERT INTO COMUNA VALUES (15,'Taltal',5);
INSERT INTO COMUNA VALUES (16,'Calama',6);
INSERT INTO COMUNA VALUES (17,'Ollague',6);
INSERT INTO COMUNA VALUES (18,'San Pedro de Atacama',6);
INSERT INTO COMUNA VALUES (19,'María Elena',7);
INSERT INTO COMUNA VALUES (20,'Tocopilla',7);
INSERT INTO COMUNA VALUES (21,'Chañaral',8);
INSERT INTO COMUNA VALUES (22,'Diego de Almagro',8);
INSERT INTO COMUNA VALUES (23,'Caldera',9);
INSERT INTO COMUNA VALUES (24,'Copiapó',9);
INSERT INTO COMUNA VALUES (25,'Tierra Amarilla',9);
INSERT INTO COMUNA VALUES (26,'Alto del Carmen',10);
INSERT INTO COMUNA VALUES (27,'Freirina',10);
INSERT INTO COMUNA VALUES (28,'Huasco',10);
INSERT INTO COMUNA VALUES (29,'Vallenar',10);
INSERT INTO COMUNA VALUES (30,'Canela',11);
INSERT INTO COMUNA VALUES (31,'Illapel',11);
INSERT INTO COMUNA VALUES (32,'Los Vilos',11);
INSERT INTO COMUNA VALUES (33,'Salamanca',11);
INSERT INTO COMUNA VALUES (34,'Andacollo',12);
INSERT INTO COMUNA VALUES (35,'Coquimbo',12);
INSERT INTO COMUNA VALUES (36,'La Higuera',12);
INSERT INTO COMUNA VALUES (37,'La Serena',12);
INSERT INTO COMUNA VALUES (38,'Paihuaco',12);
INSERT INTO COMUNA VALUES (39,'Vicuña',12);
INSERT INTO COMUNA VALUES (40,'Combarbalá',13);
INSERT INTO COMUNA VALUES (41,'Monte Patria',13);
INSERT INTO COMUNA VALUES (42,'Ovalle',13);
INSERT INTO COMUNA VALUES (43,'Punitaqui',13);
INSERT INTO COMUNA VALUES (44,'Río Hurtado',13);
INSERT INTO COMUNA VALUES (45,'Isla de Pascua',14);
INSERT INTO COMUNA VALUES (46,'Calle Larga',15);
INSERT INTO COMUNA VALUES (47,'Los Andes',15);
INSERT INTO COMUNA VALUES (48,'Rinconada',15);
INSERT INTO COMUNA VALUES (49,'San Esteban',15);
INSERT INTO COMUNA VALUES (50,'La Ligua',16);
INSERT INTO COMUNA VALUES (51,'Papudo',16);
INSERT INTO COMUNA VALUES (52,'Petorca',16);
INSERT INTO COMUNA VALUES (53,'Zapallar',16);
INSERT INTO COMUNA VALUES (54,'Hijuelas',17);
INSERT INTO COMUNA VALUES (55,'La Calera',17);
INSERT INTO COMUNA VALUES (56,'La Cruz',17);
INSERT INTO COMUNA VALUES (57,'Limache',17);
INSERT INTO COMUNA VALUES (58,'Nogales',17);
INSERT INTO COMUNA VALUES (59,'Olmué',17);
INSERT INTO COMUNA VALUES (60,'Quillota',17);
INSERT INTO COMUNA VALUES (61,'Algarrobo',18);
INSERT INTO COMUNA VALUES (62,'Cartagena',18);
INSERT INTO COMUNA VALUES (63,'El Quisco',18);
INSERT INTO COMUNA VALUES (64,'El Tabo',18);
INSERT INTO COMUNA VALUES (65,'San Antonio',18);
INSERT INTO COMUNA VALUES (66,'Santo Domingo',18);
INSERT INTO COMUNA VALUES (67,'Catemu',19);
INSERT INTO COMUNA VALUES (68,'Llaillay',19);
INSERT INTO COMUNA VALUES (69,'Panquehue',19);
INSERT INTO COMUNA VALUES (70,'Putaendo',19);
INSERT INTO COMUNA VALUES (71,'San Felipe',19);
INSERT INTO COMUNA VALUES (72,'Santa María',19);
INSERT INTO COMUNA VALUES (73,'Casablanca',20);
INSERT INTO COMUNA VALUES (74,'Concón',20);
INSERT INTO COMUNA VALUES (75,'Juan Fernández',20);
INSERT INTO COMUNA VALUES (76,'Puchuncaví',20);
INSERT INTO COMUNA VALUES (77,'Quilpué',20);
INSERT INTO COMUNA VALUES (78,'Quintero',20);
INSERT INTO COMUNA VALUES (79,'Valparaíso',20);
INSERT INTO COMUNA VALUES (80,'Villa Alemana',20);
INSERT INTO COMUNA VALUES (81,'Viña del Mar',20);
INSERT INTO COMUNA VALUES (82,'Colina',21);
INSERT INTO COMUNA VALUES (83,'Lampa',21);
INSERT INTO COMUNA VALUES (84,'Tiltil',21);
INSERT INTO COMUNA VALUES (85,'Pirque',22);
INSERT INTO COMUNA VALUES (86,'Puente Alto',22);
INSERT INTO COMUNA VALUES (87,'San José de Maipo',22);
INSERT INTO COMUNA VALUES (88,'Buin',23);
INSERT INTO COMUNA VALUES (89,'Calera de Tango',23);
INSERT INTO COMUNA VALUES (90,'Paine',23);
INSERT INTO COMUNA VALUES (91,'San Bernardo',23);
INSERT INTO COMUNA VALUES (92,'Alhué',24);
INSERT INTO COMUNA VALUES (93,'Curacaví',24);
INSERT INTO COMUNA VALUES (94,'María Pinto',24);
INSERT INTO COMUNA VALUES (95,'Melipilla',24);
INSERT INTO COMUNA VALUES (96,'San Pedro',24);
INSERT INTO COMUNA VALUES (97,'Cerrillos',25);
INSERT INTO COMUNA VALUES (98,'Cerro Navia',25);
INSERT INTO COMUNA VALUES (99,'Conchalí',25);
INSERT INTO COMUNA VALUES (100,'El Bosque',25);
INSERT INTO COMUNA VALUES (101,'Estación Central',25);
INSERT INTO COMUNA VALUES (102,'Huechuraba',25);
INSERT INTO COMUNA VALUES (103,'Independencia',25);
INSERT INTO COMUNA VALUES (104,'La Cisterna',25);
INSERT INTO COMUNA VALUES (105,'La Granja',25);
INSERT INTO COMUNA VALUES (106,'La Florida',25);
INSERT INTO COMUNA VALUES (107,'La Pintana',25);
INSERT INTO COMUNA VALUES (108,'La Reina',25);
INSERT INTO COMUNA VALUES (109,'Las Condes',25);
INSERT INTO COMUNA VALUES (110,'Lo Barnechea',25);
INSERT INTO COMUNA VALUES (111,'Lo Espejo',25);
INSERT INTO COMUNA VALUES (112,'Lo Prado',25);
INSERT INTO COMUNA VALUES (113,'Macul',25);
INSERT INTO COMUNA VALUES (114,'Maipú',25);
INSERT INTO COMUNA VALUES (115,'Ñuñoa',25);
INSERT INTO COMUNA VALUES (116,'Pedro Aguirre Cerda',25);
INSERT INTO COMUNA VALUES (117,'Peñalolén',25);
INSERT INTO COMUNA VALUES (118,'Providencia',25);
INSERT INTO COMUNA VALUES (119,'Pudahuel',25);
INSERT INTO COMUNA VALUES (120,'Quilicura',25);
INSERT INTO COMUNA VALUES (121,'Quinta Normal',25);
INSERT INTO COMUNA VALUES (122,'Recoleta',25);
INSERT INTO COMUNA VALUES (123,'Renca',25);
INSERT INTO COMUNA VALUES (124,'San Miguel',25);
INSERT INTO COMUNA VALUES (125,'San Joaquín',25);
INSERT INTO COMUNA VALUES (126,'San Ramón',25);
INSERT INTO COMUNA VALUES (127,'Santiago',25);
INSERT INTO COMUNA VALUES (128,'Vitacura',25);
INSERT INTO COMUNA VALUES (129,'El Monte',26);
INSERT INTO COMUNA VALUES (130,'Isla de Maipo',26);
INSERT INTO COMUNA VALUES (131,'Padre Hurtado',26);
INSERT INTO COMUNA VALUES (132,'Peñaflor',26);
INSERT INTO COMUNA VALUES (133,'Talagante',26);
INSERT INTO COMUNA VALUES (134,'Codegua',27);
INSERT INTO COMUNA VALUES (135,'Coínco',27);
INSERT INTO COMUNA VALUES (136,'Coltauco',27);
INSERT INTO COMUNA VALUES (137,'Doñihue',27);
INSERT INTO COMUNA VALUES (138,'Graneros',27);
INSERT INTO COMUNA VALUES (139,'Las Cabras',27);
INSERT INTO COMUNA VALUES (140,'Machalí',27);
INSERT INTO COMUNA VALUES (141,'Malloa',27);
INSERT INTO COMUNA VALUES (142,'Mostazal',27);
INSERT INTO COMUNA VALUES (143,'Olivar',27);
INSERT INTO COMUNA VALUES (144,'Peumo',27);
INSERT INTO COMUNA VALUES (145,'Pichidegua',27);
INSERT INTO COMUNA VALUES (146,'Quinta de Tilcoco',27);
INSERT INTO COMUNA VALUES (147,'Rancagua',27);
INSERT INTO COMUNA VALUES (148,'Rengo',27);
INSERT INTO COMUNA VALUES (149,'Requínoa',27);
INSERT INTO COMUNA VALUES (150,'San Vicente de Tagua Tagua',27);
INSERT INTO COMUNA VALUES (151,'La Estrella',28);
INSERT INTO COMUNA VALUES (152,'Litueche',28);
INSERT INTO COMUNA VALUES (153,'Marchihue',28);
INSERT INTO COMUNA VALUES (154,'Navidad',28);
INSERT INTO COMUNA VALUES (155,'Peredones',28);
INSERT INTO COMUNA VALUES (156,'Pichilemu',28);
INSERT INTO COMUNA VALUES (157,'Chépica',29);
INSERT INTO COMUNA VALUES (158,'Chimbarongo',29);
INSERT INTO COMUNA VALUES (159,'Lolol',29);
INSERT INTO COMUNA VALUES (160,'Nancagua',29);
INSERT INTO COMUNA VALUES (161,'Palmilla',29);
INSERT INTO COMUNA VALUES (162,'Peralillo',29);
INSERT INTO COMUNA VALUES (163,'Placilla',29);
INSERT INTO COMUNA VALUES (164,'Pumanque',29);
INSERT INTO COMUNA VALUES (165,'San Fernando',29);
INSERT INTO COMUNA VALUES (166,'Santa Cruz',29);
INSERT INTO COMUNA VALUES (167,'Cauquenes',30);
INSERT INTO COMUNA VALUES (168,'Chanco',30);
INSERT INTO COMUNA VALUES (169,'Pelluhue',30);
INSERT INTO COMUNA VALUES (170,'Curicó',31);
INSERT INTO COMUNA VALUES (171,'Hualañé',31);
INSERT INTO COMUNA VALUES (172,'Licantén',31);
INSERT INTO COMUNA VALUES (173,'Molina',31);
INSERT INTO COMUNA VALUES (174,'Rauco',31);
INSERT INTO COMUNA VALUES (175,'Romeral',31);
INSERT INTO COMUNA VALUES (176,'Sagrada Familia',31);
INSERT INTO COMUNA VALUES (177,'Teno',31);
INSERT INTO COMUNA VALUES (178,'Vichuquén',31);
INSERT INTO COMUNA VALUES (179,'Colbún',32);
INSERT INTO COMUNA VALUES (180,'Linares',32);
INSERT INTO COMUNA VALUES (181,'Longaví',32);
INSERT INTO COMUNA VALUES (182,'Parral',32);
INSERT INTO COMUNA VALUES (183,'Retiro',32);
INSERT INTO COMUNA VALUES (184,'San Javier',32);
INSERT INTO COMUNA VALUES (185,'Villa Alegre',32);
INSERT INTO COMUNA VALUES (186,'Yerbas Buenas',32);
INSERT INTO COMUNA VALUES (187,'Constitución',33);
INSERT INTO COMUNA VALUES (188,'Curepto',33);
INSERT INTO COMUNA VALUES (189,'Empedrado',33);
INSERT INTO COMUNA VALUES (190,'Maule',33);
INSERT INTO COMUNA VALUES (191,'Pelarco',33);
INSERT INTO COMUNA VALUES (192,'Pencahue',33);
INSERT INTO COMUNA VALUES (193,'Río Claro',33);
INSERT INTO COMUNA VALUES (194,'San Clemente',33);
INSERT INTO COMUNA VALUES (195,'San Rafael',33);
INSERT INTO COMUNA VALUES (196,'Talca',33);
INSERT INTO COMUNA VALUES (197,'Arauco',34);
INSERT INTO COMUNA VALUES (198,'Cañete',34);
INSERT INTO COMUNA VALUES (199,'Contulmo',34);
INSERT INTO COMUNA VALUES (200,'Curanilahue',34);
INSERT INTO COMUNA VALUES (201,'Lebu',34);
INSERT INTO COMUNA VALUES (202,'Los Álamos',34);
INSERT INTO COMUNA VALUES (203,'Tirúa',34);
INSERT INTO COMUNA VALUES (204,'Alto Biobío',35);
INSERT INTO COMUNA VALUES (205,'Antuco',35);
INSERT INTO COMUNA VALUES (206,'Cabrero',35);
INSERT INTO COMUNA VALUES (207,'Laja',35);
INSERT INTO COMUNA VALUES (208,'Los Ángeles',35);
INSERT INTO COMUNA VALUES (209,'Mulchén',35);
INSERT INTO COMUNA VALUES (210,'Nacimiento',35);
INSERT INTO COMUNA VALUES (211,'Negrete',35);
INSERT INTO COMUNA VALUES (212,'Quilaco',35);
INSERT INTO COMUNA VALUES (213,'Quilleco',35);
INSERT INTO COMUNA VALUES (214,'San Rosendo',35);
INSERT INTO COMUNA VALUES (215,'Santa Bárbara',35);
INSERT INTO COMUNA VALUES (216,'Tucapel',35);
INSERT INTO COMUNA VALUES (217,'Yumbel',35);
INSERT INTO COMUNA VALUES (218,'Chiguayante',36);
INSERT INTO COMUNA VALUES (219,'Concepción',36);
INSERT INTO COMUNA VALUES (220,'Coronel',36);
INSERT INTO COMUNA VALUES (221,'Florida',36);
INSERT INTO COMUNA VALUES (222,'Hualpén',36);
INSERT INTO COMUNA VALUES (223,'Hualqui',36);
INSERT INTO COMUNA VALUES (224,'Lota',36);
INSERT INTO COMUNA VALUES (225,'Penco',36);
INSERT INTO COMUNA VALUES (226,'San Pedro de La Paz',36);
INSERT INTO COMUNA VALUES (227,'Santa Juana',36);
INSERT INTO COMUNA VALUES (228,'Talcahuano',36);
INSERT INTO COMUNA VALUES (229,'Tomé',36);
INSERT INTO COMUNA VALUES (230,'Bulnes',37);
INSERT INTO COMUNA VALUES (231,'Chillán',37);
INSERT INTO COMUNA VALUES (232,'Chillán Viejo',37);
INSERT INTO COMUNA VALUES (233,'Cobquecura',37);
INSERT INTO COMUNA VALUES (234,'Coelemu',37);
INSERT INTO COMUNA VALUES (235,'Coihueco',37);
INSERT INTO COMUNA VALUES (236,'El Carmen',37);
INSERT INTO COMUNA VALUES (237,'Ninhue',37);
INSERT INTO COMUNA VALUES (238,'Ñiquen',37);
INSERT INTO COMUNA VALUES (239,'Pemuco',37);
INSERT INTO COMUNA VALUES (240,'Pinto',37);
INSERT INTO COMUNA VALUES (241,'Portezuelo',37);
INSERT INTO COMUNA VALUES (242,'Quillón',37);
INSERT INTO COMUNA VALUES (243,'Quirihue',37);
INSERT INTO COMUNA VALUES (244,'Ránquil',37);
INSERT INTO COMUNA VALUES (245,'San Carlos',37);
INSERT INTO COMUNA VALUES (246,'San Fabián',37);
INSERT INTO COMUNA VALUES (247,'San Ignacio',37);
INSERT INTO COMUNA VALUES (248,'San Nicolás',37);
INSERT INTO COMUNA VALUES (249,'Treguaco',37);
INSERT INTO COMUNA VALUES (250,'Yungay',37);
INSERT INTO COMUNA VALUES (251,'Carahue',38);
INSERT INTO COMUNA VALUES (252,'Cholchol',38);
INSERT INTO COMUNA VALUES (253,'Cunco',38);
INSERT INTO COMUNA VALUES (254,'Curarrehue',38);
INSERT INTO COMUNA VALUES (255,'Freire',38);
INSERT INTO COMUNA VALUES (256,'Galvarino',38);
INSERT INTO COMUNA VALUES (257,'Gorbea',38);
INSERT INTO COMUNA VALUES (258,'Lautaro',38);
INSERT INTO COMUNA VALUES (259,'Loncoche',38);
INSERT INTO COMUNA VALUES (260,'Melipeuco',38);
INSERT INTO COMUNA VALUES (261,'Nueva Imperial',38);
INSERT INTO COMUNA VALUES (262,'Padre Las Casas',38);
INSERT INTO COMUNA VALUES (263,'Perquenco',38);
INSERT INTO COMUNA VALUES (264,'Pitrufquén',38);
INSERT INTO COMUNA VALUES (265,'Pucón',38);
INSERT INTO COMUNA VALUES (266,'Saavedra',38);
INSERT INTO COMUNA VALUES (267,'Temuco',38);
INSERT INTO COMUNA VALUES (268,'Teodoro Schmidt',38);
INSERT INTO COMUNA VALUES (269,'Toltén',38);
INSERT INTO COMUNA VALUES (270,'Vilcún',38);
INSERT INTO COMUNA VALUES (271,'Villarrica',38);
INSERT INTO COMUNA VALUES (272,'Angol',39);
INSERT INTO COMUNA VALUES (273,'Collipulli',39);
INSERT INTO COMUNA VALUES (274,'Curacautín',39);
INSERT INTO COMUNA VALUES (275,'Ercilla',39);
INSERT INTO COMUNA VALUES (276,'Lonquimay',39);
INSERT INTO COMUNA VALUES (277,'Los Sauces',39);
INSERT INTO COMUNA VALUES (278,'Lumaco',39);
INSERT INTO COMUNA VALUES (279,'Purén',39);
INSERT INTO COMUNA VALUES (280,'Renaico',39);
INSERT INTO COMUNA VALUES (281,'Traiguén',39);
INSERT INTO COMUNA VALUES (282,'Victoria',39);
INSERT INTO COMUNA VALUES (283,'Corral',40);
INSERT INTO COMUNA VALUES (284,'Lanco',40);
INSERT INTO COMUNA VALUES (285,'Los Lagos',40);
INSERT INTO COMUNA VALUES (286,'Máfil',40);
INSERT INTO COMUNA VALUES (287,'Mariquina',40);
INSERT INTO COMUNA VALUES (288,'Paillaco',40);
INSERT INTO COMUNA VALUES (289,'Panguipulli',40);
INSERT INTO COMUNA VALUES (290,'Valdivia',40);
INSERT INTO COMUNA VALUES (291,'Futrono',41);
INSERT INTO COMUNA VALUES (292,'La Unión',41);
INSERT INTO COMUNA VALUES (293,'Lago Ranco',41);
INSERT INTO COMUNA VALUES (294,'Río Bueno',41);
INSERT INTO COMUNA VALUES (295,'Ancud',42);
INSERT INTO COMUNA VALUES (296,'Castro',42);
INSERT INTO COMUNA VALUES (297,'Chonchi',42);
INSERT INTO COMUNA VALUES (298,'Curaco de Vélez',42);
INSERT INTO COMUNA VALUES (299,'Dalcahue',42);
INSERT INTO COMUNA VALUES (300,'Puqueldón',42);
INSERT INTO COMUNA VALUES (301,'Queilén',42);
INSERT INTO COMUNA VALUES (302,'Quemchi',42);
INSERT INTO COMUNA VALUES (303,'Quellón',42);
INSERT INTO COMUNA VALUES (304,'Quinchao',42);
INSERT INTO COMUNA VALUES (305,'Calbuco',43);
INSERT INTO COMUNA VALUES (306,'Cochamó',43);
INSERT INTO COMUNA VALUES (307,'Fresia',43);
INSERT INTO COMUNA VALUES (308,'Frutillar',43);
INSERT INTO COMUNA VALUES (309,'Llanquihue',43);
INSERT INTO COMUNA VALUES (310,'Los Muermos',43);
INSERT INTO COMUNA VALUES (311,'Maullín',43);
INSERT INTO COMUNA VALUES (312,'Puerto Montt',43);
INSERT INTO COMUNA VALUES (313,'Puerto Varas',43);
INSERT INTO COMUNA VALUES (314,'Osorno',44);
INSERT INTO COMUNA VALUES (315,'Puero Octay',44);
INSERT INTO COMUNA VALUES (316,'Purranque',44);
INSERT INTO COMUNA VALUES (317,'Puyehue',44);
INSERT INTO COMUNA VALUES (318,'Río Negro',44);
INSERT INTO COMUNA VALUES (319,'San Juan de la Costa',44);
INSERT INTO COMUNA VALUES (320,'San Pablo',44);
INSERT INTO COMUNA VALUES (321,'Chaitén',45);
INSERT INTO COMUNA VALUES (322,'Futaleufú',45);
INSERT INTO COMUNA VALUES (323,'Hualaihué',45);
INSERT INTO COMUNA VALUES (324,'Palena',45);
INSERT INTO COMUNA VALUES (325,'Aisén',46);
INSERT INTO COMUNA VALUES (326,'Cisnes',46);
INSERT INTO COMUNA VALUES (327,'Guaitecas',46);
INSERT INTO COMUNA VALUES (328,'Cochrane',47);
INSERT INTO COMUNA VALUES (329,'Ohiggins',47);
INSERT INTO COMUNA VALUES (330,'Tortel',47);
INSERT INTO COMUNA VALUES (331,'Coihaique',48);
INSERT INTO COMUNA VALUES (332,'Lago Verde',48);
INSERT INTO COMUNA VALUES (333,'Chile Chico',49);
INSERT INTO COMUNA VALUES (334,'Río Ibáñez',49);
INSERT INTO COMUNA VALUES (335,'Antártica',50);
INSERT INTO COMUNA VALUES (336,'Cabo de Hornos',50);
INSERT INTO COMUNA VALUES (337,'Laguna Blanca',51);
INSERT INTO COMUNA VALUES (338,'Punta Arenas',51);
INSERT INTO COMUNA VALUES (339,'Río Verde',51);
INSERT INTO COMUNA VALUES (340,'San Gregorio',51);
INSERT INTO COMUNA VALUES (341,'Porvenir',52);
INSERT INTO COMUNA VALUES (342,'Primavera',52);
INSERT INTO COMUNA VALUES (343,'Timaukel',52);
INSERT INTO COMUNA VALUES (344,'Natales',53);
INSERT INTO COMUNA VALUES (345,'Torres del Paine',53);
