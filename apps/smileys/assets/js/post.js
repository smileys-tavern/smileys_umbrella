import $ from "jquery"
import { Channels } from "./socket"


export var Post = {

  init: function() {
    var that = this

    if ($('#original-post').length) {
      Channels.joinPost($('#original-post').data('hash'))
    }

    $('body').on('click', '.vote-up', function() {
      var hash = $(this).data('hash')

      if (Channels.postChannel) {
        Channels.postChannel.push("voteup", {posthash: hash.toString()})
      }
    })

    $('body').on('click', '.vote-down', function() {
      var hash = $(this).data('hash')

      if (Channels.postChannel) {
        Channels.postChannel.push("votedown", {posthash: hash.toString()})
      }
    })

    $('.comments, .original-post').on('click', '.reply', function() {
      var hash = $(this).data('hash')

      var commentForm = $('#comment-reply-form').html()

      // Get form and show it below current comment
      $('#comment-reply-' + hash).html(commentForm)

      $('#comment-reply-' + hash).find('textarea').focus()

      $('#comment-reply-' + hash).find('.comment-reply-send').data('hash', hash)
    })

    $('.comments, .original-post').on('click', '.moddelete', function() {
      var hash = $(this).data('hash')

      var commentForm = $('#comment-delete-form').html()

      // Get form and show it below current comment
      $('#comment-reply-' + hash).html(commentForm)

      $('#comment-reply-' + hash).find('textarea').focus()

      $('#comment-reply-' + hash).find('.comment-delete-send').data('hash', hash)
    })

    $('.comments, .original-post').on('click', '.edit', function() {
      var hash = $(this).data('hash')

      var commentForm = $('#comment-edit-form').html()

      $('#comment-reply-' + hash).html(commentForm)

      $('#comment-reply-' + hash).find('textarea').focus()

      $('#comment-reply-' + hash).find('.comment-edit-send').data('hash', hash)

      $('#comment-reply-' + hash).find('textarea').val($('#comment-reply-' + hash).parent().find('.textbody').html())
    })

    $('.comments, .original-post').on('click', '.comment-reply-cancel', function() {
      $(this).parent().parent().remove()
    })

    $('.comments, .original-post').on('click', '.comment-edit-send', function() {
      var editHash = $(this).data('hash')

      var body = $(this).parent().parent().find('textarea').first().val()

      that.commentEdit(editHash, body)
    })

    $('.comments, .original-post').on('click', '.comment-reply-send', function() {
      var replyToHash = $(this).data('hash')

      var body = $(this).parent().parent().find('textarea').first().val()

      var depth = $('#comment-reply-' + replyToHash).data('commentdepth')

      that.commentReply(replyToHash, body, depth)
    })

    $('.comments, .original-post').on('click', '.comment-delete-send', function() {
      var replyToHash = $(this).data('hash')

      var body = $(this).parent().parent().find('textarea').first().val()

      var depth = $('#comment-reply-' + replyToHash).data('commentdepth')

      that.commentReply(replyToHash, body, depth, true)
    })

    // Reload thread
    $('.actions').on('click', '.load-thread', function() {
      var hash = $(this).data('hash')
      var op = $('#original-post')

      if (Channels.userChannel) {
        Channels.userChannel.push("load_thread", {hash: hash, mode: op.data("mode")})
          .receive("ok", (response) => {

            that.reloadThread(hash, response.thread)
          })
      }

      $(this).parent().addClass("hidden")
    })

    $('.comments').on('click', '.collapse-thread', function() {
      var hash = $(this).data('hash')

      that.collapseThread(hash)

      $(this).removeClass('collapse-thread')
      $(this).addClass('expand-thread')
      $(this).text('Expand')
    })

    $('.comments').on('click', '.expand-thread', function() {
      var hash = $(this).data('hash')

      that.expandThread(hash)

      $(this).addClass('collapse-thread')
      $(this).removeClass('expand-thread')
      $(this).text('Collapse')
    })
  },

  reloadThread: function(hash, new_thread_html) {
    var comment = $('#comment-' + hash)

    var current = comment.next()

    // remove all comments in current thread
    while (current.data("commentdepth") && current.data("commentdepth") > 1) {
      current.remove()

      current = comment.next()
    }

    // Since thread was treates as op, need to increase depth 1 for all nodes
    var thread_nodes = $.parseHTML(new_thread_html)

    $.each(thread_nodes, function() {
      var depth     = $(this).data("commentdepth")
      var new_depth = depth - (-1)

      $(this).data("commentdepth", new_depth)
      $(this).removeClass("comment-depth-" + depth)
      $(this).addClass("comment-depth-" + new_depth)
    });

    comment.after(thread_nodes)
  },

  collapseThread: function(hash) {
    var comment = $("#comment-" + hash)
    var originalDepth = comment.data("commentdepth")

    var current = comment.next()

    while (current.data("commentdepth") && current.data("commentdepth") > originalDepth) {
      current.addClass("hidden")

      current = current.next()
    }
  },

  expandThread: function(hash) {
    var comment = $("#comment-" + hash)
    var originalDepth = comment.data("commentdepth")

    var current = comment.next()

    while (current.data("commentdepth") && current.data("commentdepth") > originalDepth) {
      current.removeClass("hidden")

      current = current.next()
    }
  },

  commentEdit: function(hash, body) {
    Channels.postChannel.push("edit", {posthash: hash, ophash: $('#original-post').data('hash'), body: body})
      .receive("ok", (response) => {
        $('#comment-reply-' + response.hash).html('')
        $('#comment-reply-' + response.hash).parent().find('.textbody').html(response.comment)
      })
  },

  // Also handles mod deletions since reason is generated as a reply
  commentReply: function(hash, body, depth, modDelete) {
    var csrfToken = $('meta[name="_csrf_token"]').attr('content');
    var operation = modDelete ? "mod-delete-comment" : "reply"

    if (operation == "mod-delete-comment") {
      $.ajax({
        url: "/mod/delete/comment/" + hash,
        data: {operation: operation, posthash: hash, ophash: $('#original-post').data('hash'), body: body, depth: depth},
        beforeSend: function(xhr) {
          xhr.setRequestHeader('x-csrf-token', csrfToken);
          xhr.setRequestHeader('_csrf_token', csrfToken);
        },
        method: "POST",
        context: document.body
      }).done(function(response) {
        $('#comment-reply-' + response.ochash).html('')
        $('#comment-reply-' + response.ochash).parent().after(response.comment)

        if (modDelete) {
          if (response.ochash == $('#original-post').data('hash')) {
            $('.op-body p').html(response.edited)
          } else {
            $('#comment-reply-' + hash).parent().find('.textbody').html(response.edited)
          }
        }
      });
    } else {
      $.ajax({
        url: "/post/" + hash + "/comment",
        data: {operation: operation, posthash: hash, ophash: $('#original-post').data('hash'), body: body, depth: depth},
        beforeSend: function(xhr) {
          xhr.setRequestHeader('x-csrf-token', csrfToken);
          xhr.setRequestHeader('_csrf_token', csrfToken);
        },
        method: "POST",
        context: document.body
      }).done(function(response) {
        $('#comment-reply-' + response.ochash).html('')
        $('#comment-reply-' + response.ochash).parent().after(response.comment)

        if (modDelete) {
          if (response.ochash == $('#original-post').data('hash')) {
            $('.op-body p').html(response.edited)
          } else {
            $('#comment-reply-' + hash).parent().find('.textbody').html(response.edited)
          }
        }
      });
    }
  }
}
