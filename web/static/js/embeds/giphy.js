let regEx = /https?:\/\/(?:www\.|i\.|media\.)?(?:giphy\.com|gph\.is)(?:\/gifs|\/media)?\/(?:.+-)?([0-9a-zA-Z]+)(?:\/source)?(?:\/html5|\.gif)?/gi

let replacer = function(match, imageId) {
  return `
    <div class="embed-responsive embed-responsive-1by1">
      <iframe src="//giphy.com/embed/${imageId}?hideSocial=true" width="480" height="600" frameborder="0" class="giphy-embed embed-responsive-item" allowfullscreen=""></iframe>
    </div>
  `;
}

export var GiphyEmbed = {
  run: function(el){
    el.html(el.html().replace(regEx, replacer));
  },
}
