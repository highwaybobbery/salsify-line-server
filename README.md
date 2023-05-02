# Salsify Coding Challenge: File Line Server
## Overview
This solution uses a Sinatra app on Puma with a Redis data store to serve arbitrary lines of a given file as quickly as possible, supporting many connections.

## Setup
Install the following on your machine:
Ruby (I used ruby 3.x, but any modern ruby should work fine)
Redis (I installed the latest with Homebrew)

Run build.sh to install the gems (or simply bundle install)

## Starting the server
run runs.sh path_to/textfile.txt (with a path from project root to your text file)
The application will launch on port 3000.

NOTE: the first request will actually read and cache the file lines, so it will take substantially longer than subsequent requests.

## Architecture and design considerations
Since the application really only has one feature, I went with Sinatra as an application framework. It had the right set of features without the overhead of something more substantial like Rails.
To give access to the individual lines, I went with Redis as a way to serve each line with minimal latency.
On the first request the cache is warmed by running over all lines of the file, and puting them in redis, keyed by line number.
Subsequent requests are served in ~2ms, regardless of file size.

## Scaling considerations
The main failure point of this approach with regards to scaling would be very large files. Because we are using a memory backed cache, this could become prohibative.
To scale to larger files, or more files, redis could be clustered and sharded, so that different clusters hosted different data sets.
If in memory cache proved cost prohibitive, the storage could be switched to disk based, likely using postgres.
If the usage pattern is that there are many requests for the same lines, this could also have redis in front of it, as a read-through cache
Clustering redis or the database is also part of scaling to higher request rates, but ultimately you would also need to add more application instances as well, and a load balacer to even out the traffic.
