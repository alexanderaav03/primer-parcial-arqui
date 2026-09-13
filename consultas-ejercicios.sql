-- Este archivo es NUEVO (sin historial de SQLTools todavía), para evitar el
-- estado roto que quedó pegado en gym-ejercicios.session.sql.
--
-- Antes de ejecutar cualquier query acá:
--   1. Hacé clic dentro de este archivo para que la pestaña tenga el foco.
--   2. Abrí el panel de SQLTools (ícono del elefante en la barra lateral
--      izquierda) y hacé clic en la conexión "gym-ejercicios" (puerto 5433)
--      para conectarla -si no aparece ya como conectada, click derecho ->
--      "Connect".
--   3. Confirmá en la esquina inferior derecha de VS Code que diga
--      "gym-ejercicios" antes de correr algo.
--   4. Recién ahí: clic en la query (el botón "Run" verde que aparece
--      arriba de cada sentencia) o Ctrl+Enter con el cursor en la línea.

SELECT nombre FROM ejercicios ORDER BY id;
