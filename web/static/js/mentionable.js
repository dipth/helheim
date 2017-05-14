let regEx = /@([\w\-\.\u00C0-\u017F]+)/giu

let replacer = function(match, username) {
  return `
    <a href="/usernames/${username}">${username}</a>
  `;
}

export var MentionableConfig = {
  at: "@",
  data: "/usernames"
}

export var MentionableInput = {
  run: function(){
    $('.mentionable-input').atwho(MentionableConfig);
  }
}

export var Mentionable = {
  run: function(){
    $('.mentionable').each(function(index){
      let el  = $(this);
      el.html(el.html().replace(regEx, replacer));
    })
  }
}
