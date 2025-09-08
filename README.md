# PickWise

PickWise is a **smart product recommendation app** focused on helping users choose the best **laptops** based on their needs, preferences, and budget. By combining product data with AI-powered recommendation logic, PickWise simplifies the decision-making process for users who feel overwhelmed by too many choices.

---

## 🚀 Features

* 🔍 **Smart Search** – Enter your requirements (e.g., "best gaming laptop under \$1000") and get tailored results.
* 💡 **AI-Powered Recommendations** – PickWise analyzes specs, performance, and value to suggest the best match.
* 📊 **Product Comparison** – Compare laptops side-by-side on specs, price, and reviews.
* 🧑‍💻 **User Profiles** – Save preferences (e.g., budget, brand, performance needs) for personalized recommendations.
* 📈 **Scoring Engine** – Each laptop is scored and ranked based on relevance to the user's requirements.

---

## 🛠️ Tech Stack

* **Frontend:** Flutter (cross-platform mobile app)
* **Backend:** Node.js
* **Database:** MongoDB
* **AI/LLM Integration:** LangChain
* **Authentication:** Firebase Authentication

---

## 📂 Project Structure

```
PickWise/
│── android/         # Android-specific config
│── ios/             # iOS-specific config
│── lib/             # Flutter source code
│   ├── screens/     # UI Screens
│   ├── widgets/     # Reusable components
│   ├── services/    # Firebase & API services
│   └── main.dart    # App entry point
│── backend/         # Node.js backend (APIs)
│── database/        # MongoDB schema & seed data
│── assets/          # Images, icons, etc.
│── README.md        # Project documentation
```

---

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/pickwise.git
cd pickwise
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Firebase

* Add your **google-services.json** (Android) and **GoogleService-Info.plist** (iOS) inside respective folders.
* Enable **Firebase Authentication** in the Firebase Console.

### 4. Run the App

```bash
flutter run
```

---

## 🎯 Roadmap

* [ ] Expand product categories beyond laptops
* [ ] Implement user reviews and ratings
* [ ] Add price-tracking and alerts
* [ ] Enhance recommendation engine with ML fine-tuning

---

## 👥 Contributing

Contributions are welcome! Please fork this repo and submit a pull request with improvements.

---

## 📜 License

This project is licensed under the MIT License – see the LICENSE file for details.
