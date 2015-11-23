OTHER_FIELD_FOR_MASK = '<other>'

OTHER_FIELD_FOR_TEXT = _.memoize -> $.t "reports.widget.other"

VIOLATION_LEVELS = [
  'High'
  'Medium'
  'Low'
  'No'
]

DIALOG_TYPES = [
  'domain'
  'email'
  'icq'
  'lotus'
  'lync'
  'pc'
  'person'
  'skype'
]

CAPTURE_DATE_TYPES = {
  "all"
  "this_day"
  "this_week"
  "this_month"
  "last_3_days"
  "last_7_days"
  "last_30_days"
  "last_days"
  "period"
}

DATE_FORMAT = "YYYY-MM-DD HH:mm:ss"

DATE_FORMAT_OUTPUT = 'DD MMM YYYY'

DATE_FORMAT_INPUT = 'YYYY-MM-DD HH:mm:ss.SSS'

captureDateToString = (captureDate, runDate) ->
  captureDateType = captureDate.type

  switch captureDateType
    when CAPTURE_DATE_TYPES.all, 'none'
      return $.t("reports.capture_date.all")

    when CAPTURE_DATE_TYPES.period
      typeStr = null

    when CAPTURE_DATE_TYPES.last_days
      days = captureDate.days
      plu = App.Helpers.pluralize(days, {"non", "gen", "plu"})
      typeStr = $.t "reports.capture_date.last_days_#{plu}", {count: days}

    else
      typeStr = $.t "reports.capture_date.#{captureDateType}"

  stingBuilder = []
  if typeStr
    stingBuilder.push(typeStr)

  period = createPeriodByCaptureDate(captureDate, runDate)
  if period and periodStr = periodToString(period)
    stingBuilder.push(periodStr)

  stingBuilder.join(", ")

periodToString = (period) ->
  if period is null
    return ""

  startDate = period.startDate
  endDate = period.endDate

  if startDate is null
    return "#{$.t("reports.capture_date.all")}"

  if startDate.year() is endDate.year()
    if startDate.month() is endDate.month()
      return "#{startDate.format('DD')} - #{endDate.format(DATE_FORMAT_OUTPUT)}"
    return "#{startDate.format('DD MMM')} - #{endDate.format(DATE_FORMAT_OUTPUT)}"

  "#{startDate.format(DATE_FORMAT_OUTPUT)} - #{endDate.format(DATE_FORMAT_OUTPUT)}"

createPeriodByCaptureDate = (captureDate, runDate) ->
  if not runDate
    return null

  startDate = null
  switch captureDate.type

    when CAPTURE_DATE_TYPES.period
      if captureDate.period[0]
        startDate = moment.unix(captureDate.period[0]).local()

      if captureDate.period[1]
        runDate = moment.unix(captureDate.period[1]).local()

    when CAPTURE_DATE_TYPES.this_day
      startDate = runDate.clone()

    when CAPTURE_DATE_TYPES.this_week
      startDate = runDate.clone().weekday(0)

    when CAPTURE_DATE_TYPES.this_month
      startDate = runDate.clone().date(1)

    when CAPTURE_DATE_TYPES.last_days
      days = captureDate.days
      startDate = runDate.clone().add(-days, 'd')

    when CAPTURE_DATE_TYPES.last_3_days
      startDate = runDate.clone().add(-3, 'd')

    when CAPTURE_DATE_TYPES.last_7_days
      startDate = runDate.clone().add(-7, 'd')

    when CAPTURE_DATE_TYPES.last_30_days
      startDate = runDate.clone().add(-30, 'd')

  if runDate.isBefore(startDate)
    startDate = [runDate, runDate = startDate][0]

  startDate : startDate
  endDate   : runDate

resolveFieldName = (text) ->
  text
  .replace(OTHER_FIELD_FOR_MASK, OTHER_FIELD_FOR_TEXT)
  .replace('<', '&lt;')
  .replace('[^-]>', '&gt;')

dateTimeUnitsToMomentFormat = (period) ->
  "#{period}s"

generateEntry = (name, levels = VIOLATION_LEVELS) ->
  violationLevels = {}
  for level in levels
    val = Math.round Math.random() * 100
    violationLevels[level] =
      name: level.toString()
      value: val

  id: name
  name: resolveFieldName name
  value: violationLevels

sortByLevels = (data, violationLevels = VIOLATION_LEVELS) ->
  data.sort (a, b) ->
    valA = a.value
    valB = b.value
    return 1 if (a.id is OTHER_FIELD_FOR_MASK)
    return -1 if (b.id is OTHER_FIELD_FOR_MASK)
    for level in violationLevels
      levelA = valA[level] or -1
      levelB = valB[level] or -1
      if levelA isnt levelB
        return if levelA < levelB then 1 else -1
    return if a.name < b.name then 1 else -1
    0

