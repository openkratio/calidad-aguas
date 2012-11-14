from calidadaguas import CSVWriter, NayadeScraping

# We don't know the number of beaches, we have to bruteforce it.
for i in range(1, 1979):
  # Get the beach info.
  scraping = NayadeScraping.NayadeScraping()
  scraping.scrap(i)

writer = CSVWriter.CSVWriter()
writer.dump_data(scraping.beaches)
