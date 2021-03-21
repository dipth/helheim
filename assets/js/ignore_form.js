export var IgnoreForm = {
  run: function(){
    let selectEl = $('#ignoree_id');

    if (selectEl.length == 0) {
      return;
    }

    let config = {
      create: false,
      maxItems: 1,
      closeAfterSelect: true
    };
    new TomSelect('#ignoree_id', config);
  },
}
