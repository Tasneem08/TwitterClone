# Project4

**Twitter Clone Part 1**

## Group Members
Tasneem Sheikh  UFID 0136-0914 <br />
Mugdha Mathkar  UFID 5414-7979

## HOW TO RUN
for starting the Engine (server) <br />
/project4 <br />

for starting the Simulator (clients) <br />
/project4 serverIP numClients <br />

Tweets received at the server will be logged on the console on the engine window along with the tweet ID. <br />
Tweets received by the users will be logged on the console on the simulator window.

## What is working
Twitter Engine : <br />
    Register <br />
    Subscribe to other users according to Zipf distribution <br />
    Tweet endlessly <br />
    Retweet the tweets received randomly <br />
    Query Tweets <br />
    Query Tweets by mentions <br />
    Query Tweets by Hashtag <br />
    Receive Live tweets

Simulator : <br />
    Subscribing users according to Zipf Distribution <br />
    Setting the frequency of tweets according to Zipf (more popular tweets more frequently) <br />
    Retweet randomly any of the received tweet. This may include a tweet from someone the user follows, a tweet where the user is mentioned or a tweet queried from a hashtag. <br />
    Period of Live connection and disconnection

## Other Features
Engine and Client are separate processes. <br />
Multiple genservers for clients and a single genserver for Engine.

## Max number of Clients
The code runs perfectly for 70000 users.

## Total number of tweets / sec
For a simulation involving 10000 users, the total tweets per second was reported as 826.

