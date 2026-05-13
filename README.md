[README.md](https://github.com/user-attachments/files/26570056/README.md)
# 📚 EduLearn — Ignite Your Learning Journey

> A full-featured EdTech mobile application built with Flutter, connecting Teachers and Students on a single platform.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Node.js](https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white)
![MySQL](https://img.shields.io/badge/MySQL-4479A1?style=for-the-badge&logo=mysql&logoColor=white)

---

## 📱 App Screenshots

| Splash Screen | Dashboard | QR Attendance |
|---|---|---|
| ![Splash](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/splash%20screen.jpeg) | ![Dashboard](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/student%20dashboard.jpeg) | ![Attendance](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/marl%20attendence.jpeg) |

| Attendance Marked | Recorded Lectures | Live Lecture |
|---|---|---|
| ![Marked](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/Attendence_marked.jpeg) | ![Lectures](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/Recorded_lecture.jpeg) | ![Live](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/live%20lecture.jpeg) |
 ![uploading Lectures](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/uploading%20lecture.jpeg) |
 ![Lecture uploaded](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/lecture_upload.jpeg) |
 | ![Video Play ](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/recorded_lecture_video%20_play.jpeg) |

| Quiz Studio | Create Quiz | Quiz Result |
|---|---|---|
| ![Create quiz ](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/Quiz.jpeg) | ![Quiz Created](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/Quiz_created.jpeg) | ![Quiz Result](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/Quiz_result.jpeg) |

| Marks Manager | Homework Hub | My Results |
|---|---|---|
| ![Manage Marks](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/Manage_marks.jpeg) | 
| ![Create Subject](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/new%20subject.jpeg) | 
| ![Homework Notification](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/HomeWork_Notification.jpeg) | 
| ![Assign Homework](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/HomeWork.jpeg) | 
| ![Submit Homework](https://github.com/jddas10/EduLearn_flutter/blob/master/EduLearn_ScreenShots/Submit_button_homework.jpeg) |
![Results](screenshots/my_results.jpg) |

---

## ✨ Features

### 👨‍🏫 Teacher Panel
- **QR Code Attendance** — Generate dynamic QR codes for location-based attendance tracking
- **Recorded Lectures** — Upload and manage video lectures by subject and class
- **Live Lectures** — Schedule and host live sessions via YouTube integration
- **Quiz Studio** — Create timed MCQ quizzes with auto-grading and results analytics
- **Marks Manager** — Enter and manage subject-wise student marks with grade calculation
- **Homework Hub** — Assign homework with file attachments, due dates, and push notifications
- **Class Management** — Create and manage multiple classes with student enrollment

### 👨‍🎓 Student Panel
- **QR Code Attendance** — Mark attendance by scanning teacher's QR code (location-verified)
- **Recorded Lectures** — Watch uploaded lectures organized by subject with playback speed control
- **Live Classes** — Join live YouTube sessions directly from the app
- **Quiz Attempt** — Attempt timed quizzes and view instant results with answer review
- **My Results** — View subject-wise marks, grade, rank, and performance insights
- **My Homework** — Track pending/submitted assignments and submit with file attachments
- **Push Notifications** — Real-time alerts for homework, quizzes, and class updates

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Frontend | Flutter (Dart) |
| Backend | Node.js (Express.js) |
| Database | MySQL (Aiven Cloud) |
| Authentication | Firebase Auth |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| File Storage | Firebase Storage |
| Deployment | Render (Backend) |

---

## 🏗️ Project Structure

```
EduLearn_flutter/
├── lib/
│   ├── screens/
│   │   ├── teacher/          # Teacher-side screens
│   │   └── student/          # Student-side screens
│   ├── models/               # Data models
│   ├── services/             # API & Firebase services
│   └── widgets/              # Reusable UI components
├── android/
├── ios/
└── pubspec.yaml
```

---

## ⚙️ Getting Started

### Prerequisites
- Flutter SDK >= 3.0
- Dart >= 3.0
- Android Studio / VS Code
- Firebase project setup

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/jddas10/EduLearn_flutter.git

# 2. Navigate to project directory
cd EduLearn_flutter

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run
```

### Backend Setup
The backend is deployed at: `https://edulearn-backend-5gxv.onrender.com`

Backend repository: [edulearn-backend](https://github.com/jddas10/edulearn-backend)

---

## 📦 Key Dependencies

```yaml
dependencies:
  firebase_core
  firebase_auth
  firebase_messaging
  cloud_firestore
  firebase_storage
  http
  qr_code_scanner
  video_player
  geolocator
```

---

## 🔑 Key Highlights

- **Dual Role System** — Separate Teacher and Student interfaces with role-based access
- **Real-time Push Notifications** — FCM integration for instant alerts on homework and quizzes
- **Location-based Attendance** — QR attendance verifies student distance from classroom
- **Video Upload with Progress** — Upload lecture videos with real-time progress tracking
- **Offline-ready UI** — Smooth experience with proper loading and error states
- **Full Stack Project** — Flutter frontend + Node.js backend + MySQL + Firebase

---

## 👨‍💻 Developer

**Dave Jaydatt Vipulbhai**

[![GitHub](https://img.shields.io/badge/GitHub-jddas10-181717?style=flat&logo=github)](https://github.com/jddas10)
[![Email](https://img.shields.io/badge/Email-jaydattdave10@gmail.com-D14836?style=flat&logo=gmail&logoColor=white)](mailto:jaydattdave10@gmail.com)

> Ganpat University — U. V. Patel College of Engineering, Mehsana

---

## 📄 License

This project is developed for educational purposes.

---

⭐ If you found this project helpful, please give it a star!
