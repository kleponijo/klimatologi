# TODO - Evaporasi Date Picker Feature

## Status: COMPLETED ✅

### Steps:

- [x] 1. Add table_calendar package to pubspec.yaml
- [x] 2. Update EvaporasiState - add selectedDate and EvaporasiViewMode
- [x] 3. Update EvaporasiEvent - add EvaporasiDateSelected and EvaporasiViewModeChanged
- [x] 4. Update EvaporasiBloc - handle date selection + view mode
- [x] 5. Add toSpecificDate function to TimeSeriesMapper
- [x] 6. Create EvaporasiDatePicker widget (WhatsApp-style calendar)
- [x] 7. Update EvaporasiPeriodSelector - add date picker button
- [x] 8. Update EvaporasiScreen - integrate date picker + show selected date
- [x] 9. Update EvaporasiChartWidget - handle custom date display (already supports "Tanggal Khusus")

### Summary:

Feature implemented successfully:

1. **Date Picker Button**: Added next to period tabs (Hari Ini, Minggu Ini, Bulan Ini)
2. **WhatsApp-style Calendar**: Using table_calendar with Indonesian format
3. **Custom Date Display**: Shows selected date above the period selector
4. **24-hour Chart**: For custom date, shows hourly data (same as "Hari Ini")
5. **Period Mode**: Users can switch back to period mode by clicking any period tab

### Notes:
- Using table_calendar: ^3.1.2
- Date format: Indonesian locale (id_ID)
- Similar to WhatsApp chat date picker functionality
