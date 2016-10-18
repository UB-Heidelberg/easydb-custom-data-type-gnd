Session::getCustomDataTypes = ->
  @getDefaults().server.custom_data_types or {}

class CustomDataTypeGND extends CustomDataType

  # the eventually running xhrs
  gnd_xhr = undefined
  entityfacts_xhr = undefined
  # suggestMenu
  suggest_Menu = new Menu
  # short info panel
  entityfacts_Panel = new Pane
  # locked gnd-URI
  conceptURI = ''
  # locked gnd-Name
  conceptName = ''
  # protocol
  protocol = location.protocol;

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-gnd.gnd"


  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.gnd.name")

  #######################################################################
  # handle editorinput
  renderEditorInput: (data, top_level_data, opts) ->
    # console.error @, data, top_level_data, opts, @name(), @fullName()
    if not data[@name()]
      cdata = {
            conceptName : ''
            conceptURI : ''
        }
      data[@name()] = cdata
      conceptURI = ''
      conceptName = ''
    else
      cdata = data[@name()]
      conceptName = cdata.conceptName
      conceptURI = cdata.conceptURI

    @__renderEditorInputPopover(data, cdata)


  #######################################################################
  # buttons, which open and close popover
  __renderEditorInputPopover: (data, cdata) ->
    @__layout = new HorizontalLayout
      left:
        content:
            loca_key: "custom.data.type.gnd.edit.button"
            onClick: (ev, btn) =>
              @showEditPopover(btn, cdata, data)
      center:
        content:
            loca_key: "custom.data.type.gnd.remove.button"
            onClick: (ev, btn) =>
              # delete data
              cdata = {
                    conceptName : ''
                    conceptURI : ''
              }
              data.gnd = cdata
              conceptURI = ''
              conceptName = ''
              # trigger form change
              Events.trigger
                node: @__layout
                type: "editor-changed"
              @__updateGNDResult(cdata)
      right: {}
    @__updateGNDResult(cdata)
    @__layout


  #######################################################################
  # update result in Masterform
  __updateGNDResult: (cdata) ->
    btn = @__renderButtonByData(cdata)
    @__layout.replace(btn, "right")


  #######################################################################
  # if type is DifferentiatedPerson or CorporateBody, get short info about entry from entityfacts
  __getInfoFromEntityFacts: (uri, tooltip) ->
    # extract gndID from uri
    gndID = uri
    gndID = gndID.split "/"
    gndID = gndID.pop()
    # download infos from entityfacts
    if entityfacts_xhr != undefined
      # abort eventually running request
      entityfacts_xhr.abort()
    # start new request
    xurl = protocol + '//jsontojsonp.gbv.de/?url=http://hub.culturegraph.org/entityfacts/' + gndID
    console.log xurl
    entityfacts_xhr = new (CUI.XHR)(url: xurl)
    entityfacts_xhr.start()
    .done((data, status, statusText) ->
      htmlContent = '<span style="font-weight: bold">Informationen über den Eintrag</span>'
      htmlContent += '<table style="border-spacing: 10px; border-collapse: separate;">'

      ##########################
      # DifferentiatedPerson and CorporateBody

      # Vollständiger Name (DifferentiatedPerson + CorporateBody)
      htmlContent += "<tr><td>Name:</td><td>" + data.preferredName + "</td></tr>"
      # Abbildung (DifferentiatedPerson + CorporateBody)
      depiction = data.depiction
      if depiction
        if depiction.thumbnail
          htmlContent += '<tr><td>Abbildung:</td><td><img src="' + depiction.thumbnail['@id'] + '" style="border: 0; max.width:120px; max-height:150px;" /></td></tr>'
      # Lebensdaten (DifferentiatedPerson)
      dateOfBirth = data.dateOfBirth
      dateOfDeath = data.dateOfDeath
      if dateOfBirth or dateOfDeath
        htmlContent += "<tr><td>Lebensdaten:</td><td>"
        if dateOfBirth and dateOfDeath
          htmlContent += dateOfBirth + " bis " + dateOfDeath
        else if dateOfBirth and !dateOfDeath
          htmlContent += dateOfBirth + " bis unbekannt"
        else if !dateOfBirth and dateOfDeath
          htmlContent += "unbekannt bis " + dateOfDeath
        htmlContent += "</td></tr>"
      # Date of Establishment (CorporateBody)
      dateOfEstablishment = data.dateOfEstablishment
      if dateOfEstablishment
        htmlContent += "<tr><td>Gründung:</td><td>" + dateOfEstablishment[0] + "</td></tr>"
      # Place of Business (CorporateBody)
      placeOfBusiness = data.placeOfBusiness
      places = []
      if placeOfBusiness
        if placeOfBusiness.length > 0
          for place in placeOfBusiness
            places.push(place.preferredName)
          htmlContent += "<tr><td>Niederlassung(en):</td><td>" + places.join("<br />") + "</td></tr>"
      # Übergeordnete Körperschaft (CorporateBody)
      hierarchicallySuperiorOrganisation = data.hierarchicallySuperiorOrganisation
      organisations = []
      if hierarchicallySuperiorOrganisation
        if hierarchicallySuperiorOrganisation.length > 0
          for organisation in hierarchicallySuperiorOrganisation
            organisations.push(organisation.preferredName)
          htmlContent += "<tr><td>Übergeordnete Körperschaft(en):</td><td>" + organisations.join("<br />") + "</td></tr>"
      # Geburtsort (DifferentiatedPerson)
      placeOfBirth = data.placeOfBirth
      if placeOfBirth
        htmlContent += "<tr><td>Geburtsort:</td><td>" + placeOfBirth[0].preferredName + "</td></tr>"
      # Sterbeort (DifferentiatedPerson)
      placeOfDeath = data.placeOfDeath
      if placeOfDeath
        htmlContent += "<tr><td>Sterbeort:</td><td>" + placeOfDeath[0].preferredName + "</td></tr>"
      # Berufe (DifferentiatedPerson)
      professionOrOccupation = data.professionOrOccupation
      professions = []
      if professionOrOccupation
        if professionOrOccupation.length > 0
          for profession in professionOrOccupation
            professions.push(profession.preferredName)
          htmlContent += "<tr><td>Beruf(e):</td><td>" + professions.join("<br />") + "</td></tr>"
      # Biographie (DifferentiatedPerson)
      biographicalOrHistoricalInformation = data.biographicalOrHistoricalInformation
      if biographicalOrHistoricalInformation
        htmlContent += "<tr><td>Biographie:</td><td>" + biographicalOrHistoricalInformation + "</td></tr>"
      # Thema (CorporateBody)
      topic = data.topic
      topics = []
      if topic
        if topic.length > 0
          for t in topic
            topics.push(t.preferredName)
          htmlContent += "<tr><td>Themen:</td><td>" + topics.join("<br />") + "</td></tr>"

      # Synonyme (DifferentiatedPerson + CorporateBody)
      variantName = data.variantName
      if variantName
        if variantName.length > 0
          variantNames = variantName.join("<br />")
          htmlContent += "<tr><td>Synonyme:</td><td>" + variantNames + "</td></tr>"

      htmlContent += "</table>"
      tooltip.getPane().replace(htmlContent, "center")
      tooltip.autoSize()
    )
    .fail (data, status, statusText) ->
        CUI.debug 'FAIL', entityfacts_xhr.getXHR(), entityfacts_xhr.getResponseHeaders()

    return


  #######################################################################
  # handle suggestions-menu
  __updateSuggestionsMenu: (cdata, cdata_form) ->
    that = @

    gnd_searchterm = cdata_form.getFieldsByName("gndSearchBar")[0].getValue()
    gnd_searchtype = cdata_form.getFieldsByName("gndSelectType")[0].getValue()
    # if "search-all-types", search all allowed types
    if gnd_searchtype == 'all_supported_types'
      gnd_searchtype = []
      if @getCustomSchemaSettings().add_differentiatedpersons?.value
        gnd_searchtype.push 'DifferentiatedPerson'
      if @getCustomSchemaSettings().add_coorporates?.value
        gnd_searchtype.push 'CorporateBody'
      if @getCustomSchemaSettings().add_geographicplaces?.value
        gnd_searchtype.push 'PlaceOrGeographicName'
      if @getCustomSchemaSettings().add_subjects?.value
        gnd_searchtype.push 'SubjectHeading'
      gnd_searchtype = gnd_searchtype.join(',')

    gnd_countSuggestions = cdata_form.getFieldsByName("gndSelectCountOfSuggestions")[0].getValue()

    if gnd_searchterm.length == 0
        return

    # run autocomplete-search via xhr
    if gnd_xhr != undefined
        # abort eventually running request
        gnd_xhr.abort()
    # start new request
    gnd_xhr = new (CUI.XHR)(url: protocol + '//ws.gbv.de/suggest/gnd/?searchterm=' + gnd_searchterm + '&type=' + gnd_searchtype + '&count=' + gnd_countSuggestions)
    gnd_xhr.start().done((data, status, statusText) ->

        CUI.debug 'OK', gnd_xhr.getXHR(), gnd_xhr.getResponseHeaders()

        # create new menu with suggestions
        menu_items = []
        for suggestion, key in data[1]
          do(key) ->
            # the actual Featureclass...
            aktType = data[2][key]
            lastType = ''
            if key > 0
              lastType = data[2][key-1]
            if aktType != lastType
              console.log aktType
              item =
                divider: true
              menu_items.push item
              item =
                label: aktType
              menu_items.push item
              item =
                divider: true
              menu_items.push item
            item =
              text: suggestion
              value: data[3][key]
              tooltip:
                markdown: true
                auto_size: true
                placement: "e"
                content: (tooltip) ->
                  # if enabled in mask-config
                  if that.getCustomMaskSettings().show_infopopup?.value
                    # if type is ready for infopopup
                    if aktType == "DifferentiatedPerson" or aktType == "CorporateBody"
                      that.__getInfoFromEntityFacts(data[3][key], tooltip)
                      new Label(icon: "spinner", text: "lade Informationen")
            menu_items.push item

        # set new items to menu
        itemList =
          onClick: (ev2, btn) ->

            # lock result in variables
            conceptName = btn.getText()
            conceptURI = btn.getOpt("value")

            # lock in save data
            cdata.conceptURI = conceptURI
            cdata.conceptName = conceptName
            # lock in form
            cdata_form.getFieldsByName("conceptName")[0].storeValue(conceptName).displayValue()
            # nach eadb5-Update durch "setText" ersetzen und "__checkbox" rausnehmen
            cdata_form.getFieldsByName("conceptURI")[0].__checkbox.setText(conceptURI)
            cdata_form.getFieldsByName("conceptURI")[0].show()

            # clear searchbar
            cdata_form.getFieldsByName("gndSearchBar")[0].setValue('')
          items: menu_items

        # if no hits set "empty" message to menu
        if itemList.items.length == 0
          itemList =
            items: [
              text: "kein Treffer"
              value: undefined
            ]

        suggest_Menu.setItemList(itemList)

        suggest_Menu.show(
          new Positioner(
            top: 60
            left: 400
            width: 0
            height: 0
          )
        )

    )
    #.fail (data, status, statusText) ->
        #CUI.debug 'FAIL', gnd_xhr.getXHR(), gnd_xhr.getResponseHeaders()


  #######################################################################
  # reset form
  __resetGNDForm: (cdata, cdata_form) ->
    # clear variables
    conceptName = ''
    conceptURI = ''
    cdata.conceptName = ''
    cdata.conceptURI = ''

    # reset type-select
    cdata_form.getFieldsByName("gndSelectType")[0].setValue("DifferentiatedPerson")

    # reset count of suggestions
    cdata_form.getFieldsByName("gndSelectCountOfSuggestions")[0].setValue(20)

    # reset searchbar
    cdata_form.getFieldsByName("gndSearchBar")[0].setValue("")

    # reset result name
    cdata_form.getFieldsByName("conceptName")[0].storeValue("").displayValue()

    # reset and hide result-uri-button
    cdata_form.getFieldsByName("conceptURI")[0].__checkbox.setText("")
    cdata_form.getFieldsByName("conceptURI")[0].hide()


  #######################################################################
  # if something in form is in/valid, set this status to masterform
  __setEditorFieldStatus: (cdata, element) ->
    switch @getDataStatus(cdata)
      when "invalid"
        element.addClass("cui-input-invalid")
      else
        element.removeClass("cui-input-invalid")

    Events.trigger
      node: element
      type: "editor-changed"

    @

  #######################################################################
  # show popover and fill it with the form-elements
  showEditPopover: (btn, cdata, data) ->
    # set default value for count of suggestions
    cdata.gndSelectCountOfSuggestions = 20
    cdata_form = new Form
      data: cdata
      fields: @__getEditorFields()
      onDataChanged: =>
        @__updateGNDResult(cdata)
        @__setEditorFieldStatus(cdata, @__layout)
        @__updateSuggestionsMenu(cdata, cdata_form)
    .start()
    xpane = new SimplePane
      class: "cui-demo-pane-pane"
      header_left:
        new Label
          text: "Header left shortcut"
      content:
        new Label
          text: "Center content shortcut"
      footer_right:
        new Label
          text: "Footer right shortcut"
    @popover = new Popover
      element: btn
      fill_space: "both"
      placement: "c"
      pane:
        # titel of popovers
        header_left: new LocaLabel(loca_key: "custom.data.type.gnd.edit.modal.title")
        # "save"-button
        footer_left: new Button
            text: "Ok, Popup schließen"
            onClick: =>
              # put data to savedata
              data.gnd = {
                conceptName : cdata.conceptName
                conceptURI : cdata.conceptURI
              }
              # close popup
              @popover.destroy()
        # "reset"-button
        footer_right: new Button
            text: "Zurücksetzen"
            onClick: =>
              @__resetGNDForm(cdata, cdata_form)
              @__updateGNDResult(cdata)
        content: cdata_form
    .show()


  #######################################################################
  # create form
  __getEditorFields: ->
    # read searchtypes from datamodell-options
    dropDownSearchOptions = []
    # offer DifferentiatedPerson
    if @getCustomSchemaSettings().add_differentiatedpersons?.value
        option = (
            value: 'DifferentiatedPerson'
            text: 'Individualisierte Personen'
          )
        dropDownSearchOptions.push option
    # offer CorporateBody?
    if @getCustomSchemaSettings().add_coorporates?.value
        option = (
            value: 'CorporateBody'
            text: 'Körperschaften'
          )
        dropDownSearchOptions.push option
    # offer PlaceOrGeographicName?
    if @getCustomSchemaSettings().add_geographicplaces?.value
        option = (
            value: 'PlaceOrGeographicName'
            text: 'Orte und Geographische Namen'
          )
        dropDownSearchOptions.push option
    # offer add_subjects?
    if @getCustomSchemaSettings().add_subjects?.value
        option = (
            value: 'SubjectHeading'
            text: 'Schlagwörter'
          )
        dropDownSearchOptions.push option
    # add "Alle"-Option? If count of options > 1!
    if dropDownSearchOptions.length > 1
        option = (
            value: 'all_supported_types'
            text: 'Alle'
          )
        dropDownSearchOptions.unshift option
    # if empty options -> offer all
    if dropDownSearchOptions.length == 0
        dropDownSearchOptions = [
          (
            value: 'DifferentiatedPerson'
            text: 'Individualisierte Personen'
          )
          (
            value: 'CorporateBody'
            text: 'Körperschaften'
          )
          (
            value: 'PlaceOrGeographicName'
            text: 'Orte und Geographische Namen'
          )
          (
            value: 'SubjectHeading'
            text: 'Schlagwörter'
          )
        ]
    [{
      type: Select
      undo_and_changed_support: false
      form:
          label: $$('custom.data.type.gnd.modal.form.text.type')
      options: dropDownSearchOptions
      name: 'gndSelectType'
    }
    {
      type: Select
      undo_and_changed_support: false
      form:
          label: $$('custom.data.type.gnd.modal.form.text.count')
      options: [
        (
            value: 10
            text: '10 Vorschläge'
        )
        (
            value: 20
            text: '20 Vorschläge'
        )
        (
            value: 50
            text: '50 Vorschläge'
        )
        (
            value: 100
            text: '100 Vorschläge'
        )
      ]
      name: 'gndSelectCountOfSuggestions'
    }
    {
      type: Input
      undo_and_changed_support: false
      form:
          label: $$("custom.data.type.gnd.modal.form.text.searchbar")
      placeholder: $$("custom.data.type.gnd.modal.form.text.searchbar.placeholder")
      name: "gndSearchBar"
    }
    {
      form:
        label: "Gewählter Eintrag"
      type: Output
      name: "conceptName"
      data: {conceptName: conceptName}
    }
    {
      form:
        label: "Verknüpfte URI"
      type: FormButton
      name: "conceptURI"
      icon: new Icon(class: "fa-lightbulb-o")
      text: conceptURI
      onClick: (evt,button) =>
        window.open conceptURI, "_blank"
      onRender : (_this) =>
        if conceptURI == ''
          _this.hide()
    }
    ]

  #######################################################################
  # renders details-output of record
  renderDetailOutput: (data, top_level_data, opts) ->
    @__renderButtonByData(data[@name()])


  #######################################################################
  # checks the form and returns status
  getDataStatus: (cdata) ->
    if (cdata)
        if cdata.conceptURI and cdata.conceptName

          uriCheck = ///^
            http://d-nb.info/gnd/
            (1|1[01])\d{7}[0-9X]|[47]\d{6}-\d|[1-9]\d{0,7}-[0-9X]|3\d{7}[0-9X]
            ///.test(cdata.conceptURI)

          nameCheck = if cdata.conceptName then cdata.conceptName.trim() else undefined

          if uriCheck and nameCheck
            console.debug "getDataStatus: OK "
            return "ok"

          if cdata.conceptURI.trim() == '' and cdata.conceptName.trim() == ''
            console.debug "getDataStatus: empty"
            return "empty"

          console.debug "getDataStatus returns invalid"
          return "invalid"
        else
          cdata = {
                conceptName : ''
                conceptURI : ''
            }
          console.debug "getDataStatus: empty"
          return "empty"


  #######################################################################
  # renders the "result" in original form (outside popover)
  __renderButtonByData: (cdata) ->
    # when status is empty or invalid --> message
    switch @getDataStatus(cdata)
      when "empty"
        return new EmptyLabel(text: $$("custom.data.type.gnd.edit.no_gnd")).DOM
      when "invalid"
        return new EmptyLabel(text: $$("custom.data.type.gnd.edit.no_valid_gnd")).DOM

    # if status is ok
    conceptURI = CUI.parseLocation(cdata.conceptURI).url

    # if conceptURI .... ... patch abwarten

    tt_text = $$("custom.data.type.gnd.url.tooltip", name: cdata.conceptName)

    # output Button with Name of picked GND-Entry and Url to the Deutsche Nationalbibliothek
    new ButtonHref
      appearance: "link"
      href: cdata.conceptURI
      target: "_blank"
      tooltip:
        markdown: true
        text: tt_text
      text: cdata.conceptName + ' (' + cdata.conceptURI + ')'
    .DOM


  #######################################################################
  # is called, when record is being saved by user
  getSaveData: (data, save_data, opts) ->
    cdata = data[@name()] or data._template?[@name()]
    switch @getDataStatus(cdata)
      when "invalid"
        throw InvalidSaveDataException
      when "empty"
        save_data[@name()] = null
      when "ok"
        save_data[@name()] =
          conceptName: cdata.conceptName.trim()
          conceptURI: cdata.conceptURI.trim()



  renderCustomDataOptionsInDatamodel: (custom_settings) ->
    @


CustomDataType.register(CustomDataTypeGND)
