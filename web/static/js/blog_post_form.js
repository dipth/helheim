import { MentionableConfig } from "./mentionable";

export var BlogPostForm = {
  run: function(){
    tinymce.init({
      selector: '#blog_post_body',
      height: 350,
      menubar: false,
      plugins: [
        'lists link image charmap print preview anchor',
        'searchreplace visualblocks code fullscreen',
        'insertdatetime table contextmenu paste code'
      ],
      toolbar: 'undo redo | insert | styleselect | bold italic | alignleft aligncenter alignright alignjustify | bullist numlist | link image',
      init_instance_callback: function(editor) {
        $(editor.contentDocument.activeElement).atwho(MentionableConfig);
      }
    })
  },
}
