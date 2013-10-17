# Dirty script to run scraper outside mocha
util = require('util')
Scraper = require('./src/lib/rrc_g10_scrape').Scraper

# The scraper emits a number of events which we handle here, check the Scraper
# class docs for a description of available events

scraper = new Scraper()

scraper.on 'fetchLeaseListError', (error) ->
  console.log "Error fetching lease list! Code: #{error.code} Message: #{error.message}"

scraper.on 'fetchedLeaseList', (response, body) ->
  # Parse the lease list
  scraper.parseLeaseList(response, body)

scraper.on 'parseLeaseListError', (error) ->
  console.log "Error parsing lease list! Stack:\n #{error.stack}"

scraper.on 'parsedLeaseList', (lease_urls) ->
  console.log "Found #{lease_urls.length} leases!"
  for url in lease_urls
    scraper.fetchLeaseDetails(url)

scraper.on 'fetchLeaseDetailsError', (error) ->
  console.log "Error fetching lease details! Code: #{error.code} Message: #{error.message}"

scraper.on 'fetchedLeaseDetails', (response, body) ->
  scraper.parseLeaseDetails(response, body)

scraper.on 'parseLeaseDetailsError', (error) ->
  console.log "Error parsing lease details! Lease: #{util.inspect(error.lease)} Stack:\n #{error.stack}"

scraper.on 'parsedLeaseDetails', (lease, g10_url) ->
  scraper.fetchG10(lease, g10_url)

scraper.on 'fetchLeaseG10Error', (error) ->
  console.log "Error fetching lease G10! Code: #{error.code} Message: #{error.message}"

scraper.on 'fetchedLeaseG10', (lease, response, body) ->
  scraper.parseG10(lease, response, body)

scraper.on 'parseLeaseG10Error', (error) ->
  console.log "Error parsing Lease G10 Data! Lease: #{util.inspect(error.lease)} Stack:\n #{error.stack} \n URL:\n #{error.url}"

total_leases_scraped = 0
scraper.on 'parsedLeaseG10', (lease) ->
  total_leases_scraped += 1
  console.log "Scraped #{total_leases_scraped} leases so far..."

maxPages = 1  # 100 results per page
scraper.run("01", "PR", 1)
