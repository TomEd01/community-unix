## 1. Objetivo de la interfaz

La interfaz de Comunidad Unix ITC busca ofrecer un acceso sencillo a una plataforma educativa relacionada con Linux y tecnología. Su diseño organiza la información para que el usuario identifique cómo iniciar sesión y continúe hacia la pantalla correspondiente a su rol.

El código proporcionado contiene la pantalla de acceso, el tema general, las ilustraciones y la lógica de navegación inicial. Las pantallas de registro, alumno e instructor se importan desde otros archivos; por ello, sus botones y contenidos internos no se pueden describir a partir de este archivo.

## 2. Justificación del acceso con Google

### Botón de inicio de sesión

El botón de Google concentra el acceso y el registro en una misma acción. Esto evita presentar formularios separados de correo y contraseña y reduce la cantidad de datos que el usuario debe capturar inicialmente.

Se utiliza el botón proporcionado por Google para que la opción de acceso sea reconocible. Su ubicación debajo del texto “Continúa con Google” permite relacionar la explicación con la acción que debe realizar el usuario.

El flujo envía el token de Google al backend para validar la cuenta. Después, la respuesta del servidor determina si el usuario debe completar su perfil o ingresar a su panel.

### Registro de nuevos usuarios

Cuando el backend identifica una cuenta nueva, la aplicación abre `OnboardingPage`. Esta separación permite realizar primero la autenticación y después solicitar la información adicional del perfil.

El contenido del formulario de registro se encuentra en otro archivo, por lo que esta justificación se limita a explicar su lugar dentro del flujo de acceso.

## 3. Justificación del tema visual

### Tema oscuro

La aplicación utiliza un tema oscuro con un fondo principal `#080C18`. Esta elección mantiene una identidad visual consistente con la temática tecnológica de la comunidad y permite destacar los textos y elementos de interacción.

La legibilidad depende del contraste, el tamaño del texto y las condiciones de uso. El tema oscuro, por sí solo, no garantiza accesibilidad ni menor fatiga visual.

### Colores principales

| Color | Uso en el código | Justificación |
|---|---|---|
| Azul oscuro `#080C18` | Fondo principal | Proporciona una base visual uniforme. |
| Naranja `#F97316` | Color base del tema, indicador de carga y detalle decorativo | Destaca elementos importantes sobre el fondo oscuro. |
| Blanco | Texto principal | Diferencia títulos y contenido relevante del fondo. |
| Gris `#9899A8` | Instrucciones y textos secundarios | Establece una jerarquía respecto a los títulos. |
| Rojo | Mensajes e icono de error | Ayuda a identificar problemas durante el acceso. |
| Verde | Icono de escudo | Acompaña el mensaje sobre el acceso mediante Google. |

El naranja se define como color base del tema, pero el botón de Google conserva la presentación de su propio componente.

### Tipografía y jerarquía

La pantalla utiliza tamaños y pesos distintos para separar títulos, instrucciones y mensajes complementarios. El encabezado de bienvenida tiene mayor tamaño y grosor, mientras que los textos explicativos son más pequeños.

Esta jerarquía orienta la lectura desde la presentación de la plataforma hasta la acción de inicio de sesión. El archivo no establece una familia tipográfica personalizada.

## 4. Justificación de los roles

La navegación diferencia a los usuarios según el rol recibido del backend o recuperado del almacenamiento local.

| Rol | Destino en el código | Justificación |
|---|---|---|
| Instructor | `InstructorPage` | Separa el espacio del personal encargado de actividades educativas. |
| Alumno | `AlumnoPage` | Dirige al usuario hacia su espacio de participación y aprendizaje. |
| Externo | `AlumnoPage` | Comparte el destino general de los alumnos en el flujo actual. |

La condición comprueba específicamente el valor `Instructor`. Los demás valores siguen la ruta de alumno; por tanto, este archivo no demuestra que exista un panel independiente para externos.

La separación por roles permite presentar opciones pertinentes para cada usuario. Sin embargo, la navegación de la interfaz no sustituye la validación de permisos en el backend.

## 5. Justificación de las ilustraciones

### Mascota Lexus

El pingüino Lexus refuerza la relación de la plataforma con Linux y proporciona un elemento visual reconocible. Su mensaje de bienvenida presenta a la mascota como acompañante de la comunidad.

El parpadeo periódico y el seguimiento del puntero aportan interacción a la pantalla. Estas animaciones cumplen una función visual; no intervienen en la autenticación.

### Tucán e identidad del proyecto

El texto “Innovación Tucán” y la ilustración del tucán aportan identidad al proyecto. La imagen se muestra únicamente cuando el panel tiene suficiente ancho, evitando ocupar espacio necesario para el acceso.

### Fondo de estrellas y montañas

Las estrellas, las montañas y los degradados complementan el panel de Lexus. Al permanecer en el área ilustrada, permiten separar la ambientación visual de las instrucciones de acceso.

Los puntos ubicados debajo de la mascota son decorativos en este código: no tienen acciones para cambiar imágenes o pantallas.

## 6. Justificación de la adaptación a dispositivos

La distribución se determina por el ancho disponible, no por el nombre del dispositivo.

| Ancho disponible | Distribución | Justificación |
|---|---|---|
| Desde 950 píxeles lógicos | Acceso a la izquierda y panel de Lexus a la derecha | Aprovecha el espacio para mostrar información e ilustración simultáneamente. |
| Menos de 950 píxeles lógicos | Una columna con el panel de acceso | Prioriza el inicio de sesión y evita comprimir los elementos. |

Una computadora o un iPad pueden mostrar cualquiera de las distribuciones según el tamaño de la ventana y la orientación.

El desplazamiento vertical permite acceder al contenido cuando la altura es reducida. El uso de `SafeArea` ayuda a mantener los elementos dentro del área disponible de la pantalla.

## 7. Justificación de la retroalimentación

Durante la validación se muestra un indicador de carga y el mensaje “Verificando tu cuenta...”. Esto informa que la solicitud está en proceso.

Cuando ocurre un error, la pantalla presenta un recuadro con texto e icono. Combinar ambos elementos permite comunicar el problema sin depender únicamente del color.

El código también evita procesar solicitudes de autenticación simultáneas, reduciendo el riesgo de repetir el mismo flujo.

## 8. Continuidad de la sesión

La aplicación guarda el token y el rol mediante `SharedPreferences` y los recupera al iniciar. Esto permite dirigir al usuario a su panel sin mostrar nuevamente el acceso cuando existe un token almacenado.

En este archivo, la comprobación inicial solo verifica que el token no esté vacío. No se muestra una validación de su vigencia, por lo que recuperar una sesión guardada no equivale a confirmar que siga siendo válida.