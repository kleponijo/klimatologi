// Perlu handle semua kasus ini:
TimestampParser.parse(1777807041)      // Unix detik → DateTime
TimestampParser.parse(1777807041000)   // Unix milidetik → DateTime  
TimestampParser.parse("14:26:01")      // String jam saja → DateTime hari ini
TimestampParser.parse("2025-03-05T14:26:01") // ISO string → DateTime
TimestampParser.parse(null)            // fallback → DateTime.now()