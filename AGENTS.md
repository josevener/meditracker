**Project:** MedTrack Mobile Application
**Tech Stack:** Flutter (Mobile App), Node.js (Backend API)
**Repository Structure:** Monorepo

```
/medtrack
   /mobile-app        -> Flutter application
   /backend-api       -> Node.js backend
```

---

# MedTrack Mobile App – Task Description

## 1. Project Overview

MedTrack is a mobile application designed to help users track their medication intake. Users can register medicines, define the dosage frequency, and receive reminders to take their medication. The system records daily medication intake and visualizes adherence through a monthly calendar view.

The application must function both **online and offline**, storing data locally when offline and synchronizing with the backend once connectivity is restored.

---

# 2. Core Features

## 2.1 Medication Management

Allow users to create and manage medications they need to take.

**User Inputs**

* Medicine name
* Dosage (optional)
* Frequency (times per day)
* Scheduled intake times
* Start date
* End date (optional)

**Capabilities**

* Add medication
* Edit medication
* Delete medication
* List all medications

---

## 2.2 Medication Reminder Notifications

The application must notify the user when it is time to take medication.

**Requirements**

* Scheduled notifications based on defined medication times
* Local notifications so reminders work offline
* Notification should allow quick interaction

**Actions**

* Mark as taken
* Snooze reminder

---

## 2.3 Medication Intake Confirmation

Users must be able to confirm that they have taken their medication.

Instead of a text-based confirmation, the UI should provide a clear action button such as:

* Checkmark button
* "Mark as Taken" icon
* Swipe action

**System Behavior**

* Record timestamp of intake
* Associate intake with medication and schedule time
* Prevent duplicate intake logs for the same schedule

---

## 2.4 Daily Medication Status

Display the user's medication progress for the day.

**Features**

* List of today's medications
* Status indicators:

  * Taken
  * Pending
  * Missed
* Quick action to confirm intake

---

## 2.5 Monthly Medication Calendar

Provide a visual overview of medication adherence.

**Calendar View**

* Monthly calendar
* Each day indicates:

  * Medication taken
  * Missed
  * Partial completion

**Visualization Examples**

* Green: All medicines taken
* Yellow: Partially taken
* Red: Missed medication

Selecting a date should display the medication log for that day.

---

# 3. Offline Support

The mobile application must work without internet connectivity.

## Offline Behavior

* All medication schedules stored locally
* Notifications continue working
* Intake confirmations stored locally

## Local Storage

Recommended options:

* SQLite
* Hive
* Drift

Local database should contain:

* medications
* schedules
* intake logs
* sync status

---

# 4. Data Synchronization

When internet becomes available, local data must synchronize with the backend.

## Sync Rules

* Unsynced local records are pushed to the server
* Server returns updated records if needed
* Conflict resolution favors the latest timestamp

## Sync Triggers

* App launch
* Internet reconnect
* Manual sync button

---

# 5. Backend Responsibilities (Node.js)

The backend will act as the central data storage and sync server.

## Core APIs

### Authentication

* User registration
* Login
* Token-based authentication

### Medication APIs

* Create medication
* Update medication
* Delete medication
* Get medications

### Intake Tracking

* Log medication intake
* Fetch intake history
* Fetch monthly logs

### Sync API

Endpoint for syncing offline data.

Example:

```
POST /sync
```

Payload:

* new medications
* intake logs
* updates

---

# 6. Database Model (Backend)

### Users

```
id
email
password
created_at
```

### Medications

```
id
user_id
name
dosage
frequency_per_day
start_date
end_date
created_at
```

### MedicationSchedules

```
id
medication_id
time_of_day
```

### IntakeLogs

```
id
medication_id
scheduled_time
taken_at
date
status
```

---

# 7. Flutter Application Modules

```
mobile-app
   /lib
      /core
         api
         database
         sync
      /modules
         auth
         medications
         reminders
         calendar
         daily_status
      /services
         notification_service
         sync_service
      /widgets
```

---

# 8. Backend Project Structure

```
backend-api
   /src
      /controllers
      /routes
      /services
      /models
      /middlewares
      /sync
      /config
```

---

# 9. Key Technical Requirements

### Flutter

* Local notifications
* Local database
* Background sync
* Clean architecture
* Offline-first design

### Node.js

* REST API
* JWT authentication
* Data sync endpoint
* Medication logging APIs

---

# 10. Future Enhancements

* Caregiver notifications
* Medication scanning (barcode)
* Smart pill adherence analytics
* Wearable integration
* AI adherence suggestions

---

If needed, additional deliverables can be produced:

* **Full system architecture**
* **Complete database schema**
* **API specification**
* **Flutter UI screen list**
* **Development task breakdown for Agile sprints**.
