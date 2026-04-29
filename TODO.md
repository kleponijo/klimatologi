# TODO: Add Live Streaming Graphs to Home Dashboard

## Plan Steps (Approved)

1. ✅ [Complete] Create & fix `lib/screens/monitoring/atmospheric_conditions/views/widgets/atmospheric_chart_widget.dart` (compact LineChart, linter clean).

2. ✅ Update `lib/screens/monitoring/atmospheric_conditions/blocs/atmospheric_conditions_state.dart` - Add `dailyTemperatures: List<double>`.

3. ✅ Update `lib/screens/monitoring/atmospheric_conditions/blocs/atmospheric_conditions_bloc.dart` - Add rolling dailyTemperatures list in `_onUpdated`.


4. ✅ Home dashboard final: removed RefreshIndicator per feedback (no button needed), streams auto-live. Linter clean.

5. [ ] Test: `flutter run` - Verify live updates on home dashboard.

6. [ ] Optional: Add refresh button or auto-period selector.

**Next Step**: Starting with Step 1.

