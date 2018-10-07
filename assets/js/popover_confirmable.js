export var PopoverConfirmable = {
  run: function() {
    let template = `
      <form class="popover-confirmable-form">
        <input type="hidden" name="_csrf_token" value="">
        <p><strong>Are you sure?</strong></p>
        <button type="button" class="btn btn-secondary">No</button>
        <button type="submit" class="btn btn-primary">Yes</button>
      </form>
    `

    let onPopoverShown = function(e) {
      let link          = $(this);
      let questionLabel = link.data('question-label');
      let submitLabel   = link.data('submit-label');
      let cancelLabel   = link.data('cancel-label');
      let submitPath    = link.data('submit-path');
      let submitType    = link.data('submit-type');
      let form          = $('.popover-confirmable-form');

      form.find('input[type=hidden]').val($('body').data('csrf'));
      form.find('strong').html(questionLabel);
      form.find('button[type=submit]').html(submitLabel);
      form.find('button[type=button]').html(cancelLabel);

      form.ajaxForm({
        url: submitPath,
        type: submitType
      });
    }

    $('.popover-confirmable').popover({
      container: 'body',
      content: template,
      html: true,
      placement: 'right'
    }).on('shown.bs.popover', onPopoverShown);

    $('body').on('click', '.popover-confirmable-form .btn', function(){
      $('.popover-confirmable').popover('hide');
    });
  }
}
