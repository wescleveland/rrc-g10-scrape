###

rrc_g10_scrape
https://github.com/wescleveland/rrc-g10-scrape

Copyright (c) 2013 Wes Cleveland
Licensed under the MIT license.

Note:  This is a quick and dirty scraping example,
is probably not going to be DRY, and is probably fragile like fine china...

###
'use strict'

request = require "request"
cheerio = require "cheerio"

class Scraper
  # TODO: determine total number of lease pages
  # TODO: rate limit fetching
  # TODO: separate fetching and parsing responsibilities
  # Big TODO: save fetched page to S3 or equiv for replay ability, debugging
  maxPages: 3  # Maximum number of lease pages to fetch (100 leases per page)

  run: (district, wellType, callback) =>
    # Callback should be called with either a lease or an error
    @fetchLeaseList(district, wellType, page, callback) for page in [0...@maxPages]
    return

  fetchLeaseList: (district, wellType, page, callback) =>
    offset = page * 100
    # This gives me nightmares but I don't want to figure out which params are
    # required right now...
    url = "http://webapps2.rrc.state.tx.us/EWA/gasProQueryAction.do?searchArgs.
gasWellTypeHndlr.inputValue=#{wellType}&searchArgs.districtCodeArgHndlr.in
putValue=#{district}&methodToCall=search&actionManager.recordCountHndlr.inputValue=2&
actionManager.currentIndexHndlr.inputValue=1&actionManager.actionRcrd%5B0%5D
.actionDisplayNmHndlr.inputValue=&actionManager.actionRcrd%5B0%5D.hostHndlr
.inputValue=webapps2.rrc.state.tx.us%3A80&actionManager.actionRcrd%5B0%5D.co
ntextPathHndlr.inputValue=%2FEWA&actionManager.actionRcrd%5B0%5D.actionHndlr
.inputValue=%2FgasProQueryAction.do&actionManager.actionRcrd%5B0%5D.actionPa
rameterHndlr.inputValue=methodToCall&actionManager.actionRcrd%5B0%5D.actionM
ethodHndlr.inputValue=returnToSearch&actionManager.actionRcrd%5B0%5D.pagerPa
rameterKeyHndlr.inputValue=&actionManager.actionRcrd%5B0%5D.actionParameters
Hndlr.inputValue=&actionManager.actionRcrd%5B0%5D.returnIndexHndlr.inputValu
e=0&actionManager.actionRcrd%5B0%5D.argRcrdParameters%28searchArgs.paramValu
e%29=%7C12%3DPR%7C102%3D01&actionManager.actionRcrd%5B1%5D.actionDisplayNmHn
dlr.inputValue=&actionManager.actionRcrd%5B1%5D.hostHndlr.inputValue=webapps
2.rrc.state.tx.us%3A80&actionManager.actionRcrd%5B1%5D.contextPathHndlr.inpu
tValue=%2FEWA&actionManager.actionRcrd%5B1%5D.actionHndlr.inputValue=%2FgasP
roQueryAction.do&actionManager.actionRcrd%5B1%5D.actionParameterHndlr.inputV
alue=methodToCall&actionManager.actionRcrd%5B1%5D.actionMethodHndlr.inputVal
ue=search&actionManager.actionRcrd%5B1%5D.pagerParameterKeyHndlr.inputValue=
pager.paramValue&actionManager.actionRcrd%5B1%5D.actionParametersHndlr.input
Value=&actionManager.actionRcrd%5B1%5D.returnIndexHndlr.inputValue=0&actionM
anager.actionRcrd%5B1%5D.argRcrdParameters%28pager.paramValue%29=%7C1%3D1%7C
2%3D10%7C3%3D3644%7C4%3D0%7C5%3D365%7C6%3D10&actionManager.actionRcrd%5B1%5D
.argRcrdParameters%28searchArgs.paramValue%29=%7C12%3DPR%7C102%3D01&pager.pa
geSize=100&pager.offset=#{offset}"
    parse_page = (error, response, body) =>
      scraper = @
      _cb = callback
      if(error or response.statusCode != 200)
        return _cb(error, undefined)
      $ = cheerio.load(body)
      # Find td's with width=50%
      # There are 2 of these per table row, we want the 2nd one with searchType=distLease in the a's href
      tds = $("td[width='50%']")
      lease_urls = []
      for td in tds
        href = td.children[1].attribs['href']
        if href.indexOf('searchType=distLease') != -1
          lease_urls.push(href)
      console.log "Found #{lease_urls.length} lease urls on page #{page}"
      scraper.fetchLease(url, _cb) for url in lease_urls
    request.get(url, parse_page)

  fetchLease: (lease_url, callback) =>
    base_url = "http://webapps2.rrc.state.tx.us/EWA/"
    parse_page = (error, response, body) =>
      _cb = callback
      scraper = @
      if(error or response.statusCode != 200)
        return _cb(error, undefined)  # this should actually call an error handler
                                 # for a specific lease, probably set in the
                                 # scraper's constructor
      $ = cheerio.load(body)
      # Build initial lease object from lease details page
      lease = {}
      row = $(".DataGrid").find('tr > td')
      # TODO: check for changing columns, new columns, etc
      lease.api = row[5].children[0].data.replace /^\s+|\s+$/g, ""
      lease.district = row[7].children[0].data.replace /^\s+|\s+$/g, ""
      lease.lease_num = row[9].children[1].children[0].data.replace /^\s+|\s+$/g, ""
      lease.lease_name = row[11].children[0].data.replace /^\s+|\s+$/g, ""
      lease.well_num = row[12].children[0].data.replace /^\s+|\s+$/g, ""
      lease.field_num = row[13].children[1].children[0].data.replace /^\s+|\s+$/g, ""
      lease.field_name = row[14].children[0].data.replace /^\s+|\s+$/g, ""
      lease.field_type = row[15].children[0].data.replace /^\s+|\s+$/g, ""
      lease.operator_num = row[16].children[0].data.replace /^\s+|\s+$/g, ""
      lease.operator_name = row[17].children[0].data.replace /^\s+|\s+$/g, ""
      lease.acres = (Number) row[18].children[0].data.replace /^\s+|\s+$/g, ""
      lease.deliv_mcf = (Number) row[19].children[0].data.replace /^\s+|\s+$/g, ""
      lease.allowable = row[20].children[0].data.replace /\s/g, ""
      g10_url = row[9].children[1].attribs['href']
      scraper.fetchG10(lease, g10_url, _cb)
    request.get(base_url + lease_url, parse_page)


  fetchG10: (lease, g10_url, callback) =>
    # Fetch lease G10 details, parse page, add details to lease object,
    # send lease object to callback, etc.
    # TODO: same consistency and sanity checking as before
    base_url = "http://webapps2.rrc.state.tx.us/EWA/"
    parse_page = (error, response, body) =>
      _cb = callback
      scraper = @
      if(error or response.statusCode != 200)
        return _cb(error, undefined)  # this should actually call an error handler
                                 # for a lease g10 failure, probably set in the
                                 # scraper's constructor as another failure func
      $ = cheerio.load(body)
      # There are some fields on this page that we already grabbed in the
      # lease details, so for now overwrite those but it would be good to check
      # for inconsistency...
      # TODO: If a field is missing, replace it with something or just leave it out?
      try
        top = $('.GroupBox1')[0]
        lease.district = top.children[1].children[3].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        lease.field_type = top.children[1].children[7].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        lease.operator_name = top.children[3].children[3].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        lease.operator_num = top.children[3].children[7].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        lease.lease_name = top.children[5].children[3].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        lease.lease_num = top.children[5].children[7].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        lease.well_num = top.children[7].children[3].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        lease.api = top.children[7].children[7].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        lease.field_name = top.children[9].children[3].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        lease.field_num = top.children[9].children[7].children[0].children[0].data.replace /\s/g, ""
        lease.monthly_allowable = top.children[11].children[1].children[3].children[0].children[0].data.replace /\s/g, ""
        if top.children[11].children[1].children[7].children[0].children.length > 0
          lease.top_allowable = (Number) top.children[11].children[1].children[7].children[0].children[0].data.replace /^\s+|\s+$/g, ""
        details = $('.GroupBox1')[1]
        lease.well_type = details.children[3].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.capability = (Number) details.children[5].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.special_daily_amount = (Number) details.children[7].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        if details.children[9].children[3].children.length > 0
          lease.special_allowable_code = details.children[9].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.k2_special_flag = details.children[11].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.deliverability_mcf = (Number) details.children[13].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.calc_deliv_potential = (Number) details.children[15].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.shut_in_pressure = (Number) details.children[17].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.bottom_hole_pressure = (Number) details.children[19].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.rock_pressure = (Number) details.children[21].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.gas_grav = (Number) details.children[23].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.cond_grav = (Number) details.children[25].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.gor = (Number) details.children[27].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.acre_feet = (Number) details.children[29].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.acres = (Number) details.children[31].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        if details.children[33].children[3].children.length > 0
          lease.g1_test = details.children[33].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.g1_test_gas = details.children[35].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        if details.children[37].children[3].children.length > 0
          lease._14_b2_flag = details.children[37].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease._14_b2_code = details.children[39].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        if details.children[41].children[3].children.length > 0
          lease._14_b2_date = details.children[41].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        if details.children[43].children[3].children.length > 0
          lease.form_lack = details.children[43].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.exception_g10_test = details.children[45].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.exception_bhp_test = details.children[47].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.exception_sip_test = details.children[49].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        test_info = $('.GroupBox1')[2]
        lease.test_type = test_info.children[3].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.test_date = test_info.children[5].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.effective_date = test_info.children[7].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.gas_mcf = (Number) test_info.children[9].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.condensate_bbls = (Number) test_info.children[11].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.water_bbls = (Number) test_info.children[13].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.shut_in_well_head_pressure = (Number) test_info.children[15].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.gas_gravity = (Number) test_info.children[17].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.condensate_gravity = (Number) test_info.children[19].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.flowing_pressure = (Number) test_info.children[21].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        # We already have a bottom hole pressure but I am keeping this as well
        lease.test_bottom_hole_pressure = (Number) test_info.children[23].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        # Same with this...
        lease.test_calc_deliv_potential = (Number) test_info.children[25].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.gas_condensate_ratio = (Number) test_info.children[27].children[3].children[0].data.replace /^\s+|\s+$/g, ""
        lease.potential = (Number) test_info.children[29].children[3].children[0].data.replace /^\s+|\s+$/g, ""
      catch e
        message = "Error scraping API #{lease.api} Lease Num #{lease.lease_num}, #{e.stack}"
        _cb(message, undefined)
      _cb(undefined, lease)
    request.get(base_url + g10_url, parse_page)

exports.Scraper = Scraper
