import {Socket} from "phoenix"

export var Notifications = {
  run: function(){
    let env = jQuery('meta[name="env"]').attr('content')
    let guardianToken = jQuery('meta[name="guardian_token"]').attr('content')
    let userId = jQuery('meta[name="user_id"]').attr('content')
    let notification_sound_path = jQuery('meta[name="notification_sound"]').attr('content')
    let notification_sound

    if (env == 'test') {
      return;
    }

    // Only try to use notification sound if the browser supports it
    try {
      notification_sound = new Audio(notification_sound_path)
    } catch(e) {
      // Continue without audio notifications
    }

    let socket = new Socket("/socket", {params: {guardian_token: guardianToken}})
    socket.connect()

    // Now that you are connected, you can join channels with a topic:
    let channel = socket.channel("notifications:" + userId, {guardian_token: guardianToken})
    channel.join()
      //.receive("ok", resp => { console.log("Joined successfully", resp) })
      //.receive("error", resp => { console.log("Unable to join", resp) })

    let handleIncomingNotification = payload => {
      $.get('/notifications', handleRefreshedNotificationsData)
    }

    let handleRefreshedNotificationsData = () => {
      $('#nav-item-notifications').animateCss('tada')
      playNotificationSound()
    }

    let playNotificationSound = () => {
      if (notification_sound) {
        notification_sound.play()
      }
    }

    channel.on("notification", handleIncomingNotification)
  },
}
