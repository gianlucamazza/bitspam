#!/bin/sh
SPAM_AMOUNT=0.00001
SPENT=0
while true
do
	# if balance > spam_amount
	PREV_BALANCE=$(bitcoin-cli getbalance)
	status=`echo $PREV_BALANCE'>'$SPAM_AMOUNT | bc -l`
	if [ $status -gt 0 ] 
		then
			# ask bitcoind for new address
			NEWADDR=`curl -s --data-binary '{"jsonrpc": "1.0", "id":"curltest", "method": "getnewaddress", "params": [] }' -H 'content-type: text/plain;' http://test:test@127.0.0.1:18888/ | jq -c .result`
        		echo "sending transaction to $NEWADDR"
			
			# clean response
			NEWADDR=$( echo $NEWADDR | sed 's/[^a-z A-Z 0-9]//g' )

			# prepare data for sendtoaddress
			DATA=$( jq -n --arg address "$NEWADDR" --arg amount "$SPAM_AMOUNT" '{"jsonrpc":  1.0, "id":"curltest", "method": "sendtoaddress", "params": [ $address , $amount , "donation", "seans outpost"]}' )
			
			# broadcast sendtoaddress
			curl -s --data-binary "$DATA" -H 'content-type: text/plain;' http://test:test@127.0.0.1:18888/ | jq .result

			# update stats
			POST_BALANCE=$(bitcoin-cli getbalance)
			TXFEE=`echo $PREV_BALANCE'-'$POST_BALANCE | bc -l`
        		echo "BALANCE: $POST_BALANCE - txfee: $TXFEE"
			echo "mempoolsize: `bitcoin-cli getmempoolinfo | jq .size`\n"
		else
			# no balance
			echo "no enough fund to send transactions. waiting 60 secs"
			sleep 60
	fi
sleep 0
done
