export var AdminTermsForm = {
  run: function(){
    tinymce.init({
      selector: '#term_body',
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
