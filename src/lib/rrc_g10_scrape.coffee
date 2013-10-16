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
  maxPages: 1  # Maximum number of lease pages to fetch (100 leases per page)

  run: (district, wellType, callback) ->
    # Callback should be called with either a lease or an error
    return @fetchLeaseList(district, wellType, page, callback) for page in [0...@maxPages]

  fetchLeaseList: (district, wellType, page, callback) ->
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

    # Fake lease list
    list = [1, 2, 3, 4, 5]
    @fetchLease(id, callback) for id in list

  fetchLease: (lease_id, callback) ->
    # Fake success result
    callback(null, {API: lease_id})


exports.Scraper = Scraper
