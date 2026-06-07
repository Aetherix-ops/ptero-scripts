// =============================================================
//  pterodactyl-scripts — power-scheduler/config.js
// =============================================================

module.exports = {

  // Pterodactyl panel URL (no trailing slash)
  PANEL_URL: "https://panel.yourdomain.com",

  // Pterodactyl Client API key (from account settings)
  API_KEY: "your_api_key_here",

  // Send Discord notification on every action? (true/false)
  NOTIFY_DISCORD: false,
  DISCORD_WEBHOOK_URL: "",

  // ── SCHEDULES ───────────────────────────────────────────────
  // Each schedule:
  //   identifier : server identifier (from panel URL) OR
  //   name       : server name (case-insensitive)
  //   action     : "start" | "stop" | "restart" | "kill"
  //   time       : "HH:MM" in 24-hour format
  //   days       : array of day numbers (0=Sun, 1=Mon ... 6=Sat)
  //                empty array [] = every day

  SCHEDULES: [

    // Example: Start TelisSMP every day at 08:00
    {
      identifier: "abc12345",
      action: "start",
      time: "08:00",
      days: []
    },

    // Example: Stop TelisSMP every day at 23:00
    {
      identifier: "abc12345",
      action: "stop",
      time: "23:00",
      days: []
    },

    // Example: Restart Lunexia Bot every Monday at 04:00
    {
      name: "Lunexia Bot",
      action: "restart",
      time: "04:00",
      days: [1]
    },

    // Example: Start Dev API on weekdays at 09:00
    {
      name: "Dev API",
      action: "start",
      time: "09:00",
      days: [1, 2, 3, 4, 5]
    },

    // Example: Stop Dev API on weekdays at 18:00
    {
      name: "Dev API",
      action: "stop",
      time: "18:00",
      days: [1, 2, 3, 4, 5]
    }

  ]

};
      
