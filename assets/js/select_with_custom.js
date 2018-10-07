export var SelectWithCustom = {
  run: function(){
    $('select[data-custom-input]').each(function(index){
      let select         = $(this)
      let customLabel    = select.data('custom-label')
      let customInput    = $(select.data('custom-input'))
      let customValue    = select.data('custom-value')
      let customOption   = $('<option value="%%CUSTOM%%">' + customLabel + '</option>')
      let selectedOption = select.find('option[value="' + customValue + '"]')

      select.append(customOption)

      // Check if there is a select option with the same value as the one set by
      // the user
      if (selectedOption.length == 0) {
        // There are no existing select options matching the value, so we must
        // assume that the value is custom
        customInput.val(customValue)
        customOption.attr('selected', true)
      } else {
        // There is a select option matching the value, so we assume that the
        // user selected this option instead of providing a custom value
        customInput.hide()
      }

      // Hide the custom input field when selecting a predefined option and show
      // it when selecting the custom option
      select.change(() =>{
        if (select.val() == customOption.attr('value')) {
          customInput.show()
        } else {
          customInput.hide()
        }
      })
    })
  },
}
