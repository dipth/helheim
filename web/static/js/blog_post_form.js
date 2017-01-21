export var BlogPostForm = {
  run: function(){
    const el_editor = $('#blog_post_body_editor');
    if (el_editor.length == 0) return;

    const el_form = el_editor.parents('form');

    var quill = new Quill(el_editor[0], {
      modules: {
        toolbar: [
          [{ header: [1, 2, false] }],
          ['bold', 'italic', 'underline'],
          [{ 'list': 'ordered'}, { 'list': 'bullet' }]
        ]
      },
      placeholder: el_editor.data('placeholder'),
      theme: 'snow'
    });

    el_form.submit(function(e){
      const html = el_editor.find('.ql-editor').html()
      const el_input = $('#blog_post_body');
      el_input.val(html);
    });
  },
}
