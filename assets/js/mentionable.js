import Tribute from "../vendor/js/tribute";

let regEx = /@([-\w\.\u00C0-\u017F]+)/giu;

let replacer = function(match, username) {
  return `<a href="/usernames/${username}">${username}</a>`;
}

export var initializeTribute = function(element) {
  console.log("initializeTribute called!", element)
  let usernames = document.querySelector("meta[name=usernames]").getAttribute("content").split(",")
  let tributes = usernames.map((username, _index) => ({ key: username, value: username }))
  let tribute = new Tribute({
    values: tributes,
    menuItemLimit: 8
  })
  tribute.attach(element)
}

export var MentionableInput = {
  run: function(){
    initializeTribute(document.querySelectorAll(".mentionable-input"))
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
