# 1. The challenge: 
Identify all users in the NY Metro area for Citibike partnership.
# 2. The approach:
- Identify what area the NY Metro area covers.
- Define metholody for determing a users location.
  - IP address where an event occurred.
- Which event to use?
  - A user can have unlimited number of events.
- Linking event data to the NY Metra area.
# 3. The solution:
- Pull list of all NY Metro area zip codes.
  - NY_Metro_Area_Zipcodes.ipynb
- Import IP range lookup.
  - load_maxmind_geo_ip_manually.sql
- Build tables to calculate events per ip address per user.
  - user_event_ip_counts.sql
  - user_purchase_ip.sql
