# Note: I wrote the profit and loss thresholds first but they are not 
# really used now since I added the market trend threshold technique 
# which works better.

# This was a fun exercise, I'd love to spend more time on it. If I had more time
# I would probably focus on better recognising patterns for when the market is 
# about the shift. Also with more parameters I would consider rewriting it as
# a genetic algorithm so I could evolve a the best solution.

# Fun fact: I tweaked the code at one point to also pass the algorithm the 
# next tick's price to see what amount of profit is possible with an algorithm that knows
# EXACTLY when the price is in a peak or a trough - it made: $4,536,268.36! :O

# http://s2.quickmeme.com/img/b2/b26aca6de3c1bae6ca2b2eb5b924ea4135b470442f4d2fc669c1941975762875.jpg

# Parameters
buyPercent = .76
buyAmount = 0
takeProfitPercent = 1.2
stopLossPercent = 0
trendBuyThreshold = 1
trendSellThreshold = -1

# Used to store the market price direction and trending tick duration
trend = 0
lastPrice = 0 

openTrade = null

# Function for placing a sell order
sell = (candle, account) ->
	order = null
	price = candle.avgPrice
	
	return if account.USD < buyAmount
	
	# If it looks like the BTC Price is trending upward then trade USD for BTC
	if trend == trendBuyThreshold
		# Create a sell order 
		order = sell: buyAmount
		
		# Record this trade so we know when to buy back USD based on our risk limits
		openTrade =
			usd: buyAmount
			btc: buyAmount / price
			price: price
			takeProfit: price * takeProfitPercent
			stopLoss: price * stopLossPercent
	
	# Return the order
	order

# Function for placing a buy order
buy = (candle, account) ->
	order = null
	price = candle.avgPrice
	
	if openTrade
		# If the price has exceeded our acceptable profit / loss margins then trade BTC back for USD
		hasHitProfitThreshold = price >= openTrade.takeProfit
		hasHitLossThreshold = price <= openTrade.stopLoss
		isMarketFalling = trend <= trendSellThreshold
		
		if hasHitProfitThreshold or hasHitLossThreshold or isMarketFalling
			# Create a buy order
			# Minus a little bit to get around floating point inaccuracies causing to buy more than we can afford
			order = buy: (Math.min(openTrade.btc, account.BTC) * price) - 0.00001 # <-- Minus a little bit to get around floating point inaccuracies causing to buy more than we can afford 
			openTrade = null 
	
	# Return the order
	order

# Tick function
exports.tick = (price, candle, account) ->
	# Set the amount we'll trade based on our initial balance
	if not buyAmount
		buyAmount = account.USD * buyPercent
	
	# Work out the market trend
	if !lastPrice
		trend = 0
	else if price > lastPrice
		if trend < 0
			trend = 1
		else
			trend++
	else if price < lastPrice
		if trend > 0
			trend = -1
		else
			trend--
	
	# Check if we should buy USD with our BTC
	order = buy candle, account
	
	# Check if we should sell USD (unless we already have a buy order in this tick)
	order = sell candle, account unless order 
	
	# Remember the last price
	lastPrice = price
	
	# Return the order
	order