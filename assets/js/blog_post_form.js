import { ContentEditable } from "./content_editable";

export var BlogPostForm = {
  run: function(){
    ContentEditable.run(
      document.getElementById('blog_post_editor'),
      document.getElementById('blog_post_body')
    )
  }
}
