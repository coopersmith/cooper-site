
Nike+ is a revolutionary product in personal fitness. In its five years, its motivated millions of people to get off the couch and go for a run. At the completion of their run, the user is given a handful of useful metrics (time, pace, and route) in an effort to improve their next run.  
  
What it doesn't offer, however, is a holistic representation of the data. What does it look like when an entire city goes running (with Nike+)? And how can we use that data to improve the experience of runners within their city?  
  
For Nicholas Felton’s Information Visualization course, we were given a CSV of 1,000 runs of Nike+ data, and two weeks to tell a story with it, which I chose to do through a timelapse video. But during this process, I encountered countless other stories that I wanted to explore once the semester was completed. Over the course of the next summer, I set out to do a complete audit of running in New York City, publishing new visualizations on my blog as they were completed. This project culminated with me working with WIRED UK to do a full spread visualization, using a new dataset of 10,000 runs throughout London, for their October 2011 issue.



## Initial Study - Time of Day

I was interested in visualizing not only where these runs were taking place, but also, at what time of day. I decided to create a timelapse video, displaying each individual route at the time of day it took place. Moreover, I elected to use a base map of New York City, but rather, let the running data generate the map as the runners move throughout the city. Paths, streets, and bridges all start to emerge as the day goes on and more runners move through the city. These videos focus on three views - NYC as a whole, as well as two areas where I found there to be the largest concentration of runners, Central Park and the three bridges of the East River.


  

In hindsight, I feel that these videos, though nice looking, were a bit convoluted in the information presented and what a viewer could extract from them. Additionally, I came to realize that though time of day was interesting, it was just one of many stories that could be told, as demonstrated below. Finally, in the rush of a grad school class, I realized that I made small errors in my data cleaning, such as not accounting for daylight savings time, that I have since corrected.


## Location

After countless hours cleaning the data in Google Refine, and even more hours in Processing, I arrived at one of the simplest visualizations, location.


JPG OF LOCATION


Though this rendering offers very little information about individual runs and the data within them, I love the story that it does tell about location. The GPS data draws its own map of New York City, from the shape of the Manhattan landmass down to its individual streets.




## Popularity of Routes

Next, I wanted to explore how popular these different routes were. I achieved this by creating a simple heat map of all the runs, examining how many runners shared the same route over the course of this data set.


Not surprisingly, Central Park and the trails along the edge of Manhattan emerge as the most popular, as well as the bridges between Manhattan & Brooklyn.