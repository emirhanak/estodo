# Firestore structure

The app stores all user-owned data under the authenticated user's document.

```text
users/{uid}
  id: string
  email: string
  displayName: string?
  createdAt: timestamp
  updatedAt: timestamp

users/{uid}/tasks/{taskId}
  id: string
  userId: string
  listId: string?
  title: string
  notes: string?
  priority: "low" | "medium" | "high"
  dueAt: timestamp?
  reminderAt: timestamp?
  isCompleted: boolean
  isImportant: boolean
  isMyDay: boolean
  myDayDate: "yyyy-MM-dd"?
  completedAt: timestamp?
  createdAt: timestamp
  updatedAt: timestamp

users/{uid}/lists/{listId}
  id: string
  userId: string
  name: string
  color: number
  createdAt: timestamp
  updatedAt: timestamp

users/{uid}/devices/{fcmToken}
  token: string
  platform: string
  updatedAt: timestamp
```

Security rules live in `firestore.rules` and restrict reads/writes to the
authenticated owner. Deploy them with:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```
