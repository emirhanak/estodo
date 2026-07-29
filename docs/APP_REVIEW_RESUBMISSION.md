# App Review resubmission

This document contains the non-secret information for estodo's App Review
resubmission. Reviewer passwords and production credentials must never be
committed to the repository.

## App Review Information

- Sign-in required: Yes
- Username: `appreview@estodo.app`
- Password: Enter the dedicated reviewer password stored in App Store Connect.
- Contact: Emirhan Ak, flashemirhan@gmail.com

## Review Notes

Hello App Review,

Thank you for reviewing estodo. We resolved the Guideline 2.1(a) issues from
submission `406a8af6-20c3-4829-b2d4-1f9fa708a709`.

- "Continue without an account" now signs in successfully and provides access
  to the task-management experience.
- We added a dedicated demo account in App Review Information so the complete
  signed-in experience can also be reviewed.
- Authentication and network failures now show clear, localized instructions
  instead of backend error messages.
- Notification permission is requested only after the user creates a task with
  a reminder.

Review steps:

1. On the welcome screen, tap "Continue without an account" to test guest
   access.
2. Create, edit, complete, search, and delete tasks or lists.
3. Sign in with the demo credentials in App Review Information to test the
   account and synchronization experience.
4. Notification permission appears only when a reminder is added to a task.

estodo is a free, ad-free task manager for daily tasks, meetings, lists, and
reminders. There are no in-app purchases or subscriptions in this version.
The app can be used worldwide and does not require special hardware.

Support:
https://github.com/emirhanak/estodo/blob/main/docs/index.md

Privacy policy:
https://github.com/emirhanak/estodo/blob/main/PRIVACY_POLICY.md
