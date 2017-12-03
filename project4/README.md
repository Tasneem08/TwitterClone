# Project4

**Twitter Clone Part 1**

## Group Members
Tasneem Sheikh  UFID 0136-0914
Mugdha Mathkar  UFID 5414-7979

## HOW TO RUN
for starting the Engine (server)
/project4

for starting the Simulator (clients)
/project4 serverIP numClients

Tweets received at the server will be logged on the console on the engine window along with the tweet ID.
Tweets received by the users will be logged on the console on the simulator window.

## What is working
Twitter Engine :
    Register
    Subscribe to other users according to Zipf distribution
    Tweet endlessly
    Retweet the tweets received randomly
    Query Tweets
    Query Tweets by mentions
    Query Tweets by Hashtag
    Receive Live tweets

Simulator :
    Subscribing users according to Zipf Distribution
    Setting the frequency of tweets according to Zipf (more popular tweets more frequently)
    Retweet randomly any of the received tweet. This may include a tweet from someone the user follows, a tweet where the user is mentioned or a tweet queried from a hashtag.
    Period of Live connection and disconnection

## Other Features
Engine and Client are separate processes.
Multiple genservers for clients and a single genserver for Engine.

## Max number of Clients
The code runs perfectly for 70000 users.

## Total number of tweets / sec
For a simulation involving 10000 users, the total tweets per second was reported as 826.

