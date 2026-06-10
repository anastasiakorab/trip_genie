importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyAvWT-UqCOK_JCnu0VCsNihgcIMJOox7Bg",
  authDomain: "tripgenie-project-finki.firebaseapp.com",
  projectId: "tripgenie-project-finki",
  storageBucket: "tripgenie-project-finki.firebasestorage.app",
  messagingSenderId: "981176022677",
  appId: "1:981176022677:web:8f127b905462fe020b8d9c"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Background message received:", payload);

  self.registration.showNotification(
    payload.notification?.title || "TripGenie",
    {
      body: payload.notification?.body || "You have a new notification",
      icon: "/icons/Icon-192.png",
    }
  );
});