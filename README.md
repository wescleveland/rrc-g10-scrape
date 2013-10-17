# RRC G10 Data Scraper

Scraper for G10 reports from RRC Database

Written in CoffeeScript, uses request and cheerio.

Read the Scraper class docs for more info on the events emitted by the scraper,
and run.coffee for examples of using those events.

## Quick Start
Scrape the first 2 pages:
```javascript
coffee run.coffee
```
This writes results to lease_g10.csv (overwriting existing file)

To scrape more pages of results, change the maxPages var on line 56 of run.coffee.  Just a heads up though,
scraping a higher number of pages can take a few minutes and might be hard on the RRC servers.

## Scraper Events
This is just copied from the Scraper class docs:

- fetchedLeaseList = Emits (response, body) from request.get
- fetchLeaseListError = Emits error from request.get's callback

- parsedLeaseList = Emits array of lease details urls
- parseLeaseListError = Emits an error with the following attribs:
  - url: the url that we attempted to parse
  - stack: the error's stacktrace
  - code: response status code
  - body: the html body we attempted to parse

- fetchedLeaseDetails = Emits (response, body) from request.get
- fetchLeaseDetailsError = Emits error from request.get's callback

- parsedLeaseDetails = Emits the following attribs:
  - lease: the lease object parsed from details
  - g10_url: the lease's G10 test url
- parseLeaseDetailsError = Emits an error with the following attribs:
  - url: the url that we attempted to parse
  - stack: the error's stacktrace
  - body: the html body we attempted to parse
  - code: response status code
  - lease: whatever we did manage to grab from the lease details

- fetchedLeaseG10 = emits (lease, response, body)
- fetchLeaseG10Error = emits error from request.get's callback

- parsedLeaseG10 = emits fully populated lease object
- parseLeaseG10Error = emits error with the following attribs:
  - url: the url that we attempted to parse
  - stack: the error's stacktrace
  - body: the html body we attempted to parse
  - code: response status code
  - lease: whatever we have managed to parse so far


## TODO
There are a number of TODO's within the scraper's code, most involving inconsistency checks and making
this scraper more robust.

Before anyone goes and scrapes every G10 report out there, I would recommend adding rate limiting!

Finally, the example run.coffee writes results to a csv, but you'd probably want a parsedLeaseG10 event handler
that writes to a database or something.