generatePersonActivity = (data, reportModel, widgetModel) ->
  maxDelta = 1000
  groupingByPeriod = dateTimeUnitsToMomentFormat(widgetModel.get('OPTIONS.groupingByPeriod') or 'day')
  runDate = moment()

  if reportModel.isCommonPeriodUsed()
    captureDate = reportModel.getCaptureDate()
    period = createPeriodByCaptureDate(captureDate, runDate)
  else
    period = widgetModel.captureDateToPeriod(runDate)

  endDate = period.endDate
  startDate = (period.startDate or endDate.clone().add(-10, groupingByPeriod)).startOf('day').startOf(groupingByPeriod)

  delta = Math.abs(if groupingByPeriod is 'quarters'
  then Math.floor(endDate.diff(startDate, 'month') / 3)
  else startDate.diff(endDate, groupingByPeriod))

  if delta > maxDelta
    delta = maxDelta
    startDate = endDate.clone().add(-maxDelta, groupingByPeriod)

  for i in [0..delta]
    data.push generateEntry(startDate.format(DATE_FORMAT))
    startDate.add(1, groupingByPeriod)

  if widgetModel.get("OPTIONS.violationLevels.all")
    for val in data
      sum = 0
      violationLevels = val.value
      for name, level of violationLevels
        sum += level.value

      violationLevels.All =
        name: 'All'
        value: sum

  # filter by selected violationLevels
  selectedViolationLevels = new RegExp widgetModel.getSelectedViolationLevels().join('|')
  for dataItem in data
    violationLevels = {}
    for itemName, itemValue of dataItem.value
      if selectedViolationLevels.test itemName
        violationLevels[itemName] = itemValue
    dataItem.value = violationLevels

  data

generateUserDecision = (data) ->
  for name in ['NotProcessed', 'NoViolation', 'Violation', 'AdditionalProcessingNeeded']
    data.push(generateEntry($.t("events.events.#{name}")))
  data

generateDialogs = (data, model) ->

  generateDialogEntry = (name) ->
    newEntry = generateEntry(name)
    newEntry.type = DIALOG_TYPES[Math.round(Math.random() * (DIALOG_TYPES.length - 1))]
    newEntry

  widgetType = model.get 'WIDGET_TYPE'
  baseEntryName = $.t "reports.widget.fake_data_types.#{widgetType}"
  limit = model.get('OPTIONS.limit')

  for i in [1..limit]
    if widgetType is 'sender_receiver'
      entryName = "#{$.t 'reports.widget.fake_data_types.sender'} #{i} -> #{$.t 'reports.widget.fake_data_types.receiver'} #{i}"
    else
      entryName = "#{baseEntryName} #{i}"

    data.push generateDialogEntry(entryName)

  if model.get('OPTIONS.showOthersGroup')
    data.push generateDialogEntry(OTHER_FIELD_FOR_MASK)

  data

generateChart = (data, model) ->
  baseEntryName = $.t "reports.widget.fake_data_types.#{model.get 'WIDGET_TYPE'}"
  limit = model.get('OPTIONS.limit')

  for i in [1..limit]
    entryName = "#{baseEntryName} #{i}"
    data.push generateEntry(entryName)

  if model.get('OPTIONS.showOthersGroup')
    data.push generateEntry(OTHER_FIELD_FOR_MASK)

filterPie = (data) ->
  for val in data
    sum = 0
    violationLevels = val.value
    for name, level of violationLevels
      sum += level.value
    val.value = sum
  data

getPeriod = (widgetModel) ->
  widgetModel

generateFakeData = (reportModel, widgetModel) ->
  widgetType = widgetModel.get('WIDGET_TYPE')
  chartType = widgetModel.get('WIDGET_VIEW')
  res = []

  switch widgetType
    when 'person_activity'
      generatePersonActivity res, reportModel, widgetModel
    when 'user_decision'
      generateUserDecision res, widgetModel
    when 'sender_receiver', 'sender', 'receiver'
      generateDialogs res, widgetModel
    else
      generateChart res, widgetModel

  switch chartType
    when 'pie'
      filterPie res

  res

module.exports =

  OTHER_FIELD_FOR_MASK        : OTHER_FIELD_FOR_MASK
  OTHER_FIELD_FOR_TEXT        : OTHER_FIELD_FOR_TEXT
  CAPTURE_DATE_TYPES          : CAPTURE_DATE_TYPES
  VIOLATION_LEVELS            : VIOLATION_LEVELS
  DIALOG_TYPES                : DIALOG_TYPES
  DATE_FORMAT                 : DATE_FORMAT
  DATE_FORMAT_INPUT           : DATE_FORMAT_INPUT

  resolveFieldName            : resolveFieldName
  createPeriodByCaptureDate   : createPeriodByCaptureDate
  periodToString              : periodToString
  captureDateToString         : captureDateToString
  dateTimeUnitsToMomentFormat : dateTimeUnitsToMomentFormat
  sortByLevels                : sortByLevels
  generateFakeData            : generateFakeData
  generateEntry               : generateEntry
