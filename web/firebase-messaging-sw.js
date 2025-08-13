/* Firebase Cloud Messaging Service Worker for web */
/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/9.6.11/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.6.11/firebase-messaging-compat.js');

// Initialize Firebase app for the service worker (web config)
firebase.initializeApp({
  apiKey: 'AIzaSyDvjzGdpYQ56uenNPgtftpRFXci0wbmkj4',
  appId: '1:580968294391:web:53b97bf4ed43b16a0330f2',
  messagingSenderId: '580968294391',
  projectId: 'findmebiz-b8cd9',
  authDomain: 'findmebiz-b8cd9.firebaseapp.com',
  storageBucket: 'findmebiz-b8cd9.firebasestorage.app',
  measurementId: 'G-7XNYLXXMY9',
});

const messaging = firebase.messaging();

// Handle background messages
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'Notification';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    data: payload.data || {},
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
