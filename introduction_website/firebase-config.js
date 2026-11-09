// Import the functions you need from the SDKs you need
import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-app.js";
import { getAnalytics } from "https://www.gstatic.com/firebasejs/10.12.0/firebase-analytics.js";

// Your web app's Firebase configuration
export const firebaseConfig = {
  apiKey: "AIzaSyAmLOKPXiB2xTEPH4qN7gtmDK5-5Octcow",
  authDomain: "sunday-school-ch.firebaseapp.com",
  projectId: "sunday-school-ch",
  storageBucket: "sunday-school-ch.firebasestorage.app",
  messagingSenderId: "75337619316",
  appId: "1:75337619316:web:196b0cf5e3e86cd79ebe21",
  measurementId: "G-T8RYKVRZ22"
};

// Initialize Firebase safely
let app = null;
let analytics = null;

try {
  app = initializeApp(firebaseConfig);
  if (typeof window !== "undefined") {
    analytics = getAnalytics(app);
  }
} catch (e) {
  console.warn("Firebase initialization notice:", e);
}

export { app, analytics };
