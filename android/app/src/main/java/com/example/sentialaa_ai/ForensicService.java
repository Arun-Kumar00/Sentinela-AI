public class ForensicService extends Service {
    private FileObserver observer;

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String folderPath = intent.getStringExtra("folderPath");

        // The Sentinel: Watching the physical folder
        observer = new FileObserver(folderPath, FileObserver.CLOSE_WRITE) {
            @Override
            public void onEvent(int event, String path) {
                if (path != null) {
                    // 🚀 TRIGGER AUTO-SCAN
                    String fullPath = folderPath + "/" + path;
                    String report = runGridAnalysis(fullPath); // Your Phase 6 logic

                    showNotification("Sentinela Alert", "New Image Detected: " + report);
                }
            }
        };
        observer.startWatching();
        return START_STICKY;
    }

    // Notification logic to alert the user instantly
    private void showNotification(String title, String content) {
        // Build standard Android Notification with a High-Priority channel
    }
}