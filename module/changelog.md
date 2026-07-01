## 2.2
- Fixed a bug where battery charging check could be skipped silently.
- Added a safety guard for package list in usage data collection.
- Boot timeout now writes a message to kernel log for easier debugging.
- Compiler thread count is now based on your actual CPU cores instead of always using 4.
