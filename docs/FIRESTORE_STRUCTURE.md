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
  iconKey: string?
  colorValue: number?
  isHabit: boolean
  priority: "low" | "medium" | "high"
  dueAt: timestamp?
  startAt: timestamp?
  durationMinutes: number?
  reminderAt: timestamp?
  isCompleted: boolean
  isImportant: boolean
  isMyDay: boolean
  myDayDate: "yyyy-MM-dd"?
  completedAt: timestamp?
  position: number
  recurrence: map?
  steps: list<map>?
  tags: list<string>?
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
