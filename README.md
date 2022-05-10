# BeerGame

# Setup

## dependencies
`mix deps.get`

## database migration (MySQL)
`mix ecto.setup`


## start
`mix phx-server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# What it is this?
The beer game it's a practice in systems thinking that can help you understand the interoperability of actors in a complex systems. In this case we have 3 roles:

1. Retailer: It is a local store in a neighbourhood, it sell several brands of beers, as well as other products, but there is an specific beer that it has been consume more and more every day, unfortunately, you don't know the reason but you are running out of stock and now it's time to increase other sizes.

2. Wholesaler: It is in charge to fulfill the others of all local retailers in an area, as in the retailer case, you experience and increase in orders for that new beer but you don't know the reason.

3. Factory: The brewery it's responsible to produce all beer, it has some production limitations, it is just an small brewery.

The different actor can't talk to each other directly, as in supply chain, the feedback has a delay of days or weeks, and there is not direct point of contact with someone who can provide the answers.

# Expected Outcome?
The game will open your eyes in some key concepts of systems thinking. Delays, connections, feedback loops, and more. You should see how you actions affect everyone else, and if you understand the root cause you can correct you actions and create a better outcome.