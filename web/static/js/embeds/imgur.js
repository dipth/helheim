let regEx = /https?:\/\/(?:www\.)?imgur\.com\/gallery\/([0-9a-zA-Z]+)/gi

let replacer = function(match, imageId) {
  return `
    <blockquote class="imgur-embed-pub" lang="en" data-id="a/${imageId}"><a href="//imgur.com/${imageId}">Imgur</a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>
  `;
}

export var ImgurEmbed = {
  run: function(el){
    el.html(el.html().replace(regEx, replacer));
  },
}
