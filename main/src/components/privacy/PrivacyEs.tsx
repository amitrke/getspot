import PrivacySection from "@/components/PrivacySection";

export default function PrivacyEs() {
  return (
    <>
      <div className="text-center">
        <h1 className="text-4xl font-semibold tracking-tight sm:text-5xl">Política de privacidad</h1>
        <p className="mt-4 text-sm text-zinc-500 dark:text-zinc-400">Última actualización: 23 de agosto de 2026</p>
      </div>

      <p className="mt-10 text-sm text-zinc-500 dark:text-zinc-400">
        Gracias por usar GetSpot. Esta Política de privacidad explica cómo recopilamos, usamos y
        compartimos información sobre ti cuando utilizas nuestra aplicación móvil y los servicios
        relacionados (colectivamente, los &ldquo;Servicios&rdquo;).
      </p>

      <p className="mt-4 text-sm text-zinc-500 dark:text-zinc-400">
        <strong className="text-zinc-700 dark:text-zinc-300">Aviso:</strong> Esta es una política de
        privacidad de plantilla y no constituye asesoramiento legal. Debes consultar con un profesional
        legal para asegurarte de que esta política sea adecuada y cumpla con la normativa para tu
        situación específica.
      </p>

      <div className="mt-16">
        <PrivacySection number={1} title="Información que recopilamos">
          <p>
            Recopilamos información que nos proporcionas directamente y también información que se
            recopila automáticamente a través del uso que haces de nuestros Servicios.
          </p>
          <p className="font-semibold text-zinc-700 dark:text-zinc-300">a) Información que nos proporcionas:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Información de la cuenta:</strong>{" "}
              Cuando te registras para obtener una cuenta, recopilamos tu nombre y dirección de correo
              electrónico a través de Firebase Authentication.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Información del grupo:</strong>{" "}
              Recopilamos información sobre los grupos que creas o a los que te unes, incluyendo el
              nombre del grupo, la descripción y los miembros.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Información del evento:</strong>{" "}
              Recopilamos detalles sobre los eventos que creas o en los que te registras, incluyendo el
              nombre del evento, la hora, la tarifa y tu estado de participación.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">
                Información de billetera y transacciones:
              </strong>{" "}
              Mantenemos un registro del saldo de tu billetera virtual y un historial de todas las
              transacciones (por ejemplo, pagos de tarifas de eventos, penalizaciones, reembolsos)
              asociadas a tu cuenta.
            </li>
          </ul>
          <p className="font-semibold text-zinc-700 dark:text-zinc-300">
            b) Información que recopilamos automáticamente:
          </p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Información de uso:</strong>{" "}
              Recopilamos información sobre tu actividad en los Servicios, como qué funciones usas y
              cuándo las usas.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Información del dispositivo:</strong>{" "}
              Podemos recopilar información sobre el dispositivo que usas para acceder a nuestros
              Servicios, incluyendo el modelo de hardware, el sistema operativo y los identificadores
              únicos del dispositivo.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">
                Token de Firebase Cloud Messaging (FCM):
              </strong>{" "}
              Para enviarte notificaciones push, recopilamos y almacenamos tu token de registro de FCM.
            </li>
          </ul>
        </PrivacySection>

        <PrivacySection number={2} title="Cómo usamos tu información">
          <p>Usamos la información que recopilamos para:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>Proporcionar, mantener y mejorar nuestros Servicios.</li>
            <li>Crear y gestionar tu cuenta, grupos y eventos.</li>
            <li>Procesar transacciones de tu billetera virtual.</li>
            <li>
              Comunicarnos contigo, incluyendo el envío de recordatorios de eventos, actualizaciones de
              listas de espera y otras notificaciones relacionadas con el servicio.
            </li>
            <li>Garantizar la seguridad de nuestros Servicios.</li>
            <li>Personalizar tu experiencia.</li>
          </ul>
        </PrivacySection>

        <PrivacySection number={3} title="Cómo compartimos tu información">
          <p>Podemos compartir tu información en las siguientes situaciones:</p>
          <ul className="list-disc space-y-2 pl-5">
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Con otros miembros del grupo:</strong>{" "}
              Tu nombre y tu estado de participación en los eventos son visibles para otros miembros de
              los grupos en los que participas. Los administradores del grupo también pueden ver los
              saldos de billetera de los miembros.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Con proveedores de servicios:</strong>{" "}
              Utilizamos proveedores de servicios externos para ayudarnos a operar nuestros Servicios,
              como Google Firebase para infraestructura de backend, autenticación y hosting. Estos
              proveedores solo tienen acceso a tu información para realizar servicios en nuestro nombre y
              están obligados a no divulgarla ni usarla para ningún otro propósito.
            </li>
            <li>
              <strong className="text-zinc-700 dark:text-zinc-300">Por motivos legales:</strong> Podemos
              divulgar tu información si consideramos razonablemente necesario cumplir con una ley,
              reglamento, proceso legal o solicitud gubernamental.
            </li>
          </ul>
          <p>No vendemos tu información personal a terceros.</p>
        </PrivacySection>

        <PrivacySection number={4} title="Seguridad de los datos">
          <p>
            Usamos Google Firebase, que implementa medidas de seguridad estándar de la industria para
            proteger tu información contra el acceso no autorizado, la alteración, la divulgación o la
            destrucción. Sin embargo, ningún sistema de seguridad es infalible y no podemos garantizar la
            seguridad absoluta de tu información.
          </p>
        </PrivacySection>

        <PrivacySection number={5} title="Retención de datos">
          <p>
            Conservamos tu información personal mientras tu cuenta esté activa o según sea necesario para
            proporcionarte los Servicios. También podemos conservar información para cumplir con nuestras
            obligaciones legales, resolver disputas y hacer cumplir nuestros acuerdos.
          </p>
        </PrivacySection>

        <PrivacySection number={6} title="Tus derechos">
          <p>
            Tienes derecho a acceder, actualizar o eliminar tu información personal. Puedes gestionar la
            mayor parte de tu información directamente dentro de la app.
          </p>
        </PrivacySection>

        <PrivacySection number={7} title="Solicitud de eliminación de datos">
          <p>
            Puedes eliminar tu cuenta y todos los datos asociados directamente dentro de la app: abre tu
            pantalla de perfil y toca &ldquo;Eliminar cuenta&rdquo;. Esta acción es inmediata y no se
            puede deshacer. Si tienes un saldo de billetera negativo en algún grupo, deberás saldarlo con
            el administrador de tu grupo antes de poder eliminar tu cuenta.
          </p>
          <p>
            Si no puedes acceder a la app, puedes enviar un correo a{" "}
            <a href="mailto:support@getspot.org" className="underline hover:no-underline">
              support@getspot.org
            </a>{" "}
            para solicitar la eliminación en su lugar.
          </p>
        </PrivacySection>

        <PrivacySection number={8} title="Privacidad de los menores">
          <p>
            Nuestros Servicios no están dirigidos a personas menores de 13 años. No recopilamos
            conscientemente información personal de menores de 13 años. Si nos damos cuenta de que un
            menor de 13 años nos ha proporcionado información personal, tomaremos medidas para eliminar
            dicha información.
          </p>
        </PrivacySection>

        <PrivacySection number={9} title="Cambios en esta política">
          <p>
            Podemos actualizar esta Política de privacidad de vez en cuando. Te notificaremos sobre
            cualquier cambio publicando la nueva Política de privacidad en esta página y actualizando la
            fecha de &ldquo;Última actualización&rdquo;.
          </p>
        </PrivacySection>

        <PrivacySection number={10} title="Contáctanos">
          <p>
            Si tienes alguna pregunta sobre esta Política de privacidad, envía un correo a{" "}
            <a href="mailto:support@getspot.org" className="underline hover:no-underline">
              support@getspot.org
            </a>
            .
          </p>
        </PrivacySection>
      </div>
    </>
  );
}
