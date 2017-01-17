export var RestfulizerTweak = {
  run: function(){
    $(".rest").click(function(d) {
      $('form').submit(function(s) {
        var input = $("<input>")
        .attr("type", "hidden")
        .attr("name", "_csrf_token").val($('body').data('csrf'));
        $(s.target).append($(input));
      });
    });
    $(".rest").restfulizer({});
  }
}
