"use strict"

App.module "Crawler",
  startWithParent: false
  define: (Module, App, Backbone, Marionette, $) ->

    class @cls.JobDetailsView extends Marionette.ItemView

      # *************
      #  PRIVATE
      # *************
      _path_replacer_for_scan_policy = (path, scan_policy) ->
        if scan_policy.match("DBFileStorage")
          path
          .replace /\\/g, "/"
          .replace /.{1};/g, (last_on_line) ->
            if last_on_line is "%;"
              "%;"
            else
              "#{ last_on_line[0] }%;"
          .replace /;$/, ""
        else
          path
          .replace /\//g, "\\"
          .replace /.{1};/g, (last_on_line) ->
            if last_on_line is "*;"
              "*;"
            else
              "#{ last_on_line[0] }*;"
          .replace /;$/, ""

      _is_ip_range = (ip_range) ->
        ips = ip_range.split "-"

        if ips.length is 2
          _.every ips, (ip) ->
            not (
              App.Common.ValidationModel::validators.ip ip
            )?
        else
          false

      # *************
      #  STICKIT
      # *************
      bindings:

        "#job_details_common_workstations" :
          observe: "Targets.Target"
          onGet: (val) ->
            if val.length is 0
              return "#{App.t('form.error.required').replace("%s", "")}"
            else if @model.get("__created_now")
              @model.set("__not_filled.workstations", null)

            if @model.get("scanPolicy").match("DBFileStorage")
              return "#{ App.t 'crawler.job_details_common_not_ws_for_dbfs' }"

            formatted_type = (type) ->
              switch type
                when "TMGroup"  then App.t 'organization.tm_group'
                when "ADGroup"  then App.t 'organization.ad_group'
                when "Workstation", "WorkstationManual"  then App.t 'organization.workstation'
                when "IpRange"  then App.t "crawler.ip_range"

            result = (
              "#{item.hostname} (#{formatted_type(item.type)}) <br/>"  for item in val
            )
            result.join("")

          getVal: ($el, e, options, extra) ->
            @model.set(
              "Targets.Target"
              extra[0].newValue
            )

          classes :
            "muted" :
              observe : "Targets.Target"
              onGet  : (val) ->
                @model.get("scanPolicy").match("DBFileStorage")
            "text-error" :
              observe : "Targets.Target"
              onGet  : (val) ->
                val.length is 0
          events: ["save"]
          updateMethod: "html"

        "#job_details_common_schedule" :
          observe: ["Schedule.type", "Schedule.dayOfWeek", "Schedule.timeOfDay"]
          onGet: (arr) ->
            [type, day, time] = arr
            if @model.get("__created_now")  and  type is ""
              return "#{App.t('form.error.required').replace("%s", "")}"
            else if @model.get("__created_now")
              @model.set("__not_filled.schedule", null)

            if type is "Manual"
              App.t 'crawler.job_details_common_schedule_type.Manual'
            else if type is "Weekly"
              """
                #{App.t('crawler.job_details_common_schedule_type.Weekly')};#{}
                #{App.t('crawler.job_details_common_schedule_day_of_week_i', { returnObjectTrees: true })[day]};#{}
                #{time}
              """
            else if type is "Daily"
              """
                #{App.t 'crawler.job_details_common_schedule_type.Daily'};#{}
                #{time}
              """

          getVal: ($el, e, options, extra) ->
            [type, day, time] = extra[0].newValue

            @model.set
              "Schedule.type"    : type
              "Schedule.dayOfWeek" : day
              "Schedule.timeOfDay" : time

          events: ["save"]
          updateMethod: "html"
          classes :
            "text-error" :
              observe : "Schedule.type"
              onGet  : (val) ->
                @model.get("__created_now")  and  val is ""

        "#job_details_common_mode" :
          observe: [
            "scanMode"
            "Filters.ForbiddenPathFilter.path"
            "Filters.AllowedPathFilter.path"
            "FileSystem.excludeSystemFolders"
          ]

          getVal: ($el, e, options, extra) ->
            val = extra[0].newValue

            @model.set "Filters.ForbiddenPathFilter.path",
              if val[0] is "AllExceptForbidden"
                _path_replacer_for_scan_policy val[1], @model.get("scanPolicy")
              else
                ""

            @model.set "Filters.AllowedPathFilter.path",
              if val[0] is "OnlyAllowed"
                _path_replacer_for_scan_policy val[1], @model.get("scanPolicy")
              else
                ""

            @model.set
              "scanMode"              : val[0]
              "FileSystem.excludeSystemFolders" : val[2]

        "#job_details_common_scan_policy" :
          observe: ["scanPolicy", "FileSystem.scanAdminShares", "Targets.Target"]
          onGet: (params) ->
            if @model.get("__created_now")  and  params[0] is ""
              return "#{App.t('form.error.required').replace("%s", "")}"
            else if @model.get("__created_now")
              @model.set("__not_filled.policy", null)

            switch true
              when params[0] is "FilesShare"
                if params[1] is "true"
                  App.t "crawler.job_details_common_scan_policy_local"
                else if params[1] is "false"
                  App.t "crawler.job_details_common_scan_policy_network"
              when !!params[0].match("DBFileStorage")
                """
                  #{App.t "crawler.job_details_common_scan_policy_sharepoint"} \
                  (#{ params[2][0].uri })
                """

          getVal: ($el, e, options, extra) ->
            val = extra[0].newValue
            scan_admin_shares = val.value.match(/\[(true|false)\]/)

            if scan_admin_shares?
              @model.set "FileSystem.scanAdminShares", scan_admin_shares[1]
              @model.set "FileSystem.protocol", "SMB"

            if val.value.match("DBFileStorage")
              @model.set(
                "Targets.Target"
                [{
                  hostname : val.dbfs_creds
                  type   : "WorkstationManual"
                  uri    : val.dbfs_creds
                }]
              )

            @model.set
              scanPolicy        : val.value.replace /\[(true|false)\]/, ""
              scanPolicyDescription : val.desc

            if val.value.match("DBFileStorage")
              @model.set "FileSystem.protocol", "DBFS"
              @model.set "FileSystem.scriptId", "1"
              @model.set "FileSystem.scriptName", "SharePoint 2007"
            else
              @model.set "FileSystem.scriptId", "-1"
              @model.set "FileSystem.scriptName", ""

            if (
              @model.previous("scanPolicy").match("DBFileStorage")  and
              not @model.get("scanPolicy").match("DBFileStorage")
            )
              @model.set(
                "Targets.Target" : []
              )
            else
              @model.trigger(
                "change:Targets.Target"
                @model
                @model.get("Targets.Target")
              )

            @ui.editable
            .editable "destroy"
            .editable _xeditable_setting

          events: ["save"]
          updateMethod: "html"
          classes :
            observe : "scanPolicy"
            onGet  : (val) ->
              @model.get("__created_now")  and  val is ""

      # ***********************
      #  MARIONETTE-EVENTS
      # ***********************
      onShow: ->
        @ui.editable.on "shown", (e, editable) ->
          unless helpers.can({action: 'edit', type: 'task'})
            editable.hide()
            App.Notifier.showError
              text : App.t 'global.must_not_edit_content'
            return

          model = Module.reqres.request "get:job:details:model"

          # Если задание/сканер заблокироно/запущено, то нельзя редактировать
          if(
            model.get("running") is "true" or

            model.get("locked") is "true" and
            model.get("owner.USER_ID") isnt App.Session.currentUser().get('USER_ID').toString()
          )
            editable.hide()
            App.Notifier.showError
              text : do ->
                if model.type is "job"
                  App.t 'crawler.job_locked_for_edit'
                else if model.type is "scanner"
                  App.t 'crawler.scanner_locked_for_edit'
            return

      # ***************
      #  PROTECTED
      # ***************
      _validation:
        scan_mode: (val) ->
          if val[0] isnt "AllFolders"
            if val[1] is ""
              App.t 'crawler.job_details_common_mode_invalid_empty'

            if val[1].match /// [ " < > : | ]+ ///
              App.t 'crawler.job_details_common_mode_invalid_symbols'

        scan_policy: (obj) ->
          if (
            obj.value.match("DBFileStorage")  and
            not obj.dbfs_creds.match(
              ///
                ^
                  .+
                  \\
                  .+
                $
              ///
            )?
          )
            App.t 'crawler.job_details_common_scan_policy_dbfs_creds_invalid'

        file_formats : (arr) ->
          if (
            _.isEmpty(arr)  or
            _.every arr, (obj) ->
              obj.enabled is "false"
          )
            App.t 'crawler.job_details_common_file_formats_invalid'



      _particular_init:
        job_details_common_workstations: (e, editable) ->
          editable.options.validate = "workstations"
          editable.input.render = ->
            $added.droppable
              activeClass: "animated  wobble"
              drop: (e, ui) ->
                # Предполагается рабочая станция
                if ui.helper.hasClass "crawler_workstation"
                  model = Module.obj.workstations_collection.get(
                    ui.helper.data "id"
                  )
                # Предполагается группа
                else if ui.helper.hasClass "fancytree-drag-helper"
                  model = Module.obj.groups_collection.get(
                    ui.helper.data("dtSourceNode").data.key
                  )

                if (
                  model?  and
                  $added.find "[data-uri=#{ model.id }]"
                  .length is 0
                )
                  $added.append(
                    Marionette.Renderer.render(
                      "crawler/added_group_workstation"
                      _.extend
                        uri     : model.id
                        displayname : model.get("DISPLAY_NAME")
                        if model.type is "group"
                          if model.get("SOURCE") is "ad"
                            type   : "ADGroup"
                            vis_type : App.t 'organization.ad_group'
                          else if model.get("SOURCE") is "tm"
                            type   : "TMGroup"
                            vis_type : App.t 'organization.tm_group'
                        else if model.type is "workstation"
                          type   : "Workstation"
                          vis_type : App.t 'organization.workstation'
                    )
                  )

            $manually_add = groups_view.$("#crawler_manually_added_workstations")
            $manually_add.on "keypress", (e) ->
              if e.keyCode isnt 13  then return
              vals = e.target.value.split("\n")

              for val in vals
                if (
                  val isnt ""  and
                  $added.find("[data-hostname=\"#{ val.toLowerCase() }\"]").length is 0  and
                  not val.match(/[а-я]+/i)?
                )
                  $added.append(
                    Marionette.Renderer.render(
                      "crawler/added_group_workstation"
                      _.extend
                        displayname : val.toLowerCase()
                      ,
                        if _is_ip_range val
                          from   : val.split( "-" )[0],
                          to     : val.split( "-" )[1],
                          type   : "IpRange"
                          vis_type : App.t 'crawler.ip_range'
                        else
                          type   : "WorkstationManual"
                          uri    : val.toLowerCase()
                          vis_type : App.t 'organization.workstation'
                    )
                  )

              _.defer -> e.target.value = ""

          editable.input.input2value = ->
            $els = $("#crawler_added_groups_workstations").children(".crawler_group_or_workstation")
            _.map $els, (el) -> el.dataset

          editable.input.value2input = ->
            params = Module.reqres.request("get:job:details:model").get("Targets.Target")
            $("#crawler_added_groups_workstations").html(
              (
                _.map params, (param) ->
                  Marionette.Renderer.render(
                    "crawler/added_group_workstation"
                    displayname : param.hostname
                    type    : param.type
                    uri     : param.uri
                    vis_type  :
                      if param.type.match /^Workstation/
                        App.t 'organization.workstation'
                      else if param.type is "ADGroup"
                        App.t 'organization.ad_group'
                      else if param.type is "TMGroup"
                        App.t 'organization.tm_group'
                  )
              )
              .join("")
            )
