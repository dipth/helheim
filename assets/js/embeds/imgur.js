let regEx = /\[imgur\](.+?)\[\/imgur\]/gi

let replacer = function(match, imageId) {
  if (imageId.length == 5) {
    return `
      <blockquote class="imgur-embed-pub" lang="en" data-id="a/${imageId}"><a href="//imgur.com/${imageId}"></a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>
    `;
  } else {
    return `
      <blockquote class="imgur-embed-pub" lang="en" data-id="${imageId}"><a href="//imgur.com/${imageId}"></a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>
    `;
  }
}

export var ImgurEmbed = {
  run: function(el){
    el.html(el.html().replace(regEx, replacer));
  },
}
