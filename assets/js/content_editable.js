import { initializeTribute } from "./mentionable";

export var ContentEditable = {
  run: function(editor_element, form_element){
    if (!form_element) {
      return;
    }

    let editor = pell.init({
      element: editor_element,
      onChange: html => {
        form_element.value = html
      },
      defaultParagraphSeparator: 'p',
      styleWithCSS: false,
      actions: [
        'bold',
        'underline',
        'italic',
        'strikethrough',
        'heading1',
        'heading2',
        'paragraph',
        'olist',
        'ulist',
        {
          name: 'justifyLeft',
          icon: '<i class="fa fa-align-left"></i>',
          title: 'Venstre juster',
          result: () => pell.exec('justifyLeft')
        },
        {
          name: 'justifyCenter',
          icon: '<i class="fa fa-align-center"></i>',
          title: 'Center juster',
          result: () => pell.exec('justifyCenter')
        },
        {
          name: 'justifyRight',
          icon: '<i class="fa fa-align-right"></i>',
          title: 'Højre juster',
          result: () => pell.exec('justifyRight')
        },
        'link',
        'image'
      ]
    });
    editor.content.innerHTML = form_element.value
    initializeTribute(document.querySelectorAll(".pell-content"))
  }
}
