const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { defineSecret } = require('firebase-functions/params');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { initializeApp } = require('firebase-admin/app');
const { Resend } = require('resend');

initializeApp();

const resendApiKey = defineSecret('RESEND_API_KEY');

exports.sendFeedbackEmail = onDocumentCreated(
  {
    document: 'mail/{mailId}',
    region: 'europe-west1',
    secrets: [resendApiKey],
  },
  async (event) => {
    const snapshot = event.data;
    const mail = snapshot?.data();
    if (!snapshot || !mail?.message?.text) return;

    const resend = new Resend(resendApiKey.value());
    const recipients = Array.isArray(mail.to) ? mail.to : [mail.to];
    const { data, error } = await resend.emails.send({
      from: 'estodo <onboarding@resend.dev>',
      to: recipients,
      subject: mail.message.subject || 'estodo geri bildirimi',
      text: mail.message.text,
    });

    const update = error
      ? { status: 'error', error: error.message }
      : {
          status: 'sent',
          resendId: data?.id ?? null,
          sentAt: FieldValue.serverTimestamp(),
        };
    await getFirestore().doc(snapshot.ref.path).update(update);
  },
);
