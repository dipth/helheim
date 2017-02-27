export var ProfileSettings = {
  run: function(){
    tinymce.init({
      selector: '#user_profile_text',
      height: 350,
      menubar: false,
      plugins: [
        'autolink lists link image charmap print preview anchor',
        'searchreplace visualblocks code fullscreen',
        'insertdatetime table contextmenu paste code'
      ],
      toolbar: 'undo redo | insert | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist | link image',
    })
  },
}
