export var BlockForm = {
  run: function(){
    let selectEl = $('#blockee_id');

    if (selectEl.length == 0) {
      return;
    }

    let config = {
      create: false,
      maxItems: 1,
      closeAfterSelect: true
    };
    new TomSelect('#blockee_id', config);
  },
}
