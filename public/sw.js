self.addEventListener('push', (event) => {
  // Parse icons from URL params (passed from GlobalContext/assets.ts)
  const urlParams = new URLSearchParams(self.location.search);
  const defaultIcon = urlParams.get('icon') || '/favicon.ico';
  const defaultBadge = urlParams.get('badge') || defaultIcon;

  const data = event.data ? event.data.json() : { title: 'Notification', body: 'New update available!' };

  const options = {
    body: data.body,
    icon: data.icon || defaultIcon,
    badge: data.badge || defaultBadge,
    data: {
      url: data.url || '/'
    }
  };

  event.waitUntil(
    self.registration.showNotification(data.title, options)
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.openWindow(event.notification.data.url)
  );
});
