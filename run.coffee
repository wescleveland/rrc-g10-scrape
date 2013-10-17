# Dirty script to run scraper outside mocha
util = require('util')
Scraper = require('./src/lib/rrc_g10_scrape').Scraper
json2csv = require('json2csv')
fs = require('fs')
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

###
For this example we are going to write the leases to a csv file called
lease_g10.csv.  For now, check to see if total_leases_scraped == maxPages * 100,
and if this is true then dump our lease list into a csv...

In the real world, you would be inserting to a database or something...
###
maxPages = 2  # 100 results per page
leases = []

csv_fields = [
  'api',
  'district',
  'lease_num',
  'lease_name',
  'well_num',
  'well_type'
  'field_num',
  'field_name',
  'field_type',
  'operator_num',
  'operator_name',
  'acres',
  'acre_feet'
  'deliv_mcf',
  'allowable',
  'monthly_allowable',
  'top_allowable',
  'capability',
  'special_daily_amount',
  'special_allowable_code',
  'k2_special_flag',
  'deliverability_mcf',
  'calc_deliv_potential',
  'shut_in_pressure',
  'bottom_hole_pressure',
  'rock_pressure',
  'gas_grav',
  'cond_grav',
  'gor',
  'g1_test',
  'g1_test_gas',
  '_14_b2_flag',
  '_14_b2_code',
  '_14_b2_date',
  'form_lack',
  'exception_g10_test',
  'exception_bhp_test',
  'exception_sip_test',
  'test_type',
  'test_date',
  'effective_date',
  'gas_mcf',
  'condensate_bbls',
  'water_bbls',
  'shut_in_well_head_pressure',
  'gas_gravity',
  'condensate_gravity',
  'flowing_pressure',
  'test_bottom_hole_pressure',
  'test_calc_deliv_potential',
  'gas_condensate_ratio',
  'potential'
]

scraper.on 'parsedLeaseG10', (lease) ->
  total_leases_scraped += 1
  console.log "Scraped #{total_leases_scraped} leases so far..."
  leases.push(lease)
  if total_leases_scraped == (maxPages * 100)
    # Scraping is done
    # This is bad, if a lease fails then we don't get here!  But it works for
    # testing purposes.
    json2csv {data: leases, fields: csv_fields}, (err, csv) ->
      if err?
        console.log(err)
      fs.writeFile 'lease_g10.csv', csv, (err) ->
        if err?
          throw err
        console.log('file saved')

scraper.run("01", "PR", maxPages)
