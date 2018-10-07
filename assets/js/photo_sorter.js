export var PhotoSorter = {
  run: function(){
    let photosContainer = $('#photos.mine')[0]

    let drake = dragula([photosContainer], {
      mirrorContainer: photosContainer
    })

    let dropHandler = (_el, target, _source, _sibling) => {
      target       = $(target)
      let photoIds = target.find('.photo').not(".gu-mirror").map((_index, photo) => { return $(photo).data('id') }).get()
      let url      = target.data('reposition-url')
      reposition(url, photoIds)
    }

    let reposition = (url, photoIds) => {
      $.ajax({
        url:  url,
        type: 'PUT',
        data: {
          _csrf_token: $('body').data('csrf'),
          photo_ids: photoIds
        }
      })
    }

    drake.on('drop', dropHandler)
  },
}
