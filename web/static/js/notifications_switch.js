export var NotificationsSwitch = {
  run: function(){
    $('.switch-notification-subscription input').change((e) =>{
      let checkbox = $(e.target)
      let form     = checkbox.closest('form')
      form.ajaxSubmit()
    })
  },
}
