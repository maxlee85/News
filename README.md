# 1. The challenge (not a personal project): 
Identify all users in the NY Metro area for Citibike partnership.
# 2. The approach:
- Identify what area the NY Metro area covers.
- Explore options for defining a users location.
  - IP address where an event occurred.
- Determine which event to use.
  - A user can have unlimited number of events.
- Linking event data to the NY Metro area.
  - IP address to zip code.
  - An ip address can be converted to an integer... ie 192.0.2.0 -> 3221225984.
# 3. The solution:
- Pull list of all NY Metro area zip codes.
  - NY_Metro_Area_Zipcodes.ipynb
- Import NY zip codes
  - Copy from .csv created via NY_Metro_Area_Zipcodes.ipynb
    - aaptiv_core.geo_ip.ny_metro_zipcodes
- Import IP location lookup.
  - load_maxmind_geo_ip_manually.sql
    - aaptiv_core.geo_ip.ip_location
- Build tables to calculate events per ip address per user.
  - user_event_ip_counts.sql
  - user_purchase_ip.sql
- Determine which ip address to use per users as their location.
  - signup_ip_majority.sql
- Pull emails from users in NY Metro area.
  - member_emails.sql
