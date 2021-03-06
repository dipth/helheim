import {Socket} from "phoenix"

export var Notifications = {
  run: function(){
    let env = jQuery('meta[name="env"]').attr('content')
    let guardianToken = jQuery('meta[name="guardian_token"]').attr('content')
    let userId = jQuery('meta[name="user_id"]').attr('content')
    let favicon = new Favico({animation:'popFade'})
    let notification_sound_path = jQuery('meta[name="notification_sound"]').attr('content')
    let muteNotifications = jQuery('meta[name="mute_notifications"]').attr('content') == 'true'
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
      // .receive("ok", resp => { console.log("notifications.js: Joined successfully", resp) })
      // .receive("error", resp => { console.log("notifications.js: Unable to join", resp) })

    let handleIncomingNotification = payload => {
      $.get('/navbar', handleRefreshedNavbar)
    }

    let handleRefreshedNavbar = (data) => {
      $('#navbar').replaceWith(data)
      $('#navbar .badge').animateCss('wobble')
      updateFavicon()
      playNotificationSound()
    }

    let updateFavicon = () => {
      let messageCount = parseInt($('#nav-link-unread-messages .badge').html()) || 0
      let notificationCount = parseInt($('#nav-link-notifications .badge').html()) || 0
      let pendingFriendshipCount = parseInt($('#nav-link-pending-friendships .badge').html()) || 0
      let totalCount = messageCount + notificationCount + pendingFriendshipCount
      favicon.badge(totalCount)
    }

    let playNotificationSound = () => {
      if (notification_sound && !muteNotifications) {
        notification_sound.play()
      }
    }

    channel.on("notification", handleIncomingNotification)
    updateFavicon()
  },
}
