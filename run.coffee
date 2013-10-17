# Dirty script to run scraper outside mocha

Scraper = require('./src/lib/rrc_g10_scrape').Scraper

total_leases = 0
handler = (err, result) =>
  if err?
    return console.log err
  # console.log result
  total_leases += 1
  console.log "Got lease num #{result.lease_num}, total leases so far: #{total_leases}"


console.log "Running Scraper"
(new Scraper()).run("01", "PR", handler)
