export var DonationForm = {
  run: function(){
    let formEl = $('#donation-form');
    let sliderEl = $('#donation_amount');
    let spacePreviewEl = $('#total-extra-space-gain');
    let donateButtonEl = $('#donate-button');
    let amountEl = $('#donation_amount')

    if (formEl.length == 0) {
      return;
    }

    let stripeHandler = StripeCheckout.configure({
      key: formEl.data('stripe-key'),
      locale: 'da',
      currency: 'dkk',
      name: formEl.data('name'),
      description: formEl.data('description'),
      image: formEl.data('logo-path'),
      token: function(token) {
        $('#donation_token').val(token.id);
        $('form').submit();
      }
    });

    sliderEl.rangeslider({
      polyfill: false,

      // Callback function
      onInit: function() {
        var $handle = $('.rangeslider__handle', this.$range);
        updateLabels($handle[0], this.value);
      },

      // Callback function
      onSlideEnd: function(position, value) {}
    }).on('input', function(e) {
      var $handle = $('.rangeslider__handle', e.target.nextSibling);
      updateLabels($handle[0], this.value);
    });

    function updateLabels(handleEl, val) {
      handleEl.textContent = (val / 100) + ' kr.';
      spacePreviewEl.html(calculateExtraSpace(val) + ' MB');
    }

    function calculateExtraSpace(amount) {
      let stepSize = formEl.data('step-size');
      let extraSpacePerStep = formEl.data('extra-space-per-step');
      let steps = amount / stepSize;
      return Math.round(extraSpacePerStep * steps / 1024 / 1024)
    }

    donateButtonEl.on('click', function(e){
      e.preventDefault();

      stripeHandler.open({
        amount: parseInt(amountEl.val())
      });
    });
  },
}
