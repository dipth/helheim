export var PreferencesForm = {
  run: function(){
    const formElm = document.getElementById('preferences-form');
    const notificationSoundRadioElms = document.getElementsByName('user[notification_sound]')

    if (!formElm) { return; }

    for (var radioCounter = 0 ; radioCounter < notificationSoundRadioElms.length; radioCounter++) {
      notificationSoundRadioElms[radioCounter].onclick = this.onNotificationSoundRadioClick;
    }
  },

  onNotificationSoundRadioClick: function() {
    const previewUrl = this.dataset.previewUrl;
    // Only try to preview sound if the browser supports it
    try {
      new Audio(previewUrl).play();
    } catch(e) {
      // Continue without preview
    }
  }
}
