
  short_poll_enable = false
  url = null
  return_data = null
  cached_resp = null
  ajax = new XMLHttpRequest()

  ajax.onreadystatechange = ->
    if @readyState is 4
      if (
        @status is 200  and
        @response isnt cached_resp
      )
        resp_obj = JSON.parse(@response).data

        switch return_data
          when "paths"
            paths = resp_obj.CurrentPaths.CurrentPath
            if paths?
              unless Array.isArray(paths)
                paths = [paths]
              paths.map (obj) ->
                obj.nodeUri = obj.nodeUri.replace(/^\\\\[^\\]*/, "")
                obj
              paths[0].megabytes =
                if resp_obj.bytesRead
                  (resp_obj.bytesRead/1024/1024).toFixed(2)
                else
                  0

            postMessage
              dest  : "paths"
              data  : paths ? []
              task_id : resp_obj.taskId

          when "events"
            postMessage
              dest  : "events"
              data  : resp_obj.Events.Event
              task_id : resp_obj.taskId

        cached_resp = @response

      set-timeout short_poll, 300

  short_poll = ->
    if short_poll_enable
      ajax.open(
        "GET"
        url
        true
      )
      ajax.send()

  onmessage = (e) ->
    if e.data.action is "start"
      cached_resp = null
      short_poll_enable = true
      return_data = e.data.return_data
      url = e.data.url
      short_poll()

    else if e.data.action is "stop"
      short_poll_enable = false
